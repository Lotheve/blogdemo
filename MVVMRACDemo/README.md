> 注：先执行 `pod install` 再运行

## 浅谈MVVM双向绑定

在上一篇[浅谈MV(X)架构](<http://lotheve.cn/article/%E6%B5%85%E8%B0%88MV(X)%E6%9E%B6%E6%9E%84/>)中谈到过MVVM，依靠ViewModel，实现了View与Model的完全解耦。另外，**View(Cotroller)**与**ViewModel**实现了双向绑定，View产生事件时ViewModel能做出响应，ViewModel数据发生更新时，View能做出响应。

双向绑定带来的直观开发体验是怎么样的？如果你有前端开发经验，并且对与React、Vue等前端响应式框架有一定了解，那你一定对双向绑定带来的开发效率上的提升深有感触。以下代码实现了Vue中输入框的双向绑定：

```vue
<input type="text" v-model="msg">
```

`input`组件和`msg`变量已经实现了双向绑定，一切都被封装在框架里，输入框的内容和`msg`变量的值总是保持着同步更新。实际前端开发中更多的是依靠数据绑定以及事件绑定带来的开发效率的提升。依靠数据绑定，你只需把注意力集中在数据上，数据的改动会实时响应到界面的更新，完全屏蔽了组件界面更新的细节，开发体验就一个字：舒服！。由于天然的响应式架构设计以及申明式的编程范式，前端实现双向绑定是很简单的一件事。

反观移动端，虽然先天并非响应式的开发模式，不过双向绑定的本质其实就是借助一些事件流处理机制，对数据更新事件或者视图交互事件进行同步响应。因此即便没有响应式框架带来的遍历，在iOS中，我们可以借助KVO、delegate、notification等事件流机制实现视图与数据（这个数据指ViewModel中的数据）的双向绑定，只是实现上并不优雅。然而借助一些开源响应式框架，例如RxJava、ReactiveCocoa（RAC）、RxSwift，可以说是为移动端的MVVM实现双向绑定铺平了道路。

在本篇的下面章节，我会以一个简单的场景，分别就"不依靠RAC"和"依靠RAC"来实现iOS中MVVM的双向绑定做一个实践对比。本篇不会涉及RAC具体实现的讲解，这是一个非常值得研究的FRP（函数响应式编程）框架（奈何笔者目前还没渗透）。

## 场景设计

一个简单的商品搜索场景：

<img src="http://lotheve.cn/blog/mvvmrac/prototype.png" alt="prototype" style="zoom:40%;" />

原型组成：输入框、搜索按钮、商品表格。

需求：点击搜索按钮，根据输入的商品关键字，请求商品列表，通过表格展示商品名及描述，不可购买的商品项背景置灰。

需求很简单，根据MVVM的设计要求，需要建立如下实体：

- GoodSearchViewController：商品搜索控制器及相关视图
- GoodSearchViewModel：商品搜索VM
- GoodCell：商品项视图
- GoodViewModel：商品项VM
- GoodModel：商品模型

本篇重点讨论的是MVVM的双向绑定，关于MVVM的设计模式不再赘述（关于本例基本结构代码已在Demo中给出，Demo地址见文章开头，下面内容强烈建议结合代码理解）。该场景主要考虑如下事件及数据的绑定：

1. `GoodSearchViewModel`绑定输入框的输入事件；
2. `GoodSearchViewModel`绑定搜索按钮点击事件；
3. 搜索按钮`enabled`状态绑定`GoodSearchViewModel`的`searchEnable`属性；
4. `GoodSearchViewController`表格刷新绑定`GoodSearchViewModel`的`needRefresh`属性；

下面内容，分别就"MVVM with ARC"和"MVVM with RAC"的情况进行双向绑定的实践。

## MVVM without RAC

所谓绑定，说白了其实当事件发生的时候，监听该事件的内容可以做出相应，也就是事件的传递。iOS中，处理事件流的方式有多种，根据不同场景可以选择KVO、Notification、Delegate、Block、Target-Action。通过这些事件流机制，就能实现MVVM的双向绑定：

- 绑定输入框输入事件

    ```objc
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textDidChangeNotification:) name:UITextFieldTextDidChangeNotification object:_searchTextField];
    
    - (void)textDidChangeNotification:(NSNotification *)notification
    {
        UITextField *tf = (UITextField *)notification.object;
        _searchViewModel.searchKey = tf.text;
    }
    ```

    通过Notification监听输入框的输入事件，当输入发生变化时，同步修改`searchViewModel`的`searchKey`，从而实现对输入框输入事件的响应，完成事件绑定。

- 绑定搜索按钮点击事件

    ```objc
    [_searchBtn addTarget:self action:@selector(actionSearch:) forControlEvents:UIControlEventTouchUpInside];
    
    - (void)actionSearch:(UIButton *)sender
    {
        [_searchViewModel searchGoods];
    }
    ```

    通过Target-Action绑定搜索按钮事件，当按钮点击时，`searchViewModel`执行`searchGoods`进行商品搜索。

- 绑定`GoodSearchViewModel`的`searchEnable`属性

    ```objc
    [self.searchViewModel addObserver:self forKeyPath:@"searchEnable" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:NULL];
    
    - (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
    {
        if ([keyPath isEqualToString:@"searchEnable"]) {
            BOOL searchEnable = ((BoolBox *)change[NSKeyValueChangeNewKey]).value;
            self.searchBtn.enabled = searchEnable;
        }
    }
    ```

    借助KVO，实现了对`searchViewModel`中`searchEnable`属性的监听。因为要求输入框内容为空时，搜索框是不可点击的，需要将`enabled`置为NO。通过监听属性同步对按钮可点击状态进行修改，即实现对该数据的绑定。

- 绑定`GoodSearchViewModel`的`needRefresh`属性

    ```objc
    [self.searchViewModel addObserver:self forKeyPath:@"needRefresh" options:NSKeyValueObservingOptionNew context:NULL];
    
    - (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
    {
        if ([keyPath isEqualToString:@"needRefresh"]) {
            BOOL needRefresh = ((BoolBox *)change[NSKeyValueChangeNewKey]).value;
            if (needRefresh) {
                [self.goodsTable reloadData];
                self.searchViewModel.needRefresh = BOOL_VALUE(NO);
            }
        }
    }
    ```

    这个场景跟上面绑定`searchEnable`一致，也是通过KVO实现，不再赘述。

通过以上这些绑定操作，就实现了该场景的基本功能：输入商品关键字，当输入内容不为空时，搜索按钮可点击。点击搜索，根据关键字进行商品列表的查询。查询结束后刷新表格进行查询结果的展示。(示例中商品数据完全是模拟的，不要在意细节~能说明问题即可)。

可见没有RAC，完全是可以实现MVVM双向绑定的！不过我认为主要有两个痛点：

1. 招式过于繁琐，各种招式大显身手，而事实上只为了做一件事：传递事件；
2. 代码过于分散，监听事件和响应事件的代码不在一处，不符合"高内聚"的思想，同时也增大了阅读瓶颈。

但有个好处是，这些招式都在iOS常规技术栈范畴，谁都会使，不存在上手门槛（更多的门槛可能是对MVVM思想的理解）。

## MVVM with RAC

RAC（ReactiveCocoa），一个函数响应式编程框架，MVVM结合该框架，可以优雅地实现视图与数据的双向绑定。RAC最主要的特点，就是它抽象了各种原生的各种"事件传递"的招式，统一成使用"Signal（信号）"的方式来传递事件。另外采用函数式的编程范式，使得"监听事件"与"响应事件"的代码高度集中，可读性更高。

下面使用RAC对上面各种招式进行改造：

- 绑定输入框输入事件

    ```objc
    RAC(self.searchViewModel, searchKey) = [self.searchTextField rac_textSignal];
    ```

    额，都在这里了。订阅了输入框的`rac_textSignal`信号，当输入框执行输入时，同步对`searchViewModel`的`searchKey`进行修改。效果和上面使用Notification是一样的！

- 绑定搜索按钮事件

    ```objc
    [[self.searchBtn rac_signalForControlEvents:UIControlEventTouchUpInside] subscribeNext:^(__kindof UIControl * _Nullable x) {
        @strongify(self);
        [self.searchViewModel searchGoods];
    }];
    ```

    绑定按钮点击事件，事件发生时`searchViewModel`执行商品搜索。

- 绑定`GoodSearchViewModel`的`searchEnable`属性

    ```objc
    RAC(self.searchBtn, enabled, @(NO)) = RACObserve(self, searchViewModel.searchEnable);
    ```

    将`searchBtn`的可点击状态与`searchViewModel`的`searchEnable`属性绑定，同时默认置为NO。

- 绑定`GoodSearchViewModel`的`needRefresh`属性

    ```objc
    [[RACObserve(self, searchViewModel.needRefresh) filter:^BOOL(NSNumber * _Nullable value) {
        return value.boolValue;
    }] subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        [self.goodsTable reloadData];
        self.searchViewModel.needRefresh = NO;
    }];
    ```

    绑定`needRefresh`属性，当监听到需要刷新，控制器对表格的刷新。

- 商品Cell参数的绑定

    当前商品Cell中展示的数据在列表滑动过程中是手动更新，即每次更新商品的ViewModel并取相关数据进行展示。借助RAC，可以实现Cell中相关视图的内容与ViewModel中数据的绑定：

    ```objc
    RAC(self.nameLabel, text) = RACObserve(self, goodsViewModel.goodsName);
    RAC(self.desLabel, text) = RACObserve(self, goodsViewModel.goodsDescription);
    RAC(self.contentView, backgroundColor) = [RACObserve(self, goodsViewModel.buyEnable) map:^id _Nullable(NSNumber *  _Nullable value) {
        return value.boolValue ? [UIColor whiteColor] : [UIColor colorWithRed:0xdd/256.0 green:0xdd/256.0 blue:0xdd/256.0 alpha:1];
    }];
    ```

    有两个注意点：

    1. 这部分代码要在cell初始化的时候执行，即在cell创建的时候执行绑定，而不能在重用过程中每次展示Cell的时候执行，否则就重复绑定了。
    2. `goodsViewModel`位于`RACObserve`宏的右边参数，表明视图是与`goodsViewModel`进行了绑定。这样cell重用时，只需更新`goodsViewModel`，界面上相关数据就会根据`goodsViewModel`同步更新，而无需手动更新这些数据。

通过RAC来实现MVVM中视图与数据的双向绑定，代码清晰度肉眼可见地得到了提升，执行的绑定逻辑一览无余。其次，代码看上去非常精炼，只需少量的代码就能实现和原生方式相同的效果。下面，我们将进一步使用RAC对当前版本进行优化，看如何移除不必要的变量状态，使代码更精简。

## 优化

当前我们通过信号对搜索按钮点击事件进行了绑定，事实上处理这种按钮事件，`RACCommand`（命令）要更擅长。通过`RACCommand`来绑定按钮点击事件有下面几个好处：

1. `RACCommand`在创建时可以设置一个"可执行性"信号`enabledSignal`，按钮点击时，只有在该信号发送的事件值为真时才能往下执行，以此过滤点击事件；
2. 按钮的`enabled`状态可以根据`enabledSignal`信号自动进行绑定，而无需额外手动绑定，从而减少不必要的状态变量；
3. 事件开始执行后，按钮的`enabled`状态会自动置为否，当command执行完毕，即当内部信号发送completed事件或error事件时才变成可点击，同样可以减少状态变量；
4. `RACCommand`自持了一个`executing`信号属性，用于发送表示command执行状态的事件值（0-未执行，1-执行中）。通过这个属性可以监听command执行的状态，而无需额外的状态变量。通常在网络请求场景下通过监听该信号事件来展示/隐藏HUD。

在`SearchViewModel`中创建一个`searchCommand`属性，表示搜索事件，初始化如下：

```objc
- (instancetype)init
{
    self = [super init];
    if (self) {
        RACSignal *searchEnableSignal = [RACObserve(self, searchKey) map:^id _Nullable(NSString *_Nullable value) {
            return @(value && value.length > 0);
        }];
        @weakify(self);
        _searchCommand = [[RACCommand alloc] initWithEnabled:searchEnableSignal signalBlock:^RACSignal * _Nonnull(id  _Nullable input) {
            @strongify(self);
            return [self singalForRequestGoods];
        }];
    }
    return self;
}
```

首先创建一个表示"按钮事件可执行性"的信号`searchEnableSignal`，一方面过滤条件不成立（商品关键字不存在）时按钮的点击事件无效，另一方面通过该信号来绑定按钮的可点击状态。如此一来，原先的`searchEnable`状态变量就能干掉了。然后根据该信号创建`searchCommand`，并传入一个返回值为"执行具体逻辑（请求商品列表）的signal"的block。

`singalForRequestGoods`返回一个信号，该信号封装了网络请求：

```objc
- (RACSignal *)singalForRequestGoods
{
    @weakify(self);
    return [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        @strongify(self);
        //模拟API请求
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSMutableArray *goods = [NSMutableArray array];
            for (int i = 0; i<20; i++) {
                GoodsBModel *model = [[GoodsBModel alloc] init];
                model.name = [NSString stringWithFormat:@"%@-%d",self.searchKey,i];
                model.des = [NSString stringWithFormat:@"商品%@，请认准！",model.name];
                model.stockCount = i%5;
                GoodsBViewModel *goodsVM = [[GoodsBViewModel alloc] initWithGoodsModel:model];
                [goods addObject:goodsVM];
            }
            self.goods = [goods copy];
            [subscriber sendNext:[goods copy]];
            [subscriber sendCompleted];
        });
        return nil;
    }];
}
```

请求完成后，发送completed事件表明该command执行完毕。command创建做的事情就是这么多了，接下来是将该命令绑定到按钮的点击事件：

```objc
self.searchBtn.rac_command = self.searchViewModel.searchCommand;
```

现在点击搜索按钮就能自动触发请求商品列表，而无需手动调用`searchGoods`，ViewModel的这个方法已经没用了。仅剩下的工作就是当请求落地即命令执行完毕时刷新tableView，这一步只需监听command的内部信号事件即可（数据源更新在网络请求内部做了，此处只需刷新表格）：

```objc
[[_searchViewModel.searchCommand.executionSignals switchToLatest] subscribeNext:^(id  _Nullable x) {
    @strongify(self);
    [self.goodsTable reloadData];
}];
```

通过监听包装了网络请求的信号事件，原先的`needRefresh`状态变量也能干掉了。

最后我还通过监听命令执行状态，添加了小菊花：

```objc
[[_searchViewModel.searchCommand.executing skip:1] subscribeNext:^(NSNumber * _Nullable x) {
    @strongify(self);
    if (x.boolValue) {
        [self.indicator startAnimating];
    } else {
        [self.indicator stopAnimating];
    }
}];
```

大功告成！通过将signal改造成command，一共节省了两个状态变量（`searchEnable`，`searchEnable`）和一个事件方法（`searchGoods`），同时减少了这些状态变量的绑定，代码进一步得到了精简。最终实现效果请查看Demo。

## 总结

通过对于MVVM双向绑定的实践，认清了两个现实：

1. 没有RAC同样可以实现双向绑定；
2. 借助RAC实现的双向绑定更为优雅，具体表现在：统一了事件流传递形势，代码更精简紧凑，同时合理运用RAC能够屏蔽一些不必要的状态变量，简化绑定逻辑。