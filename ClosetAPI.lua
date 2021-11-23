--[[
ClosetAPI version 1.8
    All Rights Reserved, if file bellow is edited in anyway do not redistribute!
]]--

local p = peripheral
local pw = p.wrap
local args = {...}  --Incase i ever need then when debuging
local arg1 = args[1]
local arg2 = args[2]
local debug = true  --Enable this to disable updating and/or if you are changing code in here
local version ="1.8" -- added added caching for log its functionaly a lot diffrent please update your code!

---@return table sorted-perpherals
getAllPeripherals = function()
    --clear all peripheral tabels
    local monitors = {}
    local reactors = {}
    local powerdevices = {}
    local tanks = {}
    local turbines = {}
    local others = {}
    local speakers = {}
    local cp = p.getNames()

    for i = 1,#cp do
        local current = cp[i]
        local curtype = p.getType(current)

        if curtype == "monitor" then
            table.insert(monitors,current)
        elseif curtype == "BigReactors-Reactor" then
            table.insert(reactors,current)
        elseif curtype == "tile_blockcapacitorbank_name"    or string.find(curtype,"tile_thermalexpansion_cell") == 1    or curtype == "draconic_rf_storage"    or curtype == "thermalexpansion:storage_cell" then
            table.insert(powerdevices,current)
        elseif curtype == "openblocks_tank"     or curtype == "rcirontankvalvetile" then
            table.insert(tanks,current)
        elseif curtype == "BigReactors-Turbine" then
            table.insert(turbines,current)
        elseif curtype == "speaker" then
            table.insert(speakers,current)
        else
            table.insert(others,current)
        end
    end

    local gap = {
    mons = monitors,
    reacs = reactors,
    pds = powerdevices,
    tanks = tanks,
    turbs = turbines,
    speaks = speakers,
    others = others
    }
    return gap
end

FileManager = {
    CurrentFileW = "",
    CurrentFileR = "",
    OpenFileW = function(file)
        if fs.getFreeSpace(file) <= 0 then log("Error no space left on computer!",5) end
        FileManager.CurrentFileW = fs.open(file,"w")
    end,
    OpenFileR = function(file)
        FileManager.CurrentFileR = fs.open(file,"r")
    end,
    WriteLine = function(text,file)
        if FileManager.CurrentFileW == nil then log("") end
        FileManager.CurrentFileW:writeLine(text)
        FileManager.CurrentFileW:flush()
    end,
    CloseCurrentW = function()
        if FileManager.OpenFileW ~= nil then
            if FileManager.CurrentFileW.close ~= nil then
                FileManager.CurrentFileW:close()
            end
        end
    end,
    CloseCurrentR = function()
        if FileManager.CurrentFileR ~= nil then
            if FileManager.CurrentFileR.close ~= nil then
                FileManager.CurrentFileR:close()
            end
        end
    end,
}

APIdebug = {
    currentlog = 1,
    detectedvars = {},
    log = function() end,
}

function APIdebug:prepLog(debugvar,lmon,levelt,levelc,halt)
    self.panics = {}
    if debugvar == false then 
        self.log = function(text,level)
            if level == halt-1 then self.panics[#panics+1] = text os.queueEvent("panic")  elseif
            level >= halt then self.panics[#panics+1] = text os.queueEvent("panic","halt") os.queueEvent("terminate") end
        end
        return
    end
    local lmon = lmon or term
    local halt = halt or 5
    local levelt = levelt or {
        "Info",
        "Warn",
        "Error",
        "PANIC NO HALT",
        "PANIC",
    }
    local levelc = levelc or {
        colors.white,
        colors.yellow,
        colors.red,
        colors.red,
        colors.red,
    }
    function log(text,level)
        local level = level or 1
        local lc = levelc[level] or colors.red
        local lt = levelt[level] or "PANIC"
        text = "["..self.currentlog.."] - "..lt.."- "..text
        drawLineText(text,lc,lmon,true)
        self.currentlog = self.currentlog+1
        if level == halt-1 then panics[#panics+1] = text os.queueEvent("panic")  elseif
        level >= halt then panics[#panics+1] = text os.queueEvent("panic","halt") os.queueEvent("terminate") end
    end
    return log
end


--Basic draw line, text features taken from Bars API ver 1.7 and upgraded so it would work better here


drawLineText = function(text,color_text,lmon,clearfront)
    local maxX,maxY = lmon.getSize()
    local lastcolor = lmon.getTextColor()
    local lastposX, lastposY = lmon.getCursorPos()
    if lastposY >= maxY then
        drawText(1,1,text,color_text,nil,lmon,true)
    else
        drawText(1,lastposY+1,text,color_text,nil,lmon,true)
    end
    if clearfront == true then
        local x,y= lmon.getCursorPos()
        lmon.setCursorPos(1,y+1)
        lmon.clearLine()
        lmon.setCursorPos(x,y)
    end
end

drawText = function(x,y,text,color_text,color_background,lmon,clear)
    color_text = color_text or colors.white
    color_background = color_background or colors.black
    lmon = lmon or term

    local lastcolor = lmon.getTextColor() --saving last color
    local lastbcolor = lmon.getBackgroundColor()
    lmon.setCursorPos(x,y)
    lmon.setBackgroundColor(color_background)
    lmon.setTextColor(color_text)
    if clear then lmon.clearLine() end
    lmon.write(text)
    lmon.setBackgroundColor(lastbcolor)  --restoring last color
    lmon.setTextColor(lastcolor)
end

drawLine = function(x,y,tall,length,color_background,lmon)--Starting X, Starting Y, Height going down from starting, Length going out from starting
    if length < 1 then return end
    if tall < 1 then return end
    color_background = color_background or colors.white
    lmon = lmon or term

    local lastbcolor = lmon.getBackgroundColor()--saving last color
    lmon.setCursorPos(x,y)
    lmon.setBackgroundColor(color_background)
    for yPos = y, y+tall-1 do
        lmon.setCursorPos(x,yPos)
        lmon.write(string.rep(" ", length))
    end
    lmon.setBackgroundColor(lastbcolor) --restoring last color
end

drawProg = function(x,y,tall,length,value,maxvalue,color_empty,color_fill,lmon) 
    lmon = lmon or term
    color_empty = color_empty or colors.gray
    color_fill = color_fill or colors.green

    local percentage = value/maxvalue
    if percentage > 1 then percentage = 1 end

    local perfill = math.floor(percentage*length+.3)
    drawLine(x,y,tall,length,color_empty,lmon)
    drawLine(x,y,tall,perfill,color_fill,lmon)
end

function drawSimpleLine(lmon,text) --Text can be nil
    lmon = lmon or term
    cx,cy = lmon.getCursorPos()
    lmon.write(text)
    lmon.setCursorPos(1,cy+1)
end

---@param returntype number
---@return string|
function numbShorten(numb,places,returntype) -- Input Number, Floor Significance, returntypes | ver 4.0
    if numb == nil then return end
    if numb < 1000 then return numb end
    if places == nil then places = 1 end
    numb = tostring(numb)
    local count = math.floor(#numb/3)
    if #numb%3 == 0 then count = count-1 end
    local letters = {"K","M","B","T","Q","Qi","Sx","Sp","N","D","Ud","Du","Te","Qa","Qid"}
    local pfnumb
    if returntype == nil or returntype == 1 then 
        pfnumb = math.floor( numb / 10^(count*3) *10^places )/10^places
        return pfnumb..letters[count]
    elseif returntype == 2 then
        pfnumb = math.floor( numb / 10^(count*3) *10^places )/10^places
        return tonumber(pfnumb)
    elseif returntype == 3 then
        pfnumb = math.floor( numb* (10^places+1) / 10^#numb  )
        return pfnumb.."*10^"..#numb
    elseif returntype == 4 then
        pfnumb = math.floor( numb* (10^places+1) / 10^#numb  )
        return pfnumb.."E"..#numb
    else
        pfnumb = math.floor( numb / 10^(count*3) *10^places )/10^places
        return pfnumb..letters[count]
    end
end
function numbShorten2(a,b,c) -- DONT USE moved to numbShorten
    return numbShorten(a,b,c)
end

--Some table saving tactics taken from the wiki.
---@param table table
---@param name string
function tableSave(table,name)
    if type(name) ~= "string" then log("TabeSave didn't get a string name!",4) return end
    if table == nil then log("TabeSave didn't get a Table, it got nil!",4) return end
    local file = fs.open(name,"w")
    file.write(textutils.serialize(table))
    file.close()
end
---@param name string
---@return table
function tableLoad(name)
    if fs.exists(name) == false then return false end
    local file = fs.open(name,"r")
    local data = file.readAll()
    file.close()
    return textutils.unserialize(data)
end
---@param table table
function tableUnnester(table)  -- basic unpacker able to unpack double nested tables
    for i =1,#table do
        for a = 1,#table[i] do
            print("table ",i,"  Index ",a,table[i][a])
        end
    end
end