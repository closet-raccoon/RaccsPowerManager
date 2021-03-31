-- Installer for RPM
-- Feel free to edit, redistrabute and copy!
local args = ...
local startup

links = {
    RPM = "https://raw.githubusercontent.com/closet-raccoon/RaccsPowerManager/main/RPM.lua",
    API = "https://raw.githubusercontent.com/closet-raccoon/RaccsPowerManager/main/ClosetAPI.lua",
    startup = "https://raw.githubusercontent.com/closet-raccoon/RaccsPowerManager/main/startup.lua",
}

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

function DownloadAll(install_startup_module)
    if not install_startup_module then
        install_startup_module = true
    end

    local RPM_File, ClosetAPI_File, startup_File
    local resp = http.get(links.RPM)
    if resp then
        RPM_File = resp.readAll()
        resp.close()
    end
    local resp = http.get(links.API)
    if resp then
        ClosetAPI_File = resp.readAll()
        resp.close()
    end
    if install_startup_module == true then
        resp = http.get(links.startup)
        if resp then
            startup_File = resp.readAll()
            resp.close()
        end
    end
    return {
        ['RPM'] = RPM_File,
        ['ClosetAPI'] = ClosetAPI_File,
        ['startup'] = startup_File,
    }
end

function SaveDownloads(downloaded_files)
    for k,v in pairs(downloaded_files) do
        if v and type(v) == "string" then
            if tonumber( string.sub( os.version() ,8) ) >= 1.8 then
                k = k..".lua"
            end
            local file = fs.open(k,"w")
            if type(file) == "table" then
                file.write(v)
                file.flush()
                file.close()
            else
                print("Failed to save file "..k)
                print("File returned "..file)
            end
        end
    end
end


if http then
    if fs then
        SaveDownloads(DownloadAll(startup))
    else
        error("fs API not found, is the module loaded?")
    end
else
    error("http API not found, is the module loaded?")
end
