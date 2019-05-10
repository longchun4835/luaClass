--[[
    Copyright(c) 2019 CppCXY
    Author: CppCXY
    Github: https://github.com/CppCXY
]]

_ENV=namespace "luaClass"
--debug等级
--debug=1代表取消一切特别的操作
--debug=2以上代表开启类型检查,函数参数检查
LUA_CLASS_DEBUG=1

--如果有宿主语言,并且企图继承宿主类型,请修改以下函数,但是要兼容lua原生类
----[[这个函数似乎没用了
function setmeta(t, index)
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

function classRawSet (classObject,key,value)
    return (classObject._host or type(classObject)=="userdata")
    and 
    rawset(tolua.getpeer(classObject),key,value)
    or 
    rawset(classObject,key,value)
end

function classRawGet(classObject,key)
    return (classObject._host or type(classObject)=="userdata")
    and 
    rawget(tolua.getpeer(classObject),key)
    or 
    rawget(classObject,key) 
end

function isHost(obj)
    return (type(obj)=="table" or type(obj)=="userdata")
    and    ( obj._host or obj[".isclass"])
end


