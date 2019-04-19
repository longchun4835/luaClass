--[[
    这部分来自网络,
    作者博客我找不到了
    
]]
local _1={}
local _2={}
local _3={}
local _4={}
local _5={}
local _6={}

local placeholder={
    _1=_1,
    _2=_2,
    _3=_3,
    _4=_4,
    _5=_5,
    _6=_6,
}

local _placeholder = {
    [_1] = 1,
    [_4] = 2,
    [_2] = 3,
    [_5] = 4,
    [_3] = 5,
    [_6] = 6
}
local unpack=unpack or table.unpack

local bind =
    function(luaf, ...)
    local argvsIn = {...}
    return function(...)
        local argvsOut = {}
        local argvsInner = {...}
        for i, v in pairs(argvsIn) do
            argvsOut[i] = _placeholder[v] and argvsInner[_placeholder[v]] or argvsIn[i]
        end
        return luaf(unpack(argvsOut))
    end

end


rawset(_G,"bind",bind)
rawset(_G,"placeholder",placeholder)

return {
    bind=bind,
    placeholder=placeholder
}