require "container.init"
_ENV=namespace "test"
using_namespace "luaClass"
using_namespace "container"
class("Role")
:declObject(number):num()

local Role=test.Role

function Role:Role()
    self.num=123
end

local arr=array(Role)()
arr:push_back(Role())
arr:push_back("other")



local file=io.open("test/__serilizeResult.lua",'w')
file:write("return \n")
file:write(arr:serilize())

file:close()