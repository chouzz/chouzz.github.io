
在2026年1月23日，Anthropic公司开发claude code的员工 [Thariq](https://x.com/trq212) 在 X 上发布了 [We’re turning Todos into Tasks in Claude Code](https://x.com/trq212/status/2014480496013803643) 这篇文章，详细的介绍了他们为什么移除todowrite并加入Tasks这个工具。

实际上，claude code中已经有Task工具了，这些也可以通过[llm-interceptor](https://github.com/chouzz/llm-interceptor)捕获到的，目前Task工具的名称和描述如下：

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

从它的工具的描述也可以看出来，Task工具本身是用来启动claude code的subagent的，claude code利用task来完成一些阶段性的任务，从而避免主agent中占用的上下窗口过多，导致一些信息的丢失，但是这次他们移除了todowrite，增加了和tasklist，taskcreate相关的工具了，不妨让我们先看看原版的todowrite的描述吧：
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
这里我省略了一些示例，但是即使加了这些taskList，他扫Create，它的本质其实没有变化，我们可以看到TaskList和TaskCreate以及TaskUpdate的工具描述为：

TaskCreate
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

TaskGet
```
Use this tool to retrieve a task by its ID from the task list.

## When to Use This Tool

- When you need the full description and context before starting work on a task
- To understand task dependencies (what it blocks, what blocks it)
- After being assigned a task, to get complete requirements

## Output

Returns full task details:
- **subject**: Task title
- **description**: Detailed requirements and context
- **status**: 'pending', 'in_progress', or 'completed'
- **blocks**: Tasks waiting on this one to complete
- **blockedBy**: Tasks that must complete before this one can start

## Tips

- After fetching a task, verify its blockedBy list is empty before beginning work.
- Use TaskList to see all tasks in summary form.
```
TaskList
```
Use this tool to update a task in the task list.

## When to Use This Tool

**Mark tasks as resolved:**
- When you have completed the work described in a task
- When a task is no longer needed or has been superseded
- IMPORTANT: Always mark your assigned tasks as resolved when you finish them
- After resolving, call TaskList to find your next task

- ONLY mark a task as completed when you have FULLY accomplished it
- If you encounter errors, blockers, or cannot finish, keep the task as in_progress
- When blocked, create a new task describing what needs to be resolved
- Never mark a task as completed if:
  - Tests are failing
  - Implementation is partial
  - You encountered unresolved errors
  - You couldn't find necessary files or dependencies

**Delete tasks:**
- When a task is no longer relevant or was created in error
- Setting status to `deleted` permanently removes the task

**Update task details:**
- When requirements change or become clearer
- When establishing dependencies between tasks

## Fields You Can Update

- **status**: The task status (see Status Workflow below)
- **subject**: Change the task title (imperative form, e.g., "Run tests")
- **description**: Change the task description
- **activeForm**: Present continuous form shown in spinner when in_progress (e.g., "Running tests")
- **owner**: Change the task owner (agent name)
- **metadata**: Merge metadata keys into the task (set a key to null to delete it)
- **addBlocks**: Mark tasks that cannot start until this one completes
- **addBlockedBy**: Mark tasks that must complete before this one can start

## Status Workflow

Status progresses: `pending` → `in_progress` → `completed`

Use `deleted` to permanently remove a task.

## Staleness

Make sure to read a task's latest state using `TaskGet` before updating it.

```
从这些工具可以看出来，从本质上来说，并没有改变todowrite这个列出todolist的意图，


那么为什么他们要移除todos这个工具呢？根据这篇文章介绍，有2个原因：

第一个是：随着模型能力的增强，它已经能意识到在在处理小型任务时需要做什么。原话是："We found that the TodoWrite Tool was no longer necessary because Claude already knew what it needed to do for smaller tasks."


但是这里看起来也仅限于Anthropic家的模型，如Opus 4.5之类的，如果用claude code跑其他的模型，比如GLM4.6， GLM4.7可能能力还是不太够，是否值得真正的移除todowrite这个工具呢？在移除这个工具后，模型是否会把拉起Subagent的Task工具和目前的TaskCreate，TaskList等工具搞混呢？我理解是很有可能得，对于人而言这个就比较混乱，对于模型而言也是一样

“”
第二个原因是因为他们使用claude code来完成时间更长的任务的时候，有些任务存在前后依赖的关系，他们受到[Beads](https://github.com/steveyegge/beads)项目的启发，才有了这个这些能够建立相互依赖的tasks。那么Beads这个项目本身其实是管理问题的一个追踪系统，整体来说就是通过结构化之后的依赖图来替代普通的markdown文档，让agent能够查询之前完成的，现在正在进行的以及后面将要执行的任务。这也和当前taskcreate, tasklist等机制非常符合。

还有一个很重要的原因，是因为这种任务机制可以用于协调跨项目的工作，而且这些任务是存在文件系统里面的，就是存在~/.claude/task相当于写入一个文本文件了，不过我看了下当前的task目录，显示的是：

···bash
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
···

在默认情况下，通过显式在prompt里面要求claude code通过tasklist，taskcreate等工具来完成任务时，它会创建一系列的json文件，这里记录的就是每个阶段需要完成的任务，和以前的todowrite非常类似，只不过增加了 blocks或者blockedBy这些字段
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

我理解这里面还有一个隐藏的变化就是现在subagent也能看到todo了，以前的claude code中todowrite工具一般是在主agent中调用的，当规划了一系列的任务后，subagent完成这其中的一个任务，改成现在的这个机制后，suabgent中也能够通过taskGet，TaskList或者TaskUpdate来阅读当前的任务以及更新任务了
