rawset(_G,"include",require)

local string_gsub=string.gsub
local function split(str,sep)
    local rt= {}
    local size=1
    string_gsub(str, '[^'..sep..']+', function(w) rt[size]=w size=size+1 end )
    return rt
end

local using_namespace
local function namespace(nsName)
    nsName=nsName or ""
    local names=split(nsName,".")
    local index=1
    local lastNs=_G
    while(names[index]~=nil) do
        local name=names[index]
        if rawget(lastNs,name)==nil then
            local ns={}
            rawset(lastNs,name,ns)
            lastNs=ns
        else
            lastNs=rawget(lastNs,name)
        end
        index=index+1
    end
    local meta=getmetatable(lastNs) 
    if meta==nil then
        local old=_G
        meta={_G=old,__usingtable={}}
        meta.__index=function (self,key )
            for _,using_table in old.ipairs(meta.__usingtable) do
                --防止无限递归访问
                local res=rawget(using_table,key)
                if res then return res end
            end
            return rawget(meta._G,key)
        end
        old.setmetatable(lastNs,meta)
        lastNs.using_namespace=function (nsName)
            using_namespace(lastNs,nsName)
        end
        --主要用于序列化
        lastNs.__nsName=nsName
    end
    if _VERSION =="Lua 5.1" then
        setfenv(2,lastNs)
    else
        _G.__currentENV=lastNs
    end
    return lastNs
end
if _VERSION =="Lua 5.1" then
    rawset(_G,"_ENV",{})
end

rawset(_G,"namespace",namespace)
rawset(_G,"__nsName","_G")
using_namespace=function(nsTable,nsName)
    local names=split(nsName,".")
    local index=1
    local __lastNs=_G
    while(names[index]~=nil) do
        local name=names[index]
        if rawget(__lastNs,name)==nil then
            local ns={}
            rawset(__lastNs,name,ns)
            __lastNs=ns
        else
            __lastNs=rawget(__lastNs,name)
        end
        index=index+1
    end
    local meta=getmetatable(nsTable)
    local using_table=meta.__usingtable
    using_table[#using_table+1]=__lastNs
end


