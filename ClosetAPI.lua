--[[
ClosetAPI version 1.7.6
    All Rights Reserved, if file bellow is edited in anyway do not redistribute!
]]--

local p = peripheral
local pw = p.wrap
local args = {...}  --Incase i ever need then when debuging
local arg1 = args[1]
local arg2 = args[2]
local debug = true  --Enable this to disable updating and/or if you are changing code in here
local version ="1.7.6" -- added minor 1.12 support for plethra peripherals ( more 1.12 suport very soon )

getAllPeripherals = function(silent) --Silent makes it not return the full table(Non-Silent by default)

    --clear all peripheral tabels
    local monitors = {}
    local reactors = {}
    local powerdevices = {}
    local tanks = {}
    local turbines = {}
    local others = {}
    local cp = p.getNames()

    for i = 1,#cp do
        local current = cp[i]
        local curtype = p.getType(current)

        if curtype == "monitor" then
            table.insert(monitors,current)
        elseif curtype == "BigReactors-Reactor" or curtype == "BiggerReactors_Reactor" then
            table.insert(reactors,current)
        elseif curtype == "tile_blockcapacitorbank_name"    or string.find(curtype,"tile_thermalexpansion_cell") == 1    or curtype == "draconic_rf_storage"    or curtype == "thermalexpansion:storage_cell" then
            table.insert(powerdevices,current)
        elseif curtype == "openblocks_tank"     or curtype == "rcirontankvalvetile" then
            table.insert(tanks,current)
        elseif curtype == "BigReactors-Turbine" then
            table.insert(turbines,current)
        else
            table.insert(others,current)
        end
    end

    local gap = {
    mons = monitors,
    reacs = reactors,
    pds = powerdevices,
    tnks = tanks,
    turbs = turbines,
    others = others
    }
    if silent == false or silent == nil then   return gap     end
end

ExtraMonitor = {
    Add = {
        
    }

}

closetUpdate = function()
    return "disabled"
end

FileManager = {
    CurrentFileW = "",
    CurrentFileR = "",
    OpenFileW = function(file)
        if fs.getFreeSpace(file) <= 0 then APIdebug.log("Error no space left on computer!",5,"current","current","current") end
        FileManager.CurrentFileW = fs.open(file,"w")
    end,
    OpenFileR = function(file)
        FileManager.CurrentFileR = fs.open(file,"r")
    end,
    WriteLine = function(text,file)
        if FileManager.CurrentFileW == nil then return {"File Manager - [3] - ","File Not Found"} end
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
    log = function(text,level,debugvar,lmon,logfile)


        local FileWrite = FileManager.WriteLine
        if logfile ~= nil and logfile ~= false then
            if APIdebug.currentlog > 500 then
                FileManager.CloseCurrentW()
                if fs.isReadOnly(logfile) == false then
                    fs.delete(logfile)
                end
                FileManager.OpenFileW(logfile)
            end
            if level == 1 then
                FileWrite("["..APIdebug.currentlog.."] -  Info - "..text)
            elseif level == 2 then
                FileWrite("["..APIdebug.currentlog.."]-  Warn - "..text)
            elseif level == 3 then
                FileWrite("["..APIdebug.currentlog.."] -  Error - "..text)
            elseif level == 4 then
                FileWrite("["..APIdebug.currentlog.."] -  Fatal No Halt - "..text)
            elseif level == 5 then
                FileWrite("["..APIdebug.currentlog.."] -  Fatal - "..text.." - HALTING")
            end
        end
        if debugvar == true then
            if level == 1 then
                drawLineText("["..APIdebug.currentlog.."] - Info - "..text,colors.white,lmon,true)
            elseif level == 2 then
                drawLineText("["..APIdebug.currentlog.."] - Warn - "..text,colors.yellow,lmon,true)
            elseif level == 3 then
                drawLineText("["..APIdebug.currentlog.."] - Error - "..text,colors.orange,lmon,true)
            elseif level == 4 then
                drawLineText("["..APIdebug.currentlog.."] - PANIC NO HALT - "..text,colors.red,lmon,true)
                os.queueEvent("panic")
            elseif level == 5 then
                drawLineText("["..APIdebug.currentlog.."] - PANIC FORCE HALT  - "..text.." - HALTING",colors.red,lmon,true)
                os.queueEvent("panic","halt")
                print("["..APIdebug.currentlog.."] - PANIC - "..text)
                os.queueEvent("terminate")
            end
        end
        APIdebug.currentlog = APIdebug.currentlog+1
        if level == 5 then os.queueEvent("terminate") os.queueEvent("panic","halt") end
    end,
    Terminal = function(text,debugvar,lmon)
        if lmon == term and lmon ~= nil then

        elseif lmon ~= term and lmon ~= nil and type(lmon) ~= "table" then
            lmon = peripheral.wrap(lmon)
        elseif lmon == nil then
            lmon = term
        end
        local maxx,maxy = lmon.getSize()
        local currentx,currenty = lmon.getCursorPos()
        if debugvar == true or debugvar == nil then            
            currenty = currenty+1
            if currenty >= maxy then
                lmon.setCursorPos(1,1)
                lmon.write(text..string.rep(" ",maxx))
                lmon.setCursorPos(1,2)
                lmon.write(string.rep(" ",maxx))
                lmon.setCursorPos(1,1)
            else
                lmon.setCursorPos(1,currenty)
                lmon.write(text..string.rep(" ",maxx))
                lmon.setCursorPos(1,currenty+1)
                lmon.write(string.rep(" ",maxx))
                lmon.setCursorPos(1,currenty)
            end

        end
    end,
    detectedvars = {},
}
--Basic draw line, text features taken from Bars API ver 1.7 and upgraded so it would work better here


drawLineText = function(text,color_text,lmon,clearfront)
    local maxX,maxY = lmon.getSize()
    local lastcolor = lmon.getTextColor()
    local lastposX, lastposY = lmon.getCursorPos()
    if lastposY >= maxY then
        lmon.setCursorPos(1,1)

        lmon.clearLine()
        lmon.setTextColor(color_text)
        lmon.write(text)
        lmon.setTextColor(lastcolor)
    else
        lmon.setCursorPos(1,lastposY+1)
        lmon.clearLine()
        lmon.setTextColor(color_text)
        lmon.write(text)
        lmon.setTextColor(lastcolor)
    end
    if clearfront == true then
        local y,x = lmon.getCursorPos()
        lmon.setCursorPos(1,x+1)
        lmon.clearLine()
        lmon.setCursorPos(y,x)
    end
end

drawText = function(x,y,text,color_text,color_background,lmon)

    if color_text == nil then
        color_text = colors.white
    end
    if color_background == nil then
        color_background = colors.black
    end
    if lmon == nil then
        lmon = term
    end

    local lastcolor = lmon.getTextColor() --saving last color
    local lastbcolor = lmon.getBackgroundColor()

    lmon.setCursorPos(x,y)
    lmon.setBackgroundColor(color_background)
    lmon.setTextColor(color_text)
    lmon.write(text)
    lastposX, lastposY = lmon.getCursorPos()

    lmon.setBackgroundColor(lastbcolor)  --restoring last color
    lmon.setTextColor(lastcolor)
end
drawLine = function(x,y,tall,length,color_background,lmon)--Starting X, Starting Y, Height going down from starting, Length going out from starting
    if length < 1 then return end
    if tall < 1 then return end
    if color_background == nil then    color_background = colors.white    end
    if lmon == nil then    lmon = term    end
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
    --Starting X, Starting Y, Height going down from starting, Length going out from starting, Current value, Max value this will divide the current to make the percentage full,color,color,mon/term to draw to
    if lmon == nil then    lmon = term    end
    if color_empty == nil then    color_background = colors.white    end
    if color_fill == nil then    color_fill = colors.gray    end
    local percentage = value/maxvalue
    if percentage > 1 then percentage = 1 end
    local perfill = math.floor(percentage*length+.3)

    drawLine(x,y,tall,length,color_empty,lmon)
    drawLine(x,y,tall,perfill,color_fill,lmon)
end
function drawNewLine(lmon,text) --Text can be nil
    cx,cy = lmon.getCursorPos()
    lmon.write(text)
    lmon.setCursorPos(1,cy+1)
end

function drawGraph(startingX,startingY,LenthOfEach,MaxHight,value,color_empty,color_fill,lmon)  --WIP
    if lmon == nil then    lmon = term    end
    if color_empty == nil then    color_background = colors.white    end
    if color_fill == nil then    color_fill = colors.gray    end
    for i=1,#value do
    end
end

numbShorten = function(num, f, table, places, significance)--OLD DO NOT USE numbShorten2  Number,dnu,dnu,dnu,Floor Significance
    numbShorten2(num,significance)
end

function numbShorten2(numb,places,returntype) -- Input Number, Floor Significance | ver 4.0
    if numb < 1000 then return numb end
    if places == nil then places = 1 end
    numb = tostring(numb)
    local count = math.floor(#numb/3)
    local letters = {"K","M","B","T","Q","Qi","Sx","Sp","N","D","Ud","Du","Te","Qa","Qid"}
    
    if returntype == nil or returntype == 1 then 
        pfnumb = math.floor( numb / 10^(count*3) *10^places )/10^places
        return pfnumb..letters[count]
    elseif returntype == 2 then
        pfnumb = math.floor( numb / 10^(count*3) *10^places )/10^places
        return pfnumb
    elseif returntype == 3 then
        pfnumb = math.floor( numb* (10^places+1) / 10^#numb  )
        return pfnumb.."*10^"..#numb
    elseif returntype == 4 then
        pfnumb = math.floor( numb* (10^places+1) / 10^#numb  )
        return pfnumb.."E"..#numb
    end

end


--Some table saving tactics taken from the wiki.
function tabeSave(table,name)
    if type(name) ~= "string" then APIdebug.log("TabeSave didn't get a string name!",4,"detect","detect","detect") return end
    if table == nil then APIdebug.log("TabeSave didn't get a Table, it got nil!",4,"detect","detect","detect") return end
    local file = fs.open(name,"w")
    file.write(textutils.serialize(table))
    file.close()
end
function tabeLoad(name)
    if fs.exists(name) == false then return false end
    local file = fs.open(name,"r")
    local data = file.readAll()
    file.close()
    return textutils.unserialize(data)
end
function tabeUnnester(table)  -- basic unpacker able to unpack double nested tables
    for i =1,#table do
        for a = 1,#table[i] do
            print("table ",i,"  Index ",a,table[i][a])
        end
    end
end
