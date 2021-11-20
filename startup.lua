if fs.exists("RPM.lua") == true then
  os.run({},"RPM.lua")
elseif fs.exists("RPM") == true then
  os.run({},"RPM")
else
  print("Your startup file is set to launch RPM but the file is was not found!")
  print("If you just downloaded RPM please try downloading it again...")
  print("Otherwise please delete your startup file!")
end