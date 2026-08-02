local config = load(LoadResourceFile(GetCurrentResourceName(), "config/server.lua"))()

local badgeCooldowns = {}

AddEventHandler("MDT:Server:RegisterCallbacks", function()
    plsr.Callbacks:RegisterServerCallback("MDT:PrintBadge", function(source, data, cb)
        local now = GetGameTimer()

        if not badgeCooldowns[source] or (now - badgeCooldowns[source]) > config.Badges.printCooldownMs then
            badgeCooldowns[source] = GetGameTimer()
            local char = plsr.Fetch:CharacterSource(source)
            if char and CheckMDTPermissions(source, { 'PD_HIGH_COMMAND', 'SAFD_HIGH_COMMAND', 'DOJ_JUDGE', 'DOC_HIGH_COMMAND' }) then
                local officer = plsr.MDT.People:View(data.SID)
                if officer then
                    local departmentName = false
                    local departmentData = false
                    local titleData = false
                    if officer.Jobs then
                        for k, v in ipairs(officer.Jobs) do
                            if v.Id == data.JobId and v.Workplace then
                                departmentData = v.Workplace.Id
                                departmentName = v.Workplace.Name
                                titleData = v.Grade.Name
                            end
                        end
                    end
    
                    if departmentData then
                        plsr.Inventory:AddItem(char:GetData('SID'), config.Items.governmentBadge, 1, {
                            ['Department Name'] = departmentName,
                            Title = titleData,
                            First = officer.First,
                            Last = officer.Last,
                            SID = officer.SID,
                            Callsign = officer.Callsign,
                            Mugshot = officer.Mugshot,
                            Department = departmentData,
                            DOB = officer.DOB,
                        }, 1)
                    else
                        cb(false)
                    end
                else
                    cb(false)
                end
            else
                cb(false)
            end
        else
            cb(false)
        end
    end)

    plsr.Inventory.Items:RegisterUse(config.Items.governmentBadge, "MDT", function(source, itemData)
        if itemData and itemData.MetaData and itemData.MetaData.Department then
            plsr.Callbacks:ClientCallback(source, "MDT:Client:CanShowBadge", itemData.MetaData, function(canShow)
                TriggerClientEvent("MDT:Client:ShowBadge", -1, source, itemData.MetaData)
            end)
        end
    end)

    plsr.Inventory.Items:RegisterUse(config.Items.governmentId, "MDT", function(source, itemData)
        local char = plsr.Fetch:CharacterSource(source)
        if char and itemData and itemData.MetaData and itemData.MetaData.StateID then
            plsr.Callbacks:ClientCallback(source, "MDT:Client:CanShowLicense", itemData.MetaData, function(canShow)
                TriggerClientEvent("MDT:Client:ShowLicense", -1, source, {
                    SID = itemData.MetaData.StateID,
                    Name = itemData.MetaData.Name,
                    Gender = itemData.MetaData.Gender,
                    DOB = itemData.MetaData.DOB,
                    Mugshot = itemData.MetaData.Mugshot,
                })
            end)
        end
    end)
end)