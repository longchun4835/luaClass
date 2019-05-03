luaTemplate("mat")

function mat:mat(rowNum,colNum)
    local data={}
    self._data=data
    self._rowNum=rowNum
    self._colNum=colNum
    for i=1,rowNum*colNum do
        data[i]=false
    end
end

function mat:at(row,col)
    return self._data[col+(row-1)*self._colNum] or nil
end

function mat:set(row,col,value)
    self._data[col+(row-1)*self._colNum]=value
end

function mat:del(row,col)
    self:set(row,col,false)
end

function mat:colNum()
    return self._colNum
end

function mat:rowNum()
    return self._rowNum
end

function mat:size()
    return self._colNum*self._rowNum
end

function mat:iter()
    return ipairs(self._data)
end
function mat:clear()
    for i=1,self:size() do
        self._data[i]=false
    end
end

function mat:onFun(luaf)
    for i,v in ipairs(self._data) do
        luaf(v)
    end
end

