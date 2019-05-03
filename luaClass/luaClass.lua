--[[
    Copyright(c) 2019 CppCXY
    Author: CppCXY
    Github: https://github.com/CppCXY
	如果觉得我的作品不错,可以去github给我的项目打星星.
]]
local classObjectHelper=require("luaClass.classObjectHelper")
local setmeta=setmeta
local LuaClass=classObjectHelper.LuaClass
local Serilize=require("luaClass.Serilize")
local split=require("luaClass.classFunctionHelper").split
---@param nsName string
local function namespace(nsName)

    local names=split(nsName,".")
    local index=1
    local lastNs=_G
    while(names[index]~=nil) do
        local name=names[index]
        if rawget(lastNs,name)==nil then
            local ns={}
            rawset(lastNs,name,ns)
            lastNs=ns
        else
            lastNs=rawget(lastNs,name)
        end
        index=index+1
    end

    return {
        class=function (self,className,debug)
            return luaClass(className,debug,lastNs,nsName)
        end,
        template=function (self,className,debug)
            return luaTemplate(className,debug,lastNs,nsName)
        end
    }
end
rawset(_G,"namespace",namespace)

local function is(self,luaClassObject)
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
rawset(_G,"is",is)
---@param className string@类型名称
---@param debug bool @是否参与debug,默认值是LUA_CLASS_DEBUG
---@param ns table @命名空间,默认为_G
---@return LuaClass
local function luaClass(className,debug,ns,nsName)
    ns=ns or _G
    local cls = {__cname = className}
    rawset(ns,className,cls)
    if debug~=nil then
        cls.__debug=debug
    else
        cls.__debug=(LUA_CLASS_DEBUG>=2)
    end
    --这样写会有问题
    --cls.__debug=debug~=nil and debug or 
    Serilize(cls)
    cls.__isClass=true
    cls.__supers={}
    cls.__argvsIn={}
    cls.__nsName=nsName or "_G"
    if cls.__debug then
        cls.__declTable={}
        cls.__methodTable={}
    end
    cls[className] = function() end
    cls.is=is
    
    --lua风格对象创建
    cls.new = function(self,...)
        local instance= createFromSuper(cls,...) 
        instance.__class = cls
        --针对序列化规则,双下划线不参与序列化,所以此处用单下划线
        instance._defineTable={}
        setmeta(instance, cls)
        instance[className](instance , ...)
        return instance
    end
    --兼容cocos 类型创建
    cls.create = function(self, ...)
        return cls.new(self,...)
    end

    local metaTable={}
    --C++, C# XLUA风格创建体系
    --不直接用new是因为兼容cocos基类
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

rawset(_G,"luaClass",luaClass)


local function luaInterface(interfaceName)
    return luaClass(interfaceName)
end

rawset(_G,"luaInterface",luaInterface)

local function luaComponent(componentName,componentFunction)
    rawset(_G,componentName,componentFunction)
end

rawset(_G,"luaComponent",luaComponent)

--这些是标识符不可用作类型创建
rawset(_G,"number",{__cname="number",__nsName="_G"})
rawset(_G,"void",{__cname="nil",__nsName="_G"})
rawset(_G,"any",{__cname="any",__nsName="_G"})
rawset(_G,"bool",{__cname="boolean",__nsName="_G"})
rawset(_G,"boolean",{__cname="boolean",__nsName="_G"})
rawset(_G,"func",{__cname="function",__nsName="_G"})
string.__cname="string"
string.__nsName="_G"
table.__cname="table"
table.__nsName="_G"
io.__cname="io"
io.__nsName="_G"
--只是保持有一个返回值的风格,实际上通常并不需要利用返回值
return {
    luaClass=luaClass,
    luaInterface=luaInterface,
    luaComponent=luaComponent,
}