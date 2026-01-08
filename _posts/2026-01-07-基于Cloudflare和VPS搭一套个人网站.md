---
layout: post
title: 基于Cloudflare和VPS搭一套个人网站
slug: cloudflare-vps-personal-site
date: 2026-01-07 22:14 +0800
categories: [运维]
tags: [cloudflare, vps, docker, rss, self-hosted]
---

## 前言


最近在cloudflare上购买了域名，有了域名之后配合VPS发现其实可以做很多有意思的事情，比如：
- Cloudflare 免费邮件转发
- 建立“私人短链接”系统 (Short URL)
- 造个人“数字名片盒” (Link-in-bio)
- 无限的“马甲邮件”转发 (Catch-all)
- 私人定制的“状态监控页”

我从这里面挑选了几个来搭建，还挺有意思的。这篇文章记录搭建过程。

## 准备清单

- Cloudflare购买的域名`chouzz.com`
- 2核心1GB 内存的 Ubuntu VPS


## 安装 Docker 与 Docker Compose

有些工具的搭建需要用到docker，虽然VPS是轻量级的VPS，但是用来搭建这些不太消耗内存的网站页足够了

可以参考docker官网给出的步骤来安装：

```bash
sudo apt update
sudo apt install -y ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo \"$VERSION_CODENAME\") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo systemctl enable --now docker
```


## 安装 cloudflared

cloudflared是cloudflare的一个服务，通过cloudflared可以将vps服务器中的本地服务映射到某个字域名，而且是不需要任何证书的，这点比较好

步骤：

```bash
curl -L -o cloudflared.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
sudo dpkg -i cloudflared.deb
cloudflared --version
```

## 订阅页rss.chouzz.com

可以打造一个个人使用 RSS 作为内容入口来订阅感兴趣的话题，FreshRSS 很轻量，1GB 也能稳住。

部署：

```yaml
# ~/freshrss/docker-compose.yml
services:
  freshrss:
    image: freshrss/freshrss:latest
    container_name: freshrss
    restart: unless-stopped
    volumes:
      - ./data:/var/www/FreshRSS/data
    ports:
      - "8080:80"
```

```bash
cd ~/freshrss
docker compose up -d
```

子域名绑定：Cloudflare Tunnel

1. 进入 Cloudflare 控制台，打开 Zero Trust。
2. 进入 `Access` -> `Tunnels`，选择你的 Tunnel。
3. 打开 `Public Hostnames`，点击 `Add a public hostname`。
4. Subdomain 填 `rss`，Domain 选 `chouzz.com`。
5. Service 选 `HTTP`，URL 填 `localhost:8080`。
6. 保存。

## 状态页status.chouzz.com

为了看到 VPS 负载与流量曲线，可以搭建 Beszel，它有图表界面显示 CPU、内存等占用情况。

部署：

```yaml
# ~/beszel/docker-compose.yml
services:
  beszel:
    image: 'henrygd/beszel:latest'
    ports:
      - '8090:8090'
    volumes:
      - ./beszel_data:/data
  beszel-agent:
    image: 'henrygd/beszel-agent:latest'
    network_mode: host
    environment:
      PORT: 4567
      KEY: 'YOUR_PUB_KEY_HERE' # 从 Web 面板获取
```

```bash
cd ~/beszel
docker compose up -d
```

子域名绑定：Cloudflare Tunnel

1. 还是在 `Public Hostnames` 里，点击 `Add a public hostname`。
2. Subdomain 填 `status`，Domain 选 `chouzz.com`。
3. Service 选 `HTTP`，URL 填 `localhost:8090`。
4. 保存。

## 个人链接页hi.chouzz.com：

可以使用LinkStack来创建一个人链接页，这样可以把所有入口集中到一个地方来展示，比较炫酷，这个相对来说有点占用内存

部署：

```yaml
# ~/linkstack/docker-compose.yml
services:
  linkstack:
    image: linkstackorg/linkstack:latest
    ports:
      - "8091:80"
    volumes:
      - ./data:/htdocs
    restart: unless-stopped
```

```bash
cd ~/linkstack
docker compose up -d
```

如果遇到权限问题：

```bash
sudo chmod -R 775 ./data
```

子域名绑定：Cloudflare Tunnel

1. 在 `Public Hostnames` 里再添加一条。
2. Subdomain 填 `hi`，Domain 选 `chouzz.com`。
3. Service 选 `HTTP`，URL 填 `localhost:8091`。
4. 保存。

## 个人笔记memo.chouzz.com

需要一个简单的私有笔记记录零碎想法，Memos 很轻量。

部署：

```yaml
# ~/memos/docker-compose.yml
services:
  memos:
    image: neosmemo/memos:latest
    ports:
      - "8092:5230"
    volumes:
      - ./memos:/var/opt/memos
    restart: unless-stopped
```

```bash
cd ~/memos
docker compose up -d
```

子域名绑定：Cloudflare Tunnel

1. 在 `Public Hostnames` 里再添加一条。
2. Subdomain 填 `memo`，Domain 选 `chouzz.com`。
3. Service 选 `HTTP`，URL 填 `localhost:8092`。
4. 保存。

## 个人订阅rsshub.chouzz.com

很多站点没有 RSS，用 RSSHub 可以补上，可以通过 Vercel 部署。

部署：

- Fork RSSHub 仓库后接入 Vercel
- Build Command 设为 `mkdir -p assets/build && npm run build`
- Node 版本选 20.x

子域名绑定：Cloudflare DNS

1. 进入 Cloudflare 控制台的 `DNS`。
2. 新建 `CNAME` 记录。
3. Name 填 `rsshub`，Target 填 Vercel 提供的域名。
4. 代理状态按需选择，可开小云朵。

## 总结

- 每个子域名能打开对应服务：`rss.chouzz.com`、`status.chouzz.com`、`hi.chouzz.com`、`memo.chouzz.com`、`rsshub.chouzz.com`
- Cloudflare Tunnel 里不要留多余端口
- VPS 上只保留 SSH 管理端口即可

到这里为止，一个“够用、轻量、能长期跑”的个人数字全家桶就搭完了。
