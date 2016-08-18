## 起因

> 最近工作发现有时候需要测试发送TCP包，而目前Mac上又没有找到功能很好的软件，所以就自己开发了一个简单而实用的工具。[PacketSender](https://itunes.apple.com/us/app/packetsender/id906185173?l=zh&ls=1&mt=12)
> 因后来实用ObjC重写了的原因，所以开源旧版本的Swift版本吧。[GitLab](https://gitlab.com/sohunjug/PacketSender-Swift.git)、[GitHub](https://github.com/sohunjug/PacketSender-Swift.git)

<!--more-->

## 所使用库

> 两个版本都使用的[CocoaAsyncSocket](https://github.com/robbiehanson/CocoaAsyncSocket)开源库来实现socket连接。
> 在objc或swift中，主界面是在主线程中执行，所以相关socket操作等，尽量需要效率且非阻塞，让等待函数在后台线程执行，这个库正好满足。

## 版本

### Version 1.0

* 满足单一发送功能

![1.0](http://oalatibtx.bkt.clouddn.com/147153152589540.jpg?imageView2/0/format/jpg)

### Version 1.2

* 增加了发送历史记录功能 
* 增加了消息背景

![1.2.1](http://7xp1l3.com1.z0.glb.clouddn.com/FgduG45k5rNkevyXERV1CEMobDaW)

![1.2.2](http://oalatibtx.bkt.clouddn.com/802423.png)

### Version 1.3

* 增加了行数
* 修改了Server状态显示
* 增加了发收包数量复制

![1.3](http://oalatibtx.bkt.clouddn.com/289304.png)

> 在此版本之前，一直未发现之前版本在Mac OS X 10.11.6 版本，根本无法使用，NSTextView无法选中，无法输入，也无法显示。
> 期初我以为是Swift在 macOS 10.12 beta 4版本使用Xcode 7.3.1编译，造成不兼容问题，所以使用了ObjC重写了Version 1.2.2。
> 但是结果显示问题依旧。虽然现在更新了1.3版本。但是此版本是使用朋友的机器，在Mac OS X 10.11.6环境下编译。

<br>
> 本人还有一个[JsonXmlFormater](https://itunes.apple.com/us/app/jsonxmlformater/id909976737?l=zh&ls=1&mt=12)，也是在beta环境编译的，但是这里面的NSTextView就没有问题。

## 待解决问题

> 希望以后如果有某位朋友找到解决办法，能沟通下，谢谢。

<br>

> 欢迎关于macOS开发的朋友，来跟我一起交流技术。


