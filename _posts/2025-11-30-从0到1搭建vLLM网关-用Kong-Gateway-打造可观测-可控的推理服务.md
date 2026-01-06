---
layout: post
title: 从 0 到 1 搭建 vLLM 网关：用 Kong Gateway 打造可观测、可控的推理服务
slug: vllm-gateway-kong
date: 2025-11-30 10:00 +0800
categories: [大模型]
tags: [kong, vllm, gateway, monitoring]
---

## 背景

在企业内部部署 vLLM 提供大模型推理服务时，如果直接把服务端口暴露在内网，往往会遇到下面这些“裸奔”问题：

1. **无权限控制**：API 地址一旦泄露，任何人都能调用，GPU 资源容易被滥用。  
2. **无流量限制**：某个脚本写了个死循环，瞬间把显卡打满，其他同事的任务直接被拖垮。  
3. **无监控审计**：不知道是谁用了多少 Token，很难做成本核算和容量规划。  
4. **协议兼容性差**：希望完全兼容 OpenAI SDK 的 `Authorization: Bearer sk-xxx` 格式，让用户零改造迁移到自建网关。

本文记录了一套在 **离线**、**多核 CPU** 的 Linux 服务器上，基于 **Kong Gateway** 对 vLLM 推理服务进行治理的完整实践，从部署、认证、限流到日志审计与监控，一步步搭建出一个**兼容 OpenAI 协议、具备身份认证、限流与可视化监控**的内部 LLM 网关。

---

## 一、环境准备与离线部署

**环境概况：**

- **OS**：Linux (Ubuntu)  
- **Hardware**：AMD EPYC 9654（384 vCores），高性能 GPU 服务器  
- **Network**：内网环境，无互联网连接  
- **vLLM**：已部署并监听 `0.0.0.0:8000`

### 1.1 镜像准备（离线方案）

由于服务器无法联网，需要在一台有公网访问能力的机器上提前拉取并导出镜像。

在有网机器上执行：

```bash
# 在有网机器执行
docker pull kong/kong:latest
docker pull postgres:13
docker pull prom/prometheus:latest
docker pull grafana/grafana:latest

docker save -o kong.tar kong/kong:latest
docker save -o postgres.tar postgres:13
# ... 其他镜像按需导出
```

将生成的 `*.tar` 镜像文件上传到内网服务器后，在服务器上加载：

```bash
docker load -i kong.tar
docker load -i postgres.tar
# ... 其他镜像同理
```

---

## 二、核心组件部署（踩坑与优化）

### 2.1 部署 PostgreSQL

Kong 需要数据库存储配置（Service、Route、Plugin、Consumer 等元数据），这里使用 PostgreSQL。

**踩坑：Connection Pool**

一开始我们把 `max_connections` 设置为 300，但服务器有 384 个 CPU 核心，Kong 默认会根据核心数启动 384 个 Nginx Worker，结果数据库连接瞬间被耗尽，日志中持续出现：

> FATAL: sorry, too many clients already

**解决思路**：适当提高数据库的最大连接数，与 Kong Worker 数量保持匹配。

启动 PostgreSQL：

```bash
docker run -d --name kong-database \
  --network host \
  -e POSTGRES_USER=kong \
  -e POSTGRES_DB=kong \
  -e POSTGRES_PASSWORD=mysecret \
  postgres:13 \
  postgres -c max_connections=1000  
  # 关键优化：提高最大连接数
```

### 2.2 初始化数据库

使用 Kong 官方镜像完成数据库初始化与迁移：

```bash
docker run --rm --network host \
  -e KONG_DATABASE=postgres \
  -e KONG_PG_HOST=127.0.0.1 \
  -e KONG_PG_USER=kong \
  -e KONG_PG_PASSWORD=mysecret \
  kong/kong:latest kong migrations bootstrap
```

### 2.3 部署 Kong Gateway（治本优化）

为避免高核心数导致的资源浪费和数据库连接竞争，需要显式限制 Worker 数量，并拉长长耗时推理请求的超时时间。

```bash
docker run -d --name kong-gateway \
  --network host \
  -e KONG_DATABASE=postgres \
  -e KONG_PG_HOST=127.0.0.1 \
  -e KONG_PG_USER=kong \
  -e KONG_PG_PASSWORD=mysecret \
  -e KONG_PROXY_LISTEN=0.0.0.0:8111 \
  -e KONG_ADMIN_LISTEN=127.0.0.1:8001 \
  -e KONG_STATUS_LISTEN=0.0.0.0:8100 \
  -e KONG_WORKER_PROCESSES=4 \              
  # 关键：限制 Worker 数量（治本）
  -e KONG_NGINX_PROXY_READ_TIMEOUT=300 \    
  # 关键：防止长文本推理 504 超时
  kong/kong:latest
```

---

## 三、配置 Service 与 Route

通过 Kong Admin API（默认监听在 `127.0.0.1:8001`）对 Kong 进行配置。

### 3.1 创建 Service 和 Route

这里我们将 Kong 反向代理到本地 vLLM 实例的端口 `8000`。

创建 Service：

```bash
curl -i -X POST http://127.0.0.1:8001/services \
  --data name=vllm-service \
  --data url=http://127.0.0.1:8000 \
  --data connect_timeout=5000 \
  --data write_timeout=60000 \
  --data read_timeout=300000  
  # 设置 5 分钟读取超时
```

创建 Route：

```bash
curl -i -X POST http://127.0.0.1:8001/services/vllm-service/routes \
  --data name=vllm-route \
  --data paths[]=/
```

---

## 四、认证与 OpenAI 协议兼容

**问题背景：**

- OpenAI SDK 默认使用 `Authorization: Bearer sk-xxx` 格式传递密钥。  
- Kong 的 `key-auth` 插件默认只识别纯 Key，而不会自动剥离 `Bearer` 前缀。  

如果直接启用 `key-auth`，就会频繁遇到 `401 Unauthorized`。  
我们尝试过使用 `request-transformer` 正则替换 Header，但在特定版本上存在兼容性问题。  
Kong 的 **AI Proxy** 插件本身可以处理这类协议适配工作，但在本次实践中我们已经跑通了 **Serverless Lua（pre-function）** 方案，ai-proxy最大的好处可以看到token的使用量，但是对于小团队而言作用性并不大。

### 4.1 使用 Lua 脚本剥离 Bearer 前缀

通过 `pre-function` 插件注入一小段 Lua 脚本，将 `Authorization` 头中的 `Bearer ` 前缀去掉，并把 Key 写入 `X-API-Key` 头中，供 `key-auth` 插件识别。

```bash
curl -i -X POST http://127.0.0.1:8001/services/vllm-service/plugins \
  --data name=pre-function \
  --data "config.access[1]=
    local auth = kong.request.get_header('Authorization')
    if auth then
      local token = auth:gsub('Bearer ', '')
      kong.service.request.set_header('X-API-Key', token)
    end"
```

### 4.2 启用 Key Auth 插件

```bash
curl -i -X POST http://127.0.0.1:8001/services/vllm-service/plugins \
  --data name=key-auth \
  --data config.key_names=X-API-Key
```

### 4.3 创建用户与密钥

创建一个示例用户（工号为 `z123456`），并为其生成一个以 `sk-` 开头的 Key，方便与 OpenAI 的习惯保持一致。

```bash
# 创建工号为 z123456 的用户
curl -i -X POST http://127.0.0.1:8001/consumers/ \
  --data username=z123456

# 为用户分配 Key
curl -i -X POST http://127.0.0.1:8001/consumers/z123456/key-auth \
  --data key=sk-z123456
```

---

## 五、限流与监控（Prometheus + Grafana）

在多租户场景下，限流与监控是生产可用的关键要素。

### 5.1 配置限流（Rate Limiting）

目标：防止单个用户过度刷接口，影响其他人的使用。

```bash
curl -i -X POST http://127.0.0.1:8001/services/vllm-service/plugins \
  --data name=rate-limiting \
  --data config.hour=100 \
  --data config.limit_by=consumer
```

上面的配置表示：以 Consumer 维度统计，每个用户每小时最多允许 100 次请求。

### 5.2 启用 Prometheus 插件

Prometheus 插件可以暴露丰富的指标用于监控。  
**关键点**：一定要开启 `per_consumer=true`，否则无法在监控中区分“谁”在用。

```bash
curl -i -X POST http://127.0.0.1:8001/plugins \
  --data name=prometheus \
  --data config.per_consumer=true
```

### 5.3 Grafana 仪表盘实践

在 Grafana 中添加 Prometheus 数据源后，可以基于 Kong 暴露的指标搭建一套实用的看板。

1. **实时速率排行榜（Top Users RPM）**  
   用于观察当前谁在高频调用接口。

   ```bash
   # PromQL：统计每个 consumer 最近 1 分钟内的调用总量，并取前 10 名
   # 注意：这里不要再额外 *60，否则会把“1 分钟窗口内的增量”放大成每分钟速率，容易统计不准
   topk(10, sum by (consumer) (increase(kong_http_requests_total[1m])))
   ```

   建议使用单位：**Requests per minute (rpm)**。  
   在 Grafana 中，这里使用的是 **Code 查询模式（Query mode: Code）**，而不是 Builder；如果选成 Builder，函数和 label 容易被重写，可能出现“实际有流量但图上没有数据”的情况。  
   此外，建议在右侧 `Standard options` 中将 `Decimals` 设置为 **0**，这样右侧数值不会显示小数，更直观（后面几个面板同样推荐将小数位数设为 0）。

2. **今日累计调用量（Daily Usage）**  
   关注当天各用户的总体调用量。

   ```bash
   # PromQL：统计最近 24 小时各 consumer 的请求增量
   topk(10, sum by (consumer) (increase(kong_http_requests_total[24h])))
   ```

   可视化类型可以选择 **Bar Gauge** 或普通柱状图。

3. **错误率分布（按状态码）**  
   用于区分 4xx（访问被网关拦截）与 5xx（系统故障）。

   ```bash
   sum by (code) (increase(kong_http_status_total[1m]))
   ```

4. **24 小时调用量明细表（All Users 24h Usage Table）**  
   用表格的方式展示所有人的使用量：左侧一列为工号（consumer），右侧一列为最近 24 小时调用总量，便于一次性查看整体使用情况。

   ```bash
   # PromQL：按 consumer 统计最近 24 小时的调用总量，用于表格视图
   sum by (consumer) (increase(kong_http_requests_total[24h]))
   ```

   在 Grafana 中选择 **Table** 可视化，将 `consumer` 字段作为左侧“工号”列，右侧这一列命名为“24 小时调用量”，并同样在右侧 `Standard options` 中将 `Decimals` 设为 **0**，避免显示小数。

---

## 六、日志审计与内容分析（Python + PostgreSQL）

Prometheus 适合做“指标”监控，但并不会记录每一次对话的具体内容。  
如果需要审计 Prompt / Response、做质量分析或合规检查，我们需要一套**结构化日志**管道。

本实践中，我们复用已有的 PostgreSQL，配合一个轻量级的 Python Collector 服务进行落库：

> Kong（`http-log` 插件） → Python Collector → PostgreSQL

### 6.1 数据库表结构设计

在 PostgreSQL 中为 LLM 日志创建一张表，使用 `JSONB` 存储原始日志，方便后续做字段扩展或结构化分析。

```sql
CREATE TABLE llm_logs (
  id SERIAL PRIMARY KEY,
  request_id VARCHAR(50),
  consumer_username VARCHAR(50),
  started_at TIMESTAMP,
  latency_ms INTEGER,
  status INTEGER,
  prompt TEXT,
  response TEXT,
  raw_log JSONB,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_llm_logs_consumer ON llm_logs(consumer_username);
CREATE INDEX idx_llm_logs_started_at ON llm_logs(started_at);
```

### 6.2 部署日志收集器（Python）

创建一个 `collector.py`，用于接收 Kong 通过 `http-log` 插件推送的日志，处理 Base64 编码，并将关键信息写入 PostgreSQL。

准备运行环境：

```bash
pip install flask psycopg2-binary
```

`collector.py` 代码如下：

```python
from flask import Flask, request
import psycopg2
import json
import base64
from datetime import datetime

app = Flask(__name__)

# 数据库连接配置（请根据实际情况修改密码等信息）
DB_CONFIG = {
    "dbname": "kong",
    "user": "kong",
    "password": "mysecret",
    "host": "127.0.0.1",
    "port": 5432,
}


def get_db_connection():
    return psycopg2.connect(**DB_CONFIG)


@app.route("/log", methods=["POST"])
def receive_log():
    data = request.json
    conn = get_db_connection()
    cur = conn.cursor()

    try:
        # 1. 基础信息解析
        req_id = data.get("request", {}).get("id")
        consumer = data.get("consumer", {}).get("username", "anonymous")
        started_at = datetime.fromtimestamp(data.get("started_at", 0) / 1000)
        latency = data.get("latencies", {}).get("request")
        status = data.get("response", {}).get("status")

        # 2. Body 解析（处理 Kong 可能的 Base64 编码）
        def parse_body(raw_body):
            if not raw_body:
                return ""
            if isinstance(raw_body, str) and not raw_body.strip().startswith("{"):
                try:
                    return base64.b64decode(raw_body).decode("utf-8")
                except Exception:
                    pass
            return raw_body

        req_text = parse_body(data.get("request", {}).get("body", ""))
        res_text = parse_body(data.get("response", {}).get("body", ""))

        # 3. 提取 Prompt（针对 OpenAI Chat Completions 格式）
        prompt = ""
        try:
            req_json = json.loads(req_text)
            for msg in reversed(req_json.get("messages", [])):
                if msg.get("role") == "user":
                    prompt = msg.get("content", "")
                    break
        except Exception:
            # 格式不符合预期时，截取前 500 字符作为兜底
            prompt = req_text[:500]

        # 4. 提取 Response
        response_content = ""
        try:
            res_json = json.loads(res_text)
            response_content = (
                res_json.get("choices", [{}])[0]
                .get("message", {})
                .get("content", "")
            )
        except Exception:
            response_content = res_text[:500]

        # 5. 入库
        cur.execute(
            """
            INSERT INTO llm_logs
              (request_id, consumer_username, started_at, latency_ms, status, prompt, response, raw_log)
            VALUES
              (%s, %s, %s, %s, %s, %s, %s, %s)
            """,
            (req_id, consumer, started_at, latency, status, prompt, response_content, json.dumps(data)),
        )

        conn.commit()
    except Exception as e:
        print(f"Error: {e}")
        conn.rollback()
    finally:
        cur.close()
        conn.close()

    return "OK", 200


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
```

后台运行 Collector 服务：

```bash
nohup python3 collector.py > collector.log 2>&1 &
```

### 6.3 配置 Kong 推送日志

通过 `http-log` 插件将网关日志推送到刚刚启动的 Python 日志收集服务：

```bash
curl -i -X POST http://127.0.0.1:8001/services/vllm-service/plugins \
  --data name=http-log \
  --data config.http_endpoint=http://127.0.0.1:5000/log \
  --data config.method=POST \
  --data config.timeout=2000 \
  --data config.keepalive=60000 \
  --data config.flush_timeout=2
```

> 注意：如果 vLLM 开启流式响应，默认可能抓不到完整 Response Body。  
> 如需完整审计，可以在 Route 上开启 `response_buffering=true`，但会牺牲流式体验，需要在体验与审计之间做权衡。

### 6.4 基于 PostgreSQL 的可视化分析

配置完成后，可以在 Grafana 中直接接入 PostgreSQL 作为数据源，使用 SQL 查询展示最近的对话记录，例如：

```sql
SELECT
  started_at,
  consumer_username,
  prompt,
  response,
  latency_ms
FROM llm_logs
ORDER BY started_at DESC
LIMIT 50;
```

---

## 七、安全“收尾”：避免绕过网关直连 vLLM

最后一步非常关键：防止用户绕过 Kong 直接访问 vLLM 服务。

### 7.1 修改 vLLM 监听地址

重启 vLLM 容器，增加 `--host 127.0.0.1` 参数，让 vLLM 仅监听本地回环地址：

```bash
docker run ... \
  --host 127.0.0.1 \
  ...
```

这样外部主机无法直接访问 `8000` 端口，只能通过 Kong 网关进来。

### 7.2 Kong Manager UI 访问（通过 SSH 隧道）

由于 Kong Admin API 只在本地监听，需要借助 SSH 隧道在开发机上访问 Kong Manager UI。例如在 Windows 终端执行：

```bash
ssh -L 9002:127.0.0.1:8002 \
    -L 9001:127.0.0.1:8001 \
    user@server_ip
```

然后在浏览器中访问：

- `http://127.0.0.1:9002`：Kong Manager UI  
- `http://127.0.0.1:9001`：Kong Admin API（如需调试）

---

## 总结与避坑清单

这套架构在实践中基本做到了“低成本、强治理”的平衡：既兼容 OpenAI 协议，又补齐了认证、限流与监控能力。

**常见问题与排查建议：**

1. **500 Internal Error**  
   - 重点排查数据库连接池是否耗尽。  
   - 在高核心数服务器上务必显式限制 `KONG_WORKER_PROCESSES`，并相应调大 `PostgreSQL max_connections`。

2. **504 Gateway Timeout**  
   - LLM 推理耗时较长，必须适当提高 Kong 的 `read_timeout`（例如设置为 300s）。  
   - 同时确认后端 vLLM 与网络路径无明显瓶颈。

3. **401 Unauthorized**  
   - 优先检查 `Authorization` 头是否符合 `Bearer sk-xxx` 格式。  
   - Kong 默认不会自动剥离 `Bearer`，需要配合 Lua `pre-function` 或 AI Proxy 做协议适配。

4. **Grafana 中无数据**  
   - 确认 Prometheus 插件是否开启了 `per_consumer=true`。  
   - 使用 `increase()` 时，如果统计窗口内没有流量，会表现为“无数据”；可以尝试拉长窗口到 `1h` 或 `24h`。  
   - PromQL 推荐使用 **Code 模式**手写表达式，Builder 模式在复杂场景下容易“坑”人。

5. **Shell 命令执行异常**  
   - 注意多行 `curl` 命令中，续行符 `\` 后面不能跟空格或空行，否则后续参数会被当作新的命令。  
   - 建议在终端中先单行调通，再整理为多行命令写入文档。

通过上述实践，我们在一个纯内网环境中，以相对低的工程成本，搭建出了一套 **兼容 OpenAI 协议、支持多租户认证、具备精准限流和可观测能力** 的内部大模型网关，为后续的 LLM 应用落地打下了坚实基础。


