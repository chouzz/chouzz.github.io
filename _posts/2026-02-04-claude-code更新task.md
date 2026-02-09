---
layout: post
title: 对Claude Code移除TodoWrite 并引入TaskCreate机制的思考
slug: claude-code-tasks-update
date: 2026-02-04 10:00 +0800
categories: [AI]
tags: [claude, claude-code, llm, agent, task-management]
---

在 2026 年 1 月 23 日，Anthropic 公司开发 Claude Code 的员工 [Thariq](https://x.com/trq212) 在 X 上发布了 [We're turning Todos into Tasks in Claude Code](https://x.com/trq212/status/2014480496013803643) 这篇文章，详细地介绍了他们为什么移除 TodoWrite 并引入 Tasks 这个工具。

实际上，Claude Code 中已经有很多工具了，其中就存在 Task 工具，但是这个 Task 和今天要说的 TaskCreate、TaskList 等工具不一样。所有的工具名称都可以通过 [llm-interceptor](https://github.com/chouzz/llm-interceptor) 捕获到的，目前 Claude Code 中 Task 工具的名称和描述如下：

**Task**
```
Launch a new agent to handle complex, multi-step tasks autonomously. 

The Task tool launches specialized agents (subprocesses) that autonomously handle complex tasks. Each agent type has specific capabilities and tools available to it.

Available agent types and the tools they have access to:
- general-purpose: General-purpose agent for researching complex questions, searching for code, and executing multi-step tasks. When you are searching for a keyword or file and are not confident that you will find the right match in the first few tries use this agent to perform the search for you. (Tools: *)
- statusline-setup: Use this agent to configure the user's Claude Code status line setting. (Tools: Read, Edit)
- Explore: Fast agent specialized for exploring codebases. Use this when you need to quickly find files by patterns (eg. "src/components/**/*.tsx"), search code for keywords (eg. "API endpoints"), or answer questions about the codebase (eg. "how do API endpoints work?"). When calling this agent, specify the desired thoroughness level: "quick" for basic searches, "medium" for moderate exploration, or "very thorough" for comprehensive analysis across multiple locations and naming conventions. (Tools: All tools)
- Plan: Fast agent specialized for exploring codebases. Use this when you need to quickly find files by patterns (eg. "src/components/**/*.tsx"), search code for keywords (eg. "API endpoints"), or answer questions about the codebase (eg. "how do API endpoints work?"). When calling this agent, specify the desired thoroughness level: "quick" for basic searches, "medium" for moderate exploration, or "very thorough" for comprehensive analysis across multiple locations and naming conventions. (Tools: All tools)
- claude-code-guide: Use this agent when the user asks questions about Claude Code or the Claude Agent SDK. This includes questions about Claude Code features ("can Claude Code...", "does Claude Code have..."), how to use specific features (hooks, slash commands, MCP servers), and Claude Agent SDK architecture or development. **IMPORTANT:** Before spawning a new agent, check if there is already a running or recently completed claude-code-guide agent that you can resume using the "resume" parameter. Reusing an existing agent is more efficient and maintains context from previous documentation lookups. (Tools: Glob, Grep, Read, WebFetch, WebSearch)
- git-commit-pusher: Use this agent when you need to commit and push code changes to a remote repository following a structured git workflow. This includes scenarios where you have made local changes and want to properly branch, commit, and push those changes while maintaining good git hygiene. Example: After implementing a new feature or fixing a bug, you want to commit your changes to a new branch and push them to origin. The agent will first check the current status and branch, then create a new appropriately named branch, commit your changes with a concise Chinese message, and push to origin. (Tools: All tools)

When using the Task tool, you must specify a subagent_type parameter to select which agent type to use.

When NOT to use the Task tool:
- If you want to read a specific file path, use the Read or Glob tool instead of the Task tool, to find the match more quickly
- If you are searching for a specific class definition like "class Foo", use the Glob tool instead, to find the match more quickly
- If you are searching for code within a specific file or set of 2-3 files, use the Read tool instead of the Task tool, to find the match more quickly
- Other tasks that are not related to the agent descriptions above


Usage notes:
...
```

从工具描述可以看出，Task 工具本身是用来启动 Claude Code 的 subagent 的，Claude Code 利用 Task 来完成一些阶段性的任务，从而避免主 agent 中占用的上下文窗口过多，导致一些信息的丢失。但是这次他们移除了 TodoWrite，增加了和 TaskList、TaskCreate 相关的工具，不妨让我们先看看原版的 TodoWrite 的描述吧：
```
Use this tool to create and manage a structured task list for your current coding session. This helps you track progress, organize complex tasks, and demonstrate thoroughness to the user.
It also helps the user understand the progress of the task and overall progress of their requests.

## When to Use This Tool
Use this tool proactively in these scenarios:

1. Complex multi-step tasks - When a task requires 3 or more distinct steps or actions
2. Non-trivial and complex tasks - Tasks that require careful planning or multiple operations
3. User explicitly requests todo list - When the user directly asks you to use the todo list
4. User provides multiple tasks - When users provide a list of things to be done (numbered or comma-separated)
5. After receiving new instructions - Immediately capture user requirements as todos
6. When you start working on a task - Mark it as in_progress BEFORE beginning work. Ideally you should only have one todo as in_progress at a time
7. After completing a task - Mark it as completed and add any new follow-up tasks discovered during implementation

## When NOT to Use This Tool

Skip using this tool when:
1. There is only a single, straightforward task
2. The task is trivial and tracking it provides no organizational benefit
3. The task can be completed in less than 3 trivial steps
4. The task is purely conversational or informational

NOTE that you should not use this tool if there is only one trivial task to do. In this case you are better off just doing the task directly.

## Examples of When to Use the Todo List
...
```
这里我省略了一些示例，但是即使加了这些 TaskList、TaskCreate，它的本质其实没有变化。我们可以看到 TaskList、TaskCreate 以及 TaskUpdate 的工具描述为：

### TaskCreate
```
Use this tool to create a structured task list for your current coding session. This helps you track progress, organize complex tasks, and demonstrate thoroughness to the user.
It also helps the user understand the progress of the task and overall progress of their requests.

## When to Use This Tool

Use this tool proactively in these scenarios:

- Complex multi-step tasks - When a task requires 3 or more distinct steps or actions
- Non-trivial and complex tasks - Tasks that require careful planning or multiple operations
- Plan mode - When using plan mode, create a task list to track the work
- User explicitly requests todo list - When the user directly asks you to use the todo list
- User provides multiple tasks - When users provide a list of things to be done (numbered or comma-separated)
- After receiving new instructions - Immediately capture user requirements as tasks
- When you start working on a task - Mark it as in_progress BEFORE beginning work
- After completing a task - Mark it as completed and add any new follow-up tasks discovered during implementation

## When NOT to Use This Tool

Skip using this tool when:
- There is only a single, straightforward task
- The task is trivial and tracking it provides no organizational benefit
- The task can be completed in less than 3 trivial steps
- The task is purely conversational or informational

NOTE that you should not use this tool if there is only one trivial task to do. In this case you are better off just doing the task directly.

## Task Fields

- **subject**: A brief, actionable title in imperative form (e.g., "Fix authentication bug in login flow")
- **description**: Detailed description of what needs to be done, including context and acceptance criteria
- **activeForm**: Present continuous form shown in spinner when task is in_progress (e.g., "Fixing authentication bug"). This is displayed to the user while you work on the task.

**IMPORTANT**: Always provide activeForm when creating tasks. The subject should be imperative ("Run tests") while activeForm should be present continuous ("Running tests"). All tasks are created with status `pending`.

## Tips

- Create tasks with clear, specific subjects that describe the outcome
- Include enough detail in the description for another agent to understand and complete the task
- After creating tasks, use TaskUpdate to set up dependencies (blocks/blockedBy) if needed
- Check TaskList first to avoid creating duplicate tasks
```

可以只看 TaskCreate 工具，可以看出，从本质上来说，并没有改变 TodoWrite 这个列出 todo list 的意图。


那么为什么他们要移除 TodoWrite 这个工具呢？根据这篇文章介绍，有三个原因：

**第一个是：**随着模型能力的增强，它已经能意识到在处理小型任务时需要做什么。原话是："We found that the TodoWrite Tool was no longer necessary because Claude already knew what it needed to do for smaller tasks."

但是这里看起来也仅限于 Anthropic 家的模型，如 Opus 4.5 之类的。如果用 Claude Code 跑其他的模型，比如 GLM4.6、GLM4.7，可能能力还是不太够，是否值得真正地移除 TodoWrite 这个工具呢？在移除这个工具后，模型是否会把拉起 subagent 的 Task 工具和目前的 TaskCreate、TaskList 等工具搞混呢？我理解是很可能的，对于人而言这个就比较混乱，对于模型而言也是一样。

**第二个原因**是因为他们使用 Claude Code 来完成时间更长的任务的时候，有些任务存在前后依赖的关系。他们受到 [Beads](https://github.com/steveyegge/beads) 项目的启发，才有了这些能够建立相互依赖的 tasks。那么 Beads 这个项目本身其实是一个管理问题的追踪系统[^footnote1]，整体来说就是通过结构化之后的依赖图来替代普通的 markdown 文档，让 agent 能够查询之前完成的、现在正在进行的以及后面将要执行的任务。这也和当前的 TaskCreate、TaskList 等机制非常符合。

**还有一个很重要的原因**，是因为这种任务机制可以用于协调跨项目的工作，而且这些任务是存在文件系统里面的，就是存在~/.claude/task相当于写入一个文本文件了，不过我看了下当前的task目录，显示的是：

```bash
~\.claude\tasks
❯ tree -a
 .
├──  19cc1529-e136-4f29-a803-75a02033ce0d
│   └──  .lock
├──  83e80a17-89ac-480d-9b77-deffffbb7c25
│   ├──  .highwatermark
│   └──  .lock
├──  559d6fd2-0e80-49fe-92c8-a2a79e130781
│   ├──  .highwatermark
│   └──  .lock
├──  64900ec0-e9fb-4fe5-9756-d51ad7348492
│   ├──  .highwatermark
│   └──  .lock
├──  b79c7e4e-b69d-4052-9034-7b8b4a64929a
│   └──  .lock
└──  c2a68d3d-2e3a-4a3f-95f6-9e9e7370f23d
    ├──  .lock
    ├──  1.json
    ├──  2.json
    ├──  3.json
    ├──  4.json
    └──  5.json
```

在默认情况下，通过显式在 prompt 里面要求 Claude Code 通过 TaskList、TaskCreate 等工具来完成任务时，它会创建一系列的 JSON 文件，这里记录的就是每个阶段需要完成的任务，和以前的 TodoWrite 非常类似，只不过增加了 blocks 或 blockedBy 这些字段。
```bash
 ❯ bat --style=header *
File: 1.json
{
  "id": "1",
  "subject": "了解l2topo代码结构和核心概念",
  "description": "探索l2topo代码库，了解主要模块、数据结构和核心概念，特别是设备、邻居、端口相关的定义",
  "activeForm": "探索l2topo代码结构",
  "status": "completed",
  "blocks": [],
  "blockedBy": []
}

File: 2.json
{
  "id": "2",
  "subject": "分析设备、邻居、端口数据模型",
  "description": "分析设备(device)、邻居(neighbor)、端口(port)的数据结构定义，理解它们之间的属性关系",
  "activeForm": "分析数据模型关系",
  "status": "completed",
  "blocks": [],
  "blockedBy": []
}

File: 3.json
{
  "id": "3",
  "subject": "理解联动关系处理流程",
  "description": "分析设备、邻居、端口变更时的联动处理逻辑，包括拓扑发现、状态同步、事件处理等机制",
  "activeForm": "分析联动处理逻辑",
  "status": "pending",
  "blocks": [],
  "blockedBy": []
}

File: 4.json
{
  "id": "4",
  "subject": "绘制Mermaid流程图",
  "description": "基于前续分析结果，使用Mermaid绘制l2topo组件设备、邻居、端口关系及处理流程图",
  "activeForm": "绘制关系和流程图",
  "status": "pending",
  "blocks": [],
  "blockedBy": []
}

File: 5.json
{
  "id": "5",
  "subject": "整理最终文档",
  "description": "整理完整的l2topo组件设备、邻居、端口关系说明文档，包含Mermaid图和详细解释",
  "activeForm": "整理说明文档",
  "status": "pending",
  "blocks": [],
  "blockedBy": []
}
```

我理解这里面还有一个隐藏的变化，就是现在 subagent 也能看到 todo 了。以前的 Claude Code 中 TodoWrite 工具一般是在主 agent 中调用的，当规划了一系列的任务后，subagent 完成这其中的一个任务。改成现在的这个机制后，subagent 中也能够通过 TaskGet、TaskList 或者 TaskUpdate 来阅读当前的任务以及更新任务了。

至于它的效果就因人而异了，虽然作者这么说，但是我很怀疑这样做是否会让 Claude Code 变得更好, 加了这个TaskCreate机制后是否需要将 Task 工具本身重命名以便更好反映出调用subagent的逻辑呢？否则和现有的 TaskCreate 是存在相关或者歧义的，模型有可能会理解错误。当然，对于 Anthropic 来说，他们的模型足够强大，理解能力也很强，但是对于其他模型，比如GLM4.6， GLM4.7,这些模型来说，有这样的工具不一定是好事。


[^footnote1]: (https://deepwiki.com/steveyegge/beads)
