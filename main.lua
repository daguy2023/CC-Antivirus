-- SAFE FILE
-- based on code made by hecker
-- all credits go to him for the great base
-- and also credits to Leveloper for fixing a binary bug!
-- edited and finished by daguy2023

local basalt = require("basalt")
local main = basalt.getMainFrame()
local render = main:render()

function log(input)
    logfile = fs.getDir(shell.getRunningProgram())
    fi = fs.open(logfile.."log.txt", "a")
    fi.write(input.."|\n")
    fi.close()
end
local safe = shell.getRunningProgram()
local maliciousPatterns = {
    "%(shell%.getRunningProgram%(%), \"r\"%)", 
    "payload", 
    "os%.pullEvent = os%.pullEventRaw",  
    "in ipairs%(fs%.list%(directory%)%)",
    "[%a_][%w_]*:%s*byte%s*%(%s*%)%s*%+.-%%.-",
    "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890",
    'fs.open("startup", "w")',
    "fs.open('startup', 'w')",
    "shell.setAlias%(",
    "X5O!P%@AP[4\\PZX54(P^)7CC)7}$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*"
}
local maliciousPatternsExplain = {
    "Self-Replicating ", 
    "Interfering ", 
    "Cannot Be Terminated ",  
    "Scanning for files ",
    "Encryption ",
    "Suspicious Activity ",
    "Suspicious Activity ",
    "Suspicious Activity ",
    "Changing Aliases ",
    "EICAR test "
}
local function typeofInfection(detectedPatterns)
 
    for _, pattern in ipairs(detectedPatterns) do
        if pattern == "Self-Replicating " then
            selfReplicating = true
        elseif pattern == "Scanning for files " then
            scanningForFiles = true
        elseif pattern == "Cannot Be Terminated " then
            cannotBeTerminated = true
        elseif pattern == "Interfering " then
            interfering = true
        elseif pattern == "Encryption " then
            Encryption = true
        elseif pattern == "Suspicious Activity  " then
            SuspiciousActivity = true
        elseif pattern == "Changing Aliases " then
            interfering = true
            nolua = true
        elseif pattern == "Infected file " then
            scanningForFiles = true
            selfReplicating = true
        elseif pattern == "EICAR test " then
            EICAR = true
        end
    end
    local endType = "Unknown"
    if EICAR then
        endType = "EICAR"
    elseif selfReplicating and scanningForFiles then
        endType = "Worm"
        if nolua then endType = "Worm(Evading)" end
    elseif selfReplicating and interfering then
        endType = "Worm"
        if nolua then endType = "Worm(Evading)" end
    elseif cannotBeTerminated and interfering then
        endType = "Malware"
    elseif scanningForFiles then
        endType = "Spyware"
    elseif Encryption and cannotBeTerminated then
        endType = "Ransomware"
    elseif interfering and nolua then
        endType = "Ransomware"
    elseif selfReplicating and nolua then
        endType = "Worm(Evading)"
    elseif nolua then
        endType = "Malware"
    end
    return endType
end
local function isMalicious(contents)
    local matches = 0
    local detectedPatterns = {}
 
    for i, pattern in ipairs(maliciousPatterns) do
        if contents:find(pattern) then
            matches = matches + 1
            table.insert(detectedPatterns, maliciousPatternsExplain[i])
        end
    end
 
    if matches >= 1 then
        return true, detectedPatterns
    end
 
    return false, detectedPatterns
end
local function truncate(str, maxLen)
    if str and maxLen then
        if string.len(str) > maxLen then
            return str:sub(1, maxLen)
        end
    else
        return str
    end
    return str
end
function listAllFiles(dir)
    local files = {}
    local items = fs.list(dir)
    for _, item in ipairs(items) do
        local path = fs.combine(dir, item)
        if fs.isDir(path) then
            if not string.find(path, "^rom$") then
                local subFiles = listAllFiles(path)
                for _, subFile in ipairs(subFiles) do
                    table.insert(files, subFile)
                end
            end
        else
            table.insert(files, path)
        end
    end
    return files
end 
function scan(files)
    local output = {}
    for itemnum in ipairs(files) do
        local item = files[itemnum]
        handle = nil
        local handle = fs.open(item, "rb")
        if handle then
            local firstline = handle.readLine()
            local contents = handle.readAll()
            handle.close()
            if contents then
                local isMal, patterns = isMalicious(tostring(contents))
                if isMal and firstline ~= "-- SAFE FILE" then
                    local fileName = fs.getName(tostring(fullPath))
                    local w, h = term.getSize()
                    listed = {
                        tostring(typeofInfection(patterns)), 
                        tostring(#patterns), 
                        truncate(item, w - 27)
                    }
                    table.insert(output, listed)
                end
            end
        end
    end
    return output
end
local button = main:addButton()
button:setText("Run scan!")
button:setPosition(1, 1)
button:setWidth("{self.text:len() + 2}")
button:onClick(function()
    log("loading list")
    but1()
end)
local button2 = main:addButton()
button2:setText("Delete selected")
button2:setPosition(14, 1)
button2:setWidth("{self.text:len() + 2}")
button2:onClick(function()
    log("attempted delete")
    but2()
end)
if not LevelOS then
    main:addButton()
        :setText("Exit")
        :setPosition(46, 1)
        :setBackground("{self.clicked and colors.red or colors.gray}")
        :setWidth("{self.text:len() + 2}")
        :onClick(function()
            log("process stopping")
            basalt.stop()
        end)
end
local listframe = main:addFrame()
listframe:setPosition(1, 4)
listframe:setSize(51, 16)
local termW, termH = term.getSize()
local list = listframe:addTable()
list:setSize(51, 16)
list:setColumns({{name="Type",width=12}, {name="Detections",width=14}, {name="Path",width=termW - 4}})
list:setData({})
function but1()
    local w, h = term.getSize()
    list:setData({})
    list:setData(scan(listAllFiles("/"), w))
end
function but2()
    local row = list.selectedRow
    local item = list.data[row]
    local data = item[3]
    if data then
        fs.delete(data)
        but1()
    end
end
parallel.waitForAny(
    function()
        while true do
            os.pullEvent("term_resize")
            local w, h = term.getSize()
            listframe:setSize(w, h - 3)
            list:setSize(w, h - 3)
        end
    end,
    function()
        basalt.run()
    end
)
print("antivirus exited")