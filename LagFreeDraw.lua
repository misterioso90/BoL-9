local DrawCircleBackUp = _G.DrawCircle

function G_DrawCircle(x, y, z, radius, color)

  local v1 = Vector(cameraPos.x, cameraPos.y, cameraPos.z)
  local v2 = Vector(x, y, z)
  local ClosestPos = v2+(v1-v2):normalized()*radius
  local ScreenPos = WorldToScreen(D3DXVECTOR3(ClosestPos.x, ClosestPos.y, ClosestPos.z))
  local radius = radius*.96
  if not color then color = 4294967295 end
  
  if OnScreen({x = ScreenPos.x, y = ScreenPos.y}, {x = ScreenPos.x, y = ScreenPos.y}) then
    DrawCircle3D(x, y, z, radius, Menu.Thick, color, Menu.Quality) 
  end
end

function ChangeDraw()
  if Menu.On then
    _G.DrawCircle = G_DrawCircle
  else
    _G.DrawCircle = DrawCircleBackUp
  end
end

function OnLoad()
  
  Menu = scriptConfig("Lag Free Draw", "lfd")
  Menu:addParam("On", "Change to LagFree", SCRIPT_PARAM_ONOFF, true)
  Menu:addParam("Thick", "Thick", SCRIPT_PARAM_SLICE, 1, 1, 8, 0)
  Menu:addParam("Quality", "Quality", SCRIPT_PARAM_SLICE, 32, 8, 128, 0)
  Menu:setCallback("On", ChangeDraw)
  
  if Menu.On then
    _G.DrawCircle = G_DrawCircle
  end
end
