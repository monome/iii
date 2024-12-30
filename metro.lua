print("metro test")
grid_led_all(0)
grid_refresh()

blink = 0

metro = function(index, count)
	if index==3 then 
		grid_led(0,0,blink)
		blink = 10 - blink
	else
		grid_led(count,index,3)
	end
	grid_refresh()
end

metro_set(1, 100, 6)
metro_set(2, 50, 12)
metro_set(3, 333)
