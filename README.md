# lua类型体系 
---
## 支持内容
* lua面向对象体系
    * 命名空间
        * 声明命名空间
        * using 命名空间
    * C++ like oop
        * 单继承
        * 实例继承
        * 多重继承
        * 多态
    * ~~类型检查~~
* lua对象序列化与反序列化
    * serilize
    * unSerilize
* lua基础数据结构
    * array
    * queue
    * map
    * stack
    * mat
    * graph
    * set

---
### 面向对象体系

1. 声明命名空间
    ```lua
    _ENV=namespace "test.a.b.c"
    ```
    此时test会存在，他的子空间 a 也会存在，a的子空间b也会存在，b的c子空间也会存在，之后当前环境变更为c子空间

    此后所有的变量都会存在于这个命名空间中
    例如
    ```lua
    _ENV=namespace "test"
    ffff=4444
    print(ffff)
    --也可以使用完全限定名
    print(test.ffff)
    
    ```
    在另一个文件中，就不能直接使用ffff，因为他不在你的命名空间中。
2.  引入命名空间
    ```lua
    --在另一个文件,并假设require 了上一个文件
    _ENV=namespace "test2"
    print(ffff) --nil
    using_namespace "test"
    print(ffff) --4444
    ```
    并不建议对全局命名空间使用using,
    因为这会让所有命名空间可见.

    值得注意的是,一些开发中会控制全局变量,使用命名空间体系和这种体系唯一的冲突是,在全局变量上.所以不要使用
    ```lua
    _ENV=namespace ()
    ```
3.  看到_ENV你可能会觉得这只能运行在LUA5.2以上的版本里面，实际上这个体系是兼容lua5.1,5.2,5.3的，具体怎么做的去看源码。
4.  声明一个类
    ```lua
    require "luaClass.init"

    _ENV=namespace "battle"
    using_namespace "luaClass"

    class "Role"
    ```
    这个Role会存在于当前环境battle 中，这里引入了命名空间luaClass，因为class 存在于命名空间luaClass中，这个命名空间中有很多函数，主要会被使用到的是
    class,is,inheritInstance，serilize，unSerilize
    * class 声明一个类他有三个参数,通常只需要关心第一个，类的名字。
    * is 他有两个参数，用于判断左边的对象是否是右边的类型。
    * inheritInstance 这个函数是实例继承函数，可以使当前对象继承一个类型实例，而不是一个类。
    * serilize 序列化函数
    * unSerilize 反序列化函数
    以上函数除了class 均集成在类型里面
    可以这样用比如
    ```lua
    role:is(Role)
    ```
3.  构造类
    类型体系支持多种构造模式
    ```lua
    ---假设Role在test命名空间中
    local r1=test.Role()--C++风格构造
    local r2=test.Role:new() --lua风格构造
    local r3=test.Role:create()--cocos静态函数构造
    ```
    以上构造方法是完全等价的
4.  构造函数
    * 与传统的lua oop不同我,这里采用的构造函数与类型同名。
    ```lua
    local Role=test.Role
    function Role:Role(id,desc)
        self._playerID=id
        self._desc=desc
    end
    ```
5.  定义其他函数
    有了构造函数的例子其他的其实比较简单,但是要注意的是所有以双下划线开头的字段均无法参与后续操作(比如继承,序列化),这被排除在外主要是因为双下划线开头有很多元方法,这个通常不需要被继承,另一方面序列化也排除双下划线开头.
6.  继承
    * 单继承
    格式如下
    ```lua
    _ENV=namespace "test"

    using_namespace "luaClass"

    class("BattleRole")
    :extend(test.Role)
    ...
    --继承之后需要显式调用基类构造函数
    function test.BattleRole:BattleRole()
        --很多传统的lua oop并没有提供对基类构造函数的主动使用,这里提供主动使用,是想让基类构造变得更加精确
        self:Role(1,"this is a describe")
    end
    ```
    * 多重继承
    格式如下
    ```lua
    _ENV=namespace "test"

    using_namespace "luaClass"
    
    class("BattleRole")
    :extend(test.Role)
    :extend(test.HasTrigger)

    function test.People:People()
        self:Role(1,"12131")
        self:HasTrigger(2,"123456")
    end
    ```
    这里可以看出采用和类型同名构造函数的意义,多重继承的情况下,非常简单区分不同构造函数.
    虽然BattleRole本身也继承自Role,但是这并没有什么矛盾,后继承的类型会覆盖先继承的类型的同名字段.
    在实现上,继承就是把基类的所有函数都复制到这个类上来,所以后复制的会覆盖前面同名的.
    但是另一方面为了更加的严谨,每一个class依然会设置一个元表,通过__index去访问在class上访问不到的字段(我也不知道这种情况会在何时发生,因为所有方法都是复制过来的),在这种情况下,访问的次序是相反的,采用从左到右的深度优先搜索.
    * 宿主类型继承
    这种情况比较复杂,因为不同的绑定方式,可能有不同的结果.作者本人的宿主环境是cocos2dx
    所以我默认提供的方式可能只对tolua++有效,
    所有与宿主相关的设计均写在classConfig.lua里面,理论上unity修改修改这里,也能用来继承宿主类型.
    针对cocos2dx的类型采用如下继承方法
    ```lua
    _ENV=namespace "test"
    using_namespace "luaClass"
    class("View")
    :extend(cc.Node)
    ```
    实际上和lua类没有任何区别,唯一有区别的是，只能支持单继承。并且基类的构造格式不同
    ```lua
    function View:View()
        --可以给__super传入参数作为create 的构造参数
        self=self:__super()
    end
    ```
    * 多态
    当然每一个函数都是虚函数了,只需要覆盖基类同名函数就可以了.

## 序列化
序列化库也是我自己写的,与之前的类型体系是低耦合的.
如果你不喜欢我的类型体系又看上了我的序列化方案,可以去Serilize.lua 看看说明,这里不表.

* 如何使用序列化
    每一个类都带一个方法serilize,使用他,就可以从这个对象开始序列化,返回一个字符串.
    在测试用例里面有例子.
    一般这样用
    ```lua
    role:serilize()
    ```
* 如何反序列化
    反序列化函数是unSerilize()
    他接受一个字符串,并返回反序列化后的对象.
    ```lua
    unSerilize(str)
    ```
## 数据结构
    我写了很多数据结构，每一个都要展示就太麻烦了。自己去看测试用例。container用例应该足够使用了
    这里就介绍一下他们的名字
    * array 数组
    * stack 栈
    * queue 队列，实现上是循环队列
    * set 集合
    * map 字典
    * mat 矩阵，这个做的很一般
    * graph 图，只有两个算法广度优先和深度优先。




