require "luaClass.luaTemplate"
luaTemplate("queue",false)
:declObject(number):_tail()
:declObject(number):_front()
:declObject(table):_data()
:declMethod(number):size()
:declMethod(void):push_back(Ty)
:declMethod(Ty):pop_front()
:declMethod(bool):empty()
:declMethod(any,any,any):iter()
function queue:queue(queueMax,data)
    queueMax=queueMax or 4
    local data=data or {}
    local size=#data
    local query={}
    for i=1,queueMax do
        data[i]=data[i] or false
        query[i]=i+1
    end
    query[queueMax]=1
    self._query=query
    self._data=data
    self._tail=1+size
    self._front=1
end   
function queue:push_back(value)    
    local tail=self._tail
    self._data[tail]=value
    self._tail=self._query[tail]
end
function queue:pop_front()
    local front=self._front
    local elem=self._data[front]
    self._data[front]=false
    self._front=self._query[front]
    return elem
end
function queue:empty()
    return self._front==self._tail and (self._data[self._tail]==false)
end
function queue:full()
    return (self._front==self._tail) and (self._data[self._tail]~=false)
end
function queue:iter()
    local data=self._data
    return ipairs(data)
end


return queue