---
title: turtlebot3（一）之Ubuntu16.04上realsenceR200的使用
date: 2020-01-30 22:48:08 +0800
categories: [机器人]
tags: [turtlebot]
---

## 前言

最近实验室买了 turtlebot3，捣鼓了 1 个月，先是跑通了激光雷达 demo，现在又跑 realsenseR200 的 demo，现在将 realsense demo 的跑通过程记录下来。

---

**设备：turtlebot3**
**平台：Ubuntu16.04.3**
**内核：4.4.14（17.12 月之前最新的内核）**

---

安装过程主要参考了[intel 的 github 项目](https://github.com/IntelRealSense/librealsense)，在该网址上可以看到说明这个包适用于深度摄像机 D400 系列和 SR300，而实验室的摄像头信号是 R200，需要到另一个[适用 R200 的网址](https://github.com/IntelRealSense/librealsense/tree/v1.12.1)安装,如下所示:

![适用R200的网址](https://imgconvert.csdnimg.cn/aHR0cDovL2ltZy5ibG9nLmNzZG4ubmV0LzIwMTcxMjE4MjIxNTQxNjY1?x-oss-process=image/format,png)

在这个网址安装时，由于当时使用`git clone`下载，后来发现下载的文件就是并非使用于 R200，所以建议直接下载 zip 文件，现在之后根据页面的安装手册，可以比较轻松的完成。

![linux的安装手册](https://imgconvert.csdnimg.cn/aHR0cDovL2ltZy5ibG9nLmNzZG4ubmV0LzIwMTcxMjE4MjIxNjM1Njg1?x-oss-process=image/format,png)

##3rd-party
首先，需要安装 3rd-party 依赖 1.保证 apt-get 的更新

```
sudo apt-get update && sudo apt-get upgrade
```

2.安装`libusb-1.0`和`pkg-config`

```
sudo apt-get install libusb-1.0-0-dev pkg-config
```

3.安装`glfw3`，Ubuntu14.04 需要用脚本安装（详见英文文档），Ubuntu16.04 可以直接用 apt-get 方式安装

```
sudo apt-get install libglfw3-dev
```

4.官方提供了 qt 和 cmake 来编译文件，这里选择使用 cmake 方式编译

```
mkdir build
cd build
```

这里将例程程序的编译也打开，方便安装完成后直接查看视频。

```
cmake .. -DBUILD_EXAMPLES:BOOL=true
```

安装路径在`/usr/local/lib` ,头文件在`/usr/local/include`

```
make && sudo make instal
```

例程的执行程序在`build/examples`下

##Video4Linux backend 安装 1.确保**没有摄像头**插上系统，注意拔出所有摄像头。 2.安装`udve rules`
返回源码目录，运行

```
sudo cp config/99-realsense-libusb.rules /etc/udev/rules.d/
sudo udevadm control --reload-rules && udevadm trigger
```

3.根据自己系统选择相应的方式选择安装版本。
由于我的系统是 Ubuntu16.04，内核为 4.4（`uname –a`命令查看系统和内核版本）

```
./scripts/patch-uvcvideo-16.04.simple.sh
```

这一步要经过漫长的安装。。。 4.重载 uvcvideo 驱动

```
sudo modprobe uvcvideo
```

5.查看安装信息的最后 50 行，应该可以看到一个新的 uvcvideo 驱动被安装

```
sudo dmesg | tail -n 50
```

运行后提示：（部分）

> Bluetooth: BNEP (Ethernet Emulation) ver 1.3
> [ 34.033878] Bluetooth: BNEP filters: protocol multicast
> [ 34.033885] Bluetooth: BNEP socket layer initialized
> [ 39.136255] IPv6: ADDRCONF(NETDEV_UP): wlp1s0: link is not ready
> [ 39.136424] iwlwifi 0000:01:00.0: L1 Disabled - LTR Disabled
> [ 39.136685] iwlwifi 0000:01:00.0: L1 Disabled - LTR Disabled
> [ 39.272219] iwlwifi 0000:01:00.0: L1 Disabled - LTR Disabled
> [ 39.272483] iwlwifi 0000:01:00.0: L1 Disabled - LTR Disabled
> [ 39.279661] mmc0: Got data interrupt 0x00000002 even though no data operation was in progress.
> [ 39.341626] IPv6: ADDRCONF(NETDEV_UP): wlp1s0: link is not ready
> [ 43.965760] IPv6: ADDRCONF(NETDEV_UP): wlp1s0: link is not ready
> [ 48.638656] wlp1s0: authenticate with b0:95:8e:89:3a:0f
> [ 48.640376] wlp1s0: send auth to b0:95:8e:89:3a:0f (try 1/3)
> [ 48.756518] wlp1s0: send auth to b0:95:8e:89:3a:0f (try 2/3)
> [ 48.758473] wlp1s0: authenticated
> [ 48.761946] wlp1s0: associate with b0:95:8e:89:3a:0f (try 1/3)
> [ 48.766951] wlp1s0: RX AssocResp from b0:95:8e:89:3a:0f (capab=0x431 status=0 aid=8)
> [ 48.768057] wlp1s0: associated
> [ 48.768117] IPv6: ADDRCONF(NETDEV_CHANGE): wlp1s0: link becomes ready
> [ 49.063317] iwlwifi 0000:01:00.0: No association and the time event is over already...
> [ 49.064030] wlp1s0: Connection to AP b0:95:8e:89:3a:0f lost
> [ 64.507052] Bluetooth: RFCOMM TTY layer initialized
> [ 64.507067] Bluetooth: RFCOMM socket layer initialized
> [ 64.507076] Bluetooth: RFCOMM ver 1.11
> [ 73.308219] wlp1s0: authenticate with b0:95:8e:89:3a:0f
> [ 73.309839] wlp1s0: send auth to b0:95:8e:89:3a:0f (try 1/3)
> [ 73.312326] wlp1s0: authenticated
> [ 73.313219] wlp1s0: associate with b0:95:8e:89:3a:0f (try 1/3)
> [ 73.319809] wlp1s0: RX AssocResp from b0:95:8e:89:3a:0f (capab=0x431 status=0 aid=8)
> [ 73.321144] wlp1s0: associated
> [ 75.552939] EXT4-fs (mmcblk1p3): recovery complete
> [ 75.552950] EXT4-fs (mmcblk1p3): mounted filesystem with ordered data mode. Opts: (null)
> [ 251.938597] media: Linux media interface: v0.10
> [ 251.962588] Linux video capture interface: v2.00
> [ 252.051084] usbcore: registered new interface driver uvcvideo
> [ 252.051089] USB Video Class driver (1.1.1)

到此为止，安装驱动过程已经全部完成，插上摄像头，运行 build/examples 下的文件即可看到效果

```
./cpp-capture
```

![截图1](https://imgconvert.csdnimg.cn/aHR0cDovL2ltZy5ibG9nLmNzZG4ubmV0LzIwMTcxMjE4MjIyMzQ2NTU1?x-oss-process=image/format,png)

尝试运行其他程序得到相应的结果：

![运行config-gui](https://imgconvert.csdnimg.cn/aHR0cDovL2ltZy5ibG9nLmNzZG4ubmV0LzIwMTcxMjE4MjIyNDM3OTky?x-oss-process=image/format,png)

##遇到的问题
安装完成后，使用 PC 上的虚拟机远程连接 turtlebot3 运行例子并不管用，即使开启了使用虚拟机桌面的权限也没法运行起来，而且有时出现找不到设备的情况，然后当使用 turtlebot3 插上 mirco HDMI 线，使用显示屏开机时，发现一切正常，欣喜若狂啊，猜测它应该是要求系统加载桌面才能跑通 demo，因为即使说 turtlebot3 开机了，但是在开机的时候没有连接 HDMI 线，开机完成才连接，也没法完整运行例子程序，老是显示找不到设备。除此之外，turtlebor3 无缘无故”死机”的问题还没解决.

##思考
现在仅仅是实现了一个 demo，能否用它来实现一个小小的项目或者一些有意思的事情呢，目前因为对摄像头还不是很了解，也不知道其具体的应用方向，在想能否在 turtlebot3 上用它来实现 vslam，实现真正的自主导航！

##下一步
用 ROS 启动摄像头

##参考网站
[CSDN blog](https://blog.csdn.net/bbqs1234/article/details/53912322)
[intel github](https://github.com/IntelRealSense/librealsense/tree/v1.12.1)
[intel installation guide](https://github.com/IntelRealSense/librealsense/blob/v1.12.1/doc/installation.md)
