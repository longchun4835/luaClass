require "luaClass.init"
require "container.init"
require "test.normalTest.Item"

_ENV=namespace "battle"

xixixi=998
using_namespace "luaClass"

class("Equipment")
:extend(Item)

function Equipment:Equipment(name,attack,defence)
    -- base constructor
    self:Item(name)

    self.attack=attack
    self.defence=defence
end

--override super's method showInfo
function Equipment:showInfo()
    --call super's method
    self.super.showInfo(self)
    
    print(self.attack,self.defence)

end