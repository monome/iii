grid_led_all(0)
grid_refresh()

grid = function(x,y,z)
	grid_led(x,y,z*3+1)
	grid_refresh()
end
