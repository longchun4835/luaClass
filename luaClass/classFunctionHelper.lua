--[[
    split来自: https://blog.51cto.com/zhaiku/1163077
    做了一定程度性能优化
    TestTime :性能测试函数
]]
local function TestTime(func)
    local t1=os.clock()
    func()
    local t2=os.clock()
    print("cost time "..t2-t1.."s")
end

local string_gsub=string.gsub
local function split(str,sep)
    local rt= {}
    local size=1
    string_gsub(str, '[^'..sep..']+', function(w) rt[size]=w size=size+1 end )
    return rt
end

return {
    split=split,
}






