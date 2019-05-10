--[[
    Copyright(c) 2019 CppCXY
    Author: CppCXY
    Github: https://github.com/CppCXY
    一些辅助的对象
]]

require "luaClass.luaClassConfig"
_ENV=namespace "luaClass"

local unpack=unpack or table.unpack

LuaClass={}
LuaClass.__index=LuaClass
function LuaClass:new(luaClassObject)
    local obj={}
    obj.object=luaClassObject
    setmetatable(obj,self)
    return obj
end
function LuaClass:extend(luaClassObject)
    local cls=self.object
    local supers=cls.__supers
    --如果这是类型体系自己的类,通过类名访问
    if luaClassObject.__cname then
        supers[luaClassObject.__cname]=luaClassObject
    else--如果来自于宿主,则使用整数索引访问
        supers[#supers+1]=luaClassObject
    end
    if not classRawGet(cls,"super") then
        classRawSet(cls,"super",luaClassObject)
        classRawSet(cls,"__super",function(self,...)
            local instance=self.super:create(...)
            tolua.setpeer(instance,self)
            classRawSet(cls,"__currentInstance",instance)
            return instance
        end)
    end
    


    --继承declTable
    if luaClassObject.__declTable and cls.__debug then
        for k,v in pairs(luaClassObject.__declTable) do
            cls.__declTable[k]=v
        end
    end
    --继承方法
    for k,v in pairs(luaClassObject) do
        if not k:match("^__.*") and k~="new" and k~="create" then
            if type(v)=="function" then
                classRawSet(cls,k,v)
            end
        end
    end
    --依然是继承方法
    if luaClassObject.__methodTable and cls.__debug then
        for k,v in pairs(luaClassObject.__methodTable) do
            cls.__methodTable[k]=v
        end
    end
    return self
end

function LuaClass:interface(interfaceObject)
    return self:extend(interfaceObject)
end

---@param component moduleFunction
function LuaClass:load(component,...)
	local cls=self.object
    component(cls,...)
    return self
end

function LuaClass:preCreate(...)
    local cls=self.object
    classRawSet(cls,"__argvsIn",{...})
    return self
end


LuaObject={}
LuaObject.__new=function (self,ctype,classObject)
    local o={}
    o.__classObject=classObject
    o.__type=ctype
    setmetatable(o,self)
    return o
end
LuaObject.__copyAndAlter=function (self,ctype)
    local newObject=LuaObject:__new(self.__type==Ty and ctype or self.__type,nil)
    newObject.__name=self.__name
    return newObject
end
LuaObject.__index=function (self,k)
    if rawget(LuaObject,k) then 
        return rawget(LuaObject,k) 
    end
    local cls=self.__classObject.object
    local decl=cls.__declTable
    decl[k]=self
    self.__name=k
    return function ()
        local classObject=self.__classObject
        self.__classObject=nil
        return classObject
    end
end

LuaObject.__assign=function (self,instance,key,value)
    if  is(value,self.__type) then
        instance._defineTable[key]=value
    else
        print("warning : attempt assign to "..instance.__cname.."."..key.." type not match")
        classRawSet(instance,key,value)
    end
end

emptyObject={}
emptyObject.__index=function(self)
    return  function ()
       return self.luaClassObject
    end
end
local emptyFunction=function(luaClassObject)
    local t={luaClassObject=luaClassObject}
    setmetatable(t,emptyObject)  
    return t
end

function LuaClass:declObject(ctype)
    return 
    (self.object.__debug)
    and
    LuaObject:__new(ctype,self)
    or 
    emptyFunction(self)
end


LuaMethod={}
LuaMethod.__call=function (self,method,...)
    local params={...}
    local types=self.__types
    for index,param in ipairs(params) do
        if not is(param,types[index]) then
            print("warning: method "..self.__name.." 's param "..(index-1).." can not convent to "..types[index].__cname)
        end
    end
    local results
    if method then
        results={method(...)}
    else
        print("error :attemp to call not define method "..self.__name)
        return 
    end
    local returnTypes=self.__returnTypes
    for index,result in ipairs(results) do
        if not is(result,returnTypes[index]) then
            print("warning: method"..self.__name.."'s return result "..index.."can not convent to "..returnTypes[index].__cname)
        end
    end
    return unpack(results)
end

LuaMethod.__index=function (self,name)
    if rawget(LuaMethod,name) then
        return rawget(LuaMethod,name)
    end
    local decl=self.__classObject.object.__declTable
    decl[name]=self
    self.__name=name
    return function (self,...)
        self.__types={any,...}
        local classObject=self.__classObject
        self.__classObject=nil
        return classObject
    end
end
LuaMethod.__new=function (self,returnTypes,classObject)
    local o={}
    o.__returnTypes=returnTypes
    o.__classObject=classObject
    setmetatable(o,self)
    return o
end
LuaMethod.__copyAndAlter=function (self,ctype)
    
    local returnTypes={}
    local types={}
    for k,ty in pairs(self.__returnTypes) do
        returnTypes[k]=(ty==Ty) and ctype or ty
    end
    for k,ty in pairs(self.__types) do
        types[k]=(ty==Ty) and ctype or ty
    end
    local newMethod=LuaMethod:__new(returnTypes,nil)
    newMethod.__types=types
    newMethod.__name=self.__name
    return newMethod
end
LuaMethod.__assign=function (self,instance,key,value)
    if  type(value)=="function" or(type(value)=="table" and value.__call~=nil ) then
        instance.__methodTable[key]=value
    else
        classRawSet(instance,key,value)
        print("warning : attempt assign to "..instance.__cname.."."..key.." ,type not match")
    end
end

function LuaClass:declMethod(...)
    local returnTypes={...}
    return 
    (self.object.__debug)
    and
    LuaMethod:__new(returnTypes,self)
    or 
    emptyFunction(self)
end

