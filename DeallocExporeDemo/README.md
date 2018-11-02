# 探索dealloc真谛

## 动机由来

最近在封装一个 `UITextField` 分类的时候遇到了一个问题，大致需求是封装 `UITextField` 的若干功能，方便业务方这样使用：

```objc
// 限制输入长度
[_tf ltv_limitLength:5];
// 限制输入字符
[_tf ltv_limitContent:[NSCharacterSet characterSetWithCharactersInString:@"-+*"]];
// 匹配输入条件触发action
[_tf ltv_matchCondition:^BOOL(NSString *text) {
    return [text isEqualToString:@"asd"];
} action:^(NSString *text) {
    NSLog(@"matched asd");
}];
```

基本实现思路是借助一个全局单例，作为UITextField内容变化时通知的观察者，其中object参数指定了需要监听的 `UITextField` 实例，这样一来，当输入内容发生变化，就能触发对应 `UITextField` 实例相关的逻辑处理：

```objc
[[NSNotificationCenter defaultCenter] addObserver:[self manager] selector:@selector(textfieldDidChangedTextNotification:) name:UITextFieldTextDidChangeNotification object:target];
```

这种思路有一个问题需要处理，就是当 `UITextField` 实例释放的时候，需要移除对应的通知。也就是说，我需要监听   `UITextField` 实例的释放。由于是系统控件，没法直接复写 `dealloc` 方法，因此需要借助一些运行时魔法。当时主要有两种思路：

1. 借助hook，替换 `dealloc` 方法。但是 `dealloc` 是NSObjec的方法，若要hook该方法，会对所有的cocoa实例产生影响，而我的实际目标只有UITextField，显然这种方式不太妙。而且事实上，ARC下是无法直接hook `dealloc` 方法的（通过运行时可以实现），会产生编译报错：`ARC forbids use of 'dealloc' in a @selector`。因此，这种方案Pass！

2. 借助AssociatedObject。我们知道，ARC下，一个实例释放后，同时会解除对其实例变量的强引用。这样一来，我就可以通过AssociatedObject动态给UITextField实例绑定一个自定义的辅助对象，并且监听该辅助对象的 `dealloc` 方法调用。因为按照我的理论，当UITextField实例被释放后，辅助对象唯一的强引用被解除，必然将触发 `dealloc` 的调用。这样一来，我就能够间接监听宿主UITextField实例的释放了。

   然而，想法很美好，现实略骨感。我确实能够监听UITextField实例的释放了，然而似乎忘记了我真正的意图——真正要做的是在UITextField实例被释放之前拿到实例本身，调用方法移除对应的通知： 

   ```objc
   [[NSNotificationCenter defaultCenter] removeObserver:[self manager] name:UITextFieldTextDidChangeNotification object:target]
   ```

   我忽略了一个很重要的问题：当实例变量的 `dealloc` 方法调用的时候，其宿主对象已经被释放了，也就是说在实例变量的 `dealloc` 方法中已经拿不到宿主对象了。因此我还是拿不到UITextField实例！！Pass！！

这个问题似乎没有很好的解决方案，最终换了一种思路：不再为每个UITextField实例绑定观察者监听通知，而是注册一个全局的通知：

```objc
[[NSNotificationCenter defaultCenter] addObserver:[self manager] selector:@selector(textfieldDidChangedTextNotification:) name:UITextFieldTextDidChangeNotification object:nil];
```

在监听通知的回调方法中判断触发通知的UITextField实例是否是需要处理的实例，仅在命中的时候进行逻辑处理。

```objc
- (void)textfieldDidChangedTextNotification:(NSNotification *)notification
{
    UITextField *textField = (UITextField *)notification.object;
    if ([_targetTable containsObject:textField]) {
        [textField.operations enumerateObjectsUsingBlock:^(LTVTFOperation * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            obj.action();
        }];
    }
}
```

这种方案虽然有个显而易见的缺陷（会监听所有的UITextField实例），但是个人认为比hook dealloc方法要好，首先受众对象只限定在UITextField，其次多余的逻辑处理较为简单，不会产生较大的性能影响。另外，想了想IQKeyBoard也是全局监听UITextField，问题应该不大吧~ 如果你有更好的方案，欢迎来撩~

虽然眼前问题是解决了，但是此时内心已经暗戳戳萌芽了一个更大的困惑：**dealloc方法到底干了啥？**

## 进入正题

首先，我们都知道当一个对象的引用计数为0的时候，就会调用 `dealloc` 方法进行析构。在MRC时代，内存需要手动管理，解除对象引用需要手动调 `release` ，通常也会这样写 `dealloc` ：

```objc
- (void)dealloc {
    self.instance1 = nil;
    self.instance2 = nil;
    // ...
    // 非cocoa对象内存的释放，如CF对象
    // ...
    [super dealloc];
}
```

+ 移除对相关实例的引用
+ 非cocoa对象的释放
+ 调用 `[super dealloc]` 来释放父类中的对象

而到了ARC时代，`dealloc` 基本变成了这样：

```objc
- (void)dealloc {
    // ...
    // 非cocoa对象内存的释放，如CF对象
    // ...
}
```

除了非cocoa对象还需要手动释放，实例变量释放和 `[super dealloc]` 都不见了身影。这也就是我们要探索的两个ARC下 `dealloc` 的问题：

1. 对象的实例变量如何释放？
2. 父类中的对象析构如何实现？

##初探dealloc的调用

当探索一个方法无从下手时，最好的方法就是查看调用栈，说不定就能从中窥见一二。测试代码如下：

```objc
// 父类Animal
@interface Animal : NSObject
@property (nonatomic, strong) Skill *skill;
@end
@implementation Animal
- (void)dealloc{
    NSLog(@"%s",__func__);
}
@end

// 子类Dog
@interface Dog : Animal
@end
@implementation Dog
- (void)dealloc{
    NSLog(@"%s",__func__);
}
@end

// 实例变量类型Skill
@interface Skill : NSObject
@end
@implementation Skill
- (void)dealloc{
    NSLog(@"%s",__func__);
}
@end
    
int main(int argc, const char * argv[]) {
    Dog *dog = [Dog new];
    dog.skill = [Skill new];
    return 0;
}
```

运行工程，由于dog实例很快过了作用域，因此会触发实例的释放。打印的日志如下：

```objc
2018-11-01 17:09:43.986073+0800 DeallocExporeDemo[5674:1072191] -[Dog dealloc]
2018-11-01 17:09:43.986302+0800 DeallocExporeDemo[5674:1072191] -[Animal dealloc]
2018-11-01 17:09:45.751398+0800 DeallocExporeDemo[5674:1072191] -[Skill dealloc]
```

可见虽然dealloc方法中尽管没调用 `[super dealloc]` ，也没有手动释放对实例变量skill的引用，父类Animal的 `dealloc` 和实例变量skill的 `dealloc` 方法最终都调用了。

由于触发对象调用dealloc的直接原因是对象引用计数为0，而实例变量实际上是被 `dog.skill` 这个变量所持有，因此可以通过 **Watchpoint** 来监听skill变量的内存变化。在main函数的 `return 0;` 语句上打个断点，然后通过 `watchpoint set variable dog->_skill` 设置监听：

![image](http://upload-images.jianshu.io/upload_images/1510019-b50deb017521642b.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

继续执行，随后就能监听到skill内存的变化：

![image](http://upload-images.jianshu.io/upload_images/1510019-e8badf56219849a2.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

可见dog的skill实例变量的内存地址从 0x00000001007661b0 变成了 0x0000000000000000，也就是说这个时间节点skill对象被释放了（其实严格来说这么说是不正确的，此时堆上的skill对象并没有被释放，我们监听到的只是栈上的skill变量值被清掉了，因此也就无法再通过变量访问该对象了）。

此时调用栈如下：

![image](http://upload-images.jianshu.io/upload_images/1510019-0c55a056fda29cc0.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

可见子类的 `dealloc` 调用之后，父类的跟着调用。随后通过一系列运行时方法，最终在一个名为 `.cxx_destruct` 的方法中调用了 `objc_storeStrong` 来完成释放工作。另外可以看到这个 `.cxx_destruct` 是Animal的方法，怎么来的呢？运行时都做了些什么事？带着这些疑问继续往下看。

##NSObject的dealloc实现

是时候来看一下runtime中相关的实现了，runtime源码可以在 [Source Browser](https://opensource.apple.com/tarballs/objc4/) 下载。

经过定位和调用追踪，发现经过了如下函数：

```
dealloc -> _objc_rootDealloc -> object_dispose -> objc_destructInstance
```

前面都是些简单的判断和跳转，重要的是 `objc_destructInstance` 函数：

```c++
void *objc_destructInstance(id obj) 
{
    if (obj) {
        // Read all of the flags at once for performance.
        bool cxx = obj->hasCxxDtor();
        bool assoc = obj->hasAssociatedObjects();

        // This order is important.
        if (cxx) object_cxxDestruct(obj);
        if (assoc) _object_remove_assocations(obj);
        obj->clearDeallocating();
    }
    return obj;
}
```

可以看到这个函数主要做了3件事：

+ object_cxxDestruct

  这个函数有点眼熟，跟刚才调用栈中看到的 `.cxx_destruct` 长得很像，猜测实例变量释放以及调用父类的`dealloc`都是在这里面进行的。

+ _object_remove_assocations

  顾名思义，用来释放动态绑定的对象。

+ clearDeallocating

  该函数实现如下：

  ```c++
  inline void objc_object::clearDeallocating()
  {
      if (slowpath(!isa.nonpointer)) {
          // Slow path for raw pointer isa.
          sidetable_clearDeallocating();
      }
      else if (slowpath(isa.weakly_referenced  ||  isa.has_sidetable_rc)) {
          // Slow path for non-pointer isa with weak refs and/or side table data.
          clearDeallocating_slow();
      }
      assert(!sidetable_present());
  }
  
  NEVER_INLINE void objc_object::clearDeallocating_slow()
  {
      assert(isa.nonpointer  &&  (isa.weakly_referenced || isa.has_sidetable_rc));
      SideTable& table = SideTables()[this];
      table.lock();
      if (isa.weakly_referenced) {
          weak_clear_no_lock(&table.weak_table, (id)this);
      }
      if (isa.has_sidetable_rc) {
          table.refcnts.erase(this);
      }
      table.unlock();
  }
  ```

  可以看到做了两件事：

  1. 将对象弱引用表清空，即将弱引用该对象的指针置为nil
  2. 清空引用计数表（当一个对象的引用计数值过大（超过255）时，引用计数会存储在一个叫 `SideTable` 的属性中，此时isa的 `has_sidetable_rc` 值为1）

接下来，要探索的就是 `object_cxxDestruct` 函数了，实现如下：

```c++
void object_cxxDestruct(id obj)
{
    if (!obj) return;
    if (obj->isTaggedPointer()) return;
    object_cxxDestructFromClass(obj, obj->ISA());
}
```

`object_cxxDestructFromClass` 这个函数之前在调用栈里看到过，再往里看：

```c++
static void object_cxxDestructFromClass(id obj, Class cls)
{
    void (*dtor)(id);

    // Call cls's dtor first, then superclasses's dtors.

    for ( ; cls; cls = cls->superclass) {
        if (!cls->hasCxxDtor()) return; 
        dtor = (void(*)(id))
            lookupMethodInClassAndLoadCache(cls, SEL_cxx_destruct);
        if (dtor != (void(*)(id))_objc_msgForward_impcache) {
            if (PrintCxxCtors) {
                _objc_inform("CXX: calling C++ destructors for class %s", 
                             cls->nameForLogging());
            }
            (*dtor)(obj);
        }
    }
}
```

通过分析，最终 `(*dtor)(obj);` 执行的其实是 `SEL_cxx_destruct` 这个SEL标记的函数，通过全局搜索 `SEL_cxx_destruct` ，不难发现该SEL对应的正是之前看到的 .cxx_destruct 方法，也就是说，最终是 `.cxx_destruct` 方法被调用了。

## 探索.cxx_destruct方法

之前在调用栈中看到该方法是Animal类中的方法，而我们并没有申明该方法，也没有动态插入该方法的相关代码。并且这个方法是析构对象相关的，具有很强的通用性，那么猜测是在编译的时候由前端编译器（clang）自动插入的。

我们可以通过 [DLIntrospection](https://github.com/delebedev/DLIntrospection) 来查看Animal类中是否真的存在这个方法，该工具可以方便在lldb中打印类中所有的实例变量、方法、对象遵守的协议等信息，是一个NSObject的分类文件，直接拉到工程中即可使用。

在main函数中打个断点，然后在lldb中打印Animal类的实例方法：

	po [[Animal class] instanceMethods]

![image](http://upload-images.jianshu.io/upload_images/1510019-dca33262fc9d1124.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

可以看到确实是有 `.css_destruct` 这个方法。随后，通过查阅相关资料，验证了我之前的猜测。在clang源码里，找到了相关的代码：

```c++
void CodeGenModule::EmitObjCIvarInitializations(ObjCImplementationDecl *D) {
    IdentifierInfo *II = &getContext().Idents.get(".cxx_destruct");
    Selector cxxSelector = getContext().Selectors.getSelector(0, &II);
    ObjCMethodDecl *DTORMethod =
    ObjCMethodDecl::Create(getContext(), D->getLocation(), D->getLocation(),
                          cxxSelector, getContext().VoidTy, nullptr, D,
                          /isInstance=/true, /isVariadic=/false,
                       /isPropertyAccessor=/true, /isImplicitlyDeclared=/true,
                          /isDefined=/false, ObjCMethodDecl::Required);
    D->addInstanceMethod(DTORMethod);
    CodeGenFunction(*this).GenerateObjCCtorDtorMethod(D, DTORMethod, false);
}
```

在clang的[CodeGenModule模块](https://clang.llvm.org/doxygen/CodeGenModule_8cpp_source.html)中看到了上面代码（只摘录了相关代码），经过分析大概是clang通过CodeGen为具体类插入了 `.cxx_destruct` 方法。 `GenerateObjCCtorDtorMethod`  函数实现在 [CGObjC.cpp](https://clang.llvm.org/doxygen/CGObjC_8cpp_source.html) 文件中，其中声明了 `.cxx_destruct` 的具体实现。最终对象释放时，会调用到 `emitCXXDestructMethod` 函数：

```c++
 static void emitCXXDestructMethod(CodeGenFunction &CGF,
                                   ObjCImplementationDecl *impl) {
   CodeGenFunction::RunCleanupsScope scope(CGF);
   llvm::Value *self = CGF.LoadObjCSelf();
   const ObjCInterfaceDecl *iface = impl->getClassInterface();
   for (const ObjCIvarDecl *ivar = iface->all_declared_ivar_begin();
        ivar; ivar = ivar->getNextIvar()) {
     QualType type = ivar->getType();
     // Check whether the ivar is a destructible type.
     QualType::DestructionKind dtorKind = type.isDestructedType();
     if (!dtorKind) continue;
     CodeGenFunction::Destroyer *destroyer = nullptr;
     // Use a call to objc_storeStrong to destroy strong ivars, for the
     // general benefit of the tools.
     if (dtorKind == QualType::DK_objc_strong_lifetime) {
       destroyer = destroyARCStrongWithStore;
     // Otherwise use the default for the destruction kind.
     } else {
       destroyer = CGF.getDestroyer(dtorKind);
     }
     CleanupKind cleanupKind = CGF.getCleanupKind(dtorKind);
     CGF.EHStack.pushCleanup<DestroyIvar>(cleanupKind, self, ivar, destroyer,
                                          cleanupKind & EHCleanup);
   }
   assert(scope.requiresCleanups() && "nothing to do in .cxx_destruct?");
 }
```

经过分析，该函数做的事情是：遍历所有实例变量，调用 `destroyARCStrongWithStore` 。而 `destroyARCStrongWithStore` 最终调用的就是之前调用栈中看到的 `objc_storeStrong` 函数，可以在runtime源码中看到其实现：

```c++
void objc_storeStrong(id *location, id obj)
{
    id prev = *location;
    if (obj == prev) {
        return;
    }
    objc_retain(obj);
    *location = obj;
    objc_release(prev);
}
```

该函数作用是将obj对象赋值给location变量，因此只要执行 `objc_storeStrong(&ivar, null)` 就能释放ivar实例变量。至此，`dealloc` 方法如何释放实例变量这个问题就探索完毕了。

至于如何调用 `[super dealloc]` ，在clang源码中同样能找到猫腻。同样在 [CGObjC.cpp](https://clang.llvm.org/doxygen/CGObjC_8cpp_source.html) 文件中，存在如下代码：

```c++
 void CodeGenFunction::StartObjCMethod(const ObjCMethodDecl *OMD,
                                       const ObjCContainerDecl *CD) {
   // In ARC, certain methods get an extra cleanup.
   if (CGM.getLangOpts().ObjCAutoRefCount &&
       OMD->isInstanceMethod() &&
       OMD->getSelector().isUnarySelector()) {
     const IdentifierInfo *ident =
       OMD->getSelector().getIdentifierInfoForSlot(0);
     if (ident->isStr("dealloc"))
       EHStack.pushCleanup<FinishARCDealloc>(getARCCleanupKind());
   }
 }
```

分析可知在 `dealloc` 方法中插入了代码，相关代码在 `FinishARCDealloc` 结构中定义：

```c++
 namespace {
 struct FinishARCDealloc final : EHScopeStack::Cleanup {
   void Emit(CodeGenFunction &CGF, Flags flags) override {
     const ObjCMethodDecl *method = cast<ObjCMethodDecl>(CGF.CurCodeDecl);
 
     const ObjCImplDecl *impl = cast<ObjCImplDecl>(method->getDeclContext());
     const ObjCInterfaceDecl *iface = impl->getClassInterface();
     if (!iface->getSuperClass()) return;
 
     bool isCategory = isa<ObjCCategoryImplDecl>(impl);
 
     // Call [super dealloc] if we have a superclass.
     llvm::Value *self = CGF.LoadObjCSelf();
 
     CallArgList args;
     CGF.CGM.getObjCRuntime().GenerateMessageSendSuper(CGF, ReturnValueSlot(),
                                                       CGF.getContext().VoidTy,
                                                       method->getSelector(),
                                                       iface,
                                                       isCategory,
                                                       self,
                                                       /*is class msg*/ false,
                                                       args,
                                                       method);
   }
 };
 }
```

大致意思就是调用父类的 `dealloc` 方法。

## 拨云见日

通过上面的探索分析，基本搞清楚了ARC下 `dealloc` 是怎么实现自动释放实例变量以及调用父类 `dealloc` 方法的。这一切要归功于clang以及运行时库，在前端编译过程中CodeGen插入了相关代码，结合运行时完成释放动作。对于ARC下 `dealloc` 实现原理的摸索就此告终。