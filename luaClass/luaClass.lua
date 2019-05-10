--[[
    Copyright(c) 2019 CppCXY
    Author: CppCXY
    Github: https://github.com/CppCXY
	如果觉得我的作品不错,可以去github给我的项目打星星.
]]
include "luaClass.luaClassConfig"
include "luaClass.classObjectHelper"
include "luaClass.Serilize"

_ENV=namespace "luaClass"

function is(self,luaClassObject)
    local tname=luaClassObject.__cname
    local _type=type(self)
    if tname=="any" then return true end
    if tname==_type then return true end  
    if _type=="table" then
        return  self[luaClassObject.__cname]~=nil
    end
    if _type=="userdata" then return true end   
    return false
end

function inheritInstance(self,luaClassInstance)
    local metatable=getmetatable(self)
    if metatable then
        local __index=metatable.__index
        if __index then
            if type(__index)=="table" then
                metatable.__index=function (self,key)
                    local result=__index[key] 
                    if result then return result end
                    return luaClassInstance[key]
                end
            elseif type(__index)=="function" then
                metatable.__index=function(self,key)
                    local result=__index(self,key) 
                    if result then return result end
                    return luaClassInstance[key]
                end
            else
                error("error: wrong code __index must be table or function")
            end
        else
            metatable.__index=luaClassInstance
        end
    else
        setmetatable(self,{__index=luaClassInstance})
    end
end

function __getdeclFenv()
    if _VERSION == "Lua 5.1" then
        return getfenv(3)
    else
        return _G.__currentENV
    end
end
---@param className string@类型名称
---@param debug bool @是否参与debug,默认值是LUA_CLASS_DEBUG
---@param ns table @命名空间,默认为_G
---@return LuaClass
function class(className,debug,ns)
    ns=ns or __getdeclFenv()
    local nsName=ns.__nsName
    local cls = {__cname = className}
    rawset(ns,className,cls)
    if debug~=nil then
        cls.__debug=debug
    else
        cls.__debug=(LUA_CLASS_DEBUG>=2)
    end

    initSerilize(cls)
    cls.__isClass=true
    cls.__supers={}
    cls.__argvsIn={}
    cls.__nsName=nsName or "_G"
    if cls.__debug then
        cls.__declTable={}
        cls.__methodTable={}
    end
    cls[className] = function() end
    --参见is函数
    cls.is=is
    --允许继承一个实例，参考inheritInstance函数
    cls.inheritInstance=inheritInstance
    --lua风格对象创建
    cls.new = function(self,...)
        local instance={}
        instance.__class = cls
        --针对序列化规则,双下划线不参与序列化,所以此处用单下划线
        if self.__debug then
            instance._defineTable={}
        end
        setmeta(instance, cls)
        instance[className](instance , ...)
        if cls.__currentInstance then
            instance=cls.__currentInstance
            cls.__currentInstance=nil
        end
        return instance
    end
    --兼容cocos 类型创建
    cls.create = function(self, ...)
        return cls.new(self,...)
    end

    local metaTable={}
    --C++, C# XLUA风格创建体系
    metaTable.__call=cls.create
    if cls.__debug then
        cls.__newindex=function (self,key,value)
            local decl=cls.__declTable
            if decl[key] then
                decl[key]:__assign(self,key,value)
            else
                print("warning : attempt assign not declare variable "..key)
                classRawSet(self,key,value) 
            end
        end

        metaTable.__newindex=function (self,key,value)
            local decl=self.__declTable
            if decl[key] then
                decl[key]:__assign(self,key,value)
            else
                print("warning : attempt assign not declare method "..key)
                classRawSet(self,key,value)
            end
        end

        cls.__index = function (self,k) 
            if cls.__declTable[k] then
                local filed=self._defineTable[k] 
                if filed then
                    return filed
                else
                    local res=cls[k]
                    if res then 
                        return res 
                    else
                        return print("warning:attempt to access undefine but decl field "..k)
                    end
                end
            end
            return cls[k]
        end
        
        metaTable.__index=function(self,k)
            local decl=cls.__declTable[k]
            local method=cls.__methodTable[k]
            if decl and method then
                return function (...)
                    return decl(method,...) 
                end
            end
            for _,super in pairs(cls.__supers) do
                local value=super[k]
                if value then return value end
            end

            return nil
        end
    else
        cls.__index=cls
        if #cls.__supers<=1 then
            metaTable.__index=cls.super
        else
            metaTable.__index=function (self,k)
                for _,super in pairs( cls.__supers) do
                    if super[k] then return super[k] end
                end
            end
        end
    end
    --类型对象的方法创建管理
    setmetatable(cls, metaTable)
    return LuaClass:new(cls)
end

function luaInterface(interfaceName)
    return luaClass(interfaceName)
end

function luaComponent(componentName,componentFunction)
    rawset(_G,componentName,componentFunction)
end

--这些是标识符不可用作类型创建
rawset(_G,"number",{__cname="number",__nsName="_G"})
rawset(_G,"void",{__cname="nil",__nsName="_G"})
rawset(_G,"any",{__cname="any",__nsName="_G"})
---@class bool
rawset(_G,"bool",{__cname="boolean",__nsName="_G"})
rawset(_G,"boolean",{__cname="boolean",__nsName="_G"})
rawset(_G,"func",{__cname="function",__nsName="_G"})
string.__cname="string"
string.__nsName="_G"
table.__cname="table"
table.__nsName="_G"
io.__cname="io"
io.__nsName="_G"

