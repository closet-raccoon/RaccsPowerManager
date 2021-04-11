if fs.exists("RPM.lua") == true then
  os.run({},"RPM.lua")
elseif fs.exists("RPM") == true then
  os.run({},"RPM")
end
