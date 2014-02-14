if not arg[1] then error "No template file given." end
print("Generating tf2items configuration from "..arg[1])
local finishedFile = ""
function rcon(host,port,password,command)
  require'socket'
  c=assert(socket.connect(host,port))
  tmp="12340003"..password.."\0\0"
  size=tostring(#tmp)
  while #size<4 do
    size=size.."\0"
  end
  c:send(size..tmp)
  packetsize=c:receive(4)
  packetid=c:receive(4)
  packettype=c:receive(4)
  data=c:receive(size-9) -- -4 for the id, -4 for the type, and -1 for the next part
  c:receive(1) -- get rid of the useless null byte at the end
  if packettype==2 and packetid==-1 then 
    error"Invalid rcon info" 
    return false
  else
    tmp="12340002"..command.."\0\0"
    size=tostring(#tmp)
    while #size<4 do
      size=size.."\0"
    end
    c:send(size..tmp)
    return true
  end
end
local defines={}
function parse(file)
  local out=""
  for line in io.lines(file) do
    if line:match("[ \t]+#inc \"(.+)\"") then -- #inc
      print("included file: "..line:match("[ \t]+#inc \"(.+)\""))
      out=out..parse(line:match("[ \t]+#inc \"(.+)\""))
    elseif line:match("[ \t]+#lua (.+)") then -- #lua 
      local code=line:match("[ \t]+#lua (.+)")
      print("running lua code: "..code)
      local f,err=loadstring(code)
      if err then print("Error in #lua statement: "..err) os.exit(1) end
      s,r=pcall(f)
      if s==false then print("Error in #lua statement: "..r) os.exit(1) end
      out=out..(r or "").."\n"
    elseif line:match("[ \t]+#define ([%l%d_]+) (.+)") then -- #define
      local var,val=line:match("[ \t]+#define ([%l%d_]+) (.+)")
      print("Defining variable "..var.." as "..val)
      defines[var]=val
    else
      for k,v in pairs(defines) do
        if line:find(k) then
            line,count=string.gsub(k,v)
            print("Replaced "..count.." occurences of "..k.." with "..v)
        end
      end
      out=out..line.."\n"
    end
  end
  return out
end
finishedFile=parse(arg[1])
print("Done generating output.")
os.remove("tf2items.weapons.txt")
f=io.open("tf2items.weapons.txt","w")
f:write(finishedFile)
f:close()
print'Now attempting to autoload the new config.'
print"or not because i tested it and it does not work"
