local function SingleInstance(classObject)
    classRawSet(classObject,"getInstance",function (self)
        if  not classRawGet(self,"s_instance") then
            classRawSet(self,"s_instance",self:create())
        end
        return self.s_instance 
    end
)
end
luaComponent("CSingleInstance",SingleInstance)

return SingleInstance