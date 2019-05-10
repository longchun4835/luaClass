
_ENV=namespace "container"
using_namespace "luaClass"
using_namespace "algorithm.iterator"
template("array",false)

function array:array(t)
    t=t or {}
    self._data=t
    self._size=#t
end
function array:at(index)
    return self._data[index]
end
function array:set(index,value)
    self._data[index]=value
end
function array:merge(arr)
    local arrsize=arr._size  or #arr
    local size=self._size
    local selfData=self._data 
    local arrData=arr._data or arr
    for i=1,arrsize do
        selfData[size+i]=arrData[i]            
    end
    self._size=size+arrsize
end    

function array:size()
    return self._size
end

function array:push_back(value)
    local num=self._size+1
    self._size=num
    self._data[num]=value
end
function array:pop_back()
    local num=self._size
    local elem=self._data[num]
    self._data[num]=nil
    num=num-1
    self._size=num<0 and 0 or num
    return elem
end
function array:empty()
    return self._size==0
end
function array:iter()
    local data=self._data
    return ipairs(data)
end
function array:clear()
    self._data={}
    self._size=0
end
function array:reverse()
    local data={}
    local sourceData=self._data
    local size=self._size
    if size~=0 then
        for i=1,size do
            data[i]=sourceData[size+1-i]
        end
    end
    return array(self.__ty)(data)
end

function array:sort(cmpFunction)
    table.sort(self._data,cmpFunction )
end


function array:zip(arr2)
    return zip(self._data,arr2._data)
end

function array:for_each(luaf)
    for k,v in self:iter() do
        luaf(k,v)
    end
end
function array:zip_each(arr2,luaf)
    for index,v1,v2 in self:zip(arr2) do
        luaf(index,v1,v2)
    end
end


return array