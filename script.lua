-- Variables for fuel starve simulation, can be customized to match a car.
-- Note: Requires VERSION=extended-2 in car.ini's HEADER section to work.
-- Basic settings --
local highgmaxtime=2.6	--average time in seconds beyond high G threshold when fuel starvation will happen.
local highgmaxtime_variance=0.15 --multiplier by which the high G time can be randomized in either direction
local fuelstarvemaxgs=0.9 --High G threshold beyond which fuel starvation can start, any axis but vertical. Most fuel tanks don't starve equally in any direction like this but it's a decent compromise. Will get worse as the level decreases further by default so don't set it too low! Recommend using the Car Physics app and not the G Meter as a gauge for testing.
local fuelstarvelitres=6.00 --fuel starvation can start below this many litres remaining in the tank.
local fuelstarvewait=0.25 -- minimum time fuel will be cut off for when fuel starve happens, in seconds. Must fall below fuelstarvemaxgs for this long for fuel to return. 0.25~1 recommended, a realistic maximum for a really bad tank might be 2-3.  Not important with quickfuelreturn=true
-- Advanced settings --
local quickfuelreturn = false --set to true for instant fuel return when Gs fall below threshold, if false wait for fuelstarvewait. False is good for use with smaller fuelstarvewait values, with larger values the fuel may take a while to get back to the pickup, like with a foam-filled unbaffled tank. A long high G max time combined with a 2-3sec fuelstarvewait and quickfuelreturn=false may simulate a street-tank-into-surge-tank setup where fuel takes a long time to starve but is slow to return if it does. Quickfuelreturn=true would simulate a foam-free unbaffled tank with a good pick-up or a relatively small Hydramat.
local worsenwithlevel = true --set to true and fuel starvation will worsen as fuel gets lower, happening at half the G threshold near totally empty. Otherwise it's constant. May only want to set this false with a multi-lift-pump surge tank setup.
local highgmaxtime_variance=0.15 --multiplier by which the high G time can be randomized in either direction
--next 3 need to be at 0 for script to work! Counters etc
local fuelstarvetimer = 0 --fuel starvation time counter, leave at 0!
local highgtimecounter = 0 --time at high Gs counter, leave at 0!
local highgmaxtime_adjuster=0; --random adjustment to high G time counter, leave at 0!
-- end fuel starve vars


function script.update(dt)
-- fuel starve simulation, the code in this function can be added into an existing script.update(dt) loop
	local data = ac.accessCarPhysics()
	if car.fuel < fuelstarvelitres then
		if worsenwithlevel and car.fuel > 0 then
			adjustedmaxgs=fuelstarvemaxgs * (((car.fuel / fuelstarvelitres) + 1) / 2)
		else
			adjustedmaxgs=fuelstarvemaxgs
		end
		if math.abs(data.gForces.x) > adjustedmaxgs or math.abs(data.gForces.y) > adjustedmaxgs then --counts up starve timer once you stay fuelstarvemaxgs from the center of the friction circle
			--car has exceeded high G threshold
			highgtimecounter = highgtimecounter + dt
		else
			--car has fallen back inside G threshold
			highgtimecounter = 0
			if quickfuelreturn then
				fuelstarvetimer = 0
			end
		end

		if highgtimecounter > highgmaxtime+highgmaxtime_adjuster then
			--time beyond G threshold exceeded, begin fuel starvation
			fuelstarvetimer = fuelstarvewait
			--randomize the next starve timer here
			highgmaxtime_adjuster=highgmaxtime * math.random((highgmaxtime * highgmaxtime_variance*-1),(highgmaxtime * highgmaxtime_variance)) --this can cause some sputtering as fuel begins to starve which is realistic for most setups
		end

		if fuelstarvetimer > 0 then
			-- While starving for fuel, lock gas pedal at 0
			fuelstarvetimer = fuelstarvetimer - dt
			data.gas = 0
		end
	end
end
