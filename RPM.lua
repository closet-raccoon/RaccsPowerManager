-- V2.4
-- All Rights Reserved, if file bellow is edited in anyway do not redistribute!

-- Settings below are changeable

--[[
Credits (C):
    Steam:      Closet Raccoon
    Discord:    Closet Raccoon#5092  -- Bug reports are welcome
    Minecraft:  ClosetRedPanda
]]
local capi, log
local enable_logging = false  -- Setting to false may inprove performance
local log_to = "right"
local log_file = nil -- not currently in use! 
local Power_Scope_Modifier = nil
local always_load_settings = false -- WARNING this can cause problems if problems are common while restarting the program then delete the save file or set to false!
local settings_save_file = "RPM2_Monitor_Settings"
local default_monitor_scale = 1
local default_monitor_tab = "all"
local monitor_settings
local theme_colors = {
    power = colors.pink,
    reacs = colors.purple,
    turbs = colors.blue,
    all = colors.cyan,
}

local auto_detect = true -- if true then it will auto add all connected peripherals
local mons = {} -- if auto_detect is false use these to add peripherals
local reacs = {}
local pds = {}
local turbs = {}

local name = "Racc's Power Management"
local short_name = "~R-P-M~"
local name_color = colors.blue
local motd = ""
local motd_color = colors.lightBlue
local use_live_motd = false
local motd_link = "https://pastebin.com/raw/rxd5wQFc"
local version = "2.4"
-- Below arnt settings dont change them!

local is112 = not (tonumber(string.sub(os.version(),8)) < 1.79)

if false then     require("ClosetAPI.lua") require("cc os")     end -- Visual Studio
function loadCAPI()  --Closet API
    if is112 == true then
        require("ClosetAPI")
    else

    end
    if capi == nil then error("API was not found") end
end
loadCAPI()


local function defineSettings()
    monitor_settings = {}
end
local startargs = {...}
if startargs[1] == "update" or startargs[1] == "reset" then
    if fs.exists("Downloader.lua") == true then
        os.run({},"Downloader.lua")
    elseif fs.exists("updater.lua") == true then
        os.run({},"updater.lua")
    else
        print("Update files not found")
        print("Would you like to download them? Y/N")
        local event
        repeat
            event = {os.pullEvent()}
            print(event[1].."  "..tostring(event[2]))
        until (event[2] == keys.y or event[2] == keys.n) and event[1] == "key_up"
        if event[2] == keys.y then 
            if http == nil then
                error("Http is not allowed on this computer!")
                return "Http is not allowed on this computer!"
            end
            
            local link = "https://raw.githubusercontent.com/closet-raccoon/RaccsPowerManager/main/Downloader.lua"
            print("Connecting and downloading")
            local resp,err1 = http.get(link)
            if resp == nil then 
                term.setTextColor(colors.red)
                print("An error occoured while connecting its possible you arnt connected to the internet!")
                error(tostring(err1))
                term.setTextColor(colors.white)
             end
            local script = resp.readAll()
            local installer, err2 = load(script)
            if installer and not (err1 or err2) then
                print("Download completed")
                installer()
            else
                error(err1.."  "..err2)
            end
        end
    end 
    print("update complete rebooting")
    sleep(.5)
    os.reboot()
end

terminate = false
running = true

term.setTextScale = function() end -- Fixes the only thing that monitors can do that computers will error on
local log_to_original_input


local function prepDebugMon()
    if peripheral.isPresent(log_to) == true then
        local temp = peripheral.wrap(log_to)
        temp.clear()
        temp.setCursorPos(1,0)
        return temp
    end
end
local function preplog()
    if log_to == term or log_to == "term" then
        log_to = nil
    end
    local l = prepDebugMon()
    log = capi.APIdebug:prepLog(enable_logging,l,nil,nil,nil)
    log("Log output is ready",1)
end
preplog()

log("Logging is enabled",1)

local function loadSettings()
    local temp = capi.tableLoad(settings_save_file)
    if type(temp) == "table"  then
        monitor_settings = temp
    else
        log("File, "..settings_save_file.." ,was not able to load!",3)
    end
end

local function getMOTD()
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

local function autoDetect()
    log("Running autoDetect()",1)
    local d = capi.getAllPeripherals()
    if d == {} or d == nil or type(d) ~= "table" then
        log("autoDetect returned nothing",4)
    else
        turbs = d.turbs or {}
        reacs = d.reacs or {}
        pds = d.pds or {}
        mons = d.mons or {}
    end
end

local reacs_data = {}
local pds_data = {}
local mons_data = {}
local turbs_data = {}
local preacs,ppds,pturbs,pmons

local function wrapedTables(tab,wrapname)
    log("Wraping and preping "..tostring(tab),1)
    local temp = {}
    for i = 1,#tab do
        if peripheral.isPresent(tab[i]) == false then
            log("'"..tab[i].."' Not found, Removing",2)
            table.remove(tab,i)
        else
            temp[tab[i]] = peripheral.wrap(tab[i])
        end
    end
    return temp
end
local function prep()
    log("running prep()",1)
    log("Removing faulty peripherals",1)
    pmons = {}
    for i = 1,#mons do
        if mons[i] ~= nil then
            if peripheral.isPresent(mons[i]) == false then
                log("'"..mons[i].."' Not found, Removing",2)
                table.remove(mons,i)
            elseif mons[i] == log_to and enable_logging == true then 
                log("'"..mons[i].."' is debug mon, Removing",2)
                table.remove(mons,i)
            else
                pmons[mons[i]] = peripheral.wrap(mons[i])
            end
        end
    end
    preacs = wrapedTables(reacs)
    ppds = wrapedTables(pds)
    pturbs = wrapedTables(turbs)
end

local function totalTable(intable)
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
            local crnt = ppds[pds[i]]
            a = crnt.getEnergyStored()
            b = crnt.getEnergyCapacity or crnt.getMaxEnergyStored
            b = b()
 
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
            local crnt = preacs[reacs[i]]
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
            local crnt = pturbs[turbs[i]]
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


local getInfo
if is112 == false then
    log("MC version is lower then 1.12",1)
    getInfo = getInfo1710
elseif is112 == true then
    log("MC version is 1.12 or higher",2)
    getInfo = getInfo1710
else
    log("is112 wasnt true or false?",5)
end




local function bwrite(text,x,y,mon,clear)
    if mon == nil or type(mon) ~= "table" then log("Basic write got bad mon variable",2) return end
    mon.setCursorPos(x,y)
    if clear == true then mon.clearLine() end
    mon.write(text)
end

local function comma_value(amount,places) --stolen right off 'http://lua-users.org/wiki/FormattingNumbers'
    places = places or 2
    local formatted = math.floor(amount*10^places)/10^places
    while true do  
      formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
      if (k==0) then
        break
      end
    end
    return formatted
end

local function reShellTerm()
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

local function wait ( time ) -- Idea stolen wiki to allow for events to handle during sleep timers without using parallel
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
local function tabDef()
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
                        local size = self.size 

                        for g = 1,#reacs do
                            local cur = reacs[g]
                            local cdata = data[cur]
                            if peripheral.isPresent(cur) == true and cdata ~= nil then
                                local cx,cy = mon.getCursorPos()
                                if cy+size > my then log("Cant fit all reacs on monitor "..mon_name.."! \n Failed on "..cur,3) break end
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
                size = 4,
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
                        local size = self.size -- size of all the elements of the for loop input not including spacer
                        for g = 1,#pds do
                            local cur = pds[g]
                            local cdata = data[cur]
                            local cx,cy = mon.getCursorPos()
                            if cy+size > my then log("Cant fit all pds on monitor "..mon_name.."! \n Failed on "..cur,3) break end
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
                size = 3,
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
                    local size = self.size  -- size of all the elements of the for loop input not including spacer
                    mon.setTextColor(self.theme)
                    for i = 1,#turbs do
                        local cur = turbs[i]
                        local cdata = data[cur]
                        local cx,cy = mon.getCursorPos()
                        if cy+size > my then log("Cant fit all turbs on monitor "..mon_name.."! \n Failed on "..cur,3) break end
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
            size = 3,
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
    for k,v in pairs(tabs) do
        if k ~= "amount" then
            if v.display and v.name and v.theme then
                log("Checked '"..k.."' and it has all required entires",1)
                tabcount = tabcount +1
            else
                log("'"..k.."' Is missing key entires removing",3)
                tabs[k] = nil
            end
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


local bottomBar = {
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

            mon = pmons[mon]
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

        local mon = pmons[lmon]
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
local topBar = {
    display = function(self,mon,data)
        if peripheral.isPresent(mon) == true then
            local mon = pmons[mon]
            local _,cy = mon.getCursorPos()
            local mx,_ = mon.getSize()
            mon.setTextColor(name_color)
            bwrite(name, mx/2 - (#name/2) + 1 ,cy,mon,true)
            mon.setTextColor(motd_color)
            bwrite(motd, mx/2 - (#motd/2) + 1 ,cy+1,mon,true)
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
    f5 = {
        run = function(self,events)
            running = false
            os.queueEvent("key_up",keys.f4)
        end,
        log = false,
    },
    f9 = {
        run = function(self,events)
            log("test panic",5)
        end,
        log = true,
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
        log = true,

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
                term.setTextColor(colors.red)
                print("PANIC WAS CALLED ESCAPING!")
                log("Due to panic force escaping!",2)
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
            "peripheral_detach"
        },
        log = true,
    },
    execute = {
        run = function(self,events)
            local script = load(events)
            local resp = {pcall(script)}
            log("Execute: "..tostring(resp[1]).."  Result: "..tostring(resp[2]))
            --os.queueEvent("exer",resp[1],resp[2])
        end,
        events = {
            "exe",
            "exc",
            "execute"
        },
        log = true,
    }

}

local function readyEvents()
    local required = {
        "events",
        "run",
        "log",
    }
    for k,v in pairs(event_list) do
        if v.events ~= nil then
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

local function readyKeys()
    local required = {
        "run",
        "log",
    }
    for k,v in pairs(key_events) do
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

readyKeys()
readyEvents()
function eventHandler(event)
    --log("eventHandler passed: "..event[1],1)
    for k,v in pairs(event_list) do
        local crnt = v.events
        local count = 0
        if crnt == nil then log(k.." doesnt have any list any call events!",3) else
            for i = 1,#crnt do
                if event[1] == crnt[i] then
                    if v.log == true then log("running event "..k,1) end
                    v:run(event)
                    break
                end
            end
        end
    end
end


if always_load_settings == true then
    loadSettings()
else
    defineSettings()
end

local function prepMonitorSettings()
    for i = 1,#mons do
        monitor_settings[mons[i]] = monitor_settings[mons[i]] or {}
        monitor_settings[mons[i]].currentTab = monitor_settings[mons[i]].currentTab or default_monitor_tab
        monitor_settings[mons[i]].scale = monitor_settings[mons[i]].scale or default_monitor_scale
        monitor_settings[mons[i]].excludeTabs = monitor_settings[mons[i]].excludeTabs or {}
    end
end

getMOTD()
reShellTerm()
while terminate == false do -- "Escape" step
    running = true
    log("Entering loop")
    if auto_detect == true then
        autoDetect()
    end
    prep()
    prepMonitorSettings()
    tabDef()
    
    local wins = {}
    for i = 1,#mons do
        local lmon = pmons[mons[i]]
        lmon.setCursorPos(1,1)
        topBar:display(mons[i])
        bottomBar:display(mons[i])
        bottomBar:addButtons(mons[i])
        local lmon = pmons[mons[i]]
        local mx,my = lmon.getSize()
        wins[mons[i]] = window.create(lmon,1,3,mx,my-4)
    end
    p=0
    --getInfo()
    while running == true do -- Display loop
        p = p+1
        getInfo()
        for i = 1,#mons do
                                -- theres no need to wrap the perpheral here cause we use windows now
            local cmon = mons[i]
            local lwin = wins[cmon]
            lwin.setCursorPos(1,1)
            lwin.setBackgroundColor(colors.black)

             -- setting up args to reduce refering to large tables
            local crnttabstring = monitor_settings[cmon].currentTab
            local crnttab = tabs[monitor_settings[cmon].currentTab] -- The tabs table, for example in "all" it would hold the display class important other information
            local crntlasttab = monitor_settings[cmon].lastTab

            if (crnttabstring ~= crntlasttab) and (crnttab ~= nil) then
                log("'"..cmon.."'".." changed tab to "..crnttabstring,2)
                lwin.setBackgroundColor(colors.black)
                lwin.clear()
                if crnttab.init then crnttab:init(lwin) end     -- Not currently used but can be used to add buttons and make other things run before the tab is displayed
                crnttab:display(lwin,nil,cmon) -- Actually displays information!
                monitor_settings[cmon].lastTab = crnttabstring
            elseif (crnttabstring == crntlasttab) and (crnttab ~= nil) then
                crnttab:display(lwin,nil,cmon)
            else
                log("'"..cmon.."'".." switched to unknown tab!",3)
            end
        end
        wait(10)
    end
    wins = nil
    log("Escaped loop, clearing windows",2)
end

if always_load_settings == true then
    capi.tableSave(monitor_settings,settings_save_file)
end

log("EOF reached",1)
capi.FileManager.CloseCurrentW()
term.clear()
term.setCursorPos(1,1)
term.setTextColor(name_color)
print(name.."  "..version)
term.setTextColor(colors.white)
if capi.APIdebug.panics then
    for i = 1,#capi.APIdebug.panics do
        print("Panic "..i..": "..capi.APIdebug.panics[i])
    end
else
    print("Panics table is nil?")
end

-- You actually scrolled this far down...