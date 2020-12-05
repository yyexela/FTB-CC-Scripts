--Connect to base
rednet.open("left")
local base = rednet.lookup("base","base")
 
--Global vars
local strip_size = 14
local strip_space = 2
local strips_done = 0
local dir = "left"
local fuel_err = 0
 
--Unique turtle number
local num = 0
 
--Functions
--Check to see if turtle has enough coal to make a strip forward and backward
--RETURN: true if turtle has enough coal to make a strip loop
local function GetCoal()
    local count = 0
    for i = 1,16 do
        item = turtle.getItemDetail(i)
        if item and item.name == "minecraft:coal" then
            count = count + turtle.getItemCount(i)
        end
    end
    return count
end
 
--Calculate if we can mine another strip loop
local function CanMine()
    local coal = GetCoal()
    local fuel = 80 * coal + turtle.getFuelLevel()
    local movement = 0
    if strips_done == 0 then
        --First loop
        movement = 1 + 3*(strip_size * 2 + strip_space * 2 + 3) + 4
    else
        --Every other loop
        movement = strip_size + strip_space * (strips_done+1) * 2 + 2 * (strips_done + 1) + 3*(strip_size + strip_space * (strips_done + 1) + 2) + 4
    end
    print("Fuel "..tostring(fuel)..", coal "..tostring(coal))
    if fuel < movement then
        rednet.send(base, "Need coal ("..tostring((movement-fuel)/80+1)..") for strip "..tostring(strips_done+1), "err"..tostring(num))
        return false
    else
        return true
    end
end
 
--Refuel turtle
local function Refuel()
    for i = 1,16 do
        item = turtle.getItemDetail(i)
        if item and item.name == "minecraft:coal" then
            fuel_err = 0
			turtle.select(i)
            turtle.refuel(1)
            return
        end
    end
    if fuel_err == 0 then
        rednet.send(base, "Error when refueling, fuel: "..turtle.getFuelLevel(), "err"..tostring(num))
    end
    fuel_err = 1
end
 
--Move forward one block
local function MoveOne()
    if(turtle.getFuelLevel() < 80) then
        Refuel()
    end
    --Check if a block is in front
    while turtle.detect() do
        --Block in front
        turtle.dig()
    end
    turtle.forward()
    --Check for block up which isn't a torch
    local succ,item = turtle.inspectUp()
    while succ and item.name ~= "minecraft:torch" and item.name ~= "minecraft:lava" and item.name ~= "minecraft:flowing_lava" and item.name ~= "minecraft:water" and item.name ~= "minecraft:flowing_water" do
        turtle.digUp()
		succ,item = turtle.inspectUp()
    end
end
 
--Turn direction
local function Turn()
    if dir == "right" then
        turtle.turnRight()
    elseif dir == "left" then
        turtle.turnLeft()
    end
end
 
local function EmptyInv()
    local err,item = turtle.inspectDown()
    if(item.name ~= "minecraft:chest" and item.name ~= "ironchest:iron_chest") then
        rednet.send(base, "No chest detected", "err"..tostring(num))
    else
        for i = 1,16 do
			turtle.select(i)
            item = turtle.getItemDetail(i)
            if item and item.name ~= "minecraft:coal" then
                turtle.dropDown()
            end
        end
    end
end
 
--Assuming turtle is placed on top of a chest
--Make a strip-mine loop in direction
--RETURN: nothing
local function StripMine()
    while CanMine() do
        --First line
        for i=1,(strip_size+1) do
            MoveOne()
        end
        Turn()
        --Second line
        for i=1,((strips_done+1)*2+(strips_done+1)) do
            MoveOne()
        end
        Turn()
        --Third line
        for i=1,(strip_size+1) do
            MoveOne()
        end
        Turn()
        --Fourth line
        for i=1,((strips_done+1)*2+(strips_done+1)) do
            MoveOne()
        end
        Turn()
        --Fill chest
        EmptyInv()
		strips_done = strips_done + 1
        rednet.send(base, "Finished strip "..strips_done, "log"..tostring(num))
    end
end
 
--Attempt to connect to base
if base then
    --Connected to base
    print("Found base on rednet")
    rednet.send(base, "Connected", "log"..tostring(num))
	--Empty inventory first
	EmptyInv()
    --Run strip mining function
    StripMine()
else
    print("Unable to find base on rednet")
end