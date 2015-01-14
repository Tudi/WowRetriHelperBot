-- Able to cast spells that have lower than this as cooldown. Spell Queue system to maximize DPS
local SpellCastAllowLatency = 0.35
-- Seconds before a spell cast would end to interrupt the cast. SecondsUntilSpellCastEndToInterruptStart - SecondsUntilSpellCastEndToInterruptEnd = the timeframe until the addon can interrupt a spell. Make it large enough to work for you
local SecondsUntilSpellCastEndToInterruptStart = 1.5	-- put as small as possible to catch all interruptable spells. Needs to be larger than SecondsUntilSpellCastEndToInterruptEnd
local SecondsUntilSpellCastEndToInterruptEnd = 0.5	-- due to global cooldown + addon latency + game latency if you put this to a too small value the interrupt might fail and you wasted interrupt spell
local DoNotInterruptPVPSpellWithCastTimeLessThan = 1501	-- i managed to interrupt 3 instant cast spells in a row. That is definetely getting reported as cheater
-- set this to 0 to disable NPC spell interrupts
local AllowAnyNPCSpellInterrupt = 1
local AllowAnyPlayerSpellInterrupt = 1
local SpellNamesCanInterruptOnPlayers = "[any1][any2]"

-- listing possible texts here so we can take screenshots of them using autoit
local SpellNames = {}
local SpellColorRGB = {}
local SpellRGBStep = 16		-- 255 / 15 = 16
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

SpellNames[IndexCounter] = "Wind Shear"
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

local function SignalBestAction( Index )
--	AutoIt will monitor the colors and send back keys based on it
--	KickBotFrame.text:SetText( Index.." "..SpellColorRGB[ Index ] )
	if( Index <= 0 ) then 
		KickBotFrame.texture:SetVertexColor( 16 / 255.0, 255 / 255.0, 128 / 255.0, 1 ) -- magic number to allow AU3 to find it
	elseif( Index < IndexCounter ) then
		local RGBColor = SpellColorRGB[ Index ] / 255.0
		KickBotFrame.texture:SetVertexColor( RGBColor, RGBColor, RGBColor, 1 )
	end
end

local function AdviseNextBestActionInterrupt( )
	-- Check if our target is casting. If he is casting then we should try to queue an interrupt before cassting ends - interrupt cast time
	local unit = "target";
	local spell, rank, displayName, icon, startTime, endTime, isTradeSkill, castID, InterruptDeny = UnitCastingInfo( unit )
	local cspell, csubText, ctext, ctexture, cstartTime, cendTime, cisTradeSkill, cInterruptDeny = UnitChannelInfo( unit )

--	if( spell ) then
--		local RemainingSecondsToFinishCast = endTime/1000 - GetTime()
--		print(" Target is casting spell "..spell.." can interrupt "..tostring(InterruptDeny).." seconds until finished "..tostring(RemainingSecondsToFinishCast).." we want "..SecondsUntilSpellCastEndToInterruptStart );
--	end
--	if( cspell ) then
--		local RemainingSecondsToFinishCast = cendTime/1000 - GetTime()
--		print(" Target is casting spell "..cspell.." can interrupt "..tostring(cInterruptDeny).." seconds until finished "..tostring(RemainingSecondsToFinishCast).." we want "..SecondsUntilSpellCastEndToInterruptStart );
--	end
	local isPlayer = UnitPlayerControlled( unit )

	local SpellIsInWhiteList = 0
	-- Deny all NPC spell interrupts. But WHY !?!?!?!
	if( AllowAnyNPCSpellInterrupt == 1 and isPlayer ~= 1 ) then
		SpellIsInWhiteList = 1
	elseif( AllowAnyPlayerSpellInterrupt == 1 and isPlayer == 1 ) then
		SpellIsInWhiteList = 1
	elseif( SpellIsInWhiteList == 0 and string.find( SpellNamesCanInterruptOnPlayers, "["..spell.."]" ) ~= nil ) then
		SpellIsInWhiteList = 1
	end
	
	local RemainingSecondsToFinishCast = -1
	if( spell and InterruptDeny == false ) then
		RemainingSecondsToFinishCast = endTime/1000 - GetTime()
		if( isPlayer == 1 and endTime - startTime < DoNotInterruptPVPSpellWithCastTimeLessThan ) then
			print(" player is casting instant spell "..cspell.." cast time "..tostring(endTime - startTime) )
			return
		end
	end
	if( cspell ) then
		RemainingSecondsToFinishCast = SecondsUntilSpellCastEndToInterruptStart
--		 print("channeling : "..cspell.." cstartTime "..tostring(cstartTime).." cendTime "..tostring(cendTime).." cInterruptDeny "..tostring(cInterruptDeny).." RemainingSecondsToFinishCast "..tostring(RemainingSecondsToFinishCast)..".");
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

local DebugTestAll = 0
function KickBot_onUpdate( )
	
	if( DebugTestAll ~= -1 ) then 
		SignalBestAction( DebugTestAll )
		if( PrevTime ~= time() ) then DebugTestAll = DebugTestAll + 1 end
		PrevTime = time()
		if( DebugTestAll >= IndexCounter ) then DebugTestAll = 0 end
		return
	end

	-- interrupt target spell casting if possible
	if( AdviseNextBestActionInterrupt( ) == 1 ) then
		return
	else
		SignalBestAction( 0 )
	end
end


