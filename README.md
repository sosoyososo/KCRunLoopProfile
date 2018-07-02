# KCRunLoopProfile
监控主线程，当主线程“变慢”的时候打印出当前的日志。

## 注意
***不要在线上版本使用***

## 原理
1. 为主线程的runloop增加observer，监控kCFRunLoopBeforeSources 和 kCFRunLoopBeforeWaiting。
2. kCFRunLoopBeforeSources回调的时候创建一个时间戳，kCFRunLoopBeforeWaiting的回调重置这个时间戳。
3. 创建一个GCD queue，启动一个timer，循环检查第二步操作的时间戳。如果检查到的时间戳没有被重置，并且超出了我们设置的阈值，我们认为主线程当前执行缓慢。
4. 检测到主线程变慢，停止所有的线程，获取所有线程的执行堆栈符号化后的信息以及当前执行环境的其他信息。
5. 使用这个信息发起回调，交给使用者处理。


## 声明
这个库严重依赖于[KSCrash](https://github.com/kstenerud/KSCrash)的代码来进行线程相关的一些操作。
