--[[
    Copyright(c) 2019 CppCXY
    Author: CppCXY
    Github: https://github.com/CppCXY
]]

--debug等级
--debug=1代表取消一切特别的操作
--debug=2以上代表开启类型检查,函数参数检查
local LUA_CLASS_DEBUG=1

--如果有宿主语言,并且企图继承宿主类型,请修改以下函数,但是要兼容lua原生类型
local setmeta
----[[
setmeta=function(t, index)
    if type(t) == "userdata" then
        local peer = tolua.getpeer(t)
        if not peer then
            peer = {}
            tolua.setpeer(t, peer)
        end
        setmeta(peer, index)
    else
        setmetatable(t,index)
    end
end
--]]
--如果有宿主语言,并且企图继承宿主类型,请修改以下函数,继承自宿主的类型需要通过这个函数进行创建
--虽然支持多重继承,但是仅仅是对luaClass 有效,对宿主类型无法找到合理的办法去解决.所以这里采用super,super为第一个继承的类型
--__host字段用于判断是否是来自宿主类型
local createFromSuper=function (cls,...) 

    local instance
    if (cls.super and  cls.super['.isclass']) then
        local f=bind(cls.super.create,cls.super,unpack(cls.__argvsIn))
        instance =f(...)--cls.super:create()
        instance._host=true
    else
        instance={}
        instance._host=false
    end
    return instance
end
local classRawSet=function (classObject,key,value)
    return (classObject._host or type(classObject)=="userdata")
    and 
    rawset(tolua.getpeer(classObject),key,value)
    or 
    rawset(classObject,key,value)
end

local classRawGet=function (classObject,key)
    return (classObject._host or type(classObject)=="userdata")
    and 
    rawget(tolua.getpeer(classObject),key)
    or 
    rawget(classObject,key) 
end

local isHost=function(obj)
    return (type(obj)=="table" or type(obj)=="userdata")
    and( obj._host or obj[".isclass"])
end
--以下尽量不做改动
rawset(_G,"isHost",isHost)
rawset(_G,"LUA_CLASS_DEBUG",LUA_CLASS_DEBUG)
rawset(_G,"setmeta",setmeta)
rawset(_G,"createFromSuper",createFromSuper)
rawset(_G,"classRawSet",classRawSet)
rawset(_G,"classRawGet",classRawGet)

