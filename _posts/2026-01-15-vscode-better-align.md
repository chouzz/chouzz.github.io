---
layout: post
title: Better Align for VS Code - 智能对齐工具
date: 2026-01-15 14:00 +0800
categories: [工具]
tags: [vscode, productivity]
---

# Better Align for Visual Studio Code

Better Align 是一款为 VS Code 设计的代码垂直对齐扩展。它能够智能地识别代码中的操作符并进行对齐，支持多种编程语言，无论是否选中代码都能高效工作。

[![GitHub](https://flat.badgen.net/github/release/chouzz/vscode-better-align)](https://github.com/chouzz/vscode-better-align/releases)
[![Visual Studio Marketplace](https://img.shields.io/visual-studio-marketplace/i/chouzz.vscode-better-align)](https://marketplace.visualstudio.com/items?itemName=Chouzz.vscode-better-align)

## 主要特性

- **多语言支持**：几乎支持所有主流编程语言。
- **智能对齐**：支持自动识别代码块对齐，也可以对选中的区域进行对齐。
- **自定义配置**：可以灵活配置对齐的操作符（如 `:`, `=`, `=>`）以及操作符周围的空格。
- **自动对齐**：支持在按下 Enter 键后自动触发对齐（需配置）。

## 安装方式

在 VS Code 扩展市场搜索 `Better Align` 或运行以下命令：

```bash
ext install chouzz.vscode-better-align
```

## 使用说明

将光标放置在需要对齐的代码行，按下快捷键 `Alt + A`，或者通过命令面板（Command Palette）运行 `Align` 命令。

![演示动画](https://github.com/chouzz/vscode-better-align/raw/main/images/auto-align-characters.gif)

## 技术实现原理

Better Align 的核心逻辑基于一套轻量级的词法分析系统。

1. **词法解析 (Tokenization)**：
   插件并不依赖复杂的语法树，而是通过正则和状态机将每一行代码拆分为一系列 Token。Token 类型包括：`Word`（单词）、`Assignment`（赋值操作符如 `=`、`+=`）、`Colon`（冒号）、`Comment`（注释）等。

2. **范围确定 (Narrowing)**：
   当触发对齐时，插件会从当前行开始向上和向下搜索，寻找具有相似结构（包含相同类型操作符且缩进一致）的相邻行，从而确定一个需要对齐的代码块范围。

3. **对齐计算 (Formatting)**：
   在确定的代码块内，插件会计算每一行在操作符之前的最大宽度。随后，它会根据配置的对齐策略（如左对齐或右对齐操作符）计算出每行需要补充的空格数量，并一次性应用编辑。

这种基于 Token 的实现方式使得它非常灵活，能够轻松扩展对新语言或新操作符的支持。
