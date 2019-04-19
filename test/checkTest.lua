require "luaClass.init"
require "dataStructure.init"

namespace("test")
:class("play")
:declObject(number):_playerID()
:declMethod(number):getPlayerID()

local play=test.play
function play:play(id)
    self._playerID=id
end
local pl=play(2)

print(pl._playerID)
print(pl.getPlayerID)


function play:getPlayerID()
    return self._playerID
end

local pl2=play(3)

print(pl._playerID)
print(pl:getPlayerID())
