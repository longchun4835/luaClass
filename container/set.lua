_ENV=namespace "container"
using_namespace "luaClass"

template("set",false)

function set:set(t)
    local data={}
    if t then
        for _,value in pairs(t) do
           data[value]=true
        end
    end
    self._data=data
end

function set:del(key)
    self._data[key]=nil
end

function set:merge(set2)
    for key,_ in set2:iter() do
        self:insert(key)
    end
end

function set:has(key)
    return  self._data[key]~=nil
end

function set:insert(key)
    self._data[key]=true
end

function set:iter()
    local data=self._data
    return pairs(data)
end

function set:for_each(luaf)
    for k,_ in self:iter() do
        luaf(k)
    end
end

return set