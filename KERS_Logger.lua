_HEMS_Log = {}
ac.onSessionStart(function(sessionIndex, restarted)
    if restarted then
        ac.log("Session Restarted")
        _HEMS_Log = {}
    end
end)


function script.windowMain(dt)
    ui.text("log")
    local saveToFile = 0
    for driverA = 0, ac.getSim().carsCount - 1, 1 do
        local driverName = ac.getDriverName(driverA)
        local currentLap = ac.getCar(driverA).lapCount
        if _HEMS_Log[driverName]["Summary"]["Laps"] ~= currentLap then
            saveToFile = 1
            _HEMS_Log[driverName]["Summary"]["Laps"] = currentLap
        end
    end
    if saveToFile == 1 then 
        SaveHEMSLog(JSON.stringify(_HEMS_Log))
    end
end

function script.update(dt)
    logsKers()
end


ac.onSessionStart(function(sessionIndex, restarted)
    if restarted then
        _HEMS_Log = {}
        ac.log("Session Restarted")
    end
end)

function logsKers() 
    for driverA = 0, ac.getSim().carsCount - 1, 1 do
        local driverName = ac.getDriverName(driverA)
        if driverName == nil then break end
        local summary = {}
        local driverLog = {}
        if _HEMS_Log[driverName] == nil then 
            summary["LapsUsed"] = 0
            summary["Time"] = 0
            summary["Laps"] = 0
            driverLog["Summary"] = summary
            driverLog["Log"] = {}
            _HEMS_Log[driverName] = driverLog
        else 
            driverLog = _HEMS_Log[driverName]
            summary = driverLog["Summary"]
        end 

        local currentLap = ac.getCar(driverA).sessionLapCount
        local lapLog = {}
        if driverLog[currentLap .. ""] == nil then 
            lapLog["UsedTimes"] = 0
            lapLog["Time"] = 0
            lapLog["_input"] = 0
        else 
            lapLog = driverLog["Log"][currentLap .. ""]
        end
        lapLog["Time"] = ac.getCar(driverA).kersCurrentKJ * 0.023
        if ac.getCar(driverA).kersInput ~= lapLog["_input"] then
            if ac.getCar(driverA).kersInput == 1 then
                lapLog["UsedTimes"] =  lapLog["UsedTimes"] + 1
            end

            lapLog["_input"] = ac.getCar(driverA).kersInput
        end
        driverLog["Log"][currentLap .. ""] = lapLog
        _HEMS_Log[driverName] = driverLog
    end
end

function ReasHEMSLog() 
    local readFile = io.open(GetFilePath(),"r")
    if readFile ~= nil then
        local fileData = readFile:read()
        readFile:close()
        _HEMS_Log = JSON.parse(fileData)
    end
end

function SaveHEMSLog(data) 
    local writeFile = io.open(GetFilePath(),"w+")
    if writeFile ~= nil then
        writeFile:write(data)
        writeFile:close()
    end
end

function GetFilePath() 
    local logFolder = ac.getFolder(ac.FolderID.RaceResults)
    ac.log(logFolder)
    local filePath = ".\\" .. ac.getSession(0).startTime .. ".json"
    return filePath
end