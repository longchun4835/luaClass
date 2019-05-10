require "luaClass.init"
require "container.init"

_ENV=namespace "battle"

using_namespace "luaClass"

class "Item"

function Item:Item(name )
    self.name=name
    self.number=1
end

function Item:showInfo()
    print(self.name,self.number)
end
