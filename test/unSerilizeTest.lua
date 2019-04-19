require("luaClass.Serilize")
require"dataStructure.init"
require("test.serilizeTest")
local file=io.open('test/__serilizeResult.lua')
local fileText=file:read("*all")
file:close()
local obj=unSerilize(fileText)

print(obj:serilize())