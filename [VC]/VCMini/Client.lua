Display = {};
Display.Width, Display.Height = guiGetScreenSize();

	local widthA = (1/1024)*Display.Width
	local heightA = (1/768)*Display.Height
	
Minimap = {};
Minimap.Width = (259)*heightA ;
Minimap.Height = (139)*heightA;
Minimap.PosX = (20/1024)*Display.Width;
Minimap.PosY = (((Display.Height - 20) - Minimap.Height)/768)*Display.Height;

Minimap.IsVisible = true;
Minimap.TextureSize = radarSettings['mapTextureSize'];
Minimap.NormalTargetSize, Minimap.BiggerTargetSize = Minimap.Width, Minimap.Width * 2;
Minimap.MapTarget = dxCreateRenderTarget(Minimap.BiggerTargetSize, Minimap.BiggerTargetSize, true);
Minimap.RenderTarget = dxCreateRenderTarget(Minimap.NormalTargetSize * 3, Minimap.NormalTargetSize * 3, true);
Minimap.MapTexture = dxCreateTexture(radarSettings['mapTexture']);

Minimap.CurrentZoom = 5;
Minimap.MaximumZoom = 10;
Minimap.MinimumZoom = 2;

Minimap.WaterColor = radarSettings['mapWaterColor'];
Minimap.Alpha = radarSettings['alpha'];
Minimap.PlayerInVehicle = false;
Minimap.LostRotation = 0;
Minimap.MapUnit = Minimap.TextureSize / 6000;

Bigmap = {};
Bigmap.Width, Bigmap.Height = Display.Width - 40, Display.Height - 40;
Bigmap.PosX, Bigmap.PosY = 20, 20;
Bigmap.IsVisible = false;
Bigmap.CurrentZoom = 2;
Bigmap.MinimumZoom = 0.2;
Bigmap.MaximumZoom = 5;

Stats = {};
Stats.Bar = {};
Stats.Bar.Width = Minimap.Width;
Stats.Bar.Height = 10;

local playerX, playerY, playerZ = 0, 0, 0;
local mapOffsetX, mapOffsetY, mapIsMoving = 0, 0, false;



function isCursorOnElement(x,y,w,h)
	local mx,my = getCursorPosition ()
	local fullx,fully = guiGetScreenSize()
	cursorx,cursory = mx*fullx,my*fully
	if cursorx > x and cursorx < x + w and cursory > y and cursory < y + h then
		return true
	else
		return false
	end
end

addEventHandler('onClientResourceStart', resourceRoot,
	function()
		setPlayerHudComponentVisible('radar', false);
		
		if (Minimap.MapTexture) then
			dxSetTextureEdge(Minimap.MapTexture, 'border', tocolor(Minimap.WaterColor[1], Minimap.WaterColor[2], Minimap.WaterColor[3], 255));
		end
	end
);

addEventHandler('onClientKey', root,
	function(key, state) 
		if (state) then
			if (key == 'F11') then
				cancelEvent();
				Bigmap.IsVisible = not Bigmap.IsVisible;
				showCursor(false);
				
				if (Bigmap.IsVisible) then
					setPlayerHudComponentVisible('radar', false);
					showChat(false);
					playSoundFrontEnd(1);
					Minimap.IsVisible = false;
				else
					setPlayerHudComponentVisible('radar', false);
					showChat(true);
					playSoundFrontEnd(2);
					Minimap.IsVisible = true;
					mapOffsetX, mapOffsetY, mapIsMoving = 0, 0, false;
				end
			elseif ((key == 'mouse_wheel_down' or key == '-' or key =='num_sub') and Bigmap.IsVisible) then
				Bigmap.CurrentZoom = math.min(Bigmap.CurrentZoom + 0.5, Bigmap.MaximumZoom);
			elseif ((key == 'mouse_wheel_up'or key == '+'or key =='num_add')  and Bigmap.IsVisible) then
				Bigmap.CurrentZoom = math.max(Bigmap.CurrentZoom - 0.5, Bigmap.MinimumZoom);
			elseif (key == 'lctrl' and Bigmap.IsVisible) then
				showCursor(not isCursorShowing());
			end
		end
	end
);

addEventHandler('onClientClick', root,
	function(button, state, cursorX, cursorY)
		if (not Minimap.IsVisible and Bigmap.IsVisible) then
			if (button == 'left' and state == 'down') then
				if (cursorX >= Bigmap.PosX and cursorX <= Bigmap.PosX + Bigmap.Width) then
					if (cursorY >= Bigmap.PosY and cursorY <= Bigmap.PosY + Bigmap.Height) then
						mapOffsetX = cursorX * Bigmap.CurrentZoom + playerX;
						mapOffsetY = cursorY * Bigmap.CurrentZoom - playerY;
						mapIsMoving = true;
					end
				end
			elseif (button == 'left' and state == 'up') then
				mapIsMoving = false;
			end
		end
	end
);

addEventHandler('onClientRender', root,
	function()
	if getElementDimension(localPlayer) > 0 then return end
		if (not Minimap.IsVisible and Bigmap.IsVisible) then
			dxDrawBorder(Bigmap.PosX, Bigmap.PosY, Bigmap.Width, Bigmap.Height, 2, tocolor(0, 0, 0, 200));
			
			local absoluteX, absoluteY = 0, 0;
			local zoneName = 'Unknown';
			
			if (getElementInterior(localPlayer) == 0) then
				if (isCursorShowing()) then
					local cursorX, cursorY = getCursorPosition();
					local mapX, mapY = getWorldFromMapPosition(cursorX, cursorY);
					
					absoluteX = cursorX * Display.Width;
					absoluteY = cursorY * Display.Height;
					
					if (getKeyState('mouse1') and mapIsMoving) then
						playerX = -(absoluteX * Bigmap.CurrentZoom - mapOffsetX);
						playerY = absoluteY * Bigmap.CurrentZoom - mapOffsetY;
						
						playerX = math.max(-3000, math.min(3000, playerX));
						playerY = math.max(-3000, math.min(3000, playerY));
					end
					
					if (not mapIsMoving) then
						if (Bigmap.PosX <= absoluteX and Bigmap.PosY <= absoluteY and Bigmap.PosX + Bigmap.Width >= absoluteX and Bigmap.PosY + Bigmap.Height >= absoluteY) then
							zoneName = getZoneName(mapX, mapY, 0);
						else
							zoneName = 'Unknown';
						end
					else
						zoneName = 'Unknown';
					end
				else
					playerX, playerY, playerZ = getElementPosition(localPlayer);
					zoneName = getZoneName(playerX, playerY, playerZ);
				end
				
				local playerRotation = getPedRotation(localPlayer);
				local mapX = (((3000 + playerX) * Minimap.MapUnit) - (Bigmap.Width / 2) * Bigmap.CurrentZoom);
				local mapY = (((3000 - playerY) * Minimap.MapUnit) - (Bigmap.Height / 2) * Bigmap.CurrentZoom);
				local mapWidth, mapHeight = Bigmap.Width * Bigmap.CurrentZoom, Bigmap.Height * Bigmap.CurrentZoom;

				dxDrawImageSection(Bigmap.PosX, Bigmap.PosY, Bigmap.Width, Bigmap.Height, mapX, mapY, mapWidth, mapHeight, Minimap.MapTexture, 0, 0, 0, tocolor(255, 255, 255, Minimap.Alpha));
				
				--> Radar area
				for _, area in ipairs(getElementsByType('radararea')) do
					local areaX, areaY = getElementPosition(area);
					local areaWidth, areaHeight = getRadarAreaSize(area);
					local areaR, areaG, areaB, areaA = getRadarAreaColor(area);
						
					if (isRadarAreaFlashing(area)) then
						areaA = areaA * math.abs(getTickCount() % 1000 - 500) / 500;
					end
					
					local areaX, areaY = getMapFromWorldPosition(areaX, areaY + areaHeight);
					local areaWidth, areaHeight = areaWidth / Bigmap.CurrentZoom * Minimap.MapUnit, areaHeight / Bigmap.CurrentZoom * Minimap.MapUnit;

					--** Width
					if (areaX < Bigmap.PosX) then
						areaWidth = areaWidth - math.abs((Bigmap.PosX) - (areaX));
						areaX = areaX + math.abs((Bigmap.PosX) - (areaX));
					end
					
					if (areaX + areaWidth > Bigmap.PosX + Bigmap.Width) then
						areaWidth = areaWidth - math.abs((Bigmap.PosX + Bigmap.Width) - (areaX + areaWidth));
					end
					
					if (areaX > Bigmap.PosX + Bigmap.Width) then
						areaWidth = areaWidth + math.abs((Bigmap.PosX + Bigmap.Width) - (areaX));
						areaX = areaX - math.abs((Bigmap.PosX + Bigmap.Width) - (areaX));
					end
					
					if (areaX + areaWidth < Bigmap.PosX) then
						areaWidth = areaWidth + math.abs((Bigmap.PosX) - (areaX + areaWidth));
						areaX = areaX - math.abs((Bigmap.PosX) - (areaX + areaWidth));
					end
					
					--** Height
					if (areaY < Bigmap.PosY) then
						areaHeight = areaHeight - math.abs((Bigmap.PosY) - (areaY));
						areaY = areaY + math.abs((Bigmap.PosY) - (areaY));
					end
					
					if (areaY + areaHeight > Bigmap.PosY + Bigmap.Height) then
						areaHeight = areaHeight - math.abs((Bigmap.PosY + Bigmap.Height) - (areaY + areaHeight));
					end
					
					if (areaY + areaHeight < Bigmap.PosY) then
						areaHeight = areaHeight + math.abs((Bigmap.PosY) - (areaY + areaHeight));
						areaY = areaY - math.abs((Bigmap.PosY) - (areaY + areaHeight));
					end
					
					if (areaY > Bigmap.PosY + Bigmap.Height) then
						areaHeight = areaHeight + math.abs((Bigmap.PosY + Bigmap.Height) - (areaY));
						areaY = areaY - math.abs((Bigmap.PosY + Bigmap.Height) - (areaY));
					end
					
					--** Draw
					dxDrawRectangle(areaX, areaY, areaWidth, areaHeight, tocolor(areaR, areaG, areaB, areaA), false);
				end
				
				--> Blips
				
								if getElementData(localPlayer,"Race") or getElementData(localPlayer,"SelectedRace") or Hover then
				
				local RaceMarkers = getElementsByType('RaceMarker')
					for i=1,#RaceMarkers do
							local v = RaceMarkers[i]
						if (getElementData(localPlayer,"Race") == getElementData(v,"RaceName")) or (getElementData(localPlayer,"SelectedRace") == getElementData(v,"RaceName")) or (Hover == getElementData(v,"RaceName")) then
							local Link = getElementData(v,"StartPoint") or i-1
								if RaceMarkers[Link] then
									if (getElementData(RaceMarkers[Link],"RaceName") == getElementData(v,"RaceName")) then
													local xa,ya = getElementPosition(RaceMarkers[Link])
														local x,y = getElementPosition(v)
												local Xa, Ya = getMapFromWorldPosition(xa,ya)
											local X, Y = getMapFromWorldPosition(x,y)
										local zoom = math.min(1/Bigmap.CurrentZoom,2)
									dxDrawLine(Xa, Ya,X, Y, tocolor(255,75,0,240),zoom*3)
								end
							end
						end
					end
				end
				Hover = nil
				
				local raceStarts = getElementsByType('RaceStart')
				if #raceStarts>0 then
				for i=1,#raceStarts do
						local v = raceStarts[i]
						local x,y = getElementPosition(v)
						local X, Y = getMapFromWorldPosition(x,y)
							if isCursorShowing() then
								if isCursorOnElement(X - 10, Y - 10, 20, 20) then
									if getKeyState ("mouse1") then
										setElementData(localPlayer,"SelectedRace",getElementData(v,"RaceName"))
							setElementData(localPlayer,"RaceElement",v)
					end
						dxDrawImage(X - 20, Y - 20, 40, 40, 'blips/53.png',0,0,0,tocolor(255,255,255,240) )
							Hover = getElementData(v,"RaceName")
						else
							dxDrawImage(X - 10, Y -10, 20, 20, 'blips/53.png',0,0,0,tocolor(255,255,255,240) )
						end
					else
							dxDrawImage(X - 10, Y -10, 20, 20, 'blips/53.png',0,0,0,tocolor(255,255,255,240) )
						end
					end
				end
				
					local warppoints = getElementsByType('WarpPoint')
				
				if #warppoints>0 then
				for i=1,#warppoints do
						local v = warppoints[i]
					local x,y,z = getElementPosition(v)
						local X, Y = getMapFromWorldPosition(x,y)
							local xa,ya,za = getElementPosition(localPlayer)
								if (z > za+100) or (z < za-100) then
									Alpha = 180
								else
									Alpha = 240
								end
					if isCursorShowing() then
						if isCursorOnElement(X - 10, Y - 10, 20, 20) then
							if getKeyState ("mouse1") then
							setElementData(localPlayer,"SelectedWarp",getElementData(v,"WarpName"))
						setElementData(localPlayer,"WarpElement",v)
					end
						dxDrawImage(X - 20, Y - 20, 40, 40, 'blips/56.png',0,0,0,tocolor(255,255,0,Alpha) )
						else
							dxDrawImage(X - 10, Y -10, 20, 20, 'blips/56.png',0,0,0,tocolor(255,255,0,Alpha) )
						end
					else
							dxDrawImage(X - 10, Y -10, 20, 20, 'blips/56.png',0,0,0,tocolor(255,255,0,Alpha) )
						end
					end
				end
				
				for _, blip in ipairs(getElementsByType('blip')) do
					if getElementDimension(blip) == getElementDimension(localPlayer) then
					local blipX, blipY, blipZ = getElementPosition(blip);

					if (localPlayer ~= getElementAttachedTo(blip)) then
						local blipSettings = {
							['color'] = {255, 255, 255, 255},
							['size'] = getElementData(blip, 'blipSize') or 20,
							['icon'] = getBlipIcon(blip),
							['exclusive'] = getElementData(blip, 'exclusiveBlip') or false
						};
						
						if (blipSettings['icon'] == 0 or blipSettings['icon'] == 1) then
							blipSettings['color'] = {getBlipColor(blip)};
						end
						
						centerX, centerY = getMapFromWorldPosition(blipX, blipY);

						if blipSettings['exclusive'] or (blipSettings['icon'] == 41) then
						local centerX, centerY = (Bigmap.PosX + (Bigmap.Width / 2)), (Bigmap.PosY + (Bigmap.Height / 2));
						local leftFrame = (centerX - Bigmap.Width / 2) + (blipSettings['size'] / 2);
						local rightFrame = (centerX + Bigmap.Width / 2) - (blipSettings['size'] / 2);
						local topFrame = (centerY - Bigmap.Height / 2) + (blipSettings['size'] / 2);
						local bottomFrame = (centerY + Bigmap.Height / 2) - (blipSettings['size'] / 2);
						local blipX, blipY = getMapFromWorldPosition(blipX, blipY);
						
						centerX = math.max(leftFrame, math.min(rightFrame, blipX));
						centerY = math.max(topFrame, math.min(bottomFrame, blipY));
						end

						dxDrawImage(centerX - (blipSettings['size'] / 2), centerY - (blipSettings['size'] / 2), blipSettings['size'], blipSettings['size'], 'blips/' .. blipSettings['icon'] .. '.png', 0, 0, 0, tocolor(blipSettings['color'][1], blipSettings['color'][2], blipSettings['color'][3], blipSettings['color'][4]));
					end
				end
				end
				
				for _, player in ipairs(getElementsByType('player')) do
				if not getElementData(player,"dontshow") then
									if getElementDimension(player) == getElementDimension(localPlayer) then
					local otherPlayerX, otherPlayerY, otherPlayerZ = getElementPosition(player);
						
					if (localPlayer ~= player) then
						local playerIsVisible = false;
						local blipSettings = {
							['color'] = {255, 255, 255, 255},
							['size'] = 25,
							['icon'] = 'player'
						};
						
						blipSettings['color'] = {getPlayerNametagColor(player)};

						local blipX, blipY = getMapFromWorldPosition(otherPlayerX, otherPlayerY);
						
						if (blipX >= Bigmap.PosX and blipX <= Bigmap.PosX + Bigmap.Width) then
							if (blipY >= Bigmap.PosY and blipY <= Bigmap.PosY + Bigmap.Height) then
								dxDrawImage(blipX - (blipSettings['size'] / 2), blipY - (blipSettings['size'] / 2), blipSettings['size'], blipSettings['size'], 'blips/2.png', -getPedRotation(player), 0, 0, tocolor(blipSettings['color'][1], blipSettings['color'][2], blipSettings['color'][3], blipSettings['color'][4]));
							end
						end
					end
				end
				end
				end
				
				--> Local player
				local localX, localY, localZ = getElementPosition(localPlayer);
				local blipX, blipY = getMapFromWorldPosition(localX, localY);
						
				if (blipX >= Bigmap.PosX and blipX <= Bigmap.PosX + Bigmap.Width) then
					if (blipY >= Bigmap.PosY and blipY <= Bigmap.PosY + Bigmap.Height) then
						dxDrawImage(blipX - 10, blipY - 10, 20, 20, 'files/images/arrow.png', 360 - playerRotation);
					end
				end
				
				--> GPS Location
				--dxDrawRectangle(Bigmap.PosX, (Bigmap.PosY + Bigmap.Height) - 25, Bigmap.Width, 25, tocolor(0, 0, 0, 200));
				--dxDrawText(zoneName, Bigmap.PosX + 10, (Bigmap.PosY + Bigmap.Height) - 25, Bigmap.PosX + 10 + Bigmap.Width - 20, (Bigmap.PosY + Bigmap.Height), tocolor(255, 255, 255, 255), 0.50, Fonts.Roboto, 'left', 'center');
			else
				--dxDrawRectangle(Bigmap.PosX, Bigmap.PosY, Bigmap.Width, Bigmap.Height, tocolor(0, 0, 0, 150));
				--dxDrawText('GPS lost connection...', Bigmap.PosX, Bigmap.PosY + 20, Bigmap.PosX + Bigmap.Width, Bigmap.PosY + 20 + Bigmap.Height, tocolor(255, 255, 255, 255 * math.abs(getTickCount() % 2000 - 1000) / 1000), 0.40, Fonts.Roboto, 'center', 'center', false, false, false, true, true);
				--dxDrawText('', Bigmap.PosX, Bigmap.PosY - 20, Bigmap.PosX + Bigmap.Width, Bigmap.PosY - 20 + Bigmap.Height, tocolor(255, 255, 255, 255 * math.abs(getTickCount() % 2000 - 1000) / 1000), 1.00, Fonts.Icons, 'center', 'center', false, false, false, true, true);
				
				if (Minimap.LostRotation > 360) then
					Minimap.LostRotation = 0;
				end
				
				--dxDrawText('', (Bigmap.PosX + Bigmap.Width - 25), Bigmap.PosY, (Bigmap.PosX + Bigmap.Width - 25) + 25, Bigmap.PosY + 25, tocolor(255, 255, 255, 100), 0.50, Fonts.Icons, 'center', 'center', false, false, false, true, true, Minimap.LostRotation);
				Minimap.LostRotation = Minimap.LostRotation + 1;
			end
				dxDrawText("Hit Ctrl to unlock mouse\n\n Drag Cursor to move around map.", (Display.Width - 321) / 2, 634*heightA, ((Display.Width - 321) / 2) + 321, 734*heightA, tocolor(150, 150, 150, 255), 1.00, "default-bold", "center", "center", false, false, false, false, false)

		elseif (Minimap.IsVisible and not Bigmap.IsVisible) then
			setElementData(localPlayer,"SelectedWarp",nil)
				setElementData(localPlayer,"WarpElement",nil)
					setElementData(localPlayer,"SelectedRace",nil)
						setElementData(localPlayer,"RaceElement",nil)
		if getElementData(localPlayer,"radar") then return end
			if (radarSettings['showStats']) then
				Minimap.PosY = ((Display.Height - 20) - Stats.Bar.Height) - Minimap.Height;
			else
				Minimap.PosY = (Display.Height - 20) - Minimap.Height;
			end
			
			dxDrawBorder(Minimap.PosX, Minimap.PosY, Minimap.Width, Minimap.Height, 2, tocolor(0, 0, 0, 200));
			
			if (getElementInterior(localPlayer) == 0) then
				Minimap.PlayerInVehicle = getPedOccupiedVehicle(localPlayer);
				playerX, playerY, playerZ = getElementPosition(localPlayer);
				
				--> Calculate positions
				local playerRotation = getPedRotation(localPlayer);
				local playerMapX, playerMapY = (3000 + playerX) / 6000 * Minimap.TextureSize, (3000 - playerY) / 6000 * Minimap.TextureSize;
				local streamDistance, pRotation = getRadarRadius(), getRotation();
				local mapRadius = streamDistance / 6000 * Minimap.TextureSize * Minimap.CurrentZoom;
				local mapX, mapY, mapWidth, mapHeight = playerMapX - mapRadius, playerMapY - mapRadius, mapRadius * 2, mapRadius * 2;
				
				--> Set world
				dxSetRenderTarget(Minimap.MapTarget, true);
				dxDrawRectangle(0, 0, Minimap.BiggerTargetSize, Minimap.BiggerTargetSize, tocolor(Minimap.WaterColor[1], Minimap.WaterColor[2], Minimap.WaterColor[3], Minimap.Alpha), false);
				dxDrawImageSection(0, 0, Minimap.BiggerTargetSize, Minimap.BiggerTargetSize, mapX, mapY, mapWidth, mapHeight, Minimap.MapTexture, 0, 0, 0, tocolor(255, 255, 255, Minimap.Alpha), false);
				
				--> Draw radar areas
				for _, area in ipairs(getElementsByType('radararea')) do
					local areaX, areaY = getElementPosition(area);
					local areaWidth, areaHeight = getRadarAreaSize(area);
					local areaMapX, areaMapY, areaMapWidth, areaMapHeight = (3000 + areaX) / 6000 * Minimap.TextureSize, (3000 - areaY) / 6000 * Minimap.TextureSize, areaWidth / 6000 * Minimap.TextureSize, -(areaHeight / 6000 * Minimap.TextureSize);
					
					if (doesCollide(playerMapX - mapRadius, playerMapY - mapRadius, mapRadius * 2, mapRadius * 2, areaMapX, areaMapY, areaMapWidth, areaMapHeight)) then
						local areaR, areaG, areaB, areaA = getRadarAreaColor(area);
						
						if (isRadarAreaFlashing(area)) then
							areaA = areaA * math.abs(getTickCount() % 1000 - 500) / 500;
						end
						
						local mapRatio = Minimap.BiggerTargetSize / (mapRadius * 2);
						local areaMapX, areaMapY, areaMapWidth, areaMapHeight = (areaMapX - (playerMapX - mapRadius)) * mapRatio, (areaMapY - (playerMapY - mapRadius)) * mapRatio, areaMapWidth * mapRatio, areaMapHeight * mapRatio;
						
						dxSetBlendMode('modulate_add');
						dxDrawRectangle(areaMapX, areaMapY, areaMapWidth, areaMapHeight, tocolor(areaR, areaG, areaB, areaA), false);
						dxSetBlendMode('blend');
					end
				end
				
				if getElementData(localPlayer,"Race") or getElementData(localPlayer,"SelectedRace") then
				
				local EA = getElementsByType('RaceMarker')
				for i=1,#EA do
					local v = EA[i]
						if (getElementData(localPlayer,"Race") == getElementData(v,"RaceName")) then
							local Connector = getElementData(v,"StartPoint") or i-1
								if EA[Connector] then
									if (getElementData(EA[Connector],"RaceName") == getElementData(v,"RaceName")) then
										local xa,ya = getElementPosition(EA[Connector])
										local x,y = getElementPosition(v)
				
											local XXa,YYa = (3000 + xa) / 6000 * Minimap.TextureSize, (3000 - ya) / 6000 * Minimap.TextureSize
											local XXb,YYb = (3000 + x) / 6000 * Minimap.TextureSize, (3000 - y) / 6000 * Minimap.TextureSize
											local mapRatio = Minimap.BiggerTargetSize / (mapRadius * 2);
				
										local XXA,YYA = (XXa - (playerMapX - mapRadius)) * mapRatio, (YYa - (playerMapY - mapRadius)) * mapRatio
											local XXB,YYB = (XXb - (playerMapX - mapRadius)) * mapRatio, (YYb - (playerMapY - mapRadius)) * mapRatio
									dxDrawLine( XXA,YYA,XXB,YYB, tocolor(0,100,255,240),4 )
								end
							end
						end
					end
				end
				
				--> Draw blip
				dxSetRenderTarget(Minimap.RenderTarget, true);
				dxDrawImage(Minimap.NormalTargetSize / 2, Minimap.NormalTargetSize / 2, Minimap.BiggerTargetSize, Minimap.BiggerTargetSize, Minimap.MapTarget, math.deg(-pRotation), 0, 0, tocolor(255, 255, 255, 255), false);
				
				local serverBlips = getElementsByType('blip');
				
				table.sort(serverBlips,
					function(b1, b2)
						return getBlipOrdering(b1) < getBlipOrdering(b2);
					end
				);
				
				for _, blip in ipairs(serverBlips) do
					local blipX, blipY, blipZ = getElementPosition(blip);
					
					if (localPlayer ~= getElementAttachedTo(blip) and getElementInterior(localPlayer) == getElementInterior(blip) and getElementDimension(localPlayer) == getElementDimension(blip)) then
						local blipDistance = getDistanceBetweenPoints2D(blipX, blipY, playerX, playerY);
						local blipRotation = math.deg(-getVectorRotation(playerX, playerY, blipX, blipY) - (-pRotation)) - 180;
						local blipRadius = math.min((blipDistance / (streamDistance * Minimap.CurrentZoom)) * Minimap.NormalTargetSize, Minimap.NormalTargetSize);
						local distanceX, distanceY = getPointFromDistanceRotation(0, 0, blipRadius, blipRotation);
						
						local blipSettings = {
							['color'] = {255, 255, 255, 255},
							['size'] = getElementData(blip, 'blipSize') or 20,
							['exclusive'] = getElementData(blip, 'exclusiveBlip') or false,
							['icon'] = getBlipIcon(blip)
						};
						
						local blipX, blipY = Minimap.NormalTargetSize * 1.5 + (distanceX - (blipSettings['size'] / 2)), Minimap.NormalTargetSize * 1.5 + (distanceY - (blipSettings['size'] / 2));
						local calculatedX, calculatedY = ((Minimap.PosX + (Minimap.Width / 2)) - (blipSettings['size'] / 2)) + (blipX - (Minimap.NormalTargetSize * 1.5) + (blipSettings['size'] / 2)), (((Minimap.PosY + (Minimap.Height / 2)) - (blipSettings['size'] / 2)) + (blipY - (Minimap.NormalTargetSize * 1.5) + (blipSettings['size'] / 2)));
						
						if (blipSettings['icon'] == 0 or blipSettings['icon'] == 1) then
							blipSettings['color'] = {getBlipColor(blip)};
						end
						
						if (blipSettings['exclusive'] == true) or (blipSettings['icon'] == 41)  then
							blipX = math.max(blipX + (Minimap.PosX - calculatedX), math.min(blipX + (Minimap.PosX + Minimap.Width - blipSettings['size'] - calculatedX), blipX));
							blipY = math.max(blipY + (Minimap.PosY - calculatedY), math.min(blipY + (Minimap.PosY + Minimap.Height - blipSettings['size'] - 25 - calculatedY), blipY));
						end
						
						dxSetBlendMode('modulate_add');
						dxDrawImage(blipX, blipY, blipSettings['size'], blipSettings['size'], 'blips/' .. blipSettings['icon'] .. '.png', 0, 0, 0, tocolor(blipSettings['color'][1], blipSettings['color'][2], blipSettings['color'][3], blipSettings['color'][4]), false);
						dxSetBlendMode('blend');
					end
				end
				
				for _, player in ipairs(getElementsByType('player')) do
				if not getElementData(player,"dontshow") then 
					local otherPlayerX, otherPlayerY, otherPlayerZ = getElementPosition(player);
					
					if (localPlayer ~= player and streamDistance * Minimap.CurrentZoom) then
						local playerDistance = getDistanceBetweenPoints2D(otherPlayerX, otherPlayerY, playerX, playerY);
						local playerRotation = math.deg(-getVectorRotation(playerX, playerY, otherPlayerX, otherPlayerY) - (-pRotation)) - 180;
						local playerRadius = math.min((playerDistance / (streamDistance * Minimap.CurrentZoom)) * Minimap.NormalTargetSize, Minimap.NormalTargetSize);
						local distanceX, distanceY = getPointFromDistanceRotation(0, 0, playerRadius, playerRotation);
						
						local otherPlayerX, otherPlayerY = Minimap.NormalTargetSize * 1.5 + (distanceX - 10), Minimap.NormalTargetSize * 1.5 + (distanceY - 10);
						local calculatedX, calculatedY = ((Minimap.PosX + (Minimap.Width / 2)) - 10) + (otherPlayerX - (Minimap.NormalTargetSize * 1.5) + 10), (((Minimap.PosY + (Minimap.Height / 2)) - 10) + (otherPlayerY - (Minimap.NormalTargetSize * 1.5) + 10));
						local playerR, playerG, playerB = getPlayerNametagColor(player);
						
						dxSetBlendMode('modulate_add');
						dxDrawImage(otherPlayerX, otherPlayerY, 20, 20, 'blips/2.png',math.deg(-pRotation)-getPedRotation(player), 0, 0, tocolor(playerR, playerG, playerB, 255), false);
						dxSetBlendMode('blend');
					end
				end
				end
				
				--> Draw fully minimap
				dxSetRenderTarget();
				dxDrawImageSection(Minimap.PosX, Minimap.PosY, Minimap.Width, Minimap.Height, Minimap.NormalTargetSize / 2 + (Minimap.BiggerTargetSize / 2) - (Minimap.Width / 2), Minimap.NormalTargetSize / 2 + (Minimap.BiggerTargetSize / 2) - (Minimap.Height / 2), Minimap.Width, Minimap.Height, Minimap.RenderTarget, 0, -90, 0, tocolor(255, 255, 255, 255));
				
				--> Local player
				dxDrawImage((Minimap.PosX + (Minimap.Width / 2)) - 10, (Minimap.PosY + (Minimap.Height / 2)) - 10, 20, 20, 'files/images/arrow.png', math.deg(-pRotation) - playerRotation);
			
				--> GPS
				--dxDrawRectangle(Minimap.PosX, Minimap.PosY + Minimap.Height - 25, Minimap.Width, 25, tocolor(0, 0, 0, 150));
				--dxDrawText(getZoneName(playerX, playerY, playerZ), Minimap.PosX + 5, (Minimap.PosY + Minimap.Height - 25), Minimap.PosX + 5 + Minimap.Width - 10, Minimap.PosY + Minimap.Height, tocolor(255, 255, 255, 255), 0.40, Fonts.Roboto, 'right', 'center', true, false, false, true, true);
				
				--> Zoom
				if (getKeyState('num_add') or getKeyState('num_sub')) then
					Minimap.CurrentZoom = math.max(Minimap.MinimumZoom, math.min(Minimap.MaximumZoom, Minimap.CurrentZoom + ((getKeyState('num_sub') and -1 or 1) * (getTickCount() - (getTickCount() + 50)) / 100)));
				end
			else
				--dxDrawRectangle(Minimap.PosX, Minimap.PosY, Minimap.Width, Minimap.Height, tocolor(0, 0, 0, 150));
				--dxDrawText('GPS lost connection...', Minimap.PosX, Minimap.PosY + 20, Minimap.PosX + Minimap.Width, Minimap.PosY + 20 + Minimap.Height, tocolor(255, 255, 255, 255 * math.abs(getTickCount() % 2000 - 1000) / 1000), 0.40, Fonts.Roboto, 'center', 'center', false, false, false, true, true);
				--dxDrawText('', Minimap.PosX, Minimap.PosY - 20, Minimap.PosX + Minimap.Width, Minimap.PosY - 20 + Minimap.Height, tocolor(255, 255, 255, 255 * math.abs(getTickCount() % 2000 - 1000) / 1000), 1.00, Fonts.Icons, 'center', 'center', false, false, false, true, true);
				
				if (Minimap.LostRotation > 360) then
					Minimap.LostRotation = 0;
				end
				
				--dxDrawText('', (Minimap.PosX + Minimap.Width - 25), Minimap.PosY, (Minimap.PosX + Minimap.Width - 25) + 25, Minimap.PosY + 25, tocolor(255, 255, 255, 100), 0.50, Fonts.Icons, 'center', 'center', false, false, false, true, true, Minimap.LostRotation);
				Minimap.LostRotation = Minimap.LostRotation + 1;
		end
	end
end
);

function doesCollide(x1, y1, w1, h1, x2, y2, w2, h2)
	local horizontal = (x1 < x2) ~= (x1 + w1 < x2) or (x1 > x2) ~= (x1 > x2 + w2);
	local vertical = (y1 < y2) ~= (y1 + h1 < y2) or (y1 > y2) ~= (y1 > y2 + h2);
	
	return (horizontal and vertical);
end

function getRadarRadius()
	if (not Minimap.PlayerInVehicle) then
		return 180;
	else
		local vehicleX, vehicleY, vehicleZ = getElementVelocity(Minimap.PlayerInVehicle);
		local currentSpeed = (1 + (vehicleX ^ 2 + vehicleY ^ 2 + vehicleZ ^ 2) ^ (0.5)) / 2;
	
		if (currentSpeed <= 0.5) then
			return 180;
		elseif (currentSpeed >= 1) then
			return 360;
		end
		
		local distance = currentSpeed - 0.5;
		local ratio = 180 / 0.5;
		
		return math.ceil((distance * ratio) + 180);
	end
end

function getPointFromDistanceRotation(x, y, dist, angle)
	local a = math.rad(90 - angle);
	local dx = math.cos(a) * dist;
	local dy = math.sin(a) * dist;
	
	return x + dx, y + dy;
end

function getRotation()
	local cameraX, cameraY, _, rotateX, rotateY = getCameraMatrix();
	local camRotation = getVectorRotation(cameraX, cameraY, rotateX, rotateY);
	
	return camRotation;
end

function getVectorRotation(X, Y, X2, Y2)
	local rotation = 6.2831853071796 - math.atan2(X2 - X, Y2 - Y) % 6.2831853071796;
	
	return -rotation;
end

function dxDrawBorder(x, y, w, h, size, color, postGUI)
end

function getMinimapState()
	return Minimap.IsVisible;
end

function getBigmapState()
	return Bigmap.IsVisible;
end

function getMapFromWorldPosition(worldX, worldY)
	local centerX, centerY = (Bigmap.PosX + (Bigmap.Width / 2)), (Bigmap.PosY + (Bigmap.Height / 2));
	local mapLeftFrame = centerX - ((playerX - worldX) / Bigmap.CurrentZoom * Minimap.MapUnit);
	local mapRightFrame = centerX + ((worldX - playerX) / Bigmap.CurrentZoom * Minimap.MapUnit);
	local mapTopFrame = centerY - ((worldY - playerY) / Bigmap.CurrentZoom * Minimap.MapUnit);
	local mapBottomFrame = centerY + ((playerY - worldY) / Bigmap.CurrentZoom * Minimap.MapUnit);
	
	centerX = math.max(mapLeftFrame, math.min(mapRightFrame, centerX));
	centerY = math.max(mapTopFrame, math.min(mapBottomFrame, centerY));
	
	return centerX, centerY;
end


function CreateBlip(button,state,aXA,aYA)
if Bigmap.IsVisible == true then
	if button == "left" and state== "down"  then			
		if blipAAAA then												
			destroyElement(blipAAAA)									
			blipAAAA=nil											
			playSoundFrontEnd(2)									
			return													
		end
		
					local cursorX, cursorY = getCursorPosition();
					local x, y = getWorldFromMapPosition(cursorX, cursorY);	
		blipAAAA =createBlip(x,y,0,41,2)			
		setElementDimension(blipAAAA,getElementDimension(localPlayer))
		
		playSoundFrontEnd(1)
		end 
	end
end
addEventHandler("onClientClick",root,CreateBlip)

function getWorldFromMapPosition(mapX, mapY)

	local worldX = playerX + ((mapX * ((Bigmap.Width * Bigmap.CurrentZoom) * 2)) - (Bigmap.Width * Bigmap.CurrentZoom));
	local worldY = playerY + ((mapY * ((Bigmap.Height * Bigmap.CurrentZoom) * 2)) - (Bigmap.Height * Bigmap.CurrentZoom)) * -1;
	
	return worldX, worldY;
end

