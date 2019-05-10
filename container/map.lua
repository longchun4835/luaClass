--[[
    和STL map 不同的是,这并不能指定key 的类型
]]
_ENV=namespace "container"
using_namespace "luaClass"

template("map",false)

function map:map(t)
    t=t or {}
    self._data=t 
end

function map:del(key)
    self._data[key]=nil
end

function map:has(key)
    return  self._data[key]~=nil
end
function map:get(key,default)
    return self._data[key] or default
end
function map:insert(key,value)
    self._data[key]=value
end
function map:set(key,value)
    self._data[key]=value
end
---@param alterFunc fun(value:any,value2:any)
function map:onFun(key,alterFunc)
    self._data[key]=alterFunc()
end
function map:size()
    local count=0
    for _,_ in pairs(self._data) do
        count=count+1
    end
    return count
end

function map:iter()
    local data=self._data
    return pairs(data)
end
function map:merge(map2)
    for k,v in map2:iter() do
        self:insert(k,v)
    end
end
function map:for_each(luaf)
    for k,v in self:iter() do
        luaf(k,v)
    end
end

return map