>好奇触摸事件是如何从屏幕转移到APP内的？
>困惑于Cell怎么突然不能点击了？
>纠结于如何实现这个奇葩响应需求？
>亦或是已经被响应链、手势、target-action这一系列响应触摸事件的方式折腾到不会打Hello World？
>现在 是时候带你上分了~ （强行YY完毕）

本文主要讲解iOS触摸事件的一系列机制，涉及的问题大致包括：
+ 触摸事件由触屏生成后如何传递到当前应用？
+ 应用接收触摸事件后如何寻找最佳响应者？实现原理？
+ 触摸事件如何沿着响应链流动？
+ 响应链、手势识别器、UIControl之间对于触摸事件的响应有着什么样的瓜葛？

> tips: iOS中的事件除了触摸事件，还包括加速计事件、远程控制事件。由于两者不在本文讨论范畴，因此文中所说事件均特指触摸事件。

## 事件的生命周期

当指尖触碰屏幕的那一刻，一个触摸事件就在系统中生成了。经过IPC进程间通信，事件最终被传递到了合适的应用。在应用内历经峰回路转的奇幻之旅后，最终被释放。大致经过如下图：

![触摸事件流动过程 图片来源(http://qingmo.me/2017/03/04/FlowOfUITouch/)](http://upload-images.jianshu.io/upload_images/1510019-62b6b1eec26730aa.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

#### 系统响应阶段

1. 手指触碰屏幕，屏幕感应到触碰后，将事件交由IOKit处理。
2. IOKit将触摸事件封装成一个IOHIDEvent对象，并通过mach port传递给SpringBoad进程。
   >mach port 进程端口，各进程之间通过它进行通信。
   >SpringBoad.app 是一个系统进程，可以理解为桌面系统，可以统一管理和分发系统接收到的触摸事件。
3. SpringBoard进程因接收到触摸事件，触发了主线程runloop的source1事件源的回调。

   此时SpringBoard会根据当前桌面的状态，判断应该由谁处理此次触摸事件。因为事件发生时，你可能正在桌面上翻页，也可能正在刷微博。若是前者（即前台无APP运行），则触发SpringBoard本身主线程runloop的source0事件源的回调，将事件交由桌面系统去消耗；若是后者（即有app正在前台运行），则将触摸事件通过IPC传递给前台APP进程，接下来的事情便是APP内部对于触摸事件的响应了。

#### APP响应阶段

1. APP进程的mach port接受到SpringBoard进程传递来的触摸事件，主线程的runloop被唤醒，触发了source1回调。
2. source1回调又触发了一个source0回调，将接收到的IOHIDEvent对象封装成UIEvent对象，此时APP将正式开始对于触摸事件的响应。
3. source0回调内部将触摸事件添加到UIApplication对象的事件队列中。事件出队后，UIApplication开始一个寻找最佳响应者的过程，这个过程又称hit-testing，细节将在[[寻找事件的最佳响应者]]()一节阐述。另外，此处开始便是与我们平时开发相关的工作了。
4. 寻找到最佳响应者后，接下来的事情便是事件在响应链中的传递及响应了，关于响应链相关的内容详见[[事件的响应及在响应链中的传递]]()一节。事实上，事件除了被响应者消耗，还能被手势识别器或是target-action模式捕捉并消耗掉。其中涉及对触摸事件的响应优先级，详见[[事件的三徒弟UIResponder、UIGestureRecognizer、UIControl]]()一节。
5. 触摸事件历经坎坷后要么被某个响应对象捕获后释放，要么致死也没能找到能够响应的对象，最终释放。至此，这个触摸事件的使命就算终结了。runloop若没有其他事件需要处理，也将重归于眠，等待新的事件到来后唤醒。


>现在，你可以回答第一个问题了。触摸事件从触屏产生后，由IOKit将触摸事件传递给SpringBoard进程，再由SpringBoard分发给当前前台APP处理。

## 触摸、事件、响应者

说了那么多，到底什么是触摸、什么是事件、什么是响应者？先简单科普一下。

#### UITouch

> 源起触摸

- 一个手指一次触摸屏幕，就对应生成一个UITouch对象。多个手指同时触摸，生成多个UITouch对象。
- 多个手指先后触摸，系统会根据触摸的位置判断是否更新同一个UITouch对象。若两个手指一前一后触摸同一个位置（即双击），那么第一次触摸时生成一个UITouch对象，第二次触摸更新这个UITouch对象（UITouch对象的 **tap count** 属性值从1变成2）；若两个手指一前一后触摸的位置不同，将会生成两个UITouch对象，两者之间没有联系。
- 每个UITouch对象记录了触摸的一些信息，包括触摸时间、位置、阶段、所处的视图、窗口等信息。

```objectivec
//触摸的各个阶段状态 
//例如当手指移动时，会更新phase属性到UITouchPhaseMoved；手指离屏后，更新到UITouchPhaseEnded
typedef NS_ENUM(NSInteger, UITouchPhase) {
    UITouchPhaseBegan,             // whenever a finger touches the surface.
    UITouchPhaseMoved,             // whenever a finger moves on the surface.
    UITouchPhaseStationary,        // whenever a finger is touching the surface but hasn't moved since the previous event.
    UITouchPhaseEnded,             // whenever a finger leaves the surface.
    UITouchPhaseCancelled,         // whenever a touch doesn't end but we need to stop tracking (e.g. putting device to face)
};
```

- 手指离开屏幕一段时间后，确定该UITouch对象不会再被更新将被释放。

#### UIEvent

> 事件的真身

+ 触摸的目的是生成触摸事件供响应者响应，一个触摸事件对应一个UIEvent对象，其中的 **type** 属性标识了事件的类型（之前说过事件不只是触摸事件）。
+ UIEvent对象中包含了触发该事件的触摸对象的集合，因为一个触摸事件可能是由多个手指同时触摸产生的。触摸对象集合通过 **allTouches** 属性获取。

#### UIResponder

> 一切为了满足它的野心

每个响应者都是一个UIResponder对象，即所有派生自UIResponder的对象，本身都具备响应事件的能力。因此以下类的实例都是响应者：

+ UIView
+ UIViewController
+ UIApplication
+ AppDelegate

响应者之所以能响应事件，因为其提供了4个处理触摸事件的方法：

```objectivec
//手指触碰屏幕，触摸开始
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event;
//手指在屏幕上移动
- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event;
//手指离开屏幕，触摸结束
- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event;
//触摸结束前，某个系统事件中断了触摸，例如电话呼入
- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event;
```

这几个方法在响应者对象接收到事件的时候调用，用于做出对事件的响应。关于响应者何时接收到事件以及事件如何沿着响应链传递将在下面章节说明。

## 寻找事件的最佳响应者（Hit-Testing）

第一节讲过APP接收到触摸事件后，会被放入当前应用的一个事件队列中（PS为什么是队列而不是栈？很好理解因为触摸事件必然是先发生先执行，切合队列FIFO的原则）。

每个事件的理想宿命是被能够响应它的对象响应后释放，然而响应者诸多，事件一次只有一个，谁都想把事件抢到自己碗里来，为避免纷争，就得有一个先后顺序，也就是得有一个响应者的优先级。因此这就存在一个寻找事件最佳响应者（又称第一响应者 first responder）的过程，目的是找到一个具备最高优先级响应权的响应对象（the most appropriate responder object），这个过程叫做Hit-Testing，那个命中的最佳响应者称为hit-tested view。

本节要探讨的问题是：

1. 应用接收到事件后，如何寻找最佳响应者？底层如何实现？
2. 寻找最佳响应者过程中事件的拦截。

#### 事件自下而上的传递

应用接收到事件后先将其置入事件队列中以等待处理。出队后，application首先将事件传递给当前应用最后显示的窗口（UIWindow）询问其能否响应事件。若窗口能响应事件，则传递给子视图询问是否能响应，子视图若能响应则继续询问子视图。子视图询问的顺序是优先询问后添加的子视图，即子视图数组中靠后的视图。事件传递顺序如下：	

	UIApplication ——> UIWindow ——> 子视图 ——> ... ——> 子视图
事实上把UIWindow也看成是视图即可，这样整个传递过程就是一个递归询问子视图能否响应事件过程，且后添加的子视图优先级高（对于window而言就是后显示的window优先级高）。

**具体流程如下：**

1. UIApplication首先将事件传递给窗口对象（UIWindow），若存在多个窗口，则优先询问后显示的窗口。
2. 若窗口不能响应事件，则将事件传递其他窗口；若窗口能响应事件，则从后往前询问窗口的子视图。
3. 重复步骤2。即视图若不能响应，则将事件传递给上一个同级子视图；若能响应，则从后往前询问当前视图的子视图。
4. 视图若没有能响应的子视图了，则自身就是最合适的响应者。

**示例：**

![hit-testing 场景](http://upload-images.jianshu.io/upload_images/1510019-70fb3876d4088b4c.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

视图层级如下（同一层级的视图越在下面，表示越后添加）：

	A
	├── B
	│   └── D
	└── C
	    ├── E
	    └── F

现在假设在E视图所处的屏幕位置触发一个触摸，应用接收到这个触摸事件事件后，先将事件传递给UIWindow，然后自下而上开始在子视图中寻找最佳响应者。事件传递的顺序如下所示：

![hit-testing 过程](http://upload-images.jianshu.io/upload_images/1510019-98355f5a157ae6ab.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

1. UIWindow将事件传递给其子视图A
2. A判断自身能响应该事件，继续将事件传递给C（因为视图C比视图B后添加，因此优先传给C）。
3. C判断自身能响应事件，继续将事件传递给F（同理F比E后添加）。
4. F判断自身不能响应事件，C又将事件传递给E。
5. E判断自身能响应事件，同时E已经没有子视图，因此最终E就是最佳响应者。

#### Hit-Testing的本质

上面讲了事件在响应者之间传递的规则，视图通过判断自身能否响应事件来决定是否继续向子视图传递。那么问题来了：视图如何判断能否响应事件？以及视图如何将事件传递给子视图？

首先要知道的是，以下几种状态的视图无法响应事件：

+ **不允许交互**：userInteractionEnabled = NO
+ **隐藏**：hidden = YES 如果父视图隐藏，那么子视图也会隐藏，隐藏的视图无法接收事件
+ **透明度**：alpha < 0.01 如果设置一个视图的透明度<0.01，会直接影响子视图的透明度。alpha：0.0~0.01为透明。

**hitTest:withEvent:**

每个UIView对象都有一个 ``hitTest:withEvent:`` 方法，这个方法是Hit-Testing过程中最核心的存在，其作用是询问事件在当前视图中的响应者，同时又是作为事件传递的桥梁。

``hitTest:withEvent:`` 方法返回一个UIView对象，作为当前视图层次中的响应者。默认实现是：

+ 若当前视图无法响应事件，则返回nil
+ 若当前视图可以响应事件，但无子视图可以响应事件，则返回自身作为当前视图层次中的事件响应者
+ 若当前视图可以响应事件，同时有子视图可以响应，则返回子视图层次中的事件响应者

一开始UIApplication将事件通过调用UIWindow对象的 ``hitTest:withEvent:`` 传递给UIWindow对象，UIWindow的 ``hitTest:withEvent:`` 在执行时若判断本身能响应事件，则调用子视图的 ``hitTest:withEvent:`` 将事件传递给子视图并询问子视图上的最佳响应者。最终UIWindow返回一个视图层次中的响应者视图给UIApplication，这个视图就是hit-testing的最佳响应者。

系统对于视图能否响应事件的判断逻辑除了之前提到的3种限制状态，默认能响应的条件就是触摸点在当前视图的坐标系范围内。因此，``hitTest:withEvent:`` 的默认实现就可以推测了，大致如下：

```objectivec
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event{
    //3种状态无法响应事件
     if (self.userInteractionEnabled == NO || self.hidden == YES ||  self.alpha <= 0.01) return nil; 
    //触摸点若不在当前视图上则无法响应事件
    if ([self pointInside:point withEvent:event] == NO) return nil; 
    //从后往前遍历子视图数组 
    int count = (int)self.subviews.count; 
    for (int i = count - 1; i >= 0; i--) 
    { 
    	// 获取子视图
    	UIView *childView = self.subviews[i]; 
    	// 坐标系的转换,把触摸点在当前视图上坐标转换为在子视图上的坐标
    	CGPoint childP = [self convertPoint:point toView:childView]; 
      	//询问子视图层级中的最佳响应视图
    	UIView *fitView = [childView hitTest:childP withEvent:event]; 
    	if (fitView) 
        {
    		//如果子视图中有更合适的就返回
    		return fitView; 
    	}
    } 
    //没有在子视图中找到更合适的响应视图，那么自身就是最合适的
    return self;
}
```

值得注意的是 ``pointInside:withEvent:`` 这个方法，用于判断触摸点是否在自身坐标范围内。默认实现是若在坐标范围内则返回YES，否则返回NO。

现在我们在上述示例的视图层次中的每个视图类中添加下面3个方法来验证一下之前的分析（注意 ``hitTest:withEvent:`` 和 ``pointInside:withEvent:`` 方法都要调用父类的实现，否则不会按照默认的逻辑来执行Hit-Testing）：

```objectivec
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event{
    NSLog(@"%s",__func__);
    return [super hitTest:point withEvent:event];
}
- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event{
    NSLog(@"%s",__func__);
    return [super pointInside:point withEvent:event];
}
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    NSLog(@"%s",__func__);
}
```

单点触摸视图E，相关日志打印如下：

```
-[AView hitTest:withEvent:]
-[AView pointInside:withEvent:]
-[CView hitTest:withEvent:]
-[CView pointInside:withEvent:]
-[FView hitTest:withEvent:]
-[FView pointInside:withEvent:]
-[EView hitTest:withEvent:]
-[EView pointInside:withEvent:]
-[EView touchesBegan:withEvent:]
```

可以看到最终是视图E先对事件进行了响应，同时事件传递过程也和之前的分析一致。事实上单击后从 [AView hitTest:withEvent:] 到 [EView pointInside:withEvent:] 的过程会执行两遍，两次传的是同一个touch，区别在于touch的状态不同，第一次是begin阶段，第二次是end阶段。也就是说，**应用对于事件的传递起源于触摸状态的变化**。

#### Hit-Testing过程中的事件拦截（自定义事件流向）

实际开发中可能会遇到一些特殊的交互需求，需要定制视图对于事件的响应。例如下面Tabbar的这种情况，中间的原型按钮是底部Tabbar上的控件，而Tabbar是添加在控制器根视图中的。默认情况下我们点击图中红色方框中按钮的区域，会发现按钮并不会得到响应。

![hit-testing过程中事件拦截场景](http://upload-images.jianshu.io/upload_images/1510019-87b06513f166f331.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)


分析一下原因其实很容易就能明白问题所在。忽略不相关的控件，视图层次如下：

```o
RootView
└── TableView
└── TabBar
	└── CircleButton
```

点击红色方框区域后，生成的触摸事件首先传到UIWindow，然后传到控制器的根视图即RootView。RootView经判断可以响应触摸事件，而后将事件传给了子控件TabBar。问题就出在这里，因为触摸点不在TabBar的坐标范围内，因此TabBar无法响应该触摸事件，``hitTest:withEvent:`` 直接返回了nil。而后RootView就会询问TableView是否能够响应，事实上是可以的，因此事件最终被TableView消耗。整个过程，事件根本没有传递到圆形按钮。

有问题就会有解决策略。经过分析，发现原因是hit-Testing的过程中，事件在传递到TabBar的时候没能继续往CircleButton传，因为点击区域坐标不在Tabbar的坐标范围内，因此Tabbar被识别成了无法响应事件。既然如此，我们可以修改事件hit-Testing的过程，当点击红色方框区域时让事件流向原型按钮。

事件传递到TabBar时，TabBar的 ``hitTest:withEvent:`` 被调用，但是 ``pointInside:withEvent:`` 会返回NO，如此一来 ``hitTest:withEvent:`` 返回了nil。既然如此，可以重写TabBard的 ``pointInside:withEvent:`` ，判断当前触摸坐标是否在子视图CircleButton的坐标范围内，若在，则返回YES，反之返回NO。这样一来点击红色区域，事件最终会传递到CircleButton，CircleButton能够响应事件，最终事件就由CircleButton响应了。同时点击红色方框以外的非TabBar区域的情况下，因为TabBar无法响应事件，会按照预期由TableView响应。代码如下：

```objectivec
//TabBar
- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    //将触摸点坐标转换到在CircleButton上的坐标
    CGPoint pointTemp = [self convertPoint:point toView:_CircleButton];
    //若触摸点在CricleButton上则返回YES
    if ([_CircleButton pointInside:pointTemp withEvent:event]) {
        return YES;
    }
    //否则返回默认的操作
    return [super pointInside:point withEvent:event];
}
```

这样一来，点击红色方框区域的按钮就有效了。

> 现在第二个问题也可以回答了。另外项目中如遇到不按常理出牌的事件响应需求，相信你也应该可以应对了。

## 事件的响应及在响应链中的传递

经历Hit-Testing后，UIApplication已经知道事件的最佳响应者是谁了，接下来要做的事情就是：

1. 将事件传递给最佳响应者响应
2. 事件沿着响应链传递

#### 事件响应的前奏

因为最佳响应者具有最高的事件响应优先级，因此UIApplication会先将事件传递给它供其响应。首先，UIApplication将事件通过 ``sendEvent:`` 传递给事件所属的window，window同样通过 ``sendEvent:`` 再将事件传递给hit-tested view，即最佳响应者。过程如下：

	UIApplication ——> UIWindow ——> hit-tested view
以[寻找事件的最佳响应者]()一节中点击视图E为例，在EView的 ``touchesBegan:withEvent:`` 上断点查看调用栈就能看清这一过程：

![touchesBegan调用栈](http://upload-images.jianshu.io/upload_images/1510019-e88409cc1dae0c26.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

那么问题又来了。这个过程中，假如应用中存在多个window对象，UIApplication是怎么知道要把事件传给哪个window的？window又是怎么知道哪个视图才是最佳响应者的呢？

其实简单思考一下，这两个过程都是传递事件的过程，涉及的方法都是 ``sendEvent:`` ，而该方法的参数（UIEvent对象）是唯一贯穿整个经过的线索，那么就可以大胆猜测必然是该触摸事件对象上绑定了这些信息。事实上之前在介绍UITouch的时候就说过touch对象保存了触摸所属的window及view，而event对象又绑定了touch对象，如此一来，是不是就说得通了。要是不信的话，那就自定义一个Window类，重写 ``sendEvent：`` 方法，捕捉该方法调用时参数event的状态，答案就显而易见了。

![sendEvent](http://upload-images.jianshu.io/upload_images/1510019-f8c33118e02686d7.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

至于这两个属性是什么时候绑定到touch对象上的，必然是在hit-testing的过程中呗，仔细想想hit-testing干的不就是这个事儿吗~

#### 事件的响应

前面介绍UIResponder的时候说过，每个响应者必定都是UIResponder对象，通过4个响应触摸事件的方法来响应事件。每个UIResponder对象默认都已经实现了这4个方法，但是默认不对事件做任何处理，单纯只是将事件沿着响应链传递。若要截获事件进行自定义的响应操作，就要重写相关的方法。例如，通过重写 ``touchesMoved: withEvent:`` 方法实现简单的视图拖动。

	- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event;

每个响应触摸事件的方法都会接收两个参数，分别对应触摸对象集合和事件对象。通过监听触摸对象中保存的触摸点位置的变动，可以时时修改视图的位置。视图（UIView）作为响应者对象，本身已经实现了 ``touchesMoved: withEvent:`` 方法，因此要创建一个自定义视图（继承自UIView），重写该方法。

```objectivec
//MovedView
//重写touchesMoved方法(触摸滑动过程中持续调用)
- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
  	//获取触摸对象
    UITouch *touch = [touches anyObject];
  	//获取前一个触摸点位置
    CGPoint prePoint = [touch previousLocationInView:self];
  	//获取当前触摸点位置
    CGPoint curPoint = [touch locationInView:self];
  	//计算偏移量
    CGFloat offsetX = curPoint.x - prePoint.x;
    CGFloat offsetY = curPoint.y - prePoint.y;
  	//相对之前的位置偏移视图
    self.transform = CGAffineTransformTranslate(self.transform, offsetX, offsetY);
}
```

每个响应者都有权决定是否执行对事件的响应，只要重写相关的触摸事件方法即可。

#### 事件的传递（响应链）

前面一直在提最佳响应者，之所以称之为“最佳”，是因为其具备响应事件的最高优先权（响应链顶端的男人）。最佳响应者首先接收到事件，然后便拥有了对事件的绝对控制权：即它可以选择独吞这个事件，也可以将这个事件往下传递给其他响应者，这个由响应者构成的视图链就称之为响应链。

> 需要注意的是，上一节中也说到了事件的传递，与此处所说的事件的传递有本质区别。上一节所说的事件传递的目的是为了寻找事件的最佳响应者，是自下而上的传递；而这里的事件传递目的是响应者做出对事件的响应，这个过程是自上而下的。前者为“寻找”，后者为“响应”。

**响应者对于事件的操作方式：**

响应者对于事件的拦截以及传递都是通过 ``touchesBegan:withEvent:`` 方法控制的，该方法的默认实现是将事件沿着默认的响应链往下传递。

响应者对于接收到的事件有3种操作：
+ 不拦截，默认操作
  事件会自动沿着默认的响应链往下传递
+ 拦截，不再往下分发事件
  重写 ``touchesBegan:withEvent:`` 进行事件处理，不调用父类的 ``touchesBegan:withEvent:`` 
+ 拦截，继续往下分发事件
  重写 ``touchesBegan:withEvent:`` 进行事件处理，同时调用父类的 ``touchesBegan:withEvent:`` 将事件往下传递


**响应链中的事件传递规则：**

每一个响应者对象（UIResponder对象）都有一个 ``nextResponder`` 方法，用于获取响应链中当前对象的下一个响应者。因此，一旦事件的最佳响应者确定了，这个事件所处的响应链就确定了。

对于响应者对象，默认的 ``nextResponder`` 实现如下：
+ UIView
  若视图是控制器的根视图，则其nextResponder为控制器对象；否则，其nextResponder为父视图。
+ UIViewController
  若控制器的视图是window的根视图，则其nextResponder为窗口对象；若控制器是从别的控制器present出来的，则其nextResponder为presenting view controller。
+ UIWindow
  nextResponder为UIApplication对象。
+ UIApplication
  若当前应用的app delegate是一个UIResponder对象，且不是UIView、UIViewController或app本身，则UIApplication的nextResponder为app delegate。

![responderChain](http://upload-images.jianshu.io/upload_images/1510019-2a9a5bb5ed21bd43.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

上图是[官网](https://developer.apple.com/documentation/uikit/understanding_event_handling_responders_and_the_responder_chain?language=objc#see-also)对于响应链的示例展示，若触摸发生在UITextField上，则事件的传递顺序是：

+ UITextField ——> UIView ——> UIView ——> UIViewController ——> UIWindow ——> UIApplication ——> UIApplicationDelegation

图中虚线箭头是指若该UIView是作为UIViewController根视图存在的，则其nextResponder为UIViewController对象；若是直接add在UIWindow上的，则其nextResponder为UIWindow对象。

可以用以下方式打印一个响应链中的每一个响应对象，在最佳响应者的 ``touchBegin:withEvent:`` 方法中调用即可（别忘了调用父类的方法）

```objectivec
- (void)printResponderChain
{
    UIResponder *responder = self;
    printf("%s",[NSStringFromClass([responder class]) UTF8String]);
    while (responder.nextResponder) {
        responder = responder.nextResponder;
        printf(" --> %s",[NSStringFromClass([responder class]) UTF8String]);
    }
}
```

以上一节原型按钮的案例为例，重写CircleButton的 ``touchBegin:withEvent:`` 

```objectivec
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [self printResponderChain];
    [super touchesBegan:touches withEvent:event];
}
```

点击原型按钮的任意区域，打印出的完整响应链如下：

**CircleButton --> CustomeTabBar --> UIView --> UIViewController --> UIViewControllerWrapperView --> UINavigationTransitionView --> UILayoutContainerView --> UINavigationController --> UIWindow --> UIApplication --> AppDelegate**

另外如果有需要，完全可以重写响应者的 ``nextResponder`` 方法来自定义响应链。

>现在，第三个问题也解决了。

## 事件的三徒弟UIResponder、UIGestureRecognizer、UIControl

iOS中，除了UIResponder能够响应事件，手势识别器、UIControl同样具备对事件的处理能力。当这几者同时存在于某一场景下的时候，事件又会有怎样的归宿呢？

#### 抛砖引玉

场景界面如图：

![手势冲突场景](http://upload-images.jianshu.io/upload_images/1510019-b5d1f89f7ebfda95.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

代码不能再简单：

```objectivec
- (void)viewDidLoad {
    [super viewDidLoad];
  	//底部是一个绑定了单击手势的backView
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(actionTapView)];
    [_backView addGestureRecognizer:tap];
  	//上面是一个常规的tableView
    _tableMain.tableFooterView = [UIView new];
  	//还有一个和tableView同级的button
	[_button addTarget:self action:@selector(buttonTap) forControlEvents:UIControlEventTouchUpInside];
}

- (void)actionTapView{
    NSLog(@"backview taped");
}

- (void)buttonTap {
    NSLog(@"button clicked!");
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    NSLog(@"cell selected!");
}
```

然后我像往常一样怀揣着吃奶的自信点击了cell。what？？点不动？？点歪了吗？？再点，还是没反应！！我试着短按了一小会儿cell，依旧没反应！！我不死心，长按了一会儿，didSelectRowAtIndexPath终于调了，还算给点面子 - -。然后我又点了下面的button，没有任何问题。but what ？？

为了搞清楚状况，我自定义了相关的控件类，均重写了4个响应触摸事件的方法以打印日志（每个重写的触摸事件方法都调用了父类的方法以保证事件默认传递逻辑）。

观察各种情况下的日志现象：

**现象一** 快速点击cell
```
backview taped
```

**现象二** 短按cell
```
-[GLTableView touchesBegan:withEvent:]
backview taped
-[GLTableView touchesCancelled:withEvent:]
```

**现象三** 长按cell
```
-[GLTableView touchesBegan:withEvent:]
-[GLTableView touchesEnded:withEvent:]
cell selected!
```

**现象四** 点击button
```
-[GLButton touchesBegan:withEvent:]
-[GLButton touchesEnded:withEvent:]
button clicked!
```

> 如果上面的现象依旧能让你舒心地抿上一口咖啡，那么恭喜你，本节的内容已经不适合你了。如果觉得一脸懵逼，那就继续往下看吧~ 

#### 二师兄—手势识别器

关于手势识别器即 ``UIGestureRecognizer`` 本身的使用不是本文要所讨论的内容，按下不表。此处要探讨的是：**手势识别器与UIResponder的联系**。

事实上，手势分为离散型手势（discrete gestures）和持续型手势（continuous gesture）。系统提供的离散型手势包括点按手势（[UITapGestureRecognizer](apple-reference-documentation://hcmEtJ0eLp)）和轻扫手势（[`UISwipeGestureRecognizer`](apple-reference-documentation://hcKMJKvz5T)），其余均为持续型手势。

两者主要区别在于状态变化过程：

+ 离散型：
  识别成功：Possible —> Recognized
  识别失败：Possible —> Failed

+ 持续型：
  完整识别：Possible —> Began —> [Changed] —> Ended
  不完整识别：Possible —> Began —> [Changed] —> Cancel

**离散型手势**

先抛开上面的场景，看一个简单的demo。

![离散型手势场景](http://upload-images.jianshu.io/upload_images/1510019-870f0e3a406b4205.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

控制器的视图上add了一个View记为YellowView，并绑定了一个单击手势识别器。

```objectivec
// LXFViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(actionTap)];
    [self.view addGestureRecognizer:tap];
}
- (void)actionTap{
    NSLog(@"View Taped");
}
```

单击YellowView，日志打印如下：

```
-[YellowView touchesBegan:withEvent:]
View Taped
-[YellowView touchesCancelled:withEvent:]
```

从日志上看出YellowView最后Cancel了对触摸事件的响应，而正常应当是触摸结束后，YellowView的 ``touchesEnded:withEvent:`` 的方法被调用才对。另外，期间还执行了手势识别器绑定的action 。我从[官方文档](https://developer.apple.com/documentation/uikit/uigesturerecognizer?language=objc)找到了这样的解释：

>A window delivers touch events to a gesture recognizer before it delivers them to the hit-tested view attached to the gesture recognizer. Generally, if a gesture recognizer analyzes the stream of touches in a multi-touch sequence and doesn’t recognize its gesture, the view receives the full complement of touches. If a gesture recognizer recognizes its gesture, the remaining touches for the view are cancelled.The usual sequence of actions in gesture recognition follows a path determined by default values of the [cancelsTouchesInView](https://developer.apple.com/documentation/uikit/uigesturerecognizer/1624218-cancelstouchesinview?language=objc), [delaysTouchesBegan](https://developer.apple.com/documentation/uikit/uigesturerecognizer/1624234-delaystouchesbegan?language=objc), [delaysTouchesEnded](https://developer.apple.com/documentation/uikit/uigesturerecognizer/1624209-delaystouchesended?language=objc) properties.

大致理解是，Window在将事件传递给hit-tested view之前，会先将事件传递给相关的手势识别器并由手势识别器优先识别。若手势识别器成功识别了事件，就会取消hit-tested view对事件的响应；若手势识别器没能识别事件，hit-tested view才完全接手事件的响应权。

一句话概括：**手势识别器比UIResponder具有更高的事件响应优先级！！**

按照这个解释，Window在将事件传递给hit-tested view即YellowView之前，先传递给了控制器根视图上的手势识别器。手势识别器成功识别了该事件，通知Application取消YellowView对事件的响应。

然而看日志，却是YellowView的 ``touchesBegan:withEvent:`` 先调用了，既然手势识别器先响应，不应该上面的action先执行吗，这又怎么解释？事实上这个认知是错误的。手势识别器的action的调用时机（即此处的 ``actionTap``）并不是手势识别器接收到事件的时机，而是手势识别器成功识别事件后的时机，即手势识别器的状态变为[UIGestureRecognizerStateRecognized](apple-reference-documentation://hcCvvcGh5U)。因此从该日志中并不能看出事件是优先传递给手势识别器的，那该**怎么证明Window先将事件传递给了手势识别器？**

要解决这个问题，只要知道手势识别器是如何接收事件的，然后在接收事件的方法中打印日志对比调用时间先后即可。说起来你可能不信，手势识别器对于事件的响应也是通过这4个熟悉的方法来实现的。

```objectivec
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event;
- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event;
- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event;
- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event;
```

需要注意的是，虽然手势识别器通过这几个方法来响应事件，但它并不是UIResponder的子类，相关的方法声明在 ``UIGestureRecognizerSubclass.h`` 中。

这样一来，我们便可以自定义一个单击手势识别器的类，重写这几个方法来监听手势识别器接收事件的时机。创建一个UITapGestureRecognizer的子类，重写响应事件的方法，每个方法中调用父类的实现，并替换demo中的手势识别器。另外需要在.m文件中引入 ``import <UIKit/UIGestureRecognizerSubclass.h>`` ，因为相关方法声明在该头文件中。

```objectivec
// LXFTapGestureRecognizer (继承自UITapGestureRecognizer)
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    NSLog(@"%s",__func__);
    [super touchesBegan:touches withEvent:event];
}
- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    NSLog(@"%s",__func__);
    [super touchesMoved:touches withEvent:event];
}
- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    NSLog(@"%s",__func__);
    [super touchesEnded:touches withEvent:event];
}
- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    NSLog(@"%s",__func__);
    [super touchesCancelled:touches withEvent:event];
}
```

现在，再次点击YellowView，日志如下：

```
-[LXFTapGestureRecognizer touchesBegan:withEvent:]
-[YellowView touchesBegan:withEvent:]
-[LXFTapGestureRecognizer touchesEnded:withEvent:]
View Taped
-[YellowView touchesCancelled:withEvent:]
```

很明显，确实是手势识别器先接收到了事件。之后手势识别器成功识别了手势，执行了action，再由Application取消了YellowView对事件的响应。

**Window怎么知道要把事件传递给哪些手势识别器？**

之前探讨过**Application怎么知道要把event传递给哪个Window**，以及**Window怎么知道要把event传递给哪个hit-tested view**的问题，答案是这些信息都保存在event所绑定的touch对象上。手势识别器也是一样的，event绑定的touch对象上维护了一个手势识别器数组，里面的手势识别器毫无疑问是在hit-testing的过程中收集的。打个断点看一下touch上绑定的手势识别器数组：

![手势识别器捕捉](http://upload-images.jianshu.io/upload_images/1510019-6414201f2a3bd5ab.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

Window先将事件传递给这些手势识别器，再传给hit-tested view。一旦有手势识别器成功识别了手势，Application就会取消hit-tested view对事件的响应。

**持续型手势**

将上面Demo中视图绑定的单击手势识别器用滑动手势识别器（UIPanGestureRecognizer）替换。

```objectivec
- (void)viewDidLoad {
    [super viewDidLoad];
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(actionPan)];
    [self.view addGestureRecognizer:pan];
}
- (void)actionPan{
    NSLog(@"View panned");
}
```

在YellowView上执行一次滑动：

![持续型手势场景](http://upload-images.jianshu.io/upload_images/1510019-4a8dc0bea513f8c7.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

日志打印如下：

```
-[YellowView touchesBegan:withEvent:]
-[YellowView touchesMoved:withEvent:]
-[YellowView touchesMoved:withEvent:]
-[YellowView touchesMoved:withEvent:]
View panned
-[YellowView touchesCancelled:withEvent:]
View panned
View panned
View panned
...
```

在一开始滑动的过程中，手势识别器处在识别手势阶段，滑动产生的连续事件既会传递给手势识别器又会传递给YellowView，因此YellowView的 ``touchesMoved:withEvent:`` 在开始一段时间内会持续调用；当手势识别器成功识别了该滑动手势时，手势识别器的action开始调用，同时通知Application取消YellowView对事件的响应。之后仅由滑动手势识别器接收事件并响应，YellowView不再接收事件。

另外，在滑动的过程中，若手势识别器未能识别手势，则事件在触摸滑动过程中会一直传递给hit-tested view，直到触摸结束。读者可自行验证。

**手势识别器的3个属性**

```objectivec
@property(nonatomic) BOOL cancelsTouchesInView;
@property(nonatomic) BOOL delaysTouchesBegan;
@property(nonatomic) BOOL delaysTouchesEnded;
```

先总结一下手势识别器与UIResponder对于事件响应的联系：

当触摸发生或者触摸的状态发生变化时，Window都会传递事件寻求响应。

+ Window先将绑定了触摸对象的事件传递给触摸对象上绑定的手势识别器，再发送给触摸对象对应的hit-tested view。
+ 手势识别器识别手势期间，若触摸对象的触摸状态发生变化，事件都是先发送给手势识别器再发送给hit-test view。
+ 手势识别器若成功识别了手势，则通知Application取消hit-tested view对于事件的响应，并停止向hit-tested view发送事件；
+ 若手势识别器未能识别手势，而此时触摸并未结束，则停止向手势识别器发送事件，仅向hit-test view发送事件。
+ 若手势识别器未能识别手势，且此时触摸已经结束，则向hit-tested view发送end状态的touch事件以停止对事件的响应。


***cancelsTouchesInView***

默认为YES。表示当手势识别器成功识别了手势之后，会通知Application取消响应链对事件的响应，并不再传递事件给hit-test view。若设置成NO，表示手势识别成功后不取消响应链对事件的响应，事件依旧会传递给hit-test view。

demo中设置: ```pan.cancelsTouchesInView = NO```

滑动时日志如下：

```
-[YellowView touchesBegan:withEvent:]
-[YellowView touchesMoved:withEvent:]
-[YellowView touchesMoved:withEvent:]
-[YellowView touchesMoved:withEvent:]
View panned
-[YellowView touchesMoved:withEvent:]
View panned
View panned
-[YellowView touchesMoved:withEvent:]
View panned
-[YellowView touchesMoved:withEvent:]
...
```

即便滑动手势识别器识别了手势，Application也会依旧发送事件给YellowView。

***delaysTouchesBegan***

默认为NO。默认情况下手势识别器在识别手势期间，当触摸状态发生改变时，Application都会将事件传递给手势识别器和hit-tested view；若设置成YES，则表示手势识别器在识别手势期间，截断事件，即不会将事件发送给hit-tested view。

设置 ``pan.delaysTouchesBegan = YES``

日志如下：

```
View panned
View panned
View panned
View panned
...
```

因为滑动手势识别器在识别期间，事件不会传递给YellowView，因此期间YellowView的 ```touchesBegan:withEvent:``` 和 ```touchesMoved:withEvent:``` 都不会被调用；而后滑动手势识别器成功识别了手势，也就独吞了事件，不会再传递给YellowView。因此只打印了手势识别器成功识别手势后的action调用。

***delaysTouchesEnded***

默认为YES。当手势识别失败时，若此时触摸已经结束，会延迟一小段时间（0.15s）再调用响应者的 ```touchesEnded:withEvent:```；若设置成NO，则在手势识别失败时会立即通知Application发送状态为end的touch事件给hit-tested view以调用 ``touchesEnded:withEvent:`` 结束事件响应。

> 总结：手势识别器比响应链具有更高的事件响应优先级。

#### 大师兄—UIControl

UIControl是系统提供的能够以target-action模式处理触摸事件的控件，iOS中UIButton、UISegmentedControl、UISwitch等控件都是UIControl的子类。当UIControl跟踪到触摸事件时，会向其上添加的target发送事件以执行action。值得注意的是，UIConotrol是UIView的子类，因此本身也具备UIResponder应有的身份。

关于UIControl，此处介绍两点：
1. target-action执行时机及过程
2. 触摸事件优先级

**target-action**
+ target：处理交互事件的对象
+ action：处理交互事件的方式

UIControl作为能够响应事件的控件，必然也需要待事件交互符合条件时才去响应，因此也会跟踪事件发生的过程。不同于UIControl以及UIGestureRecognizer通过 ``touches`` 系列方法跟踪，UIControl有其独特的跟踪方式：

```objectivec
- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(nullable UIEvent *)event;
- (BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(nullable UIEvent *)event;
- (void)endTrackingWithTouch:(nullable UITouch *)touch withEvent:(nullable UIEvent *)event;
- (void)cancelTrackingWithEvent:(nullable UIEvent *)event;
```

乍一看，这4个方法和UIResponder的那4个方法几乎吻合，只不过UIControl只能接收单点触控，因此接收的参数是单个UITouch对象。这几个方法的职能也和UIResponder一致，用来跟踪触摸的开始、滑动、结束、取消。不过，UIControl本身也是UIResponder，因此同样有 ``touches`` 系列的4个方法。事实上，UIControl的 ``Tracking`` 系列方法是在 ``touch`` 系列方法内部调用的。比如 ``beginTrackingWithTouch``  是在 ``touchesBegan`` 方法内部调用的， 因此它虽然也是UIResponder，但 ``touches`` 系列方法的默认实现和UIResponder本类还是有区别的。

当UIControl跟踪事件的过程中，识别出事件交互符合响应条件，就会触发target-action进行响应。UIControl控件通过 ``addTarget:action:forControlEvents:`` 添加事件处理的target和action，当事件发生时，UIControl通知target执行对应的action。说是“通知”其实很笼统，事实上这里有个action传递的过程。当UIControl监听到需要处理的交互事件时，会调用 ``sendAction:to:forEvent: `` 将target、action以及event对象发送给全局应用，Application对象再通过 ``sendAction:to:from:forEvent:`` 向target发送action。

![target-action过程](http://upload-images.jianshu.io/upload_images/1510019-0592ab73ec1e432e.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

因此，可以通过重写UIControl的 ``sendAction:to:forEvent: `` 或 ``sendAction:to:from:forEvent:`` 自定义事件执行的target及action。

另外，若不指定target，即 ``addTarget:action:forControlEvents:`` 时target传空，那么当事件发生时，Application会在响应链上从上往下寻找能响应action的对象。官方说明如下：

> If you specify `nil` for the target object, the control searches the responder chain for an object that defines the specified action method.

**触摸事件优先级**

当原本关系已经错综复杂的UIGestureRecognizer和UIResponder之间又冒出一个UIControl，又会摩擦出什么样的火花呢？

> In iOS 6.0 and later, default control actions prevent overlapping gesture recognizer behavior. For example, the default action for a button is a single tap. If you have a single tap gesture recognizer attached to a button’s parent view, and the user taps the button, then the button’s action method receives the touch event instead of the gesture recognizer.This applies only to gesture recognition that overlaps the default action for a control, which includes:
>
> + A single finger single tap on a `UIButton`, `UISwitch`, `UIStepper`, `UISegmentedControl`, and `UIPageControl`.
>
>
> + A single finger swipe on the knob of a `UISlider`, in a direction parallel to the slider.
>
>
> + A single finger pan gesture on the knob of a `UISwitch`, in a direction parallel to the switch.

简单理解：UIControl会阻止父视图上的手势识别器行为，也就是UIControl处理事件的优先级比UIGestureRecognizer高，但前提是相比于父视图上的手势识别器。

![UIControl测试场景](http://upload-images.jianshu.io/upload_images/1510019-4d4ceaa8787dbbc4.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

+ 预置场景：在BlueView上添加一个button，同时给button添加一个target-action事件。
  + 示例一：在BlueView上添加点击手势识别器
  + 示例二：在button上添加手势识别器

+ 操作方式：单击button

+ 测试结果：示例一中，button的target-action响应了单击事件；示例二中，BlueView上的手势识别器响应了事件。过程日志打印如下：

  ```
  //示例一
  -[CLTapGestureRecognizer touchesBegan:withEvent:]
  -[CLButton touchesBegan:withEvent:]
  -[CLButton beginTrackingWithTouch:withEvent:]
  -[CLTapGestureRecognizer touchesEnded:withEvent:] after called state = 5
  -[CLButton touchesEnded:withEvent:]
  -[CLButton endTrackingWithTouch:withEvent:]
  按钮点击
  ```

  ```
  //示例二
  -[CLTapGestureRecognizer touchesBegan:withEvent:]
  -[CLButton touchesBegan:withEvent:]
  -[CLButton beginTrackingWithTouch:withEvent:]
  -[CLTapGestureRecognizer touchesEnded:withEvent:] after called state = 3
  手势触发
  -[CLButton touchesCancelled:withEvent:]
  -[CLButton cancelTrackingWithEvent:]
  ```

+ 原因分析：点击button后，事件先传递给手势识别器，再传递给作为hit-tested view存在的button（UIControl本身也是UIResponder，这一过程和普通事件响应者无异）。示例一中，由于button阻止了父视图BlueView中的手势识别器的识别，导致手势识别器识别失败（状态为failed 枚举值为5），button完全接手了事件的响应权，事件最终由button响应；示例二中，button未阻止其本身绑定的手势识别器的识别，因此手势识别器先识别手势并识别成功（状态为ended 枚举值为3），而后通知Application取消响应链对事件的响应，因为 ``touchesCancelled`` 被调用，同时 ``cancelTrackingWithEvent`` 跟着调用，因此button的target-action得不到执行。

+ 其他：经测试，若示例一中的手势识别器设置 ``cancelsTouchesInView`` 为NO，手势识别器和button都能响应事件。也就是说这种情况下，button不会阻止父视图中手势识别器的识别。

+ 结论：UIControl比其**父视图**上的手势识别器具有更高的事件响应优先级。


> TODO:
> 上述过程中，手势识别器在执行touchesEnded时是根据什么将状态置为ended还是failed的？即根据什么判断应当识别成功还是识别失败？

### 纠正 2017.11.17

以上所述UIControl的响应优先级比手势识别器高不准确，准确地说只适用于系统提供的有默认action操作的UIControl，例如UIbutton、UISwitch等的单击，而对于自定义的UIControl，经验证，响应优先级比手势识别器低。读者可自行验证，感谢 @[闫仕伟](http://www.jianshu.com/u/47c49d576b79) 同学的纠正。

#### 拨云见日

现在，把胶卷回放到本章节开头的场景。给你一杯咖啡的时间看看能不能解释得通那几个现象了，不说了泡咖啡去了...

我肥来了！

先看***现象二***，短按 cell无法响应，日志如下：

```
-[GLTableView touchesBegan:withEvent:]
backview taped
-[GLTableView touchesCancelled:withEvent:]
```

这个日志和上面[离散型手势]()Demo中打印的日志完全一致。短按后，BackView上的手势识别器先接收到事件，之后事件传递给hit-tested view，作为响应者链中一员的GLTableView的 ``touchesBegan:withEvent:`` 被调用；而后手势识别器成功识别了点击事件，action执行，同时通知Application取消响应链中的事件响应，GLTableView的 ``touchesCancelled:withEvent:`` 被调用。

因为事件被取消了，因此Cell无法响应点击。

再看***现象三***，长按cell能够响应，日志如下：

```
-[GLTableView touchesBegan:withEvent:]
-[GLTableView touchesEnded:withEvent:]
cell selected!
```

长按的过程中，一开始事件同样被传递给手势识别器和hit-tested view，作为响应链中一员的GLTableView的 ``touchesBegan:withEvent:`` 被调用；此后在长按的过程中，手势识别器一直在识别手势，直到一定时间后手势识别失败，才将事件的响应权完全交给响应链。当触摸结束的时候，GLTableView的 ``touchesEnded:withEvent:`` 被调用，同时Cell响应了点击。

OK，现在回到***现象一***。按照之前的分析，快速点击cell，讲道理不管是表现还是日志都应该和***现象二***一致才对。然而日志仅仅打印了手势识别器的action执行结果。分析一下原因：GLTableView的 ```touchesBegan``` 没有调用，说明事件没有传递给hit-tested view。那只有一种可能，就是事件被某个手势识别器拦截了。目前已知的手势识别器拦截事件的方法，就是设置 ``delaysTouchesBegan`` 为YES，在手势识别器未识别完成的情况下不会将事件传递给hit-tested view。然后事实上并没有进行这样的设置，那么问题可能出在别的手势识别器上。

Window的 ``sendEvent:`` 打个断点查看event上的touch对象维护的手势识别器数组：

![ScrollView延迟发送事件](http://upload-images.jianshu.io/upload_images/1510019-786581b9d7281d92.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

捕获可疑对象：``UIScrollViewDelayedTouchesBeganGestureRecognizer`` ，光看名字就觉得这货脱不了干系。从类名上猜测，这个手势识别器大概会延迟事件向响应链的传递。github上找到了该私有类的[头文件](https://github.com/nst/iOS-Runtime-Headers/blob/master/Frameworks/UIKit.framework/UIScrollViewDelayedTouchesBeganGestureRecognizer.h)：

```objectivec
@interface UIScrollViewDelayedTouchesBeganGestureRecognizer : UIGestureRecognizer {
    UIView<UIScrollViewDelayedTouchesBeganGestureRecognizerClient> * _client;
    struct CGPoint { 
        float x; 
        float y; 
    }  _startSceneReferenceLocation;
    UIDelayedAction * _touchDelay;
}
- (void).cxx_destruct;
- (id)_clientView;
- (void)_resetGestureRecognizer;
- (void)clearTimer;
- (void)dealloc;
- (void)sendDelayedTouches;
- (void)sendTouchesShouldBeginForDelayedTouches:(id)arg1;
- (void)sendTouchesShouldBeginForTouches:(id)arg1 withEvent:(id)arg2;
- (void)touchesBegan:(id)arg1 withEvent:(id)arg2;
- (void)touchesCancelled:(id)arg1 withEvent:(id)arg2;
- (void)touchesEnded:(id)arg1 withEvent:(id)arg2;
- (void)touchesMoved:(id)arg1 withEvent:(id)arg2;
@end
```

有一个_touchDelay变量，大概是用来控制延迟事件发送的。另外，方法列表里有个 ``sendTouchesShouldBeginForDelayedTouches:`` 方法，听名字似乎是在一段时间延迟后向响应链传递事件用的。为一探究竟，我创建了一个类hook了这个方法：

```objectivec
//TouchEventHook.m
+ (void)load{
    Class aClass = objc_getClass("UIScrollViewDelayedTouchesBeganGestureRecognizer");
    SEL sel = @selector(hook_sendTouchesShouldBeginForDelayedTouches:);
    Method method = class_getClassMethod([self class], sel);
    class_addMethod(aClass, sel, class_getMethodImplementation([self class], sel), method_getTypeEncoding(method));
    exchangeMethod(aClass, @selector(sendTouchesShouldBeginForDelayedTouches:), sel);
}

- (void)hook_sendTouchesShouldBeginForDelayedTouches:(id)arg1{
    [self hook_sendTouchesShouldBeginForDelayedTouches:arg1];
}

void exchangeMethod(Class aClass, SEL oldSEL, SEL newSEL) {
    Method oldMethod = class_getInstanceMethod(aClass, oldSEL);
    Method newMethod = class_getInstanceMethod(aClass, newSEL);
    method_exchangeImplementations(oldMethod, newMethod);
}
```

断点看一下点击cell后 ``hook_sendTouchesShouldBeginForDelayedTouches:`` 调用时的信息：

![延迟的本质](http://upload-images.jianshu.io/upload_images/1510019-bb69397f67b4eb44.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

可以看到这个手势识别器的 _touchDelay 变量中，保存了一个计时器，以及一个长得很像延迟时间间隔的变量m\_delay。现在，可以推测该手势识别器截断了事件并延迟0.15s才发送给hit-tested view。为验证猜测，我分别在Window的 ``sendEvent:`` ，``hook_sendTouchesShouldBeginForDelayedTouches:`` 以及TableView的 ``touchesBegan:`` 中打印时间戳，若猜测成立，则应当前两者的调用时间相差0.15s左右，后两者的调用时间很接近。短按Cell后打印结果如下（不能快速点击，否则还没过延迟时间触摸就结束了，无法验证猜测）：

```
-[GLWindow sendEvent:]调用时间戳 :
525252194779.07ms
-[TouchEventHook hook_sendTouchesShouldBeginForDelayedTouches:]调用时间戳 :
525252194930.91ms
-[TouchEventHook hook_sendTouchesShouldBeginForDelayedTouches:]调用时间戳 :
525252194931.24ms
-[GLTableView touchesBegan:withEvent:]调用时间戳 :
525252194931.76ms
```

因为有两个 ``UIScrollViewDelayedTouchesBeganGestureRecognizer``，所以 ``hook_sendTouchesShouldBeginForDelayedTouches`` 调了两次，两次的时间很接近。可以看到，结果完全符合猜测。

这样就都解释得通了。***现象一***由于点击后，```UIScrollViewDelayedTouchesBeganGestureRecognizer``` 拦截了事件并延迟了0.15s发送。又因为点击时间比0.15s短，在发送事件前触摸就结束了，因此事件没有传递到hit-tested view，导致TableView的 ``touchBegin`` 没有调用。而***现象二***，由于短按的时间超过了0.15s，手势识别器拦截了事件并经过0.15s后，触摸还未结束，于是将事件传递给了hit-tested view，使得TableView接收到了事件。因此现象二的日志虽然和[离散型手势]()Demo中的日志一致，但实际上前者的hit-tested view是在触摸后延迟了约0.15s左右才接收到触摸事件的。

至于***现象四*** ，你现在应该已经觉得理所当然了才对。

## 总结

+ 触摸发生时，系统内核生成触摸事件，先由IOKit处理封装成IOHIDEvent对象，通过IPC传递给系统进程SpringBoard，而后再传递给前台APP处理。
+ 事件传递到APP内部时被封装成开发者可见的UIEvent对象，先经过hit-testing寻找第一响应者，而后由Window对象将事件传递给hit-tested view，并开始在响应链上的传递。
+ UIRespnder、UIGestureRecognizer、UIControl，笼统地讲，事件响应优先级依次递增。

#### 参考资料

1. [史上最详细的iOS之事件的传递和响应机制-原理篇](http://www.jianshu.com/p/2e074db792ba)
2. [Understanding Event Handling, Responders, and the Responder Chain](https://developer.apple.com/documentation/uikit/understanding_event_handling_responders_and_the_responder_chain?language=objc#see-also)
3. [iOS触摸事件的流动](http://qingmo.me/2017/03/04/FlowOfUITouch/)
  4. [UIKit: UIControl](http://southpeak.github.io/2015/12/13/cocoa-uikit-uicontrol/)