require "test.normalTest.Role"

_ENV=namespace "test"

using_namespace "battle"

local role=Role("xixixi")
role.attack=998
role.defence=888
role.hp=666
role.equipments:push_back(Equipment("xixixi",1,2))
role.equipments:push_back(Equipment("hahah",1,2))
role.equipments:push_back(Equipment("yinyinyin",1,2))

local file=io.open('test./__serilizeResult.lua','w')
file:write("return \n")
file:write(role:serilize())
file:close()

