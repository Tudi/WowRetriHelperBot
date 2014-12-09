-- Able to cast spells that have lower than this as cooldown. Spell Queue system to maximize DPS
local SpellCastAllowLatency = 0
-- MAX Health PCT required for defensive buffs to be casted. 
local MaxCharHealthPCTForDefensiveCasts = 80
-- Number of seconds need to pass until we check our heath change again. If too large than we could die before we shield up. If too low than we might shield up even when healer is doing a fine job
local SecondPeriodCheckHealthChange = 3
-- if we are in combat and we have nothing else to do ( enemy is too far or we are not facing him ) than shield up
local ShieldUpWhileIdleInCombat = 1
-- Seconds before a spell cast would end to interrupt the cast. SecondsUntilSpellCastEndToInterruptStart - SecondsUntilSpellCastEndToInterruptEnd = the timeframe until the addon can interrupt a spell. Make it large enough to work for you
local SecondsUntilSpellCastEndToInterruptStart = 2.0	-- put as small as possible to catch all interruptable spells. Needs to be larger than SecondsUntilSpellCastEndToInterruptEnd
local SecondsUntilSpellCastEndToInterruptEnd = 0.5	-- due to global cooldown + addon latency + game latency if you put this to a too small value the interrupt might fail and you wasted interrupt spell

-- listing possible texts here so we can take screenshots of them using autoit
local SpellNames = {};
local SpellSignalPrefix = {};	-- to be more clear will add the keyboard shortcut the autoit script is supposed to push
local CombatSpellsStartAt = 0
local CombatSpellsEndAt = 4
SpellNames[0] = "Templar's Verdict";
SpellSignalPrefix[0] = "1";
SpellNames[1] = "Hammer of Wrath";
SpellSignalPrefix[1] = "2";
SpellNames[2] = "Crusader Strike";
SpellSignalPrefix[2] = "3";
SpellNames[3] = "Exorcism";
SpellSignalPrefix[3] = "4";
SpellNames[4] = "Judgment";
SpellSignalPrefix[4] = "5";
SpellNames[5] = "Attack";
SpellSignalPrefix[5] = "-";
SpellNames[6] = "Aquire new target";
SpellSignalPrefix[6] = "9";
SpellNames[7] = "Waiting for combat";
SpellSignalPrefix[7] = "+";
-- defensive spells
local DefensiveSpellsStartAt = 8
local DefensiveSpellsEndAt = 10
SpellNames[8] = "Sacred Shield";
SpellSignalPrefix[8] = "0";
SpellNames[9] = "Hand of Purity";
SpellSignalPrefix[9] = "-";
SpellNames[10] = "Divine Protection";
SpellSignalPrefix[10] = "=";
-- interrupt spells
local InterruptSpellsStartAt = 11
local InterruptSpellsEndAt = 13
SpellNames[11] = "Fist of Justice";
SpellSignalPrefix[11] = "6";
SpellNames[12] = "Rebuke";
SpellSignalPrefix[12] = "7";
SpellNames[13] = "Arcane Torrent";
SpellSignalPrefix[13] = "8";
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

frame.text:SetText(".0123456789")

frame:RegisterEvent("ADDON_LOADED");
frame:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN");
frame:RegisterEvent("PLAYER_TARGET_CHANGED");
frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED");

--frame.text:SetMultiLine( true )
--frame.text:SetText( "Aquire new target\n\r12" );

local function SignalBestAction( Index )
	--always start with a "." so Autoit can search + focus on it
	frame.text:SetText( "."..SpellSignalPrefix[ Index ]..SpellNames[ Index ] )
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

local PreviousCheckHealth = 0
local HealthUpdateNextStamp = 0
local function AdviseNextBestActionDefensive( CantDoAnythingElseAndInCombat, unit )
	
	if( unit == nil ) then
		unit = "player"
	end
	-- If we are loosing health and do not have defensive buffs. Cast Some
	local runtime = time()
	if( runtime > HealthUpdateNextStamp or CantDoAnythingElseAndInCombat == 1 ) then
		unit = "player";
		local HealthNow = UnitHealth( unit )
		local HealthMax = UnitHealthMax( unit )
		-- only shield if healer is not doing he's job properly
		local HealthPCT	= HealthNow * 100 / HealthMax
		if( CantDoAnythingElseAndInCombat == 1 or ( HealthNow < PreviousCheckHealth and HealthNow > 10 and HealthPCT < MaxCharHealthPCTForDefensiveCasts and UnitIsDeadOrGhost( unit ) == false ) ) then
			for N=DefensiveSpellsStartAt,DefensiveSpellsEndAt,1 do
				local NextSpellName = SpellNames[ N ];
				if( NextSpellName ~= nil ) then
					local usable, nomana = IsUsableSpell( NextSpellName );
					local inRange = IsSpellInRange( NextSpellName, unit )
					local start, duration, enabled = GetSpellCooldown( NextSpellName )
					local name, rank, icon, count, debuffType, auraduration, expirationTime, unitCaster, isStealable, shouldConsolidate, spellId = UnitAura( unit, NextSpellName )
--					print(" "..NextSpellName.." usable "..tostring(usable).." nomana "..tostring(nomana).." inrange "..tostring(inRange).." cooldown "..tostring(duration).." isactive "..tostring(spellId)..".");
					if( usable == true and nomana == false and ( inRange == 1 or inrange == nil ) and duration <= SpellCastAllowLatency and spellId == nil ) then
--						print( " advising : "..NextSpellName );
						SignalBestAction( N );
						return 1
					end
				end
			end
		end
		-- put this before loop if you do not wish to cast all defensive spells one after another
		PreviousCheckHealth = HealthNow
		HealthUpdateNextStamp = runtime + SecondPeriodCheckHealthChange
	end 
	return 0
end

local function AdviseNextBestActionInterrupt( )
	-- Check if our target is casting. If he is casting then we should try to queue an interrupt before cassting ends - interrupt cast time
	local unit = "target";
	local spell, rank, displayName, icon, startTime, endTime, isTradeSkill, castID, InterruptDeny = UnitCastingInfo( unit )
	local cspell, csubText, ctext, ctexture, cstartTime, cendTime, cisTradeSkill, cInterruptDeny = UnitChannelInfo("unit")

--	if( spell ) then
--		local RemainingSecondsToFinishCast = endTime/1000 - GetTime()
--		print(" Target is casting spell "..spell.." can interrupt "..tostring(InterruptDeny).." seconds until finished "..tostring(RemainingSecondsToFinishCast).." we want "..SecondsUntilSpellCastEndToInterruptStart );
--	end
--	if( cspell ) then
--		local RemainingSecondsToFinishCast = cendTime/1000 - GetTime()
--		print(" Target is casting spell "..cspell.." can interrupt "..tostring(cInterruptDeny).." seconds until finished "..tostring(RemainingSecondsToFinishCast).." we want "..SecondsUntilSpellCastEndToInterruptStart );
--	end
	local RemainingSecondsToFinishCast = -1
	if( spell and InterruptDeny == false ) then
		RemainingSecondsToFinishCast = endTime/1000 - GetTime()
	end
	if( cspell and cInterruptDeny == false ) then
		RemainingSecondsToFinishCast = SecondsUntilSpellCastEndToInterruptStart
		 print("channeling : "..cspell.." cstartTime "..tostring(cstartTime).." cendTime "..tostring(cendTime).." cInterruptDeny "..tostring(cInterruptDeny).." RemainingSecondsToFinishCast "..tostring(RemainingSecondsToFinishCast)..".");
	end
	if( RemainingSecondsToFinishCast <= SecondsUntilSpellCastEndToInterruptStart and RemainingSecondsToFinishCast >= SecondsUntilSpellCastEndToInterruptEnd ) then
			for N=InterruptSpellsStartAt,InterruptSpellsEndAt,1 do
				local NextSpellName = SpellNames[ N ];
				if( NextSpellName ~= nil ) then
					local usable, nomana = IsUsableSpell( NextSpellName )
					local inRange = IsSpellInRange( NextSpellName, unit )
--					local inRange2 = UnitInRange( unit )	--40 yards range check, should be the same as spell in range, only that AOE spells have radius and not range
					local start, duration, enabled = GetSpellCooldown( NextSpellName )
--					 print(" "..NextSpellName.." usable "..tostring(usable).." nomana "..tostring(nomana).." inRange "..tostring(inRange).." coldown "..tostring(duration)..".");
					if( usable == true and nomana == false and ( inRange == 1 or inrange == nil ) and duration <= SpellCastAllowLatency ) then
--						print( " advising : "..NextSpellName );
						SignalBestAction( N );
						return 1
					end
				end
			end
	end
	return 0
end

local function AdviseNextBestActionCombatDPS( )
	local unit = "target";
	local SelectedAttackSpell = SpellNames[7] --this could be attack also	
    for N=CombatSpellsStartAt,CombatSpellsEndAt,1 do
		local NextSpellName = SpellNames[ N ];
		if( NextSpellName ~= nil ) then
			local usable, nomana = IsUsableSpell( NextSpellName );
			local inRange = IsSpellInRange( NextSpellName, unit )
			local start, duration, enabled = GetSpellCooldown( NextSpellName )
--			 print(" "..NextSpellName.." usable "..tostring(usable).." nomana "..tostring(nomana).." Exists "..tostring(Exists).." IsVisible "..tostring(IsVisible).." CanAttack "..tostring(CanAttack).." inRange "..tostring(inRange)..".");
--			 print( NextSpellName );
			if( usable == true and nomana == false and inRange == 1 and duration <= SpellCastAllowLatency ) then
				SignalBestAction( N );
				return 1
			end
		end
	end
	
	return 0
end
	
local DemoMode = -1
local function AdviseNextBestAction()
-- /target [@targettarget,harm,nodead,exists] [@focus,harm,nodead,exists] [@focustarget,harm,exists] [harm,nodead,exists]
	
	if( DemoMode ~= -1 ) then
		DemoMode = DemoMode + 1
		if( SpellNames[ DemoMode ] == nil ) then
			DemoMode = 0
		end
		SignalBestAction( DemoMode );
		return
	end

	local unit = "target";
	local SelectedAttackSpell = SpellNames[7] --this could be attack also
	
--	 print(" exists "..tostring(UnitExists( unit )).." canattack "..tostring(UnitCanAttack( "player", unit )).." visible "..tostring(UnitIsVisible(unit)).." dead "..tostring(UnitIsDeadOrGhost(unit)));
	if( UnitExists( unit ) == false or UnitCanAttack( "player", unit ) == false or UnitIsVisible(unit) == false or UnitIsDeadOrGhost( unit ) == true ) then
		if( InCombatLockdown() == 1 or checkCombat() == 1 ) then 
			SignalBestAction( 6 ); -- if we are in combat we can try to search for a new target
		else
			SignalBestAction( 7 );
		end
		return 1
	end
	
	-- interrupt target spell casting if possible
	if( AdviseNextBestActionInterrupt( ) == 1 ) then
		return
	end
	
	-- if our health is low / dropping and nobody is healing us than try to shield ourself to prevent further damage
	if( AdviseNextBestActionDefensive( 0, nil ) == 1 ) then
		return
	end
	
	-- check if we can take actions that would maximize our DPS : target an enemy + cast best spell
	if( AdviseNextBestActionCombatDPS( ) == 1 ) then
		return
	end
	
	-- if we could not cast any spells on target than try to shield ourself out of boredom
	if( ShieldUpWhileIdleInCombat == 0 or AdviseNextBestActionDefensive( 1, nil ) == 0 ) then
		SignalBestAction( 7 )
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


