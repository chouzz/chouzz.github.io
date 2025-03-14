---
layout: post
title: Tree-Sitter 解析 C 语言的工作原理
date: 2025-03-09 09:20 +0800
categories: [编程语言]
tags: [tree-sitter]
image:
  path: assets/img/posts/20250309/tree-sitter-logo.png
---

# Tree-Sitter 解析 C 语言的工作原理

## 1. Tree-Sitter 的核心设计

Tree-Sitter 的核心是一个**确定性有限自动机 (DFA)** 和**解析表**的组合。它通过以下流程实现高效的语法解析：

- **语法定义**：每种语言的语法规则通过 **JSON 或 JavaScript DSL** 定义。
- **解析器生成**：Tree-Sitter 根据语法规则自动生成高效的解析器。
- **增量解析**：支持增量解析技术，在源代码变更时仅重新解析受影响的部分，而非整个文件。

## 2. Tree-Sitter 的源码结构

Tree-Sitter 的源码架构主要分为三个部分：

- **核心解析引擎**：使用 C 语言实现，负责解析语法规则并生成语法树。
- **语言定义**：每种语言的语法规则存储在独立的代码仓库中（例如 `tree-sitter-c` 用于 C 语言）。
- **多语言绑定**：提供多种编程语言的绑定（如 JavaScript、Python、Rust 等），便于在不同环境中使用。

## 3. Tree-Sitter 解析 C 语言的工作流程

以 C 语言为例，Tree-Sitter 的解析过程分为以下几个关键步骤：

### 3.1 语法规则定义

C 语言的语法规则定义在 `tree-sitter-c` 仓库的 `grammar.js` 文件中。该文件定义了 C 语言的词法和语法规则。例如：

```javascript
module.exports = grammar({
  name: 'c',
  rules: {
    source_file: $ => repeat($._statement),
    _statement: $ => choice(
      $.expression_statement,
      $.return_statement,
      $.if_statement,
      $.while_statement,
      // 其他语句
    ),
    expression_statement: $ => seq($.expression, ';'),
    return_statement: $ => seq('return', $.expression, ';'),
    if_statement: $ => seq(
      'if', '(', $.expression, ')', $.statement,
      optional(seq('else', $.statement))
    ),
    // 其他规则
  }
});
```

这些规则定义了 C 语言的基本语法结构，例如 `if` 语句、`return` 语句等。实际的 C 语言语法规则更为复杂，完整规则可以参考 [tree-sitter-c](https://github.com/tree-sitter/tree-sitter-c) 代码仓库中的 [grammar.js](https://github.com/tree-sitter/tree-sitter-c/blob/master/grammar.js) 文件。

### 3.2 词法分析

Tree-Sitter 使用**词法分析器 (Lexer)** 将源代码分解为**词法单元 (tokens)**。例如：

```c
int main() {
  return 0;
}
```

会被分解为以下词法单元：
- `int`（关键字）
- `main`（标识符）
- `(`（符号）
- `)`（符号）
- `{`（符号）
- `return`（关键字）
- `0`（数字）
- `;`（符号）
- `}`（符号）

词法分析器不是直接写在 tree-sitter-c 仓库中的，而是由 Tree-Sitter 的核心库基于 grammar.js 中定义的语法规则自动生成。在 grammar.js 中，可以通过正则表达式或字符串定义词法规则：

```javascript
    true: _ => token(choice('TRUE', 'true')),
    false: _ => token(choice('FALSE', 'false')),
    null: _ => choice('NULL', 'nullptr'),

    identifier: _ =>
      /(\p{XID_Start}|\$|_|\\u[0-9A-Fa-f]{4}|\\U[0-9A-Fa-f]{8})(\p{XID_Continue}|\$|\\u[0-9A-Fa-f]{4}|\\U[0-9A-Fa-f]{8})*/,

    // http://stackoverflow.com/questions/13014947/regex-to-match-a-c-style-multiline-comment/36328890#36328890
    comment: _ => token(choice(
      seq('//', /(\\+(.|\r?\n)|[^\\\n])*/),
      seq(
        '/*',
        /[^*]*\*+([^/*][^*]*\*+)*/,
        '/',
      ),
    )),
```

其中，`token`、`choice`、`alias` 等函数表示不同的语法含义：
- `choice` 函数用于定义多个可能的语法规则之一
- `token` 函数用于显式标记某个语法规则为词法单元

Tree-Sitter 的词法分析器生成过程包括：

1. **提取词法规则**：从 grammar.js 中提取所有与词法相关的规则（如 identifier、number、string 等）
2. **生成有限自动机**：将这些词法规则转换为确定性有限自动机 (DFA)，用于高效地匹配词法单元
3. **嵌入到解析器中**：生成的词法分析器与语法分析器协同工作

在 Tree-Sitter 核心库源码中，相关实现文件包括：
- `lexer.c`：词法分析器的主要实现文件，定义了如何根据词法规则匹配词法单元
- `subtree.c`：负责管理词法单元和语法树的节点
- `parser.c`：将词法分析器和语法分析器结合起来，完成整个解析过程

### 3.3 语法分析

Tree-Sitter 使用**LR 解析算法**将词法单元转换为语法树。解析器根据 `grammar.js` 中定义的规则，逐步构建语法树。例如：

解析 `int main() { return 0; }` 时，Tree-Sitter 会识别出这是一个函数定义，并生成以下语法树：

```
source_file
  └── function_definition
      ├── type: int
      ├── identifier: main
      ├── parameters: ()
      └── body: compound_statement
          └── return_statement
              └── expression: number_literal (0)
```

Tree-Sitter 的语法分析器并非传统的 LR(1) 或 LALR(1) 解析器，而是一种改进的 GLR（通用 LR）解析器，具有以下特点：

- **支持歧义语法**：可以处理歧义语法（例如 JavaScript 的自动分号插入）
- **增量解析**：可以在源代码发生更改时，只重新解析受影响的部分
- **高性能**：解析速度非常快，适合在编辑器等实时场景中使用

语法分析器的实现步骤：

1. **提取语法规则**：从 grammar.js 中提取所有语法规则（如 if_statement、function_definition 等）
2. **生成解析表**：将这些语法规则转换为解析表，定义在特定状态下遇到特定词法单元时应采取的动作（移进、规约或接受）
3. **嵌入到解析器中**：生成的解析表与词法分析器协同工作

核心库中与语法分析相关的文件：
- `parser.c`：语法分析器的主要实现文件，定义了如何根据解析表对词法单元流进行解析
- `subtree.c`：负责管理语法树的节点
- `language.c`：定义了如何加载和使用特定语言的语法规则

### 3.4 增量解析

Tree-Sitter 的一个重要特性是支持增量解析，即在源代码发生更改时，只重新解析受影响的部分。例如：

如果将 `return 0;` 修改为 `return 1;`，Tree-Sitter 只会重新解析 `return` 语句部分，而不会重新解析整个文件。

#### 增量解析的核心思想

增量解析的核心思想是**复用之前的解析结果**，而不是从头开始重新解析整个文件：

- 当源代码发生更改时，Tree-Sitter 会分析更改的范围（插入、删除或修改的字符位置）
- 只重新解析受更改影响的部分，保留未受影响的部分的解析结果
- 将重新解析的结果与未受影响的部分合并，生成新的语法树

#### 增量解析的实现机制

Tree-Sitter 的增量解析通过以下机制实现：

1. **语法树的结构**

   Tree-Sitter 的语法树是一个**持久化数据结构**，每次解析生成的语法树是不可变的（immutable）。当源代码发生更改时，Tree-Sitter 会创建一个新的语法树，但会复用未受更改影响的部分。语法树的节点是子树（subtree）的集合，每个子树可以独立地被复用或替换。

2. **更改范围分析**

   当源代码发生更改时，Tree-Sitter 会分析更改的类型：
   - 插入：新字符被插入到源代码中
   - 删除：字符从源代码中删除
   - 替换：字符被替换为其他字符

   Tree-Sitter 会计算出受更改影响的字符范围，并确定需要重新解析的语法树节点。

3. **局部重新解析**

   Tree-Sitter 只重新解析受更改影响的部分：
   - 定位受影响的节点：根据更改的字符范围，找到语法树中受影响的节点
   - 重新解析：从受影响的节点开始，重新解析该部分源代码
   - 合并结果：将重新解析的结果与未受影响的节点合并，生成新的语法树

4. **复用未受影响的节点**

   Tree-Sitter 会尽可能地复用未受更改影响的节点。例如，如果更改只影响了一个函数体，那么该函数体之外的节点（如其他函数、全局声明等）会被直接复用。复用的节点不需要重新解析，从而大大提高了性能。

参考链接：

https://tree-sitter.github.io/tree-sitter/
https://github.com/tree-sitter/tree-sitter-c
