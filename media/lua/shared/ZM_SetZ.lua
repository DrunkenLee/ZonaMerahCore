
local function forceSprint(zombie)
	-- Get zombie position
	local zombieX = zombie:getX()
	local zombieY = zombie:getY()

	-- Define the sprinter area
	local x1, x2 = 838, 3227
	local y1, y2 = 5318, 7468

	-- Check if zombie is within the specified area
	local isInArea = zombieX >= x1 and zombieX <= x2 and zombieY >= y1 and zombieY <= y2

	if isInArea then
		zombie:setWalkType('sprint1')

	end

end

-- Events.OnZombieUpdate.Add(forceSprint)
