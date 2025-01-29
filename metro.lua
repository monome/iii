print("metro test")
grid_led_all(0)
grid_refresh()

blink = 0

c = function(x,y)
	grid_led_rel(x,y,2)
	grid_refresh()
end

b = function()
	blink = 1-blink
	grid_led(1,1,blink*15)
	grid_refresh()
end

bb = metro.new(b,250)

c1 = metro.new(function(x) c(x,2) end, 100, 11)
c2 = metro.new(function(x) c(x,3) end, 270, 15)
c3 = metro.new(function(x) c(x%16,4) end, 220, 33)
c4 = metro.new(function(x) c(x%12,5) end, 70, 111 )
