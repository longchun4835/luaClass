--[[
    Copyright(c) 2019 CppCXY
    Author: CppCXY
	Github: https://github.com/CppCXY
	如果觉得我的作品不错,可以去github给我的项目打星星.
	序列化方案
	针对我自己的编码规则进行特定的序列化和反序列化方式
	默认屏蔽一切双下划线开头的字段
	这部分内容与luaClass没有太多耦合,
	如果想分离出来,需要将require 部分删掉
]]
--这些key并不参与序列化
local disableKey={
	["class"]=true,--实际上我并没有这个字段
	["super"]=true,
}
require "luaClass.luaClassConfig"

local serilizeTable={}
local serilizeClassTable={}
local luaIDQuery={}
local id=0
local getId=function ()
	id=id+1
	return id
end
local reset=function ()
	id=0
	luaIDQuery={}
end

local type=type
local getmetatable=getmetatable
local string_format=string.format
local table_concat=table.concat
local table_insert=table.insert
local getType=function ( value )
	local t=type(value)
	if t=="table" then
		--这种做法并不科学,也并不正确但是性能较好
		--面面俱到总有遗漏,正确约束,更容易实现.
		if value[1] then return "array" end
		if not getmetatable(value) then return "unMetaTable" end
		if value.__isClass then return "class" end
		return "nil"
	elseif t=="string" then
		if value:find("\n") then return "blockString" end
		if disableKey[value] then return "nil" end
        if value:match("^__") then return "nil" end 
        return t       
    elseif t=="number" or t=="boolean" then
		return t
	end
    return "nil"
end

local arraySerilize=function(array)
	local t={}
	for i=1,#array do
		local value=array[i]
		t[i]=serilizeTable[getType(value)](value)
	end
	local str="{"..table_concat(t,",").."}"
	return str
end
serilizeTable["array"]=arraySerilize

local numberSerilize=tostring

serilizeTable["number"]=numberSerilize

local stringSerilize=function ( str )
	return "\""..str.."\""
end
serilizeTable["string"]=stringSerilize
local blockStringSerilize=function ( str )
	return "[["..str.."]]"
end
serilizeTable["blockString"]=blockStringSerilize
local booleanSerilize=function ( bool )
	return bool and "true" or "false"
end
serilizeTable["boolean"]=booleanSerilize
local nilSerilize=function ( value )
	return "\"\""
end
serilizeTable["nil"]=nilSerilize
local unMetaTableSerilize=function ( tb)
	local t={}
	for k,v in pairs(tb) do
		local kType=getType(k)
		if kType~="nil" then
		table_insert(t,
			string_format("[%s]=%s",
			serilizeTable[kType](k),serilizeTable[getType(v)](v)
			))
		end
	end
	return "{"..table_concat(t,",").."}"
end
serilizeTable["unMetaTable"]=unMetaTableSerilize

--以下专门针对cocos2dx-lua 中用class 声明得到的类型
--并不处理元表
local classSerilize=function (classValue)
	local t={}
	if luaIDQuery[classValue]==nil then
		local id=getId()
		luaIDQuery[classValue]=id
	else
		return ("\"luaID"..luaIDQuery[classValue].."\"")
	end
	table_insert(t,"__luaID="..id)
    for key,value in pairs(classValue) do
		local kType=getType(key)
		local vType=getType(value)
		if kType~="nil"  and vType~="nil" then	
			table_insert(t,
			"["..
			(
			luaIDQuery[key] and 
			("\"luaID"..luaIDQuery[key].."\"")
			or
			serilizeTable[kType](key)
			)
			.."]="..
			(
			luaIDQuery[value] and 
			("\"luaID"..luaIDQuery[value].."\"")
			or
			serilizeTable[vType](value)
			)
			)
		end
        
    end

    table_insert(t,
        "__class="..classValue.__nsName.."."..classValue.__cname
        )
	return "{"..table_concat(t,",").."}\n"
end
serilizeTable["class"]=classSerilize

local __serilizeAux
__serilizeAux=function (object)
	local objectType=type(object)
	if objectType=="table" then
		if object.__luaID then
			luaIDQuery[object.__luaID]=object
		end
		local keyAlterTable={}
		for key,value in pairs(object) do
			local keyType=type(key)
			if keyType=="table" then
				__serilizeAux(key)
			elseif keyType=="string" then
				local mc=key:match("^luaID(%d+)")
				if mc then
					table_insert(
					keyAlterTable,
					{key=luaIDQuery[tonumber(mc)],oldKey=key}
					)
				end
			end

			local valueType=type(value)
			if valueType=="string" then
				local mc=value:match("^luaID(%d+)")
				if mc then
					object[key]=luaIDQuery[tonumber(mc)]
				end
			elseif key~="__class" and valueType=="table" then
				__serilizeAux(value)
			end
		end
		for _,keys in pairs(keyAlterTable) do
			object[keys.key]=object[keys.oldKey]
			object[keys.oldKey]=nil
		end
		if object.__class then
			--object.__class=serilizeClassTable[object.__createClass]
			setmetatable(object,object.__class)
		end
	end
end
---@type fun(object:luaObject):string
local serilize=function (object)
	local str=serilizeTable[getType(object)](object)
	reset()
	return str
end
rawset(_G,"serilize",serilize)
---@type fun(str:string):luaObject
local unSerilize=function (str)
    local g=load(str)
	local t=g()
	__serilizeAux(t)
	reset()
	return t
end
rawset(_G,"unSerilize",unSerilize)
---这里弃用
---@type fun(classObject:luaObject):void
local registerClass=function (classObject)
	serilizeClassTable[classObject.__cname]=classObject
end


local function Serilize(luaClassObject)
   -- registerClass(luaClassObject)
	classRawSet(luaClassObject,"serilize",serilize)
	classRawSet(luaClassObject,"unSerilize",unSerilize)
end



return Serilize
