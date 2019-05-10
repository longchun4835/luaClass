--[[
    Copyright(c) 2019 CppCXY
    Author: CppCXY
    Github: https://github.com/CppCXY
    如果觉得我的作品不错,可以去github给我的项目打星星.
]]

include "luaClass.luaClass"
_ENV=namespace "luaClass"

rawset(_G,"Ty",{__cname="Ty"})
function template(className,debug,ns)
    ns=ns or __getdeclFenv()
    local nsName=ns.__nsName
    local cls = {__cname = className}
    rawset(ns,className,cls)
    if debug~=nil then
        cls.__debug=debug
    else
        cls.__debug=(LUA_CLASS_DEBUG>=2)
    end
    --这样写会有问题
    --cls.__debug=debug~=nil and debug or 
    initSerilize(cls)
    cls.__isClass=true
    cls.__supers={}
    cls.__argvsIn={}
    cls.__nsName=nsName or "_G"
    if cls.__debug then
        cls.__declTable={}
        cls.__methodTable={}
    end
    cls.__lookUp={__nsName=cls.__cname}
    cls[className] = function() end

    local metaTable={}
    --C++, C# XLUA风格创建体系
    --不直接用new是因为兼容cocos基类
    metaTable.__call=function (self,ctype)
        ctype=isHost(ctype) and any or ctype
        if self.__lookUp[ctype.__cname] then
            return self.__lookUp[ctype.__cname]
        end
        local t=self.__cname.."("..ctype.__nsName.."."..ctype.__cname..")"
        class(t,cls.__debug,cls.__lookUp)
        :extend(cls)
        local tCls=cls.__lookUp[t]
        classRawSet(tCls,"__ty",ctype)
        if tCls.__declTable and tCls.__debug then
            local decl=tCls.__declTable
            for k,v in pairs(tCls.__declTable) do
                decl[k]=v:__copyAndAlter(ctype)
            end
        end

        tCls[t]=cls[className] 
        return tCls
    end

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