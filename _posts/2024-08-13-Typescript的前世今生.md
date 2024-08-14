---
layout: post
title: Typescript的前世今生
date: 2024-08-04 16:40 +0800
categories: [编程语言]
tags: [typescript]
---
## JavaScript的由来
JavaScript并非凭空而来，它本身出自浏览器，最开始是用来嵌入到浏览器网页上，执行几段代码的，例如，当时的网速很慢也贵，有些操作不适合在服务端完成，比如输入用户名密码时，如果用户忘了输入密码，直接点击发送，到服务器发现这一点就太晚了，需要有一个小程序在用户没有填一下密码的时候给出一个提示。1995年，**Microsoft**推出了Internet Explorer, 因为Javascript能极大提高浏览器的体验，Microsoft希望Internet Explorer也可以这样，当时Javascript是在Netscape Navigator浏览器中的，Microsoft对它的解释器进行逆向工程，开发了Jscript，这就相当于有两门语言了，开发人员必须在2个浏览器中为同一个功能实现通过2种语言各适配一次。

## ECMAScript规范

为统一标准，Netscape将JavaScript提交给ECMA（European Computer Manufacturers Association, 欧洲计算机制造商协会）进行规范化。这就形成了ECMAScript，本来按理来说这个标准应该叫Javscript规范的，但是由于当时Javascript商标已经被Sun公司拥有(后来被Oracle收购)，而Oracle也拥有Javascript的版权，为了避免商业纠纷，javscript的标准被命名为ECMAScript. 后面2008年，google推出了Chrome浏览器，基于V8 Javscript引擎，由于速度比竞争对手快，并且拥有即时编译的特性，可以在代码运行时将Javscript编译为机器码，而不是在执行前进行完全的解释或静态编译，显著提高速度，2009年发布了ECMAScript 5，2015年发布了ECMAScript 6

后来，2009年创建的Nodejs引发了在web浏览器之外使用Javscript的使用，Nodejs结合V8 引擎，事件循环和I/O API，而且拥有NPM，使其包括了绝大多数的包管理器。Nodejs现在已经被非常多的用户使用了，并且为Javascript的流行程度带来极大的提升。目前，很多应用程序尤其是跨平台软件都是基于web技术构建的的，如vscode、discord等。

## Typescript的由来
Typescript是有微软在2012年开发和维护的开源编程语言，是Javscript的超集，提供可选的静态类型检查。Javscript本身很流行，但是其本身存在诸多缺陷，导致在开发大型应用中遇到很多问题，Typescript在不破坏现有ECMAScript规范的前提下，兼容Javscript语法，提供静态检查，其开发者同时是[C#](https://zh.wikipedia.org/wiki/C_Sharp)和[Delphi](https://zh.wikipedia.org/wiki/Delphi "Delphi")和[Turbo Pascal](https://zh.wikipedia.org/wiki/Turbo_Pascal "Turbo Pascal")的创始人


## Typescript的语言特性

TypeScript是一种为JavaScript添加特性的语言扩展。增加的功能包括：

- [类型批注](https://zh.wikipedia.org/wiki/%E7%B1%BB%E5%9E%8B%E6%89%B9%E6%B3%A8 "类型批注")和[编译时](https://zh.wikipedia.org/wiki/%E7%BC%96%E8%AF%91%E6%97%B6 "编译时")[类型检查](https://zh.wikipedia.org/wiki/%E7%B1%BB%E5%9E%8B%E7%B3%BB%E7%BB%9F "类型系统")
- [类型推断](https://zh.wikipedia.org/wiki/%E7%B1%BB%E5%9E%8B%E6%8E%A8%E6%96%AD "类型推断")
- [类型擦除](https://zh.wikipedia.org/wiki/%E7%B1%BB%E5%9E%8B%E6%93%A6%E9%99%A4 "类型擦除")
- [接口](https://zh.wikipedia.org/wiki/%E4%BB%8B%E9%9D%A2_(%E8%B3%87%E8%A8%8A%E7%A7%91%E6%8A%80) "接口 (信息技术)")
- [枚举](https://zh.wikipedia.org/wiki/%E6%9E%9A%E4%B8%BE "枚举")
- [Mixin](https://zh.wikipedia.org/wiki/Mixin "Mixin")
- [泛型编程](https://zh.wikipedia.org/wiki/%E6%B3%9B%E5%9E%8B%E7%BC%96%E7%A8%8B "泛型编程")
- [命名空间](https://zh.wikipedia.org/wiki/%E5%91%BD%E5%90%8D%E7%A9%BA%E9%97%B4 "命名空间")
- [元组](https://zh.wikipedia.org/wiki/%E5%85%83%E7%BB%84 "元组")
- [async/await](https://zh.wikipedia.org/wiki/Async/await "Async/await")

以下功能是从ECMA 2015反向移植而来：

- [类](https://zh.wikipedia.org/wiki/%E7%B1%BB_(%E8%AE%A1%E7%AE%97%E6%9C%BA%E7%A7%91%E5%AD%A6) "类 (计算机科学)")
- [模块](https://zh.wikipedia.org/wiki/%E6%A8%A1%E7%B5%84_(%E7%A8%8B%E5%BC%8F%E8%A8%AD%E8%A8%88) "模块 (编程)")[[27]](https://zh.wikipedia.org/wiki/TypeScript#cite_note-27)
- [匿名函数](https://zh.wikipedia.org/wiki/%E5%8C%BF%E5%90%8D%E5%87%BD%E6%95%B0 "匿名函数")的箭头语法
- 可选参数以及[默认参数](https://zh.wikipedia.org/wiki/%E7%BC%BA%E7%9C%81%E5%8F%82%E6%95%B0 "缺省参数")



## Typescript的现状和未来
随着Nodejs的发展，VSCode的流行，Javscript和Typescript也被大范围使用，当前Typescript在Github上进行维护，社区成员也非常活跃，同时也衍生出非常多的框架和库，如React、Vue.js、Next.js等。
下面是jetbrains的一些调研数据。
### 最喜欢的编程语言
![Favorite programming language](https://blog.jetbrains.com/wp-content/uploads/2024/02/JS-TS-Develop.png)

### 最喜欢的IDE
![Favorite IDE](https://blog.jetbrains.com/wp-content/uploads/2024/02/Popular-JS-TS-tools-1.png)

### 最喜欢的框架和库
![Favorite frameworks and libraries](https://blog.jetbrains.com/wp-content/uploads/2024/02/Frameworks-and-libraries-1.png)
### 最喜欢的测试框架

![Favorite testing framework](https://blog.jetbrains.com/wp-content/uploads/2024/02/Unit-testing3.png)
### 最喜欢的打包工具
![Favorite packaging tool](https://blog.jetbrains.com/wp-content/uploads/2024/02/module-bundlers-1.png)
### 使用的领域

![Field of use](https://blog.jetbrains.com/wp-content/uploads/2024/02/ts-vs-js.png)



Ref:

[JavaScript - 维基百科，自由的百科全书 (wikipedia.org)](https://zh.wikipedia.org/wiki/JavaScript)
[Ecma TC39 (github.com)](https://github.com/tc39)
[microsoft/TypeScript: TypeScript is a superset of JavaScript that compiles to clean JavaScript output. (github.com)](https://github.com/microsoft/TypeScript)
[JavaScript and TypeScript Trends 2024: Insights From the Developer Ecosystem Survey | The WebStorm Blog (jetbrains.com)](https://blog.jetbrains.com/webstorm/2024/02/js-and-ts-trends-2024/)
