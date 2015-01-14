-- Able to cast spells that have lower than this as cooldown. Spell Queue system to maximize DPS
local SpellCastAllowLatency = 0.35
-- Seconds before a spell cast would end to interrupt the cast. SecondsUntilSpellCastEndToInterruptStart - SecondsUntilSpellCastEndToInterruptEnd = the timeframe until the addon can interrupt a spell. Make it large enough to work for you
local SecondsUntilSpellCastEndToInterruptStart = 1.5	-- put as small as possible to catch all interruptable spells. Needs to be larger than SecondsUntilSpellCastEndToInterruptEnd
local SecondsUntilSpellCastEndToInterruptEnd = 0.5	-- due to global cooldown + addon latency + game latency if you put this to a too small value the interrupt might fail and you wasted interrupt spell
local DoNotInterruptPVPSpellWithCastTimeLessThan = 1501	-- i managed to interrupt 3 instant cast spells in a row. That is definetely getting reported as cheater
-- set this to 0 to disable NPC spell interrupts
local AllowAnyNPCSpellInterrupt = 1
local AllowAnyPlayerSpellInterrupt = 1
local SpellNamesCanInterruptOnPlayers = ""	-- local SpellNamesCanInterruptOnPlayers = "|Fireball||Frostbolt|"
local SpellNamesCanNotInterrupt = ""

-- listing possible texts here so we can take screenshots of them using autoit
local TargetTypes = {}
TargetTypes[0] = "target"
TargetTypes[1] = "focus"
TargetTypes[2] = "arena1"
TargetTypes[3] = "arena2"
TargetTypes[4] = "arena3"
TargetTypes[5] = "arena4"
TargetTypes[6] = "arena5"
local SpellNames = {}
local SpellColorRGB = {}
local SpellRGBStep = 4		-- 255 / 15 = 16
local IndexCounter = 0
-- when we do nothing we will show this
SpellNames[IndexCounter] = "Waiting for the moonshine"
SpellColorRGB[IndexCounter] = IndexCounter*SpellRGBStep
IndexCounter = IndexCounter + 1
-- interrupt spells
local InterruptSpellsStartAt = IndexCounter

SpellNames[IndexCounter] = "Fist of Justice"
SpellColorRGB[IndexCounter] = IndexCounter*SpellRGBStep
IndexCounter = IndexCounter + 1

SpellNames[IndexCounter] = "Rebuke"
SpellColorRGB[IndexCounter] = IndexCounter*SpellRGBStep
IndexCounter = IndexCounter + 1

SpellNames[IndexCounter] = "Arcane Torrent"
SpellColorRGB[IndexCounter] = IndexCounter*SpellRGBStep
IndexCounter = IndexCounter + 1

SpellNames[IndexCounter] = "Counterspell"
SpellColorRGB[IndexCounter] = IndexCounter*SpellRGBStep
IndexCounter = IndexCounter + 1

SpellNames[IndexCounter] = "Wind Shear"
SpellColorRGB[IndexCounter] = IndexCounter*SpellRGBStep
IndexCounter = IndexCounter + 1

SpellNames[IndexCounter] = "Kick"
SpellColorRGB[IndexCounter] = IndexCounter*SpellRGBStep
IndexCounter = IndexCounter + 1

SpellNames[IndexCounter] = "Counter Shot"
SpellColorRGB[IndexCounter] = IndexCounter*SpellRGBStep
IndexCounter = IndexCounter + 1

SpellNames[IndexCounter] = "Pummel"
SpellColorRGB[IndexCounter] = IndexCounter*SpellRGBStep
IndexCounter = IndexCounter + 1

SpellNames[IndexCounter] = "Spear Hand Strike"
SpellColorRGB[IndexCounter] = IndexCounter*SpellRGBStep
IndexCounter = IndexCounter + 1

SpellNames[IndexCounter] = "Mind Freeze"
SpellColorRGB[IndexCounter] = IndexCounter*SpellRGBStep
IndexCounter = IndexCounter + 1

SpellNames[IndexCounter] = "Strangulate"
SpellColorRGB[IndexCounter] = IndexCounter*SpellRGBStep
IndexCounter = IndexCounter + 1

SpellNames[IndexCounter] = "Hammer of Justice"
SpellColorRGB[IndexCounter] = IndexCounter*SpellRGBStep
IndexCounter = IndexCounter + 1

--print("Index Counter : "..IndexCounter )

local InterruptSpellsEndAt = IndexCounter

function KickBot_OnLoad(self)
	KickBotFrame = self
	KickBotFrame:RegisterForDrag("LeftButton")
	KickBotFrame:SetScript("OnUpdate",KickBot_onUpdate)

	KickBotFrame.texture = KickBotFrame:CreateTexture( nil, "BACKGROUND" )
	KickBotFrame.texture:SetTexture( 1, 1, 1, 1 )
	KickBotFrame.texture:SetAllPoints()

	KickBotFrame.text = KickBotFrame:CreateFontString( nil, "ARTWORK", "GameFontNormal" )
	KickBotFrame.text:SetFont( "Fonts\\Arialn.TTF", 18, "BOLD")
	KickBotFrame.text:SetJustifyH("LEFT")
	KickBotFrame.text:SetShadowColor( 0, 0, 0, 0 )
	KickBotFrame.text:SetAlpha( 1 );
	KickBotFrame.text:SetAllPoints();
	
    print("KickBot loaded.Don't forget to start AU3 script. To stop AU3 press '['. To pause AU3 press '\\'.");
end

local DebugLastValue = -1
local function SignalBestAction( Index, TargetTypeIndex )
--	AutoIt will monitor the colors and send back keys based on it
--	KickBotFrame.text:SetText( Index.." "..SpellColorRGB[ Index ] )
	if( Index <= 0 ) then 
		KickBotFrame.texture:SetVertexColor( 16 / 255.0, 255 / 255.0, 128 / 255.0, 1 ) -- magic number to allow AU3 to find it
		DebugLastValue = -1
	elseif( Index < IndexCounter ) then
		local RGBColor = SpellColorRGB[ Index ] / 255.0
		local TargetTypeRGB = ( TargetTypeIndex + 1 ) * SpellRGBStep / 255.0
		KickBotFrame.texture:SetVertexColor( TargetTypeRGB, RGBColor, RGBColor, 1 )
--		if( DebugLastValue ~= Index ) then
--			print( "Change state to "..Index.." target "..TargetTypeIndex )
--		end
		DebugLastValue = Index
	end
end

local function AdviseNextBestActionInterrupt( TargetTypeIndex )
	-- Check if our target is casting. If he is casting then we should try to queue an interrupt before cassting ends - interrupt cast time
	local unit = TargetTypes[ TargetTypeIndex ];
	local spell, rank, displayName, icon, startTime, endTime, isTradeSkill, castID, InterruptDeny = UnitCastingInfo( unit )
	local cspell, csubText, ctext, ctexture, cstartTime, cendTime, cisTradeSkill, cInterruptDeny = UnitChannelInfo( unit )

--[[	
	if( spell ) then
		local RemainingSecondsToFinishCast = endTime/1000 - GetTime()
		print(" Target is casting spell "..spell.." interruptdeny '"..tostring(InterruptDeny).."' seconds until finished "..tostring(RemainingSecondsToFinishCast).." we want "..SecondsUntilSpellCastEndToInterruptStart );
	end
	if( cspell ) then
		local RemainingSecondsToFinishCast = cendTime/1000 - GetTime()
		print(" Target is casting spell "..cspell.." interruptdeny '"..tostring(cInterruptDeny).."' seconds until finished "..tostring(RemainingSecondsToFinishCast).." we want "..SecondsUntilSpellCastEndToInterruptStart );
	end
	]]--
	
	local isPlayer = UnitPlayerControlled( unit )

	if( not spell and not cspell ) then
		return
	end
	
	local SpellName = spell
	if( SpellName == nil ) then 
		SpellName = cspell
	end
	
	local SpellIsInWhiteList = 0
	-- Deny all NPC spell interrupts. But WHY !?!?!?!
	if( AllowAnyNPCSpellInterrupt == 1 and isPlayer ~= 1 ) then
--		print( "Target is NPC" )
		SpellIsInWhiteList = 1
	elseif( AllowAnyPlayerSpellInterrupt == 1 and isPlayer == 1 ) then
--		print( "Can interrupt all target player spells" )
		SpellIsInWhiteList = 1
	elseif( string.find( SpellNamesCanInterruptOnPlayers, "(|"..SpellName.."|)" ) ~= nil ) then
--		print( "Spell "..SpellName.." can be interrupted because of whitelist" )
		SpellIsInWhiteList = 1
	end
	
	if( SpellIsInWhiteList ~= 1 ) then
--		print("spell "..SpellName.." is not in whitelist " )
		return
	end
	
	if( string.find( SpellNamesCanNotInterrupt, "(|"..SpellName.."|)" ) ~= nil ) then
--local s1,s2,s3,s4 = string.find( SpellNamesCanNotInterrupt, "(|"..SpellName.."|)" )
--print( "s1 "..tostring(s1).." s2 "..tostring(s2).." ".." s3 "..tostring(s3).." s4 "..tostring(s4)..SpellNamesCanNotInterrupt )
--		print("spell "..SpellName.." is in blacklist " )
		return
	end
	
	local RemainingSecondsToFinishCast = -1
	if( spell and InterruptDeny == false ) then
		RemainingSecondsToFinishCast = endTime/1000 - GetTime()
		if( isPlayer == 1 and endTime - startTime < DoNotInterruptPVPSpellWithCastTimeLessThan ) then
--			print(" player is casting instant spell "..cspell.." cast time "..tostring(endTime - startTime) )
			return
		end
	end
	if( cspell ) then
		RemainingSecondsToFinishCast = SecondsUntilSpellCastEndToInterruptStart
--		 print("channeling : "..cspell.." cstartTime "..tostring(cstartTime).." cendTime "..tostring(cendTime).." cInterruptDeny "..tostring(cInterruptDeny).." RemainingSecondsToFinishCast "..tostring(RemainingSecondsToFinishCast)..".");
	end
	if( RemainingSecondsToFinishCast <= SecondsUntilSpellCastEndToInterruptStart and RemainingSecondsToFinishCast >= SecondsUntilSpellCastEndToInterruptEnd ) then
--			print( InterruptSpellsStartAt.." "..InterruptSpellsEndAt )
			for N=InterruptSpellsStartAt,InterruptSpellsEndAt,1 do
				local NextSpellName = SpellNames[ N ];
--				print( N.." "..NextSpellName )
				if( NextSpellName ~= nil ) then
					local usable, nomana = IsUsableSpell( NextSpellName )
					local inRange = IsSpellInRange( NextSpellName, unit )
--					local inRange2 = UnitInRange( unit )	--40 yards range check, should be the same as spell in range, only that AOE spells have radius and not range
					local start, duration, enabled = GetSpellCooldown( NextSpellName )
--					print(" "..NextSpellName.." usable "..tostring(usable).." nomana "..tostring(nomana).." inRange "..tostring(inRange).." coldown "..tostring(duration)..".")
					if( ( usable == true or usable == 1 ) and ( nomana == false or nomana == nil ) and ( inRange == 1 or inrange == nil ) and duration <= SpellCastAllowLatency ) then
--						print( " advising : "..NextSpellName.." on target (string) '"..unit.."'" );
						SignalBestAction( N, TargetTypeIndex );
						return 1
					end
				end
			end
	end
	return 0
end

local DebugTestAll = -1
function KickBot_onUpdate( )
	
	if( DebugTestAll ~= -1 ) then 
		SignalBestAction( DebugTestAll, DebugTestAll )
		if( PrevTime ~= time() ) then DebugTestAll = DebugTestAll + 1 end
		PrevTime = time()
		if( DebugTestAll >= IndexCounter ) then DebugTestAll = 0 end
		return
	end

	-- interrupt target spell casting if possible
	if( AdviseNextBestActionInterrupt( 0 ) == 1 ) then	-- target
		return
	elseif( AdviseNextBestActionInterrupt( 1 ) == 1 ) then	-- focus
		return
	elseif( AdviseNextBestActionInterrupt( 2 ) == 1 ) then	-- arena1
		return
	elseif( AdviseNextBestActionInterrupt( 3 ) == 1 ) then	-- arena2
		return
	elseif( AdviseNextBestActionInterrupt( 4 ) == 1 ) then	-- arena3
		return
	elseif( AdviseNextBestActionInterrupt( 5 ) == 1 ) then	-- arena4
		return
	elseif( AdviseNextBestActionInterrupt( 6 ) == 1 ) then	-- arena5
		return
	else
		SignalBestAction( 0 )
	end
end


