require "luaClass.luaTemplate"
luaTemplate("set",false)
:declObject(table):_data()
:declMethod(void):del(Ty)
:declMethod(bool):has(Ty)
:declMethod(void):insert(Ty)
:declMethod(any):iter()
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

return set