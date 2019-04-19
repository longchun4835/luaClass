local unpakc=unpack or table.unpack
local createFromStyleTable
createFromStyleTable=function (self,styleTable)
    local name=styleTable.name
    local node=
    type(styleTable.cls)~="function"
    and
    styleTable.cls:create(unpack(styleTable.create))
    or 
    styleTable.cls(unpack(styleTable.create))
    local setting=styleTable.setting
    if setting then 
        for fun,params in pairs(setting) do
            node[fun](node,unpack(params))
        end
    end
    local tag=styleTable.tag or 0
    self:addChild(node,tag)
    if name then
        if tolua.getpeer(node) ==nil then
            tolua.setpeer(node,{})
        end
        classRawSet(self,name,node)
    end
    if styleTable.child then
        for _,child in pairs(styleTable.child ) do
            createFromStyleTable(node,child)
        end
    end
end
classRawSet(_G,"CSS",createFromStyleTable)

local ViewNode=function (classObject)
    classRawSet(classObject,"createFromStyleTable",createFromStyleTable)
    classRawSet(classObject,"CSS",createFromStyleTable)
end
luaComponent("CViewNode",ViewNode)

return ViewNode