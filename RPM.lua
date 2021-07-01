-- V2.2
-- All Rights Reserved, if file bellow is edited in anyway do not redistribute!

--[[
Credits (C):
    Steam:      Closet Raccoon
    Discord:    Closet Raccoon#5092  -- Bug reports are welcome
    Minecraft:  ClosetRedPanda
]]


if false then     require("ClosetAPI.lua")     end -- Visual Studio
local capi

if fs.exists("ClosetAPI.lua") then  -- 1.12 support
    os.loadAPI("ClosetAPI.lua")
elseif fs.exists("ClosetAPI") then
    os.loadAPI("ClosetAPI")
else
    error("API not found")
end

if _G["ClosetAPI.lua"] then  -- 1.12 support
    capi = _G["ClosetAPI.lua"]
elseif _G["ClosetAPI"] then
    capi = _G["ClosetAPI"]
end

if capi == nil then error("API was not found") end

local error_on_wrong_ver = nil -- set to nil to disable!

local name = "Racc's Power Management"
local short_name = "~R-P-M~"
local name_color = colors.blue

local motd = "Enjoy"
local motd_color = colors.lightBlue
local use_live_motd = true
local motd_link = "https://pastebin.com/raw/rxd5wQFc"
local update_motd_with_f5 = false -- Disable for more preforment f5 refreshing ( Standered update refreshing not effected [f4] )

local version = 2.3

local enable_logging = true
local log_to = "left"
local log_file = nil
local Power_Scope_Modifier = nil --Will divide the capacity of connected powerdevices by this number when making the progress bar to allow for more finite storage on large storage devices this is skipped if the number is <1 or nil
-- ^ ability to set to each power device is coming!

local auto_detect = true -- if true then it will auto add all connected peripherals

local mons = {}
local reacs = {}
local pds = {}
local turbs = {}
local theme_colors = {
    power = colors.pink,
    reacs = colors.purple,
    turbs = colors.blue,
    all = colors.cyan,
}

local reacs_data = {}
local pds_data = {}
local mons_data = {}
local turbs_data = {}

local always_load_settings = false -- WARNING this can cause problems if problems are common while restarting the program then delete the save file or set to false!
local settings_save_file = "RPM2_Monitor_Settings"

local default_monitor_scale = 1
local default_monitor_tab = "all"
local monitor_settings
local function defineSettings()
    monitor_settings = {}
end

local startargs = {...}
if startargs[1] == "update" or startargs[1] == "reset" then
    os.run({},"updater.lua")
    os.exit(0)
end

terminate = false
running = true

term.setTextScale = function() return end -- Fixes the only thing that monitors can do that computers will error on
local log_to_original_input
function prepDebugMon()
    if enable_logging == false then return end
    if log_to == term then return end
    if peripheral.isPresent(log_to) == true then
        local temp = peripheral.wrap(log_to)
        temp.clear()
        temp.setCursorPos(1,0)
    end
end
prepDebugMon()

function redefine_log()
    log = function(text,level)
        if enable_logging == false then return end
        if not level then level = 1 end 

        if (type(log_to) == "string" and peripheral.isPresent(log_to) == true) then
            log_to_original_input = log_to
            log_to = peripheral.wrap(log_to)
        elseif log_to_original_input == nil then
            log_to_original_input = log_to
        end
        
        if log_to.write == nil then return end
        if capi.FileManager.CurrentFileW == "" and log_file ~= nil then capi.FileManager.OpenFileW(log_file) end
        capi.APIdebug.log(text,level,enable_logging,log_to,log_file)
    end
    log("Log output is ready",1)
end

if enable_logging == true then redefine_log() log("Logging is enabled",1) else log = function () return end end

function loadSettings()
    local temp = capi.tabeLoad(settings_save_file)
    if type(temp) == "table"  then
        monitor_settings = temp
    else
        log("File, "..settings_save_file.." ,was not able to load!",3)
    end
end

function getMOTD()
    if http then
        if use_live_motd == true and type(motd_link) == "string" then
            local resp = http.get(motd_link)
            if type(resp) == "table" then
                if resp.readLine() == "Format : 1" then
                    log("Connected to live motd server",1)
                    local new_motd = resp.readLine()
                    motd = new_motd
                    local ncolor = tonumber(resp.readLine())
                    if type(ncolor) == "number" then
                        if colors.test(65535,ncolor) then
                            log("Using live MOTD color",1)
                            motd_color = ncolor
                        else
                            log("Live MOTD color was not in the color range!",1)
                        end
                    end
                elseif resp.readLine() == "Format : 2" then
                    log("Connected to live motd server",1)
                    local new_motd = resp.readLine()
                    motd = new_motd
                    local ncolor = tonumber(resp.readLine())
                    if type(ncolor) == "number" then
                        if colors.test(65535,ncolor) then
                            log("Using live MOTD color",1)
                            motd_color = ncolor
                        else
                            log("Live MOTD color was not in the color range!",1)
                        end
                    end
                else
                    log("MOTD was not in a supported format, try updating RPM",2)
                end
                resp.close()
            else
                log("Was unable to connect to live MOTD server, using default motd.",2)
            end
        end
    end
end

function autoDetect()
    log("Running autoDetect()",1)
    local d = capi.getAllPeripherals()
    if d == {} or d == nil or type(d) ~= "table" then
        log("autoDetect returned nothing",4)
    else
        reacs = {}
        pds = {}
        mons = {}
        turbs = {}
        turbs = d.turbs
        reacs = d.reacs
        pds = d.pds
        mons = d.mons
    end
end

function prep()
    log("running prep()",1)
    log("Removing faulty peripherals",1)
    for i = 1,#mons do
        if mons[i] ~= nil then
            if peripheral.isPresent(mons[i]) == false then
                log("'"..mons[i].."' Not found, Removing",2)
                table.remove(mons,i)
            end
            if mons[i] == log_to_original_input and enable_logging == true then 
                log("'"..mons[i].."' is debug mon, Removing",2)
                table.remove(mons,i)
            end
        end
    end
    for i = 1,#reacs do
        if peripheral.isPresent(reacs[i]) == false then
            log("'"..reacs[i].."' Not found, Removing",2)
            table.remove(reacs,i)
        end
    end
    for i = 1,#pds do
        if peripheral.isPresent(pds[i]) == false then
            log("'"..pds[i].."' Not found, Removing",2)
            table.remove(pds,i)
        end
    end
end

function totalTable(intable)
    log("Totaling "..tostring(intable),1)
    local outtable = {
        activeAmount = 0,
        amount = 0,
        name = "total_table"
    }
    for k,v in pairs(intable) do
        outtable.amount = outtable.amount+1
        for l,b in pairs(v) do
            if type(b) == "number" then
                --log(tostring(k).."    "..tostring(v).."    "..tostring(l).."    "..tostring(b),1)
                if outtable[l] == nil then outtable[l] = 0 end
                outtable[l] = outtable[l] + b
                --log(outtable[l],1)
            elseif l == "active" and b == true then 
                outtable.activeAmount = outtable.activeAmount + 1
                --log(tostring(k).."    "..tostring(v).."    "..tostring(l).."    "..tostring(b).." ADDED 1 ACTIVE",1)
            end
        end
    end
    return outtable
end

local function getInfo1710()
    for i = 1,#pds do 
        if peripheral.isPresent(pds[i]) == false then 
            log("'"..pds[i].."' was not found while getting info!",3)
        else
            local a,b,c,d,e,f,g,h   --Indvidual 
            local crnt = peripheral.wrap(pds[i])
            a = crnt.getEnergyStored()
            if crnt.getMaxEnergyStored == nil and crnt.getEnergyCapacity ~= nil then  b = crnt.getEnergyCapacity() end
            if crnt.getMaxEnergyStored ~= nil then  b = crnt.getMaxEnergyStored() end
 
            f = math.floor(a/b*10)/10
            pds_data[pds[i]] = {
                energyStored = math.floor(crnt.getEnergyStored()*10) /10                ,-- 1  Energy
                maxEnergy    = b                                                        ,-- 2  Max Energy
                shortEnergy = capi.numbShorten2(a,3), -- Shortened Energy
                f, -- Percentage
                d = peripheral.getType(pds[i]), -- Type
                g = pds[i], -- Name
                h = "Draconic", -- Human name (Old and will not display proper name)
            }
            log("'"..pds[i].."' data retreived",1)
        end
    end
    for i = 1,#reacs do
        if peripheral.isPresent(reacs[i]) == false then
            log("'"..reacs[i].."' was not found while getting info!",3)
        else
            local crnt = peripheral.wrap(reacs[i])
            local cdata = {
                energyStored = math.floor(crnt.getEnergyStored()*10) /10                ,-- 1  Energy
                maxEnergy    = 10000000                                                 ,-- 2  Max Energy
                fuelUsage    = math.floor( crnt.getFuelConsumedLastTick()*100 ) / 100   ,-- 3  Fuel Usage
                energyOut    = crnt.getEnergyProducedLastTick()                         ,-- 4  Energy Produced
                active       = crnt.getActive()                                         ,-- 6  Is Active (Bool)
                rodLevel     = crnt.getControlRodLevel(0)                               ,-- 7  Rod Level
                fuelLevel    = crnt.getFuelAmount()                                     ,-- 8  Fuel Level
                fuelMax      = crnt.getFuelAmountMax()                                  ,-- 9  Fuel Max
                type         = peripheral.getType(reacs[i])                             ,-- 11 Type
                name         = reacs[i]                                                 ,-- 12 Name
                actCooled    = crnt.isActivelyCooled()                                  ,-- 13 true if its a steam producing reactor (Bool)
            }
            cdata["RFFuel"]          = math.floor(cdata["energyOut"]/cdata["fuelUsage"]*100)/100
            cdata["fuelPercentage"]  = math.floor(cdata["fuelLevel"]/cdata["fuelMax"]*1000)/10
            reacs_data[ reacs[i] ] = cdata
            log("'"..reacs[i].."' data retrieved",1)
        end
    end
    for i = 1,#turbs do
        if peripheral.isPresent(turbs[i]) == false then
            log("'"..turbs[i].."' was not found while getting info!",3)
        else
            local crnt = peripheral.wrap(turbs[i])
            local cdata = {
                energyStored = math.floor(crnt.getEnergyStored()*10) /10                ,-- 1  Energy
                maxEnergy    = 10000000                                                 ,-- 2  Max Energy
                energyOut    = crnt.getEnergyProducedLastTick()                         ,-- 4  Energy Produced
                active       = crnt.getActive()                                         ,-- 6  Is Active (Bool)
                type         = peripheral.getType(turbs[i])                             ,-- 11 Type
                name         = reacs[i]                                                 ,-- 12 Name
                rpm          = crnt.getRotorSpeed()                                     ,-- 13 Rotor Speed
                hotConsumed  = crnt.getFluidFlowRate()                                  ,-- 14 Steam consumed
            }
            turbs_data[ turbs[i] ] = cdata
            log("'"..turbs[i].."' data retrieved",1)
        end
    end
    totals = {
        turbs = totalTable(turbs_data),
        pds = totalTable(pds_data),
        reacs = totalTable(reacs_data)
    }
end



if tonumber(string.sub(os.version(),8)) < 1.79 then
log("MC version is lower then 1.12",1)
    log("1.7.10 is the prefered version to use this with!")
    getInfo = getInfo1710
else
    log("MC version is 1.12 or higher",2)
    log("1.7.10 is the prefered version to use this with!",2)
    if error_on_wrong_ver ~= nil then error("MC version is 1.12 or higher, 1.7.10 is the prefered version to use this with!") end
    getInfo = getInfo1710
end




function bwrite(text,x,y,mon,clear)
    if mon == nil or type(mon) ~= "table" then log("Basic write got bad mon variable",2) return end
    mon.setCursorPos(x,y)
    if clear == true then mon.clearLine() end
    mon.write(text)
end

function comma_value(amount,places) --stolen right off 'http://lua-users.org/wiki/FormattingNumbers'
    if places == nil then places = 2 end
    local formatted = math.floor(amount*10^places)/10^places
    while true do  
      formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
      if (k==0) then
        break
      end
    end
    return formatted
end

function reShellTerm()
    log("reshelling term",1)
    term.clear()
    local mX,mY = term.getSize()
    term.setCursorPos( (mX/2-#name/2) ,1)
    term.setTextColor(name_color)
    print(name)
    term.setCursorPos( (mX/2-#motd/2) ,2)
    term.setTextColor(motd_color)
    print(motd)
    term.setCursorPos(1,3)
end

local buttons = {}
local button = {
    process = function (self,event)
        log("Processing possible button.",1)
        local call = event[1]
        local monitor = event[2]
        local cX = event[3]
        local cY = event[4]
        if buttons[monitor] == {} or buttons[monitor] == nil then log("'"..monitor.."' has no buttons!",1) return end
        for k,v in pairs(buttons[monitor]) do
            if cX >= v.minX and cX <= v.maxX   then
                if cY >= v.minY and cY <= v.maxY   then
                    log("Button named '"..v.name.."' was called",1)
                    v:run()
                end
            end
        end
    end,
    createButton = function(self,maxX,maxY,minX,minY,funct,name,monitor,tablename) -- WARNING FUNCTIONS MUST HAVE A SELF DELCARATION!
        if type(maxX) ~= "number" or type(maxY) ~= "number" or type(minY) ~= "number" or type(minX) ~= "number" or type(funct) ~= "function" or type(monitor) ~= "string" or type(tablename) ~= "string" then
            log("Atempted to create button with args that wernt the correct type",4)
            return
        end
        buttons[monitor][tablename] = {
            maxX = maxX,
            maxY = maxY,
            minX = minX,
            minY = minY,
            monitor = monitor,
            name = name,
            run = funct,
        }

    end,
    createButtonTable = function(self,table,tablename) -- WARNING FUNCTIONS MUST HAVE A SELF DELCARATION!
        if type(table) ~= "table" or type(tablename) ~= "string" then
            log("Atempted to create button with table, with args that wernt the correct type",4)
            return false
        end
        buttons[tablename] = table
    end,
}

local tabbuttons = {}
local tabbutton = {
    createButton = function(self,maxX,maxY,minX,minY,funct,name,monitor,tablename) -- WARNING FUNCTIONS MUST HAVE A SELF DELCARATION!
        if type(maxX) ~= "number" or type(maxY) ~= "number" or type(minY) ~= "number" or type(minX) ~= "number" or type(funct) ~= "function" or type(monitor) ~= "string" or type(tablename) ~= "string" then
            log("Atempted to create button with args that wernt the correct type",4)
            return
        end
        tabbuttons[monitor][tablename] = {
            maxX = maxX,
            maxY = maxY,
            minX = minX,
            minY = minY,
            monitor = monitor,
            name = name,
            run = funct,
        }
    end,
    process = function (self,event)
        log("Processing possible button.",1)
        local call = event[1]
        local monitor = event[2]
        local cX = event[3]
        local cY = event[4]
        if tabbuttons[monitor] == {} or tabbuttons[monitor] == nil then log("'"..monitor.."' has no buttons!",1) return end
        for k,v in pairs(tabbuttons[monitor]) do
            log("Testing "..k,1)
            if cX >= v.minX and cX <= v.maxX   then
                if cY >= v.minY and cY <= v.maxY   then
                    log("Button named '"..v.name.."' was called",1)
                    v:run()
                end
            end
        end
    end,
}

local function wait ( time ) -- Off wiki to allow for events to handle during sleep timers without using parallel
    local timer_finished = false
    local timer = os.startTimer(time)

    while timer_finished == false do
      local event = {os.pullEventRaw()}

      if (event[1] == "timer" and event[2] == timer) or (event[1] == "key_up" and event[2] == keys.f4) then
        timer_finished = true
      else
        eventHandler(event)
      end
    end
end

local tabs
function tabDef()
    tabs = {}
    tabs.all = {
        display = function(self,mon,data,mon_name)
            if data == nil then data =  self.cortable() end
            if mon then
                log(mon_name.." displaying 'all'",1)
                local mon = mon
                local mx,my = mon.getSize()
                if #reacs > 0 then
                    local size = 4
                    local cdata = data["reacs"]
                    mon.setTextColor(theme_colors.reacs)
                    local cx,cy = mon.getCursorPos()
                    bwrite("Reactors: ",1,cy,mon,true)
                    local acttext = cdata.activeAmount.."/"..cdata.amount
                    bwrite(acttext,mx-#acttext,cy,mon)
                    bwrite("Fuel amount: "..cdata.fuelPercentage,2,cy+1,mon,true)
                    bwrite("Fuel Usage: "..cdata.fuelUsage,2,cy+2,mon,true)

                    local amntActCooled = 0
                    local amntPassiveCooled = 0
                    local totalSteamOut = 0
                    local totalPowerOut = 0
                    for i = 1,#reacs do
                        if reacs_data[reacs[i]].actCooled then
                            amntActCooled = amntActCooled + 1
                            totalSteamOut = reacs_data[reacs[i]].energyOut + totalSteamOut
                        else
                            amntPassiveCooled = amntPassiveCooled+ 1
                            totalPowerOut = reacs_data[reacs[i]].energyOut + totalPowerOut 
                        end
                    end
                    if amntActCooled > 0 then 
                        local cx,cy = mon.getCursorPos()
                        bwrite("Steam Output: "..math.floor(totalSteamOut).." MB/t",2,cy+1,mon,true)
                        --[[if amntActCooled ~= cdata.amount then 
                            local endstring = tostring(amntActCooled).."/"..cdata.amount
                            bwrite(endstring,mx-#endstring,cy+1,mon,false)
                        end]]
                    end
                    if amntPassiveCooled > 0 then
                        local cx,cy = mon.getCursorPos()
                        bwrite("Power Output: "..comma_value(totalPowerOut).." RF/t",2,cy+1,mon,true)
                        --[[if amntActCooled ~= cdata.amount then 
                            local endstring = tostring(amntActCooled).."/"..cdata.amount
                            bwrite(endstring,mx-#endstring,cy+1,mon,false)
                        end]]
                    end

                    local ex,ey = mon.getCursorPos()
                    mon.setCursorPos(1,ey+2)
                end
                if #pds > 0 then
                    local size = 4
                    local cdata = data["pds"]
                    mon.setTextColor(theme_colors.power)
                    local cx,cy = mon.getCursorPos()
                    bwrite("Power Storage: ",1,cy,mon)
                    bwrite("Power Stored: "..capi.numbShorten2(cdata.energyStored,2),2,cy+1,mon,true)
                    local scope
                    if Power_Scope_Modifier ~= nil and Power_Scope_Modifier > 1 then scope = Power_Scope_Modifier else scope = 1 end
                    capi.drawProg(2,cy+2,1,mx-2,cdata["energyStored"],cdata["maxEnergy"]/scope,colors.gray,theme_colors.power,mon)
                    mon.setCursorPos(1,cy+size)
                end
                if #turbs > 0 then
                    local size = 4
                    local cdata = data["turbs"]
                    mon.setTextColor(theme_colors.turbs)
                    local cx,cy = mon.getCursorPos()
                    bwrite("Turbines: ",1,cy,mon,true)
                    local acttext = cdata.activeAmount.."/"..cdata.amount
                    bwrite(acttext,mx-#acttext,cy,mon)
                    bwrite("Energy Output: "..comma_value(cdata.energyOut).." RF/t",2,cy+1,mon,true)
                    bwrite("Rotor Speed: "..cdata.rpm,2,cy+2,mon,true)
                    bwrite("Steam Consumed: "..cdata.hotConsumed,2,cy+3,mon,true)
                    mon.setCursorPos(1,cy+size)
                end
            end
        end,
        name = "All",
        theme = theme_colors.all,
        delete = function()
            return false
        end,
        cortable = function()
            return totals
        end,
    }
    if #reacs > 0 then
        tabs.reacs = {
                --[[init = function(self,mon,data,mon_name)
                    monitor_settings[mon_name].tabsettings[self.name] = {}
                    monitor_settings[mon_name].tabsettings[self.name].pages = {}
                    monitor_settings[mon_name].tabsettings[self.name].page = 1
                    for i = 1,#reacs do  end

                    
                end,]]
                display = function(self,mon,data,mon_name,page)
                    --if page == nil then page = monitor_settings[mon_name].tabsettings[self.name].pages[monitor_settings[mon_name].tabsettings[self.name].page] end
                    if data == nil then data =  self.cortable() end
                    if mon then
                        log(mon_name.." displaying 'reacs'",1)
                        local mon = mon
                        local mx,my = mon.getSize()
                        local size = 4

                        for g = 1,#reacs do
                            local cur = reacs[g]
                            local cdata = data[cur]
                            if peripheral.isPresent(cur) == true and cdata ~= nil then
                                local cx,cy = mon.getCursorPos()
                                if cy+size > my then break end
                                mon.setTextColor(self.theme)
                                bwrite("Reactor "..g..":",1,cy,mon)
                                if cdata["name"] == "DISCONNECTED" then
                                    local r = "DISCONNECTED"
                                    capi.drawText(mx-#r+1,cy, r, colors.red, nil, mon)
                                elseif cdata["active"] == true then
                                    local r = "Running"
                                    capi.drawText(mx-#r+1,cy, r, colors.green, nil, mon)
                                elseif cdata["active"] == false then
                                    local r = "Halted"
                                    capi.drawText(mx-#r+1,cy, r, colors.gray, nil, mon)
                                else
                                    local r = "ERROR"
                                    capi.drawText(mx-#r+1,cy, r, colors.red, nil, mon)
                                end
                                bwrite("Fuel Percentage: "..cdata["fuelPercentage"],2,cy+1,mon,true)
                                bwrite("Fuel Usage: "..cdata["fuelUsage"],2,cy+2,mon,true)
                                local react_out
                                if cdata.actCooled == true then 
                                    react_out = "Steam Output: "..math.floor(cdata.energyOut).." MB/t"
                                else
                                    react_out = "Power Output: "..comma_value(cdata.energyOut).." RF/t"
                                end
                                bwrite(react_out,2,cy+3,mon,true)
                                mon.setCursorPos(1,cy+size+1)
                            end
                        end
                    else
                    end
                end,
                name = "Reactors",
                theme = theme_colors.reacs,
                delete = function()
                    return false
                end,
                cortable = function()
                    return reacs_data
                end,
        }
    end
    if #pds > 0 then
        tabs.pds = {
                display = function(self,mon,data,mon_name)
                    if data == nil then data =  self.cortable() end
                    if mon then
                        log(mon_name.." displaying 'pds'",1)
                        local mon = mon
                        local mx,my = mon.getSize()
                        local size = 3 -- size of all the elements of the for loop input not including spacer
                        for g = 1,#pds do
                            local cur = pds[g]
                            local cdata = data[cur]
                            local cx,cy = mon.getCursorPos()
                            if cy+size > my then break end
                            if peripheral.isPresent(cur) == true and cdata ~= nil then
                                mon.setTextColor(self.theme)
                                bwrite("Power Device "..g..":",1,cy,mon)
                                bwrite("Energy Stored: "..comma_value(cdata["energyStored"]),2,cy+1,mon)
                                local scope
                                if Power_Scope_Modifier ~= nil and Power_Scope_Modifier > 1 then scope = Power_Scope_Modifier else scope = 1 end
                                capi.drawProg(2,cy+2,1,mx-2,cdata["energyStored"],cdata["maxEnergy"]/scope,colors.gray,self.theme,mon)
                                mon.setCursorPos(1,cy+size+1)
                            end
                        end
                    end
                end,
                name = "Power",
                theme = theme_colors.power,
                delete = function()
                    return false
                end,
                cortable = function()
                    return pds_data
                end,
        }
    end
    if #turbs > 0 then
        tabs.turbs = {
            display = function(self,mon,data,mon_name)
                if data == nil then data =  self.cortable() end
                if mon then
                    log(mon_name.." displaying 'pds'",1)
                    local mon = mon
                    local mx,my = mon.getSize()
                    local size = 3 -- size of all the elements of the for loop input not including spacer
                    mon.setTextColor(self.theme)
                    for i = 1,#turbs do
                        local cur = turbs[i]
                        local cdata = data[cur]
                        local cx,cy = mon.getCursorPos()
                        if cy+size > my then break end
                        bwrite("Turbine "..i..": ",1,cy,mon)
                        if cdata["name"] == "DISCONNECTED" then
                            local r = "DISCONNECTED"
                            capi.drawText(mx-#r+1,cy, r, colors.red, nil, mon)
                        elseif cdata["active"] == true then
                            local r = "Running"
                            capi.drawText(mx-#r+1,cy, r, colors.green, nil, mon)
                        elseif cdata["active"] == false then
                            local r = "Halted"
                            capi.drawText(mx-#r+1,cy, r, colors.gray, nil, mon)
                        else
                            local r = "ERROR"
                            capi.drawText(mx-#r+1,cy, r, colors.red, nil, mon)
                        end
                        bwrite("Energy Out: "..cdata.energyOut,1,cy+1,mon)
                        bwrite("RPM: "..cdata.rpm,1,cy+2,mon)
                        mon.setCursorPos(1,cy+size+1)
                    end
                end
            end,
            name = "Turbines",
            theme = theme_colors.turbs,
            delete = function()
                return false
            end,
            cortable = function()
                return turbs_data
            end,
        }
    end
    local tabcount = 0
    for v,k in pairs(tabs) do
        if k ~= "amount" then
            tabcount = tabcount +1
        end
    end
    tabs.amount = tabcount
    log("Tabs registred: ",1)
    for k,v in pairs(tabs) do
        if k ~= "amount" then
            log("  "..k,1)
        end
    end
end



bottomBar = {
    display = function(self,mon,data)
        local lmon = mon
        local lTabs = {
            amount = 0
        }
        if peripheral.isPresent(mon) == true then

            for k,v in pairs(tabs) do
                if k ~= "amount" then
                    if type(monitor_settings[lmon].excludeTabs) ~= "table" then
                        lTabs[k] = tabs[k]
                        lTabs.amount = lTabs.amount +1
                    else
                        if monitor_settings[lmon].excludeTabs[k] == true then
                            --log("monitor_settings for "..lmon.." has tab exlusions!",1)
                            log("monitor_settings for "..lmon.." exludes "..k.." from displaying",1)
                        else
                            lTabs[k] = tabs[k]
                            lTabs.amount = lTabs.amount +1
                        end
                    end
                end
            end

            mon = peripheral.wrap(mon)
            local mX,mY = mon.getSize()
            local temp = math.abs(math.floor( mX /lTabs.amount))
            if temp < lTabs.amount then return end 
            mon.setCursorPos(1,mY)
            local oldbgc = mon.getBackgroundColor()
            local i = 1
            mon.setTextColor(colors.black)
            for k,v in pairs(lTabs) do
                if k ~= "amount" then
                    local tempX,tempY = mon.getCursorPos()
                    local color
                    if v.theme == nil then color = colors.green else color = v.theme end
                    mon.setBackgroundColor(color)
                    mon.write(string.rep(" ",temp+1))
                    mon.setCursorPos( (tempX+(temp/2)+1)-#v.name/2,tempY)                    
                    mon.write(v.name)
                    mon.setCursorPos(tempX+temp+1,tempY)
                end
                i = i + 1
            end
            mon.setBackgroundColor(oldbgc)
        end
    end,
    addButtons = function (self,lmon)
        local lTabs = {
            amount = 0
        }
        buttons[lmon] = {
            default_refresh = {
                maxX = 4,
                minX = 1,
                minY = 1,
                maxY = 4,
                run = function (self)
                    running = false
                    os.queueEvent("key_up",keys.f4)
                end,
                monitor = "all",
                name = "refresh",
                delete = function()
                    return
                end,
            }
        }
        for k,v in pairs(tabs) do
            if k ~= "amount" then
                if type(monitor_settings[lmon].excludeTabs) ~= "table" then 
                    lTabs[k] = tabs[k]
                    lTabs.amount = lTabs.amount +1
                else
                    if monitor_settings[lmon].excludeTabs[k] == true then
                        log("monitor_settings for "..lmon.." exludes "..k.." from creating button",1)
                    else
                        lTabs[k] = tabs[k]
                        lTabs.amount = lTabs.amount + 1
                    end
                end
            end
        end

        local mon = peripheral.wrap(lmon)
        local mX,mY = mon.getSize()
        local temp = math.abs(math.floor(mX/lTabs.amount))
        if temp < lTabs.amount then return end
        mon.setCursorPos(1,mY)
        for k,v in pairs(lTabs) do
                if k ~= "amount" then
                local tempX,tempY = mon.getCursorPos()
                button:createButton(tempX+temp,mY,tempX,mY,
                    function(self)
                        monitor_settings[lmon].currentTab = k
                        os.queueEvent("key_up",keys.f4)
                    end,"TabSwitch".."_"..k.."_"..lmon,lmon,"TabSwitch".."_"..k.."_"..lmon
                )
                mon.setCursorPos(tempX+temp,mY)
            end
        end
    end,
    name = "BottomBar",
    theme = name_color,
    theme2 = motd_color,
    cortable = function()
        return mons
    end,
}
topBar = {
    display = function(self,mon,data)
        if peripheral.isPresent(mon) == true then
            local mon = peripheral.wrap(mon)
            local cx,cy = mon.getCursorPos()
            local mx,my = mon.getSize()
            mon.setTextColor(name_color)
            bwrite(name, mx/2 - (#name/2) + 1 ,cy,mon)
            mon.setTextColor(motd_color)
            bwrite(motd, mx/2 - (#motd/2) + 1 ,cy+1,mon)
            mon.setCursorPos(1,cy+4)
        end
    end,
    name = "TopBar",
    cortable = function()
        return mons
    end,
}

local key_events = {
    p = {
        run = function(self,events)
            reShellTerm()
        end,
        log = false,
    },
}

local reversed_keys = {}

for k,v in pairs(keys) do
    reversed_keys[v] = k
end

local event_list = {
    terminate = {
        run =function(self,events)
            term.clear()
            term.setTextColor(colors.red)
            term.setCursorPos(1,1)
            print("TERMINATING PLEASE WAIT")
            terminate = true
            running = false
            os.queueEvent("key_up",keys.f4)
        end,
        events = {
            "terminate",
        },
        log = true,
    },
    monitor_touch = {
        run = function (self,events)
            button:process(events)
        end,
        events = {
            "monitor_touch"
        },
        log = false,
    },
    peripheral_detach = {
        run = function (self,events)
            running = false
            os.queueEvent("key_up",keys.f4)
        end,
        events = {
            "peripheral_detach"
        },
        log = true,
    },
    key_up = {
        run = function (self,events)
            if events[2] == keys.f5 then
                running = false
                os.queueEvent("key_up",keys.f4)
            elseif key_events[reversed_keys[events[2]]] then
                if key_events[reversed_keys[events[2]]].log == true then log("Running key press "..reversed_keys[events[2]],1) end
                key_events[reversed_keys[events[2]]]:run()
            end
        end,
        events = {
            "key_up"
        },
        log = false,

    },
    panic = {
        run = function (self,events)
            if events[2] == "halt" then
                terminate = true
                running = false
                term.setTextColor(colors.red)
                print("PANIC HALT WAS CALLED")
                os.queueEvent("key_up",keys.f4)
            else
                running = false
            end
        end,
        events = {
            "panic"
        },
        log = true,
    },
    peripheral_attach = {
        run = function ()
            running = false
            os.queueEvent("key_up",keys.f4)
        end,
        events = {
            "peripheral",
        },
        log = true,
    },

}

function readyEvents()
    local required = {
        "events",
        "run",
        "log",
    }
    for k,v in pairs(event_list) do
        if k.events == nil then
            for i = 1,#required do
                if v[required[i]] == nil then
                    event_list[k] = nil
                    log("Removed "..k.." because of missing table variables!",3)
                    log(required[i],3)
                    break
                end
            end
        end
    end
end

function readyKeys()
    local required = {
        "run",
        "log",
    }
    for k,v in pairs(key_events) do
        if k.events == nil then
            for i = 1,#required do
                if v[required[i]] == nil then
                    event_list[k] = nil
                    log("Removed "..k.." because of missing table variable!",3)
                    log(required[i],3)
                    break
                end
            end
        end
    end
end

readyKeys()
readyEvents()
function eventHandler(event)
    --log("eventHandler passed: "..event[1],1)
    for k,v in pairs(event_list) do
        local crnt = v.events
        local count = 0
        if crnt == nil then log(k.." doesnt have any list any call events!",3) else
            local isnt = false
            for i = 1,#crnt do
                if event[i] == crnt[i] then
                    count = count + 1
                else
                    isnt = true
                    break
                end
            end
            if count == #crnt and isnt == false then
                if v.log == true then log("running event "..k,1) end
                v:run(event)
            end
        end
    end
end


if always_load_settings == true then
    loadSettings()
else
    defineSettings()
end

function prepMonitorSettings()
    for i = 1,#mons do
        if monitor_settings[mons[i]] == nil then
            monitor_settings[mons[i]] = {}
        end
        if monitor_settings[mons[i]].currentTab == nil then
            monitor_settings[mons[i]].currentTab = default_monitor_tab
        end
        if monitor_settings[mons[i]].scale == nil then
            monitor_settings[mons[i]].scale = default_monitor_scale
        end
        if monitor_settings[mons[i]].excludeTabs == nil then
            monitor_settings[mons[i]].excludeTabs = {}
        end
    end
end

getMOTD()
reShellTerm()
while terminate == false do
    running = true
    log("refreshing",1)
    autoDetect()
    prep()
    prepMonitorSettings()
    tabDef()

    local wins = {}
    for i = 1,#mons do
        local lmon = peripheral.wrap(mons[i])
        lmon.setCursorPos(1,1)
        topBar:display(mons[i])
        bottomBar:display(mons[i])
        bottomBar:addButtons(mons[i])
        local lmon = peripheral.wrap(mons[i])
        local mx,my = lmon.getSize()
        wins[mons[i]] = window.create(lmon,1,3,mx,my-4)
    end
    
    getInfo()
    while running == true do
        for i = 1,#mons do
            local lmon = peripheral.wrap(mons[i])
            local lwin = wins[mons[i]]
            local mx,my = lmon.getSize()
            lwin.setCursorPos(1,1)
            lwin.setBackgroundColor(colors.black)
            local crntset = monitor_settings[mons[i]]
            local crntmon = mons[i]
            local crnttabstring = monitor_settings[mons[i]].currentTab
            local crnttab = tabs[monitor_settings[mons[i]].currentTab]
            if (crnttabstring ~= monitor_settings[mons[i]].lastTab) and (crnttab ~= nil) then
                log("'"..mons[i].."'".." changed tab to "..crnttabstring,2)
                lwin.clear()
                lwin.setBackgroundColor(colors.black)
                tabbuttons[mons[i]] = {}
                if crnttab.init then crnttab:init(lwin) end
                if crnttab.display then crnttab:display(lwin,nil,mons[i]) end
                monitor_settings[mons[i]].lastTab = crnttabstring
            elseif (crnttabstring == monitor_settings[mons[i]].lastTab) and (crnttab ~= nil) then
                getInfo()
                if crnttab.display then crnttab:display(lwin,nil,mons[i]) end
            else
                log("'"..mons[i].."'".." switched to unknown tab!",3)
            end
        end
        wait(10)
    end
end

if always_load_settings == true then
    capi.tabeSave(monitor_settings,settings_save_file)
end

log("EOF reached",1)
capi.FileManager.CloseCurrentW()

-- You actually scrolled this far down...
