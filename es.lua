print("early earthsea")
print("- left column sets midi channel")

grid_led_all(0)
grid_led(0,0,3)
grid_refresh()

ch = 0

grid = function(x,y,z)
	if x==0 then
		if z then
			grid_led(0,ch,0)
			ch=y
			grid_led(0,ch,3)
			grid_refresh()	
		end
	else
		note = x + (7-y)*5 + 50
		midi_tx(0, 0x90+ch, note, z*127)
		grid_led(x,y,z*15)
		grid_refresh()
	end
end
