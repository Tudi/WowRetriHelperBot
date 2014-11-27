-- Able to cast spells that have lower than this as cooldown. Spell Queue system to maximize DPS
local SpellCastAllowLatency = 0
-- listing possible texts here so we can take screenshots of them using autoit
local SpellNames = {};
local CombatSpellsStartAt = 0
local CombatSpellsEndAt = 4
SpellNames[0] = "Templar's Verdict";
SpellNames[1] = "Hammer of Wrath";
SpellNames[2] = "Crusader Strike";
SpellNames[3] = "Exorcism";
SpellNames[4] = "Judgment";
SpellNames[5] = "Attack";
SpellNames[6] = "Aquire new target";
SpellNames[7] = "Waiting for combat";
-- defensive spells
local DefensiveSpellsStartAt = 8
local DefensiveSpellsEndAt = 10
SpellNames[8] = "Sacred Shield";
SpellNames[9] = "Hand of Purity";
SpellNames[10] = "Divine Protection";
-- interrupt spells
local InterruptSpellsStartAt = 8
local InterruptSpellsEndAt = 10
SpellNames[11] = "Fist of Justice";
SpellNames[12] = "Rebuke";
SpellNames[13] = "Arcane Torrent";
local QueuedInterruptName = "none"
local QueuedInterruptAtStamp = 0

----------------------
-- 		FRAME SETUP
----------------------
local frame = CreateFrame("FRAME", "NextBestSpell");

frame:SetHeight( 18 )
frame:SetWidth( 12 * 17 )
frame:SetPoint("CENTER", 0, 0)

frame.texture = frame:CreateTexture( nil, "BACKGROUND" )
frame.texture:SetVertexColor( 0.5, 0.5, 0.5 );	-- magic RGB for us to search for 64,64,64
frame.texture:SetTexture( 0.5, 0.5, 0.5, 1 )
frame.texture:SetAllPoints()

frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

frame.text = frame:CreateFontString( nil, "ARTWORK", "GameFontNormal" )
frame.text:SetFont( "Fonts\\Arialn.TTF", 18, "BOLD")
frame.text:SetJustifyH("LEFT")
frame.text:SetShadowColor( 0, 0, 0, 0 )

frame.text:SetAllPoints();
frame.text:SetAlpha( 1 );

--always start with a "." so Autoit can search + focus on it
frame.text:SetText(".0123456789")

frame:RegisterEvent("ADDON_LOADED");
frame:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN");
frame:RegisterEvent("PLAYER_TARGET_CHANGED");
frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");

--frame.text:SetMultiLine( true )
--frame.text:SetText( "Aquire new target\n\r12" );

local function SignalBestAction( NewAction )
	frame.text:SetText( "."..NewAction )
end

local function checkCombat()
	if UnitAffectingCombat('player') then 
		return 1
	end
--[[	if UnitAffectingCombat('player') then 
		return 1
	else
		for i=1,GetNumRaidMembers() do
			if UnitAffectingCombat('raid'..i) or UnitAffectingCombat('raidpet'..i) then 
				return 1 
			end
		end
		for i=1,GetNumPartyMembers() do
			if UnitAffectingCombat('party'..i) or UnitAffectingCombat('partypet'..i) then 
				return 1 
			end
		end
	end ]]--
	return 0
end
	
local DemoMode = -1
local PreviousCheckHealth = 0
local HealthUpdateNextStamp = 0
local function AdviseNextBestAction()
-- /target [@targettarget,harm,nodead,exists] [@focus,harm,nodead,exists] [@focustarget,harm,exists] [harm,nodead,exists]
	
	if( DemoMode ~= -1 ) then
		DemoMode = DemoMode + 1
		if( SpellNames[ DemoMode ] == nil ) then
			DemoMode = 0
		end
		SignalBestAction( SpellNames[ DemoMode ] );
		return
	end

--[[	
	-- If we are loosing health and do not have defensive buffs. Cast Some
	local HealthNow = UnitHealth( "player" )
	local unit = "player";
	if( HealthNow < PreviousCheckHealth and HealthNow > 10 and UnitIsDeadOrGhost( unit ) == false ) then
	
		-- memorize this action for X seconds to not oscilate between decisions
		local runtime = time();
		if( runtime > HealthUpdateNextStamp ) then
			PreviousCheckHealth = HealthNow
			HealthUpdateNextStamp = runtime + 2
		end
		
		for N=DefensiveSpellsStartAt,DefensiveSpellsEndAt,1 do
			local NextSpellName = SpellNamesDef[ N ];
			if( NextSpellName ~= nil ) then
				local usable, nomana = IsUsableSpell( NextSpellName );
				local inRange = IsSpellInRange( NextSpellName, unit )
				local start, duration, enabled = GetSpellCooldown( NextSpellName )
				local name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, shouldConsolidate, spellId = UnitBuff( unit, NextSpellName )
				print(" "..NextSpellName.." usable "..tostring(usable).." nomana "..tostring(nomana).." cooldown "..tostring(duration).." isactive "..tostring(HasThisAura)..".");
--				print( NextSpellName );
				if( usable == true and nomana == false and inRange == 1 and duration <= SpellCastAllowLatency ) then
					SignalBestAction( NextSpellName );
					return;
				end
			end
		end
	end ]]--
	
--[[
	-- Check if our target is casting. If he is casting then we should try to queue an interrupt before cassting ends - interrupt cast time
	]]--
	
	local unit = "target";
	local SelectedAttackSpell = SpellNames[7] --this could be attack also
	
--	 print(" exists "..tostring(UnitExists( unit )).." canattack "..tostring(UnitCanAttack( "player", unit )).." visible "..tostring(UnitIsVisible(unit)).." dead "..tostring(UnitIsDeadOrGhost(unit)));
	if( UnitExists( unit ) == false or UnitCanAttack( "player", unit ) == false or UnitIsVisible(unit) == false or UnitIsDeadOrGhost( unit ) == true ) then
		if( InCombatLockdown() == 1 or checkCombat() == 1 ) then 
			SignalBestAction( SpellNames[6] ); -- if we are in combat we can try to search for a new target
		else
			SignalBestAction( SpellNames[7] );
		end
		return
	end
	
    for N=CombatSpellsStartAt,CombatSpellsEndAt,1 do
		local NextSpellName = SpellNames[ N ];
		if( NextSpellName ~= nil ) then
			local usable, nomana = IsUsableSpell( NextSpellName );
			local inRange = IsSpellInRange( NextSpellName, unit )
			local start, duration, enabled = GetSpellCooldown( NextSpellName )
--			 print(" "..NextSpellName.." usable "..tostring(usable).." nomana "..tostring(nomana).." Exists "..tostring(Exists).." IsVisible "..tostring(IsVisible).." CanAttack "..tostring(CanAttack).." inRange "..tostring(inRange)..".");
--			 print( NextSpellName );
			if( usable == true and nomana == false and inRange == 1 and duration <= SpellCastAllowLatency ) then
				SignalBestAction( NextSpellName );
				return
			end
		end
	end
end

SLASH_TARGETROLE1 = '/NextBestSpell';
SLASH_TARGETROLE2 = '/NBS';
local function slashHandler(msg, editbox)
  local command, rest = msg:match("^(%S*)%s*(.-)$");
  if command == "run" then
    AdviseNextBestAction();
  elseif command == "demo" then
	if( DemoMode == -1 ) then
		print( "Demo mode is on" )
		DemoMode = 0;
	else
		print( "Demo mode is off" )
		DemoMode = -1
	end
  else
    print("Syntax: /NextBestSpell demo");
  end
end
SlashCmdList["TARGETROLE"] = slashHandler;

local function eventHandler(self, event, arg1)
  local runtime = time();
  if event == "ADDON_LOADED" and arg1 == "NextBestSpell" then
    frame:UnregisterEvent("ADDON_LOADED"); 
    print("NextBestSpell loaded");
  elseif OneUpdateThisStamp ~= runtime then
    OneUpdateThisStamp = runtime;
    AdviseNextBestAction(); 
  end
end
frame:SetScript("OnEvent", eventHandler);

function frame:onUpdate(sinceLastUpdate)
	self.sinceLastUpdate = (self.sinceLastUpdate or 0) + sinceLastUpdate;
	if ( self.sinceLastUpdate >= 1 ) then 
		AdviseNextBestAction()
		self.sinceLastUpdate = 0;
	end
end
frame:SetScript("OnUpdate",frame.onUpdate)

