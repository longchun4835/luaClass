_ENV=namespace "container"
using_namespace "luaClass"

template("stack",false)
:declObject(number):_size()
:declObject(table):_data()
:declMethod(number):size()
:declMethod(void):push(Ty)
:declMethod(Ty):pop()
:declMethod(bool):empty()

function stack:stack(t)
    t=t or {}
    self._data=t
    self._size=#t
end   
function stack:size()
    return self._size
end

function stack:push(value)
    local num=self._size+1
    self._size=num
    self._data[num]=value
end
function stack:pop()
    local num=self._size
    local elem=self._data[num]
    self._data[num]=nil
    num=num-1
    self._size=num<0 and 0 or num
    return elem
end
function stack:empty()
    return self._size==0
end

return stack