-- Installer for RPM
-- Feel free to edit, redistrabute and copy!

local args = ...

local use_live_file_list = true
local link_location = "https://raw.githubusercontent.com/closet-raccoon/RaccsPowerManager/main/filelist"
local links, startup

if not os.version then
    print("WHERES COMPUTERCRAFT.... WHAT HAVE YOU DONE!")
    print("This script only functions on computercraft for minecraft!")
    return "This is not computercraft"
end

if type(args) == "table" then
    if args[1] == "help" then
        print("Download RPM files and APIs")
        print("Argument 1 is a boolean ( True of False ),")
        print(" on whether or not it should install it with a startup.lua")
        print("By default it installs as startup!")
    end

    if args[1] == "" or args[1] == nil or args[1] == "true" then
        print("Installing has startup!")
        startup = true
    elseif args[1] == false then
        print("Installing without startup!")
        startup = false
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
        print("Using hard coded links!")
        return {
            RPM = "https://raw.githubusercontent.com/closet-raccoon/RaccsPowerManager/main/RPM.lua",
            ClosetAPI = "https://raw.githubusercontent.com/closet-raccoon/RaccsPowerManager/main/ClosetAPI.lua",
            startup = "https://raw.githubusercontent.com/closet-raccoon/RaccsPowerManager/main/startup.lua",
        }
    else
        local resp = http.get(link_location)
        if type(resp) == "table" then
            local data = resp.readAll()
            resp.close()
            local finished = textutils.unserialize(data)
            if finished == nil or type(finished) ~= "table" then
                print("Was not able to download links from "..link_location)
                print("Will continue with hard coded links!")
                return {
                    RPM = "https://raw.githubusercontent.com/closet-raccoon/RaccsPowerManager/main/RPM.lua",
                    ClosetAPI = "https://raw.githubusercontent.com/closet-raccoon/RaccsPowerManager/main/ClosetAPI.lua",
                    startup = "https://raw.githubusercontent.com/closet-raccoon/RaccsPowerManager/main/startup.lua",
                }
            else
                print("Found links from"..link_location)
                return finished
            end
        end
    end
end

links = getLinks()

function DownloadAll(install_startup_module)
    local files = {}
    if not install_startup_module then
        install_startup_module = true
    end

    for k,v in pairs(links) do
        if ((k == "startup" and install_startup_module == true) or k ~= "startup") and  type(k) == "string"   then
            print("Downloading "..k.." from ")
            printlink("'"..v.."'")
            local data
            local resp = http.get(v)
            if resp then data = resp.readAll() end
            files[k] = data
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
    error("http API not found, is the module loaded?")
end
