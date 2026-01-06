---
layout: post
title: chrome-launcher Node.js包研究
slug: chrome-launcher-nodejs-notes
date: 2024-06-28 14:11 +0800
categories: [编程语言]
tags: [typescript]
---

# chrome-launcher Node.js包研究

chrome-launcher 是一个 Node.js 库，用于启动 Chrome 浏览器并简化启动时对 Chrome 浏览器的一些设置。本文旨在通过研究其源代码，学习其中的优秀编码风格和实践。

## chrome-finder

在该代码仓库中，有一个名为 `chrome-finder.ts` 的文件，用于在不同平台上寻找 Chrome 浏览器的安装路径。支持的平台包括：

- darwin（macOS）
- linux
- win32（Windows）
- wsl（Windows Subsystem for Linux）

下面简要介绍了在每个平台上查找 Chrome 安装路径的逻辑：

### darwin（macOS）

对于 macOS，该代码会查找多个 Chrome 安装路径，并以数组形式返回。它会读取数组并选择第一个安装路径。具体的路径获取逻辑如下：

1. 优先考虑自定义的 Chrome 路径。
2. 读取 Chrome 的默认安装路径，通常这种方式更快且适用于大多数用户。
3. 使用 lsregister、grep、awk 等命令组合来获取 Chrome 的路径，并将获取到的路径放入路径数组中。

此外，它还会返回两个路径，这些路径通常是 Chrome 的默认安装路径，作为 `drawinFast()` 方法的返回值。有趣的是，在获取 Chrome 路径时，还会检查是否具有访问权限。

### linux

linux 代表 Linux 系统下的 Chrome 安装路径获取，其中有三种方式：

1. 检查 chrome_path 环境变量，可能是自定义的环境变量。
2. 在桌面上搜索 Chrome 的快捷方式。
3. 使用 grep 结合 which 命令来查找 Chrome 的路径。

### win32

win32 代表 Windows 系统下获取 Chrome 安装路径的逻辑，其中包括：

- 基于默认安装路径寻找。
- 基于环境变量寻找。

### 技巧部分

- ChromePathNotSetError 继承自 Error，并抛出该异常，包括异常代码如 ERR_LAUNCHER_PATH_NOT_SET 以及该 Error 属性的调用栈。这样，在抛出异常时可以直接定位到代码的调用栈。

```typescript
export class LauncherError extends Error {
  constructor(public message: string = 'Unexpected error', public code?: string) {
    super();
    this.stack = new Error().stack;
    return this;
  }
}
```

- 在 execFileSync 时使用 pipe，明确意图是捕获子进程的输出。但在我看来，似乎不太清楚为何这样使用更好。

```typescript
try {
  const chromePath = execFileSync('which', [executable], { stdio: 'pipe' }).toString().split(newLineRegex)[0];
  if (canAccess(chromePath)) {
    installations.push(chromePath);
  }
} catch (e) {
  // 未安装
}
```

- 对数组进行基于优先级的排序 sort(str: string[], priorities: Priorities)。实现了一个基于优先级的排序方法，使用正则表达式来设置每个条件的权重，非常有意思。

```typescript
type Priorities = Array<{ regex: RegExp; weight: number }>;
function sort(installations: string[], priorities: Priorities) {
  const defaultPriority = 10;
  return installations
    // 分配优先级
    .map((inst: string) => {
      for (const pair of priorities) {
        if (pair.regex.test(inst)) {
          return { path: inst, weight: pair.weight };
        }
      }
      return { path: inst, weight: defaultPriority };
    })
    // 根据优先级排序
    .sort((a, b) => b.weight - a.weight)
    // 移除优先级标记
    .map((pair) => pair.path);
}

const priorities: Priorities = [
  { regex: /chrome-wrapper$/, weight: 60 },
  { regex: /google-chrome-stable$/, weight: 50 },
  { regex: /google-chrome$/, weight: 40 },
  { regex: /chromium-browser$/, weight: 30 },
  { regex: /chromium$/, weight: 20 },
  { regex: /chrome$/, weight: 10 },
];
const sortedInstallations = sort(installations, priorities);
```

该方法会根据正则表达式匹配结果给不同的路径分配权重，并根据权重对路径进行排序。这种灵活的排序方法使得可以根据不同的优先级对安装路径进行自定义排序。

## 总结

通过对 chrome-launcher 包中的 chrome-finder 文件的研究，可以看出其采用了一些编码的最佳实践，如异常处理、优先级排序等。它提供了跨平台的功能，能够在不同的操作系统上找到 Chrome 的安装路径。这对于需要在 Node.js 环境中启动 Chrome 浏览器的开发人员来说是非常有用的。
