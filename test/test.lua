require "luaClass.init"
require "dataStructure.init"

namespace("test")
:class("Role")
:declObject(number):_playerID()
:declObject(string):_desc()
:declMethod(void):speak()
:declMethod(string):getDesc()

local t=test.Role()
print(t._playerID)
print(t:speak())   