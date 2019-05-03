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




local table_unpack=unapck or table.unpack

local _zip2=function ( arrs,index )
	index=index+1
	if arrs[1][index]==nil then return end
	return index,arrs[1][index],arrs[2][index]
end

local _zip3=function ( arrs,index )
	index=index+1
	if arrs[1][index]==nil then return end
    return index,arrs[1][index],arrs[2][index],arrs[3][index]
end

local _zip=function ( arrs,index )
	index=index+1
	if arrs[1][index]==nil then return end
	local ar={}
	for i,arr in ipairs(arrs) do
		ar[i]=arr[index]	
	end	
	return index,table_unpack(ar)
end
--[[
--可以同时遍历多个数组table,针对主要使用情况进行优化
--for i,a,b,c in zip(arr,brr,crr) do
--  print(i,a,b,c)
--end
--]]
local function zip(arr,... )
	local index=0
    local arrs={arr,...}
    local size=#arrs
    if size==1 then
        return ipairs(arr)
    elseif size==2 then
        return _zip2,arrs,index
    elseif size==3 then
        return _zip3,arrs,index
    else
        return _zip,arrs,index
    end
end

rawset(_G,"zip",zip)

return {
    split=split,
    zip=zip
}






