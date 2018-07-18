An = {}
An['mall_fans'] = 2
An['htl_fan_rotate_nt'] = 2
An['htl_fan_rotate_dy'] = 2
An['od_lightbeam'] = 0.05
An['ap_radar1_01'] = 2


Animation = {}
for i,v in pairs(getElementsByType('object')) do
	if An[getElementID(v)] then
		table.insert(Animation,{v,An[getElementID(v)]})
			local xr,yr,zr = getElementRotation(v)
			setElementRotation(v,xr,yr,zr+math.random(1,10))
			local xra,yra,zra = getElementRotation(v)

	end
end



function updateCamera ()
	for i,v in pairs(Animation) do
		local xr,yr,zr = getElementRotation(v[1])
		setElementRotation(v[1],xr,yr,zr+v[2])
		
		if getLowLODElement(v[1]) then
				setElementRotation(getLowLODElement(v[1]),xr,yr,zr+v[2] )
		end
		
		end
	end
addEventHandler ( "onClientRender", root, updateCamera )

