---
layout: post
title: Inno Setup for VS Code - 开发环境增强
date: 2026-01-15 14:10 +0800
categories: [工具]
tags: [vscode, innosetup]
---

# Inno Setup for Visual Studio Code

这是一个为 Inno Setup 脚本提供全面支持的 VS Code 扩展。它包含了语法高亮、代码片段、悬停文档提示以及一键编译运行的集成环境。

[![GitHub](https://flat.badgen.net/github/release/chouzz/vscode-innosetup)](https://github.com/chouzz/vscode-innosetup/releases)
[![Visual Studio Marketplace](https://vsmarketplacebadges.dev/installs-short/Chouzz.vscode-innosetup.svg?style=flat-square)](https://marketplace.visualstudio.com/items?itemName=Chouzz.vscode-innosetup)

## 主要特性

- **语法高亮**：完整支持 `.iss` 脚本的语法着色。
- **代码片段**：内置常用的 Inno Setup 段落（如 `[Files]`, `[Icons]`, `[Run]`）的代码片段。
- **集成编译**：支持直接在 VS Code 中调用 `ISCC.exe` 进行脚本编译。
- **错误高亮**：编译过程中的警告和错误会直接在编辑器中标记出来。
- **悬停提示**：将光标悬停在 Inno Setup 关键词上时，会显示相关的文档说明。

## 安装方式

在 VS Code 扩展市场搜索 `Inno Setup` (作者: Chouzz) 或运行以下命令：

```bash
ext install chouzz.vscode-innosetup
```

## 使用说明

### 编译脚本
确保 `ISCC.exe` 已经添加到系统的 PATH 环境变量中。在打开 `.iss` 文件时，按下 `Shift + Alt + B` 即可触发编译。编译结果会实时显示在输出面板中。

![截图](https://raw.githubusercontent.com/chouzz/vscode-innosetup/master/images/screenshot.png)

## 技术实现原理

该插件主要通过以下几个模块来实现对 Inno Setup 的深度支持：

1. **编译器集成 (Compiler Integration)**：
   插件使用 Node.js 的 `child_process.spawn` 异步调用外部编译器 `ISCC.exe`。通过监听编译进程的 `stdout` 和 `stderr`，将编译日志实时传输到 VS Code 的输出通道（Output Channel）。

2. **错误解析与反馈 (Error Parsing)**：
   插件内置了针对 `ISCC` 输出格式的解析逻辑。通过正则表达式匹配日志中的文件名、行号以及错误描述，并利用 VS Code 的 `DiagnosticCollection` API 将其转化为编辑器中的红色/黄色波浪线提醒。

3. **文档悬停服务 (Hover Provider)**：
   为了提供悬停提示，插件维护了一份 Inno Setup 关键词的离线文档索引。当用户光标悬停在特定指令上时，插件会快速检索并展示对应的用法说明和参数示例。

4. **语法与片段**：
   采用 TextMate 语法定义文件（`.tmLanguage`）来实现高精度的词法着色，并定义了一系列标准的 JSON 片段文件来加速开发。
