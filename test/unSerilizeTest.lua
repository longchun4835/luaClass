require "test.normalTest.Role"

_ENV=namespace "test"

using_namespace "luaClass"

local file=io.open('test/__serilizeResult.lua','r')
if not file then return end

local str=file:read("a")
local obj=unSerilize(str)
print(obj:is(battle.Role))
print(obj:serilize())