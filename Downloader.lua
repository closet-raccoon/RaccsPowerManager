-- Installer for RPM
-- Feel free to edit, redistrabute and copy just dont remove line below!
-- Downloader By ClosetRedPanda aka ClosetRaccoon

local args = {...}
local AppName = "RPM" -- Used when changing args and ect..


local use_live_file_list = true  --if you want to use this your self then change the link below to a sterilized table of links to download..-
-- like seen on that site below. also dont forget to change the list of hardcoded links!

local link_location = "https://raw.githubusercontent.com/closet-raccoon/RaccsPowerManager/main/filelist"
local hardlinks = { -- ONLY USED WHEN HTTP REQUEST DROPS!
    RPM = "https://raw.githubusercontent.com/closet-raccoon/RaccsPowerManager/main/RPM.lua",
    ClosetAPI = "https://raw.githubusercontent.com/closet-raccoon/RaccsPowerManager/main/ClosetAPI.lua",
    startup = "https://raw.githubusercontent.com/closet-raccoon/RaccsPowerManager/main/startup.lua",
}
local latestbranch = "https://pastebin.com/raw/u4PDfDHv"  -- used when arg latest is used

local links, startup

if not os.version then
    print("WHERES COMPUTERCRAFT.... WHAT HAVE YOU DONE!")
    print("This script only functions on computercraft for minecraft!")
    return "This is not computercraft"
end
if not http then
    error("HTTP is not enabled in this servers config")
end

if type(args) == "table" then
    if args[1] == "help" then
        print("For args put:")
        print(" True to install the startup.lua file to launch RPM on startup")
        print(" False to not install startup.lua")
        print(" OR put latest to install the latest branch off github")
 
    end

    if args[1] == "" or args[1] == nil or args[1] == "true" then
        print("Installing has startup!")
        startup = true
    elseif args[1] == false then
        print("Installing without startup!")
        startup = false
    end
    if args[1] == "latest" then
        link_location =  latestbranch
    end
else
    startup = true
end

local color = term.isColor() == true

function printlink(link)
    local oldc = term.getTextColor()
    if color == true then
        term.setTextColor(colors.lightBlue)
    end
    print(link)
    term.setTextColor(oldc)
end

function getLinks()
    if use_live_file_list == false or type(link_location) ~= "string" then
        local temp = term.getTextColor()
        term.setTextColor(colors.red)
        print("Using hard coded links!")
        term.setTextColor(temp)
        return hardlinks
    else
        local resp = http.get(link_location)
        if type(resp) == "table" then
            local data = resp.readAll()
            resp.close()
            local finished = textutils.unserialize(data)
            if finished == nil or type(finished) ~= "table" then
                print("Was not able to download links from "..link_location)
                print("Will continue with hard coded links!")
                return hardlinks
            else
                print("Found links from"..link_location)
                return finished
            end
        else
            print("Something happened to the HTTP request to get the files...")
            print("the reply from the HTTP request wasn't a table")
            print("Please check your connection and try again later")
            print("Otherwise theres no logic explanation for this error")
        end
    end
end

links = getLinks()

function DownloadAll(ism)
    local files = {}  -- so we can add to the tabnle in the loop below
    ism = ism or true -- install_startup_module

    for k,v in pairs(links) do
        if ((k == "startup" and ism == true) or k ~= "startup") and  type(k) == "string"   then
            print("Downloading "..k.." from ")
            printlink("'"..v.."'")
            local data
            local resp = http.get(v)
            if resp then data = resp.readAll() end
            files[k] = data
        elseif k== 'startup' then
            print("didn't download startup because of set args!")
        else
           term.write("Could not download data for '"..k.."' with link")
           printlink("'"..v.."'")
        end
    end
    return files
end

function SaveDownloads(downloaded_files)
    local ver_high = tonumber( string.sub( os.version(), 8 ) ) >= 1.8
    if ver_high == true then print("You are on version 1.8 or higher of ComputerCraft, using .lua files") end

    for k,v in pairs(downloaded_files) do
        if v and type(v) == "string" then
            if ver_high == true then  --Version check
                k = k..".lua"
            end
            local file = fs.open(k,"w") --Opening and saving to file
            if type(file) == "table" then
                file.write(v)
                file.flush()
                file.close()
                print("Saved to "..k)
            else
                print("Failed to save file "..k)
                print("File returned "..file)
            end
        end
    end
end


if http then
    if fs then
        print("Downloading RPM!")
        SaveDownloads(DownloadAll(startup))
    else
        error("fs API not found, is the module loaded?")
    end
else
    error("http API not found, is the module loaded? Its posible it was disabled in server config!")
end


return true