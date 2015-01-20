-- Able to cast spells that have lower than this as cooldown. Spell Queue system to maximize interrupt precision. My avg latency is 0.35. You can experiment what is best for you
local SpellCastAllowLatency = 0.01
-- Seconds before a spell cast would end to interrupt the cast. SecondsUntilSpellCastEndToInterruptStart - SecondsUntilSpellCastEndToInterruptEnd = the timeframe until the addon can interrupt a spell. Make it large enough to work for you
local SecondsUntilSpellCastEndToInterruptStart = 1.5	-- put as small as possible to catch all interruptable spells. Needs to be larger than SecondsUntilSpellCastEndToInterruptEnd
local SecondsUntilSpellCastEndToInterruptEnd = 0.5	-- due to global cooldown + addon latency + game latency if you put this to a too small value the interrupt might fail and you wasted interrupt spell
local DoNotInterruptPVPSpellWithCastTimeLessThan = 1002	-- i managed to interrupt 3 instant cast spells in a row. That is definetely getting reported as cheater
-- set this to 0 to disable NPC spell interrupts
local AllowAnyNPCSpellInterrupt = 1
-- set this to 0 if you want to specify a list of spells to interrupt for players
local AllowAnyPlayerSpellInterrupt = 1
-- white list of spell names. The ones that LUA is allowed to automatically interrupt. This list is only used if you set AllowAnyPlayerSpellInterrupt=0
local SpellNamesCanInterruptOnPlayers = ""	-- local SpellNamesCanInterruptOnPlayers = "Fireball|Frostbolt"
-- black list of spells names. The ones that LUA is NOT allowed to automatically interrupt. This list is always used
local SpellNamesCanNotInterrupt = ""
-- do not autocast interrupt spells unless target is bursting. A value greater than 0 represents the number of buffs the target needs to have to be considered bursting
local OnlyInterruptOnBurst = 0
-- leave this variable alone. It's just a counter :P
local NumberOfBurstAuras = 0
-- list of possible buffs that target needs to have to be considered bursting
local BurstAuraList = {}
BurstAuraList[NumberOfBurstAuras] = "Call of Conquest"
NumberOfBurstAuras = NumberOfBurstAuras + 1
BurstAuraList[NumberOfBurstAuras] = "Call of Victory"
NumberOfBurstAuras = NumberOfBurstAuras + 1
BurstAuraList[NumberOfBurstAuras] = "Call of Dominance"
NumberOfBurstAuras = NumberOfBurstAuras + 1
BurstAuraList[NumberOfBurstAuras] = "Screaming Spirits"
NumberOfBurstAuras = NumberOfBurstAuras + 1
BurstAuraList[NumberOfBurstAuras] = "Sword Technique"
NumberOfBurstAuras = NumberOfBurstAuras + 1
BurstAuraList[NumberOfBurstAuras] = "Convulsive Shadows"
NumberOfBurstAuras = NumberOfBurstAuras + 1
BurstAuraList[NumberOfBurstAuras] = "Lub-Dub"
NumberOfBurstAuras = NumberOfBurstAuras + 1
--BurstAuraList[NumberOfBurstAuras] = "Arcane Missiles!"	-- i'm debugging the script, chill
--NumberOfBurstAuras = NumberOfBurstAuras + 1
-- list of Buffs the target should NOT have
local NumberOfCounterAuras = 0
local CounterAuraList = {}
CounterAuraList[NumberOfCounterAuras] = "Mass Spell Reflection"
NumberOfCounterAuras = NumberOfCounterAuras + 1
CounterAuraList[NumberOfCounterAuras] = "Spell Reflection"
NumberOfCounterAuras = NumberOfCounterAuras + 1
CounterAuraList[NumberOfCounterAuras] = "Deterrence"
NumberOfCounterAuras = NumberOfCounterAuras + 1
CounterAuraList[NumberOfCounterAuras] = "Grounding Totem"
NumberOfCounterAuras = NumberOfCounterAuras + 1
--CounterAuraList[NumberOfCounterAuras] = "Arcane Brilliance" -- i'm debugging the script, chill
--NumberOfCounterAuras = NumberOfCounterAuras + 1
-- Only interrupt spells if target also has one of these buffs, You can separate buff names by , if you want to check one of more than 1 buffs
local ConditionalInterrupts = {}
--ConditionalInterrupts["Fireball"] = "Arcane Brilliance,Arcane Missiles!" -- i'm debugging the script, chill

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
local SpellNameTargetTypeKeyBinds = {}
local SpellColorRGB = {}
local SpellRGBStep = 4		
local IndexCounter = 0

function RegisterKickerSpell( SpellName, MainTargetKeyBind, FocusTargetKeybind, Arena1KeyBind, Arena2KeyBind, Arena3KeyBind, Arena4KeyBind, Arena5KeyBind )
	SpellNames[IndexCounter] = SpellName
	SpellColorRGB[IndexCounter] = IndexCounter * SpellRGBStep
	SpellNameTargetTypeKeyBinds[0 * 100 + IndexCounter] = string.byte( MainTargetKeyBind )
	SpellNameTargetTypeKeyBinds[1 * 100 + IndexCounter] = string.byte( FocusTargetKeybind )
	SpellNameTargetTypeKeyBinds[2 * 100 + IndexCounter] = string.byte( Arena1KeyBind )
	SpellNameTargetTypeKeyBinds[3 * 100 + IndexCounter] = string.byte( Arena2KeyBind )
	SpellNameTargetTypeKeyBinds[4 * 100 + IndexCounter] = string.byte( Arena3KeyBind )
	SpellNameTargetTypeKeyBinds[5 * 100 + IndexCounter] = string.byte( Arena4KeyBind )
	SpellNameTargetTypeKeyBinds[6 * 100 + IndexCounter] = string.byte( Arena5KeyBind )
	IndexCounter = IndexCounter + 1
end

-- when we do nothing we will show this
RegisterKickerSpell( "Idle state(do not change me)", "", "", "", "", "", "", "" )
-- interrupt spells
local InterruptSpellsStartAt = IndexCounter
-- add spells that LUA should try to use to interrupt enemy spell cast. Also add the keybind LUA should use for that specific target type to cast the spell. 
-- the order of the spells will say what the LUA should try to cast first. You might want to cast Rebuke more than Hammer of Justice...
RegisterKickerSpell( "Rebuke", '8', '-', '=', '', '', '', '' )
RegisterKickerSpell( "Fist of Justice", '9', '', '', '', '', '', '' )
RegisterKickerSpell( "Hammer of Justice", '9', '', '', '', '', '', '' )
RegisterKickerSpell( "Arcane Torrent", '0', '', '', '', '', '', '' )
RegisterKickerSpell( "Counterspell", '8', '', '', '', '', '', '' )
RegisterKickerSpell( "Wind Shear", '8', '', '', '', '', '', '' )
RegisterKickerSpell( "Kick", '8', '9', '0', '-', '=', '', '' )
RegisterKickerSpell( "Counter Shot", '8', '9', '0', '-', '=', '', '' )
RegisterKickerSpell( "Pummel", '8', '9', '0', '-', '=', '', '' )
RegisterKickerSpell( "Spear Hand Strike", '8', '9', '0', '-', '=', '', '' )
RegisterKickerSpell( "Mind Freeze", '8', '9', '0', '-', '=', '', '' )
RegisterKickerSpell( "Strangulate", '8', '9', '0', '-', '=', '', '' )
local InterruptSpellsEndAt = IndexCounter
--print("Index Counter : "..IndexCounter )

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
		local SpellNameIndex = SpellColorRGB[ Index ] / 255.0
		local TargetType = ( TargetTypeIndex + 1 ) * SpellRGBStep / 255.0
		local KeyBindToPress = SpellNameTargetTypeKeyBinds[ Index + TargetTypeIndex * 100 ] / 255.0
		KickBotFrame.texture:SetVertexColor( TargetType, SpellNameIndex, KeyBindToPress, 1 )
--[[		
		if( DebugLastValue ~= Index ) then
			print( "Change state to "..SpellNameIndex.." target "..TargetTypeIndex.." KeyBind "..KeyBindToPress.." Index "..Index.." ttindex "..TargetTypeIndex )
		end
		DebugLastValue = Index
		]]--
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

	-- if no spell are getting casted by this target than we have nothing to do 
	if( not spell and not cspell ) then
		return
	end
	
	-- whatever spell it is, we just use the name of it
	local SpellName = spell
	if( SpellName == nil ) then 
		SpellName = cspell
	end
	
	-- is the spell whitelisted ?
	local isPlayer = UnitPlayerControlled( unit )
	local SpellIsInWhiteList = 0
	-- Deny all NPC spell interrupts. But WHY !?!?!?!
	if( AllowAnyNPCSpellInterrupt == 1 and isPlayer ~= 1 ) then
--		print( "Target is NPC" )
		SpellIsInWhiteList = 1
	elseif( AllowAnyPlayerSpellInterrupt == 1 and isPlayer == 1 ) then
--		print( "Can interrupt all target player spells" )
		SpellIsInWhiteList = 1
	elseif( string.find( SpellNamesCanInterruptOnPlayers, "("..SpellName..")" ) ~= nil ) then
--		print( "Spell "..SpellName.." can be interrupted because of whitelist" )
		SpellIsInWhiteList = 1
	end
	if( SpellIsInWhiteList ~= 1 ) then
--		print("spell "..SpellName.." is not in whitelist " )
		return
	end
	
	-- is the spell blacklisted ?
	if( string.find( SpellNamesCanNotInterrupt, "("..SpellName..")" ) ~= nil ) then
--local s1,s2,s3,s4 = string.find( SpellNamesCanNotInterrupt, "("..SpellName..")" )
--print( "s1 "..tostring(s1).." s2 "..tostring(s2).." ".." s3 "..tostring(s3).." s4 "..tostring(s4)..SpellNamesCanNotInterrupt )
--		print("spell "..SpellName.." is in blacklist " )
		return
	end
	
	-- in WOD even instant cast spells have 1 second cast time. I do not advise interrupting these. It's unhuman to interrupt most sub 1 second spell casts
	local RemainingSecondsToFinishCast = -1
	if( spell and InterruptDeny == false ) then
		RemainingSecondsToFinishCast = endTime/1000 - GetTime()
		if( isPlayer == 1 and endTime - startTime < DoNotInterruptPVPSpellWithCastTimeLessThan ) then
--			print(" player is casting instant spell "..cspell.." cast time "..tostring(endTime - startTime) )
			return
		end
	end
	
	-- channeled spells should be interrupted as soon as possible.
	if( cspell ) then
		RemainingSecondsToFinishCast = SecondsUntilSpellCastEndToInterruptStart
--		 print("channeling : "..cspell.." cstartTime "..tostring(cstartTime).." cendTime "..tostring(cendTime).." cInterruptDeny "..tostring(cInterruptDeny).." RemainingSecondsToFinishCast "..tostring(RemainingSecondsToFinishCast)..".");
	end
	
	-- Optional : Only interrupt spells if target is burst casting. They trinket + talent proc than cast biggest dmg spell....
	if( OnlyInterruptOnBurst > 0 ) then
		local TargetHasBurstAuras = 0
		for N=0,NumberOfBurstAuras-1,1 do
			local name, rank, icon, count, debuffType, auraduration, expirationTime, unitCaster, isStealable, shouldConsolidate, spellId = UnitAura( unit, BurstAuraList[N] )
			if( name ~= nil ) then
--				print(" target has burst aura "..tostring(name) )
				TargetHasBurstAuras = TargetHasBurstAuras + 1
			end
		end
		if( TargetHasBurstAuras < OnlyInterruptOnBurst ) then
--			print(" We need "..OnlyInterruptOnBurst.." burst auras, but target only had "..TargetHasBurstAuras )
			return
		end
	end
	
	-- do not try to interrupt(stun?) target if he has spell reflect on him. Wait for the effect to expire
	for N=0,NumberOfCounterAuras-1,1 do
--		print(" check counter aura "..tostring(CounterAuraList[N])..".")
		local name, rank, icon, count, debuffType, auraduration, expirationTime, unitCaster, isStealable, shouldConsolidate, spellId = UnitAura( unit, CounterAuraList[N] )
		if( name ~= nil ) then
--			print(" target has counter aura "..tostring(name).." can't interrupt now.")
			return
		end
	end
	
	local ConditionalInterruptChecked = 0
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
					local AllInterruptConditionsAreMet = 0
					if( ( usable == true or usable == 1 ) and ( nomana == false or nomana == nil ) and ( inRange == 1 or inrange == nil ) and duration <= SpellCastAllowLatency ) then
--						print( " advising : "..NextSpellName.." on target (string) '"..unit.."'" );
						AllInterruptConditionsAreMet = 1
					end
					-- to avoid fake casts, you might want to check if target is casting a spell that he is specced in
					if( AllInterruptConditionsAreMet == 1 and ConditionalInterruptChecked == 0 ) then
						ConditionalInterruptChecked = 1
						if( ConditionalInterrupts[ SpellName ] ~= nil ) then
--							print( " target needs to have one of these buffs : "..ConditionalInterrupts[ SpellName ].." to interrupt spell '"..SpellName.."'" );
							local FoundAnyBuff = 0
							local RequiredBuffsList = { strsplit( ",", ConditionalInterrupts[ SpellName ] ) }
							for i, RequiredBuff in ipairs( RequiredBuffsList ) do
--								print( "Checking buff "..RequiredBuff.." on target " )
								local name, rank, icon, count, debuffType, auraduration, expirationTime, unitCaster, isStealable, shouldConsolidate, spellId = UnitAura( unit, RequiredBuff )
								if( name ~= nil ) then
									FoundAnyBuff = FoundAnyBuff + 1
									break
								end
							end	
							if( FoundAnyBuff == 0 ) then
								AllInterruptConditionsAreMet = 0
							end
						end
					end
					if( AllInterruptConditionsAreMet == 1 ) then
						SignalBestAction( N, TargetTypeIndex );
						return 1
					end
				end
			end
	end
	return 0
end

function AdviseNextBestActionPQR()
	return 0
end

local DebugTestAll = -1
function KickBot_onUpdate( )
	--[[
	if( DebugTestAll ~= -1 ) then 
		SignalBestAction( DebugTestAll, DebugTestAll )
		if( PrevTime ~= time() ) then DebugTestAll = DebugTestAll + 1 end
		PrevTime = time()
		if( DebugTestAll >= IndexCounter ) then DebugTestAll = 0 end
		return
	end
	]]--

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
	elseif( AdviseNextBestActionPQR( ) == 1 ) then	-- this is not used, it's only put here as demo for people who want to use the bot for DPS / class specific scripts also
		return
	else
		SignalBestAction( 0 )
	end
end


