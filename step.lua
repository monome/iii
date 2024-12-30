print("step")

ch = 0
step = 1
last = 0
note = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
map = {66,68,70,72,74,76,78,80,82,84,86,88,90,92,94,96}

-- change this to toggle clock input:
midi_clock_in = true

tick = function()
	if last > 0 then midi_note_off(map[last]) end
	step = (step % 16) + 1
	last = note[step]
	if last > 0 then midi_note_on(map[last]) end
	redraw()
end

metro = function(index, count)
	tick()
end

grid = function(x,y,z)
	if z==0 then return end
	if y==0 then
		-- top row
	else
		x = x+1
		if note[x] == y then note[x] = 0
		else note[x] = y end
		redraw()
	end
end

redraw = function()
	grid_led_all(0)
	grid_led(step-1,0,5)
	for n=1,16 do
		if note[n] > 0 then
			grid_led(n-1,note[n],step==n and 15 or 5)
		end
	end
	grid_refresh()
end

ticks = 0

midi_rx = function(d1,d2,d3,d4)
	if d1==8 and d2==240 then
		ticks = ((ticks + 1) % 12)
		if ticks == 0 and midi_clock_in then tick() end
	else
		ps("midi_rx %d %d %d %d",d1,d2,d3,d4)
	end
end


if not midi_clock_in then
	-- 150ms per step
	metro_set(1, 150)
end

redraw()
