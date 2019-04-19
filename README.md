# lua类型体系 
---
## 支持内容
* lua面向对象体系
    * 命名空间
    * C++ like oop
        * 多重继承
        * 多态
    * 类型检查
* lua对象序列化与反序列化
    * serilize
        * 支持key 为 number,string,table类型
        * 避免了环的出现
    * unSerilize
* lua基础数据结构与简单模板类型
    * array
    * queue
    * map
    * stack
    * luaTemplate(鸡肋,不做介绍)
* lua组件式(测试)
    * 不知道怎么说

---
### 面向对象体系

1. 声明一个类
    * 直接声明
    ```lua
    luaClass("Role")
    ```
    这个类就存在于_G中,注意不要使用luaClass的返回值,他返回值是LuaClass对象.
    * 命名空间
    ```lua
    namespace("test.a.b.c")
    ```
    此时test.a.b.c就会存在, 命名空间的声明不用一个一个声明,也不需要任何提前的声明,遇到不存在的空间会自动产生.
    * 命名空间和luaClass结合
    ```lua
    namespace("test.a")
    :class("Role")

    local Role=test.a.Role
    ```
    这样声明的类存在于test.a命名空间中
    * 所有的处理是绕过元表的,无论是否管控了对_G的赋值.
2.  声明类的字段
    通过declObject声明一个成员
    通过declMethod声明一个函数
    ```lua
    namespace("test")
    :class("Role")
    :declObject(number):_playerID()
    :declObject(string):_desc()
    :declMethod(void):speak()
    :declMethod(string):getDesc()

    ```
    通过这种声明,可以在运行时检查类型是否匹配,是否使用了未定义字段,是否使用了未声明字段.
    例如在上面的基础上
    ```lua
    local t=test.Role()
    print(t._playerID)
    print(t:speak())    
    ```
    会得到下面的输出
    ```
    warning:attempt to access undefine but decl field _playerID
    nil
    warning:attempt to access undefine but decl field speak
    ```
    除了以上输出因为speak本身未定义,还会引发error抛出异常
3.  构造类
    类型体系支持多种构造模式
    ```lua
    local r1=test.Role()--C++风格构造
    local r2=test.Role:new() --lua风格构造
    local r3=test.Role:create()--cocos静态函数构造
    ```
    以上构造方法是完全等价的
4.  构造函数
    与传统的lua oop不同我,这里采用的构造函数与类型同名在上面的基础上
    ```lua
    local Role=test.Role
    function Role:Role(id,desc)
        self._playerID=id
        self._desc=desc
    end
    ```
    值得注意的是我在前面的声明中并没有包含构造函数声明,因为在实现上构造函数这一块无法控制(虽然通过调整一些顺序可以控制,但是我觉得没有必要),再加上构造函数主要初始化前面声明的字段或者说成员,字段已经被声明了,参数类型可以在赋值给自己字段的时候被检测.
5.  定义其他函数
    有了构造函数的例子其他的其实比较简单,但是要注意的是所有以双下划线开头的字段均无法参与后续操作(比如继承,序列化),这被排除在外主要是因为双下划线开头有很多元方法,这个通常不需要被继承,另一方面序列化也排除双下划线开头.
6.  继承
    有些说法是如果oop不支持继承,那么他只是一个语法糖而已,虽然我并不喜欢这种说法,但是我觉得继承还是很有用的.
    * 单继承
    格式如下
    ```lua
    namespace("test")
    :class("BattleRole")
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
    namespace("test")
    :class("People")
    :extend(test.Role)
    :extend(test.BattleRole)

    function test.People:People()
        self:Role(1,"12131")
        self:BattleRole(2,"123456")
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
    namesapce("test")
    :class("View")
    :extend(cc.Node)
    ```
    实际上和lua类没有任何区别,唯一有区别的是,不能显式使用宿主的创建函数.
    默认情况下,这样的类型创建,会首先执行cc.Node:create(),
    当然了,cocos2dx不是所有类型都支持无参的构造方式,比如cc.TableView
    这里提供新函数preCreate,并且使用占位符
    ```lua
    namespace("test")
    :class("TableView")
    :extend(cc.TableView)
    :preCreate(placeholder._1)

    function test.TableView:TableView(size)
    --会把size自动传递给cc.TableView的create参数,关于占位符如何使用,就是跟stl bind 差不多,这部分内容来自网络,我做了约等于没有的修改.
    end
    ```
    并不支持对宿主类型的多重继承
    * 多态
    当然每一个函数都是虚函数了,只需要覆盖基类同名函数就可以了.
7.  性能
    这么厚的封装性能当然是非常差的啊,但是看官你不要慌,性能当然是非常需要考虑的问题,这就涉及到了luaClass第二个参数了,
    luaClass有四个参数,后面两个是给命名空间用的,一般不主动使用,第二个参数叫debug,传入true则开启一切厚厚的封装,如果为false,则去掉一切多余的东西,比如类型信息,这种本身lua就没有的东西,比如赋值和使用未定义值的控制,这些统统去掉.
    这样剩下来的东西性能基本就是lua oop的最高性能了
8.  哪些东西可以不用
    当然能用的尽量用啊,我其实也不喜欢做类型声明,如果你觉得麻烦,可以关闭类型检查,然后不写类型声明,实际上除了第二个参数
    还有变量 LUA_CLASS_DEBUG,这是一个全局变量
    其值为2以上时,开始未显式指定的类的检查.值为1时,关闭所有未显式指定的类的检查.

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
    这是一个全局的函数
    虽然每个类都带了这么一个函数,但是请使用如下方式
    ```lua
    local r=role.unSerilize(str)
    ```
## 数据结构
数据结构都是泛型结构
创建方式如下
```lua
local arr=array(number)()
local s=set(string)()
local m=map(string)()
local q=queue(number)(20)
```
array 的参数是一个table,
set也是
map也是
stack也是
queue不是,他采用循环队列的设计,传统的lua队列设计方案,会让key不断增大,这会有很多隐患,比如在足够多次push之后数据会溢出.
所以queue的参数是最大队列容量
可能你们会发现,map按道理应该有两个模板参数,实际上只有一个,因为设计多个模板参数会增加复杂性,另一方面...好吧其实就是我觉得这个设计很鸡肋,就没有继续设计了.

## 组件式设计
其实这里大有可谈,但是我不想谈了,就简单介绍,
支持通过load 去加载一个函数对象,这个函数对象会对class进行很多设置,比如增加单例函数,这样就不需要反复复制同样的代码.
自带的组件里面还有一个与cocos2dx相关的CSS风格创建函数,但是我不想举例了.自己去看吧.


