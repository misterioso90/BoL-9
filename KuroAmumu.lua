--[[
  
      __ __                    _____           _       __     _____           _          
     / //_/_  ___________     / ___/__________(_)___  / /_   / ___/___  _____(_)__  _____
    / ,< / / / / ___/ __ \    \__ \/ ___/ ___/ / __ \/ __/   \__ \/ _ \/ ___/ / _ \/ ___/
   / /| / /_/ / /  / /_/ /   ___/ / /__/ /  / / /_/ / /_    ___/ /  __/ /  / /  __(__  ) 
  /_/ |_\__,_/_/   \____/   /____/\___/_/  /_/ .___/\__/   /____/\___/_/  /_/\___/____/  
                                            /_/                                          

  Kuro Amumu Alpha Test
            by. KuroXNeko
]]--

if not myHero then
  myHero = GetmyHero()
end
if myHero.charName ~= "Amumu" then return end

local ScriptVersion = 0.1
local target = nil
local DespairStatus = false
local NearEnemyW = false
local jungleMinions = minionManager(MINION_JUNGLE, 315, myHero)
local enemyMinions = minionManager(MINION_ENEMY, 315, myHero)


-- [Shared Function] --

function print_msg(msg)
  if msg ~= nil then
    msg = tostring(msg)
    print("<font color=\"#79E886\"><b>[Kuro Amumu]</b></font> <font color=\"#FFFFFF\">".. msg .."</font>")
  end
end

function LoadSimpleLib()
  if FileExist(LIB_PATH .. "/SimpleLib.lua") then
    require("SimpleLib")
    return true
  else
    print_msg("Downloading SimpleLib, please don't press F9")
    DelayAction(function() DownloadFile("https://raw.githubusercontent.com/jachicao/BoL/master/SimpleLib.lua".."?rand="..math.random(1,10000), LIB_PATH.."SimpleLib.lua", function () print_msg("Successfully downloaded SimpleLib. Press F9 twice.") end) end, 3) 
    return false
  end
end

function LoadSLK()
  if FileExist(LIB_PATH .. "/SourceLibk.lua") then
    require("SourceLibk")
    return true
  else
    print_msg("Downloading SourceLibk, please don't press F9")
    DelayAction(function() DownloadFile("https://raw.githubusercontent.com/kej1191/anonym/master/Common/SourceLibk.lua".."?rand="..math.random(1,10000), LIB_PATH.."SourceLibk.lua", function () print_msg("Successfully downloaded SourceLibk. Press F9 twice.") end) end, 3) 
    return false
  end
end


-- [Script Function] --

-- OnLoad works Update and Download SLK.
function OnLoad()
  
  -- Check SLK.
  if LoadSLK() then
  
    -- Check SimpleLib
    if LoadSimpleLib() then
    
      -- Start Update with SimpleLib.
      local UpdateInfo = {}
      UpdateInfo.LocalVersion = ScriptVersion
      UpdateInfo.VersionPath = "raw.githubusercontent.com/kuroxnekos2/BoL/master/KuroAmumu.version"
      UpdateInfo.ScriptPath =  "raw.githubusercontent.com/kuroxnekos2/BoL/master/KuroAmumu.lua"
      UpdateInfo.SavePath = SCRIPT_PATH .. GetCurrentEnv().FILE_NAME
      UpdateInfo.CallbackUpdate = function(NewVersion, OldVersion) print_msg("Updated to ".. NewVersion ..". Press F9x2!") end
      UpdateInfo.CallbackNoUpdate = LoadScript()
      UpdateInfo.CallbackNewVersion = function(NewVersion) print_msg("New version found. Don't press F9.") end
      UpdateInfo.CallbackError = function(NewVersion) print_msg("Error to download new version. Please try again.") end
      _ScriptUpdate(UpdateInfo)
    end
  end
end

function LoadScript()
  -- Load script with class.
  KA = KuroAmumu()
  _G.KuroAmumuLoaded = true
  DelayAction(function() print_msg("Lastset version (".. ScriptVersion ..") loaded!") end, 2)
end

-- [Main Class] --

class "KuroAmumu"

function KuroAmumu:__init()
  self:Config()
end

-- Config, menu and etc.
function KuroAmumu:Config()

  -- Set Spell with SimpleLib
  self.Spell_Q = _Spell({Slot = _Q, DamageName = "Q", Range = 1100, Width = 80, Delay = 0.25, Speed = 2000, Collision = true, Aoe = false, Type = SPELL_TYPE.LINEAR})
  self.Spell_Q:SetAccuracy(70)
  self.Spell_Q:AddDraw({Enable = true, color = {255,0,125,255}})
  
  self.Spell_W = _Spell({Slot = _W, DamageName = "W", Range = 300, Delay = 0, Aoe = true, Type = SPELL_TYPE.SELF})
  self.Spell_W:AddDraw({Enable = false, color = {255,255,140,0}})
  
  self.Spell_E = _Spell({Slot = _E, DamageName = "E", Range = 350, Delay = 0.125, Aoe = true, Type = SPELL_TYPE.SELF})
  self.Spell_E:AddDraw({Enable = true, color = {255,170,0,255}})
  
  self.Spell_R = _Spell({Slot = _R, DamageName = "R", Range = 550, Delay = 0.25, Aoe = true, Type = SPELL_TYPE.SELF})
  self.Spell_R:AddDraw({Enable = true, color = {255,255,0,0}})
  
  -- Make Menu.
  self.cfg = scriptConfig("Kuro Amumu", "kuro_amumu")
  
  -- Target Selector with SLK.
  self.STS = SimpleTS(STS_PRIORITY_LESS_CAST_MAGIC)
  self.cfg:addSubMenu("Target Selector", "ts")
  self.STS:AddToMenu(self.cfg.ts)
  
  -- Combo Menu
  self.cfg:addSubMenu("Combo Setting", "combo")
      self.cfg.combo:addParam("autow", "Use Auto W", SCRIPT_PARAM_ONOFF, true)
      self.cfg.combo:addParam("autowmana", "Auto W Mana", SCRIPT_PARAM_SLICE, 0,0,100)
      self.cfg.combo:addParam("info1", "", SCRIPT_PARAM_INFO, "")
      self.cfg.combo:addParam("autoe", "Use Auto E", SCRIPT_PARAM_ONOFF, true)
      self.cfg.combo:addParam("autoemana", "Auto E Mana", SCRIPT_PARAM_SLICE, 20,0,100)
      self.cfg.combo:addParam("info2", "", SCRIPT_PARAM_INFO, "")
      self.cfg.combo:addParam("autor", "Use Auto R", SCRIPT_PARAM_ONOFF, true)
      self.cfg.combo:addParam("autornum", "Auto R Chmps", SCRIPT_PARAM_SLICE, 3,1,5)
  
  -- Harass
  self.cfg:addSubMenu("Harass Setting", "harass")
      self.cfg.harass:addParam("autow", "Use Auto W", SCRIPT_PARAM_ONOFF, true)
      self.cfg.harass:addParam("autowmana", "Auto W Mana", SCRIPT_PARAM_SLICE, 20,0,100)
      self.cfg.harass:addParam("info1", "", SCRIPT_PARAM_INFO, "")
      self.cfg.harass:addParam("autoe", "Use Auto E", SCRIPT_PARAM_ONOFF, true)
      self.cfg.harass:addParam("autoemana", "Auto E Mana", SCRIPT_PARAM_SLICE, 50,0,100)
      
  -- Lane Clear
  self.cfg:addSubMenu("Clear Setting", "clear")
  
  -- Jungle Clear
  
  -- Spell Menu with SimpleLib.
  self.cfg:addSubMenu("Spell Setting", "spell")
  
  -- Draw Menu
  self.cfg:addSubMenu("Draw Setting", "draw")
      self.cfg.draw:addParam("info1", "", SCRIPT_PARAM_INFO, "")
      self.cfg.draw:addParam("drawtarget", "Draw Target", SCRIPT_PARAM_ONOFF, true)
      
  -- Key Menu with SimpleLib
  self.cfg:addSubMenu("Key Setting", "key")
      OrbwalkManager:LoadCommonKeys(self.cfg.key)
  
  -- Etc
  self.cfg:addSubMenu("Msic Setting", "msic")
    self.cfg.msic:addParam("autodisablew", "Auto disable W", SCRIPT_PARAM_ONOFF, true)
    self.cfg.msic:addParam("debug", "Debug Mode", SCRIPT_PARAM_ONOFF, false)
  
  -- Set CallBack.
  AddDrawCallback(function() self:Draw() end)
  AddTickCallback(function() self:Tick() end)
  AddCastSpellCallback(function(slot) self:OnCastSpell(slot) end)
  AddDeleteObjCallback(function(obj) self:OnDeleteObj(obj) end)
end

function KuroAmumu:Draw()
  
  -- If dead, disable everything.
  if myHero.dead then
    return
  end

  -- Draw Other
  --if self.cfg.draw.drawtarget then
  
  --end
  
  -- Debug
  if self.cfg.msic.debug then
    DrawText("W: "..tostring(DespairStatus), 20, 80, 100, ARGB(255,255,255,255))
    DrawText("All Enemy W: "..tostring(self:GetAllEnemyW()), 20, 80, 130, ARGB(255,255,255,255))
    DrawText("Enemy W: "..tostring(self:GetEnemyW()), 20, 80, 160, ARGB(255,255,255,255))
    DrawText("Enemy R: "..tostring(self:GetEnemyR()), 20, 80, 190, ARGB(255,255,255,255))
    DrawText("Combo Mode: "..tostring(OrbwalkManager:IsCombo()), 20, 80, 220, ARGB(255,255,255,255))
  end
end

function KuroAmumu:Tick()
  
  -- If dead, disable everything.
  if myHero.dead then
    return
  end
  
  -- Update
  target = self.STS:GetTarget(1600)
  
  -- Auto Disable W
  if self.cfg.msic.autodisablew then
    self:AutoDisableW()
  end
  
  -- Combo Logic
  if OrbwalkManager:IsCombo() then
    self:Combo()
  end
  
  -- Harass
  if OrbwalkManager:IsHarass() then
    self:Harass()
  end
  
  -- Clear
  if OrbwalkManager:IsClear() then
    self:Clear()
  end
  
  -- LastHit
  if OrbwalkManager:IsLastHit() then
    self:LastHit()
  end
  
end

function KuroAmumu:OnCastSpell(slot)
  if slot == _W then
    DespairStatus = true
  end
end

function KuroAmumu:OnDeleteObj(obj)
  if obj.name == "Despair_buf.troy" then
    DespairStatus = false
  end
end

function KuroAmumu:Combo()
  
  -- Cast Q for target
  self.Spell_Q:Cast(target)
  
  -- Auto W
  if self.cfg.combo.autow then
    self:CastW("Combo", self.cfg.combo.autowmana)
  end
  
  -- Auto E
  if self.cfg.combo.autoe and (myHero.mana / myHero.maxMana > self.cfg.combo.autoemana / 100) then
    self.Spell_E:Cast(target)
  end
  
  -- Auto R
  if self.cfg.combo.autor and self.Spell_R:IsReady() and myHero.mana >= self.Spell_R:Mana() then
  
    -- If enemy is many, cast on mousepos.
    if self:GetEnemyR() >= self.cfg.combo.autornum then
      CastSpell(_R, mousePos.x, mousePos.y)
    end
  end
end

function KuroAmumu:Harass()
  
  -- Cast Q for target
  self.Spell_Q:Cast(target)
  
  -- Auto W
  if self.cfg.harass.autow then
    self:CastW("Harass", self.cfg.harass.autowmana)
  end
  
  -- Auto E
  if self.cfg.harass.autoe and (myHero.mana / myHero.maxMana > self.cfg.harass.autoemana / 100) then
    self.Spell_E:Cast(target)
  end
end

function KuroAmumu:Clear()

end

function KuroAmumu:LastHit()

end

function KuroAmumu:CastW(mode, minmana)
  if not mode then mode = "Combo" end
  if not minmana then minmana = 0 end
  
  if (myHero.mana / myHero.maxMana > minmana / 100) then
    self:DisableW()
    return
  end
  
  if mode == "Combo" then
    
    -- Find every enemy in range
    if self:GetEnemyW() ~= 0 then
      self:EnableW()
    else
      self:DisableW()
    end
  
  elseif mode == "Harass" then
    
    -- Check Target is InRange.
    if self.Spell_W:ValidTarget(target) then
      self:EnableW()
    else
      self:DisableW()
    end

  elseif mode == "Clear" then
    
    -- Check Object is InRange.
    if NearEnemy then
      self:EnableW()
    else
      self:DisableW()
    end
  end
end

function KuroAmumu:AutoDisableW()
  if DespairStatus and not self:GetAllEnemyW() and self.Spell_W:IsReady() then
    CastSpell(_W, mousePos.x, mousePos.y)
  end
end

function KuroAmumu:EnableW()
  if not DespairStatus and self.Spell_W:IsReady() then
    CastSpell(_W, mousePos.x, mousePos.y)
  end
end

function KuroAmumu:DisableW()
  if DespairStatus and self.Spell_W:IsReady() then
    CastSpell(_W, mousePos.x, mousePos.y)
  end
end

function KuroAmumu:GetAllEnemyW()
  
  -- Update minions.
  jungleMinions:update()
  enemyMinions:update()
  
  if jungleMinions.iCount > 0 or enemyMinions.iCount > 0 or CountEnemyHeroInRange(315) > 0 then
    return true
  else
    return false
  end
end

function KuroAmumu:GetEnemyW()
  
  -- Return enemy in range.
  return CountEnemyHeroInRange(315)
end

function KuroAmumu:GetEnemyR()
  
  -- Set enemy is 0.
  local EnemyCount = 0
  
  -- Find every enemy in range
  for index, value in ipairs(GetEnemyHeroes()) do
    if self.Spell_R:ValidTarget(value) then EnemyCount = EnemyCount + 1 end
  end
  
  -- Return total enemy count.
  return EnemyCount
end