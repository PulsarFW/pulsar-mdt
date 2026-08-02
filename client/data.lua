RegisterNetEvent("MDT:Client:SetData")
AddEventHandler("MDT:Client:SetData", function(type, data, options)
	plsr.MDT.Data:Set(type, data)
end)

RegisterNetEvent("MDT:Client:SetMultipleData", function(data)
	if data then
		for k, v in pairs(data) do
			plsr.MDT.Data:Set(k, v)
		end
	end
end)

RegisterNetEvent("MDT:Client:AddData")
AddEventHandler("MDT:Client:AddData", function(type, data, id)
	plsr.MDT.Data:Add(type, data, id)
end)

RegisterNetEvent("MDT:Client:UpdateData")
AddEventHandler("MDT:Client:UpdateData", function(type, id, data)
	plsr.MDT.Data:Update(type, id, data)
end)

RegisterNetEvent("MDT:Client:RemoveData")
AddEventHandler("MDT:Client:RemoveData", function(type, id)
	plsr.MDT.Data:Remove(type, id)
end)

RegisterNetEvent("MDT:Client:ResetData")
AddEventHandler("MDT:Client:ResetData", function()
	plsr.Phone.Data:Reset()
end)

RegisterNetEvent("Characters:Client:Logout")
AddEventHandler("Characters:Client:Logout", function()
	plsr.MDT.Data:Reset()
end)
