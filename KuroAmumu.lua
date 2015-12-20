--[[
  
      __ __                    _____           _       __     _____           _          
     / //_/_  ___________     / ___/__________(_)___  / /_   / ___/___  _____(_)__  _____
    / ,< / / / / ___/ __ \    \__ \/ ___/ ___/ / __ \/ __/   \__ \/ _ \/ ___/ / _ \/ ___/
   / /| / /_/ / /  / /_/ /   ___/ / /__/ /  / / /_/ / /_    ___/ /  __/ /  / /  __(__  ) 
  /_/ |_\__,_/_/   \____/   /____/\___/_/  /_/ .___/\__/   /____/\___/_/  /_/\___/____/  
                                            /_/                                          

  Kuro Script Series - Kuro Amumu
                       by. KuroXNeko
]]--

if not myHero then
  myHero = GetmyHero()
end
if myHero.charName ~= "Amumu" then return end

local ScriptVersion = 1.00
local ScriptVersionDisp = "1.00"
local ScriptUpdate = "20.12.2015"
local SupportedVersion = "5.24"
local target = nil
local DespairStatus = false
local jungleMinions = minionManager(MINION_JUNGLE, 350, myHero)
local enemyMinions = minionManager(MINION_ENEMY, 350, myHero)
local LastCastingPacket = ""


-- [Shared Function] --

function toHex(int)
  return "0x"..string.format("%04X",int)
end

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
      UpdateInfo.CallbackUpdate = function(NewVersion, OldVersion) print_msg("Updated to v".. NewVersion ..". Press F9x2!") end
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
  DelayAction(function() print_msg("Lastset version (v".. ScriptVersion ..") loaded!") end, 2)
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
  self.Spell_Q:AddDraw({Enable = true, Color = {255,0,125,255}})
  
  self.Spell_W = _Spell({Slot = _W, DamageName = "W", Range = 300, Delay = 0, Aoe = true, Type = SPELL_TYPE.SELF})
  self.Spell_W:AddDraw({Enable = false, Color = {255,255,140,0}})
  
  self.Spell_E = _Spell({Slot = _E, DamageName = "E", Range = 350, Delay = 0.125, Aoe = true, Type = SPELL_TYPE.SELF})
  self.Spell_E:AddDraw({Enable = true, Color = {255,170,0,255}})
  
  self.Spell_R = _Spell({Slot = _R, DamageName = "R", Range = 550, Delay = 0.25, Aoe = true, Type = SPELL_TYPE.SELF})
  self.Spell_R:AddDraw({Enable = true, Color = {255,255,0,0}})
  
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
      self.cfg.harass:addParam("autoq", "Use Q", SCRIPT_PARAM_ONOFF, false)
      self.cfg.harass:addParam("info1", "", SCRIPT_PARAM_INFO, "")
      self.cfg.harass:addParam("autow", "Use Auto W", SCRIPT_PARAM_ONOFF, false)
      self.cfg.harass:addParam("autowmana", "Auto W Mana", SCRIPT_PARAM_SLICE, 20,0,100)
      self.cfg.harass:addParam("info2", "", SCRIPT_PARAM_INFO, "")
      self.cfg.harass:addParam("autoe", "Use Auto E", SCRIPT_PARAM_ONOFF, true)
      self.cfg.harass:addParam("autoemana", "Auto E Mana", SCRIPT_PARAM_SLICE, 30,0,100)
      
  -- Lane & Jungle Clear
  self.cfg:addSubMenu("Clear Setting", "clear")
      self.cfg.clear:addParam("info1", "---- Lane Clear ----", SCRIPT_PARAM_INFO, "")
      self.cfg.clear:addParam("lanew", "Use W", SCRIPT_PARAM_ONOFF, false)
      self.cfg.clear:addParam("lanewmana", "W Mana", SCRIPT_PARAM_SLICE, 20,0,100)
      self.cfg.clear:addParam("info2", "", SCRIPT_PARAM_INFO, "")
      self.cfg.clear:addParam("lanee", "Use E", SCRIPT_PARAM_ONOFF, true)
      self.cfg.clear:addParam("laneemana", "E Mana", SCRIPT_PARAM_SLICE, 50,0,100)
      self.cfg.clear:addParam("info3", "", SCRIPT_PARAM_INFO, "")
      self.cfg.clear:addParam("lanecount", "Min Minion Count", SCRIPT_PARAM_SLICE, 2,0,8)
      self.cfg.clear:addParam("info4", "", SCRIPT_PARAM_INFO, "")
      self.cfg.clear:addParam("info5", "---- Jungle Clear ----", SCRIPT_PARAM_INFO, "")
      self.cfg.clear:addParam("jungleq", "Use Q", SCRIPT_PARAM_ONOFF, true)
      self.cfg.clear:addParam("jungleqlong", "Use Q only jungle is far.", SCRIPT_PARAM_ONOFF, true)
      self.cfg.clear:addParam("info6", "", SCRIPT_PARAM_INFO, "")
      self.cfg.clear:addParam("junglew", "Use W", SCRIPT_PARAM_ONOFF, true)
      self.cfg.clear:addParam("junglewmana", "W Mana", SCRIPT_PARAM_SLICE, 0,0,100)
      self.cfg.clear:addParam("info7", "", SCRIPT_PARAM_INFO, "")
      self.cfg.clear:addParam("junglee", "Use E", SCRIPT_PARAM_ONOFF, true)
      self.cfg.clear:addParam("jungleemana", "E Mana", SCRIPT_PARAM_SLICE, 0,0,100)
  
  
  -- Lasthit
  self.cfg:addSubMenu("Lasthit Setting", "lasthit")
      self.cfg.lasthit:addParam("smarte", "Use Smart Lasthit E", SCRIPT_PARAM_ONOFF, true)
      self.cfg.lasthit:addParam("smartemana", "E Mana", SCRIPT_PARAM_SLICE, 50,0,100)
      
      
  -- Spell Menu with SimpleLib.
  --self.cfg:addSubMenu("Spell Setting", "spell")
  
  -- Draw Menu
  self.cfg:addSubMenu("Draw Setting", "draw")
      self.cfg.draw:addParam("info1", "What do you want to draw?", SCRIPT_PARAM_INFO, "")
      
  -- Key Menu with SimpleLib
  self.cfg:addSubMenu("Key Setting", "key")
      OrbwalkManager:LoadCommonKeys(self.cfg.key)
      self.cfg.key:addParam("info1", "---- Other Key ----", SCRIPT_PARAM_INFO, "")
      self.cfg.key:addParam("manualr", "Manually cast R", SCRIPT_PARAM_ONKEYTOGGLE, false, string.byte("T"))
      self.cfg.key:permaShow("manualr")
      
  -- Etc
  self.cfg:addSubMenu("Msic Setting", "msic")
      self.cfg.msic:addParam("autodisablew", "Auto disable W", SCRIPT_PARAM_ONOFF, true)
      self.cfg.msic:addParam("info1", "Auto disable W can have some bug", SCRIPT_PARAM_INFO, "")
      self.cfg.msic:addParam("info2", "when you reload or reconnect during game.", SCRIPT_PARAM_INFO, "")
      self.cfg.msic:addParam("info3", "", SCRIPT_PARAM_INFO, "")
      self.cfg.msic:addParam("blockr", "Block R", SCRIPT_PARAM_ONOFF, false)
      self.cfg.msic:addParam("info4", "Block R when outrange. (For VIP)", SCRIPT_PARAM_INFO, "")
      self.cfg.msic:addParam("info5", "", SCRIPT_PARAM_INFO, "")
      self.cfg.msic:addParam("manualr", "Manually R Chmps", SCRIPT_PARAM_SLICE, 3,1,5)
      self.cfg.msic:addParam("info5", "If you press manually casting key", SCRIPT_PARAM_INFO, "")
      self.cfg.msic:addParam("info5", "script try to cast R if champ is near.", SCRIPT_PARAM_INFO, "")
      self.cfg.msic:addParam("info7", "", SCRIPT_PARAM_INFO, "")
      self.cfg.msic:addParam("checkwdistance", "Check Hero W Distance", SCRIPT_PARAM_SLICE, 400,300,500)
      self.cfg.msic:addParam("checkrdistance", "Check Hero R Distance", SCRIPT_PARAM_SLICE, 500,400,550)
      self.cfg.msic:addParam("info8", "Low R distance makes better CC.", SCRIPT_PARAM_INFO, "")
      self.cfg.msic:addParam("info9", "", SCRIPT_PARAM_INFO, "")
      self.cfg.msic:addParam("debug", "Debug Mode", SCRIPT_PARAM_ONOFF, false)
    
  -- Info
  self.cfg:addParam("info1", "", SCRIPT_PARAM_INFO, "")
  self.cfg:addParam("info2", "Script version", SCRIPT_PARAM_INFO, ScriptVersionDisp)
  self.cfg:addParam("info3", "Last update", SCRIPT_PARAM_INFO, ScriptUpdate)
  self.cfg:addParam("info4", "Supported LoL Version", SCRIPT_PARAM_INFO, SupportedVersion)
  self.cfg:addParam("info5", "", SCRIPT_PARAM_INFO, "")
  self.cfg:addParam("info6", "Script developed by KuroXNeko", SCRIPT_PARAM_INFO, "")
  
  -- Set CallBack.
  AddDrawCallback(function() self:Draw() end)
  AddTickCallback(function() self:Tick() end)
  AddCastSpellCallback(function(slot) self:OnCastSpell(slot) end)
  AddDeleteObjCallback(function(obj) self:OnDeleteObj(obj) end)
  
  -- for VIP
  if VIP_USER and string.find(GetGameVersion(), "Releases/"..SupportedVersion) then
    AddSendPacketCallback(function(p) self:OnSendPacket(p) end)
  end
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
    DrawText("Last Casting Packet: "..tostring(LastCastingPacket), 20, 80, 220, ARGB(255,255,255,255))
    
    local jungle_q = self.Spell_Q:JungleClear({UseCast = false})
    if jungle_q then
      DrawText("Distance Jungle Q: "..GetDistance(jungle_q, myHero), 20, 80, 250, ARGB(255,255,255,255))
      DrawCircle3D(jungle_q.x, jungle_q.y, jungle_q.z, 100, 2, ARGB(255,255,255,255), 8) 
    end
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
  
  if self.cfg.key.manualr then
    self:ManualCastR()
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

-- 5.24 Q "0x00A8", W "0x0054", E "0x0027", R "0x005F", D "Ignite, 0x0005", F "Flash, 0x0085"
function KuroAmumu:OnSendPacket(p)
  if p.header == 0x00A6 then
    p.pos = 18
    local spell = toHex(p:Decode1())
    LastCastingPacket = spell
    if spell == "0x005F" then
      if self.cfg.msic.blockr and self:GetEnemyR() == 0 then
        print_msg("Block R because no one here!")
        p:Block()
      end
    end 
  end
end

function KuroAmumu:Combo()
  
  -- Cast Q for target
  self.Spell_Q:Cast(target)
  
  -- Auto W
  if self.cfg.combo.autow then
    if self:GetEnemyW() ~= 0 and self:CheckMana(self.cfg.combo.autowmana) then
      self:EnableW()
    else
      self:DisableW()
    end
  end
  
  -- Auto E
  if self.cfg.combo.autoe and self.Spell_E:IsReady() and self.Spell_E:ValidTarget(target) and self:CheckMana(self.cfg.combo.autoemana) then
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
  if self.cfg.harass.autoq then
    self.Spell_Q:Cast(target)
  end
  
  -- Auto W
  if self.cfg.harass.autow then
    if self:GetEnemyW() ~= 0 and self:CheckMana(self.cfg.harass.autowmana) then
      self:EnableW()
    else
      self:DisableW()
    end
  end
  
  -- Auto E
  if self.cfg.harass.autoe and self.Spell_E:ValidTarget(target) and self:CheckMana(self.cfg.harass.autoemana) then
    self.Spell_E:Cast(target)
  end
end

function KuroAmumu:Clear()
  
  -- Get Minion
  local minion = self:GetMinionW()
  local jungle = self:GetJungleW()
  local jungle_Q = self.Spell_Q:JungleClear({UseCast = false})
  
  -- Lane Clear
  if minion >= self.cfg.clear.lanecount then
    
    -- W
    if self.cfg.clear.lanew and self:CheckMana(self.cfg.clear.lanewmana) then
      self:EnableW()
    else
      self:DisableW()
    end
    
    -- E
    if self.cfg.clear.lanee and self.Spell_E:IsReady() and self:CheckMana(self.cfg.clear.laneemana) then
      CastSpell(_E, mousePos.x, mousePos.y)
    end
  end
  
  
  -- Jungle Clear
  if jungle > 0 then
    
    -- W
    if self.cfg.clear.junglew and self:CheckMana(self.cfg.clear.junglewmana) then
      self:EnableW()
    else
      self:DisableW()
    end
    
    -- E
    if self.cfg.clear.junglee and self.Spell_E:IsReady() and self:CheckMana(self.cfg.clear.jungleemana) then
      CastSpell(_E, mousePos.x, mousePos.y)
    end
  end
  
  -- Jungle Q
  if jungle_Q and self.cfg.clear.jungleq then
    
    -- Check distance
    if self.cfg.clear.jungleqlong and GetDistance(myHero, jungle_Q) >= 400 then
      
      -- Cast Spell
      self.Spell_Q:Cast(jungle_Q)
      
    -- If "Check distance" is disabled
    elseif not self.cfg.clear.jungleqlong then
    
      -- Just Cast Spell
      self.Spell_Q:Cast(jungle_Q)
    end
  end
  
  -- Auto Disable W
  self:AutoDisableW()
end

function KuroAmumu:LastHit()
  
  -- Config Check.
  if not self.cfg.lasthit.smarte then return end
  
  -- Get Lasthit with E
  local lasthit_target = self.Spell_E:LastHit()
  
  -- Cast spell
  if lasthit_target and self:CheckMana(self.cfg.lasthit.smartemana) then
    self.Spell_E:Cast(lasthit_target)
  end
end

function KuroAmumu:ManualCastR()
  
  -- Check Enemy is more then setting
  if self:GetEnemyR() >= self.cfg.msic.manualr then
    CastSpell(_R, mousePos.x, mousePos.y)
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
  
  if jungleMinions.iCount > 0 or enemyMinions.iCount > 0 or CountEnemyHeroInRange(self.cfg.msic.checkwdistance) > 0 then
    return true
  else
    return false
  end
end

function KuroAmumu:GetMinionW()
  
  -- Update minions.
  enemyMinions:update()
  
  -- Return Count
  return enemyMinions.iCount
end

function KuroAmumu:GetJungleW()
  
  -- Update minions.
  jungleMinions:update()
  
  -- Return Count
  return jungleMinions.iCount
end

function KuroAmumu:GetEnemyW()
  
  -- Return enemy in range.
  return CountEnemyHeroInRange(self.cfg.msic.checkwdistance)
end

function KuroAmumu:GetEnemyR()
  
  -- Find every enemy in range
  return CountEnemyHeroInRange(self.cfg.msic.checkrdistance)
end

function KuroAmumu:CheckMana(mana)
  
  if not mana then mana = 100 end
  
  -- Check Mana
  if myHero.mana / myHero.maxMana > mana / 100 then
    return true
  else 
    return false
  end
end
