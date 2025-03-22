HEMS_Log = {}
SessionID = 0
ac.onSessionStart(function(sessionIndex, restarted)
    HEMS_Log = {}
    SessionID = sessionIndex
end)

function script.update(dt)
    LogHems()
    SaveFileOnStartFinish()
end

function SaveFileOnStartFinish() 
    local saveToFile = 0
    for driverA = 0, ac.getSim().carsCount - 1, 1 do
        local driverName = ac.getDriverName(driverA)
        if driverName == "" then break end
        local currentLap = ac.getCar(driverA).sessionLapCount

        if driverName == nil then break end
        if HEMS_Log[driverName] == nil then 
            HEMS_Log[driverName] =  GetNewDriverLog(driverName) 
        end

        if HEMS_Log[driverName]["Summary"]["Laps"] ~= currentLap then
            saveToFile = 1
            HEMS_Log[driverName]["Summary"]["Laps"] = currentLap
        end
    end
    -- ac.log(JSON.stringify(HEMS_Log))
    if saveToFile == 1 then 
        UpdateSummary()
        SaveHEMSLog(JSON.stringify(HEMS_Log))
    end
end


ac.onSessionStart(function(sessionIndex, restarted)
    if restarted then
        HEMS_Log = {}
        ac.log("Session Restarted")
    end
end)

function GetNewDriverLog(driverName) 
    if driverName == nil then return end
    local summary = {}
    summary["LapsUsed"] = 0
    summary["Time"] = 0
    summary["Laps"] = 0

    local driverLog = {}
    driverLog["Summary"] = summary
    driverLog["Log"] = {}
    
    ac.log("created tempty log for " .. driverName)
    return driverLog
end

function LogHems() 
    for driverA = 0, ac.getSim().carsCount - 1, 1 do
        local driverName = ac.getDriverName(driverA)
        if driverName == "" then break end
        local driverLog = {}
        if HEMS_Log[driverName] == nil then break end
             
        driverLog = HEMS_Log[driverName]["Log"]
        local currentLap = ac.getCar(driverA).sessionLapCount
        local lapLog = {}
        if driverLog[currentLap .. ""] == nil then 
            lapLog["UsedTimes"] = 0
            lapLog["Time"] = 0
            lapLog["_input"] = 0
        else 
            lapLog = driverLog[currentLap .. ""]
        end
        lapLog["Time"] = ac.getCar(driverA).kersCurrentKJ * 0.023
        if ac.getCar(driverA).kersInput ~= lapLog["_input"] then
            if ac.getCar(driverA).kersInput == 1 then
                lapLog["UsedTimes"] =  lapLog["UsedTimes"] + 1
            end

            lapLog["_input"] = ac.getCar(driverA).kersInput
        end
        HEMS_Log[driverName]["Log"][currentLap .. ""] = lapLog
    end
end

function UpdateSummary() 
    for driverA = 0, ac.getSim().carsCount - 1, 1 do
        local driverName = ac.getDriverName(driverA)
        if driverName == "" then break end
        local driverLog = HEMS_Log[driverName]["Log"]
        local hemsTimeSum = 0
        local hemsUsedInLaps = 0
        for lap, lapData in pairs(driverLog) do
            if lapData["UsedTimes"] > 0 then
                hemsUsedInLaps = hemsUsedInLaps + 1
            end
            hemsTimeSum = hemsTimeSum + lapData["Time"]
        end
        HEMS_Log[driverName]["Summary"]["Time"] = hemsTimeSum
        HEMS_Log[driverName]["Summary"]["LapsUsed"] = hemsUsedInLaps
    end
end

function ReasHEMSLog() 
    local readFile = io.open(GetFilePath(),"r")
    if readFile ~= nil then
        local fileData = readFile:read()
        readFile:close()
        HEMS_Log = JSON.parse(fileData)
    end
end

function SaveHEMSLog(data) 
    local writeFile = io.open(GetFilePath(),"w+")
    if writeFile ~= nil then
        writeFile:write(data)
        writeFile:close()
        ac.log("file saved: " .. GetFilePath())
    else
        ac.log("io open error " .. GetFilePath());
    end
end

function GetFilePath() 
    local fileName = "HEMS log session " .. SessionID .. " day " .. ac.getSim().dayOfYear .. " start time " .. ac.getSession(SessionID).startTime
    local filePath = ".\\" .. fileName .. ".json"
    return filePath
end