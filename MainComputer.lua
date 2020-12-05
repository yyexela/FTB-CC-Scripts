--Print output from various computer to the display
 
--Global variables
local lines = 19 --Used to specify monitor height
 
--Get monitor object
local monitor = peripheral.wrap("right")
 
--Reset display
monitor.clear()
monitor.setCursorPos(1,1)
monitor.write("Running")
 
--Set cursor to last line
monitor.setCursorPos(1,lines)
 
--Set up rednet using protocol and name 'base'
rednet.open("left")
rednet.host("base","base")
 
--Print incoming messages
while true do
    id, message, prot = rednet.receive()
    if prot ~= "dns" then
        --Extract message type and number
        local type = string.sub(prot,1,3)
        local num = string.sub(prot,4,4)
        --Print message
        monitor.scroll(1)
        monitor.setCursorPos(1,lines)
        monitor.write("#"..num.."["..type.."]"..":")
        monitor.write(message)
    end
end