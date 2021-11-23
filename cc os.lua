-- DO NOT RUN THIS FILE ON A COMPUTER
-- ITS JUST HERE TO DEFINE FIELDS!

os = os or {}

function os.pullEventRaw(filter) end
function os.pullEvent(filter) end
---@vararg string
---@param event string
---@return nil
function os.queueEvent(event,...) end
function os.reboot() end
function os.run(env,filename) end
function os.unloadAPI(APIname) end
---@return table
function os.loadAPI(Filename) end
---@return number
function os.version() end
---Returns timer code
---@return number
---@param timeout number
function os.startTimer(timeout) end
