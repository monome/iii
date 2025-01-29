slew.init()

test = function()
	slew.new(print,3,80,1000,1)
end

px = {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1}

skid = function(x,y)
	grid_led(px[y],y,0)
	grid_led(x,y,5)
	px[y] = x
	grid_refresh()
end

sl = {}

grid = function(x,y,z)
	if z==1 then
		if(sl[y]) then slew.stop(sl[y]) end
		sl[y]=slew.new(function(a) skid(a,y) end,px[y],x,500)
	end
end
