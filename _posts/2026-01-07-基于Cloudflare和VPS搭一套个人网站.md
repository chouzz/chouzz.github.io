---
layout: post
title: 基于Cloudflare和VPS搭一套个人网站
slug: cloudflare-vps-personal-site
date: 2026-01-07 22:14 +0800
categories: [运维]
tags: [cloudflare, vps, docker, rss, self-hosted]
---

## 前言

记录一次搭建过程：利用 Cloudflare 的边缘能力和一台轻量 VPS，把常用服务集中起来，并通过子域名对外提供访问。每个子域名就是一个章节，按步骤写清楚如何部署与如何绑定。

## 准备清单

- 一个域名并接入 Cloudflare，使用 `chouzz.com`
- 一台 1GB 内存的 Ubuntu VPS
- 安装好 Docker 与 Docker Compose
- 安装好 `cloudflared`，用于 Cloudflare Tunnel

下面开始按子域名逐个搭建。

## 安装 Docker 与 Docker Compose

步骤：

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

可选：让当前用户免 sudo 使用 Docker。

```bash
sudo usermod -aG docker $USER
```

## 安装 cloudflared

步骤：

```bash
curl -L -o cloudflared.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
sudo dpkg -i cloudflared.deb
cloudflared --version
```

## rss.chouzz.com：FreshRSS

RSS 作为内容入口更省心，FreshRSS 很轻量，1GB 也能稳住。

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

## status.chouzz.com：Beszel

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

## hi.chouzz.com：LinkStack

需要一个个人链接页，把所有入口集中到一个地方。

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

## memo.chouzz.com：Memos

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

## rsshub.chouzz.com：RSSHub

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

## 收尾检查

- 每个子域名能打开对应服务：`rss.chouzz.com`、`status.chouzz.com`、`hi.chouzz.com`、`memo.chouzz.com`、`rsshub.chouzz.com`
- Cloudflare Tunnel 里不要留多余端口
- VPS 上只保留 SSH 管理端口或使用 WireGuard

到这里为止，一个“够用、轻量、能长期跑”的个人数字全家桶就搭完了。
