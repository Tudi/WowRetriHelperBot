-- Short explanation : Put this value as small as possible to interrupt spells at the end of the castbar. The smaller the value the chance that you will fail to interrupt also increases
-- Long explanation : If target has a 2 second cast bar and you have this value at 0.5 second, it means that kickbot addon will try to interrupt the spell when the target cast bar is at 1.5 seconds ( 2 - 0.5 ). If you put this value too small than there is a chance that some cooldown will block the casting of the interrupt spell. Due to latency spikes you might also fail to properly cast the interrupt spell
-- if you have low ingame latency, you can try to put this number as low as 0.5 seconds. That means that the enemy cast bar will be almost full when kickbot will try to interrupt it.
-- You can edit this value in GUI. Saved values will override this setting
local SecondsUntilSpellCastEndToInterruptStart = 1.5	-- put as small as possible to catch all interruptable spells. Needs to be larger than SecondsUntilSpellCastEndToInterruptEnd
local SecondsChanneledSpellCastStartToInterruptStart = 0.5	-- number of seconds that need to pass since a channeled spell started casting
-- Short explanation : put this value larger than your ingame latency spikes
-- Long explanation : If target is casting a 1 second cast bar spell. You have 0.75 second lag. You will notice him casting, but there is no point for you to try to interrupt it as your cast will arrive to late to the server. Your target already casted the spell
-- If you put this value too small you might see kickbock try to interrupt a spell that was already casted by the target
local SecondsUntilSpellCastEndToInterruptEnd = 0.5	-- due to global cooldown + addon latency + game latency if you put this to a too small value the interrupt might fail and you wasted interrupt spell
-- This might be valid only for warlords of draenor(WOD) retail servers. Even instant casts spells have a 1 second cast time. You can interrupt instant cast spells
-- For older private server you can try to put this number to 0
local DoNotInterruptPVPSpellWithCastTimeLessThan = 1002	-- i managed to interrupt 3 instant cast spells in a row. That is definetely getting reported as cheater
-- Able to cast spells that have lower than this as cooldown. Spell Queue system to maximize interrupt precision. My avg latency is 0.35. You can experiment what is best for you
-- This value is only worth adjusting when you are using the kickbot addon as a DPS rotation bot
local SpellCastAllowLatency = 0.01
-- set this to 0 to disable NPC spell interrupts
-- if you set this to 1 all NPC spells will be included in whitelist
local AllowAnyNPCSpellInterrupt = 1
-- set this to 0 if you want to specify a list of spells to interrupt for players
-- if you set this to 1 than all spells are considered to be in whitelist
local AllowAnyPlayerSpellInterrupt = 1
-- white list of spell names. The ones that LUA is allowed to automatically interrupt. This list is only used if you set AllowAnyPlayerSpellInterrupt=0
-- White list means that kickbot will only try to interrupt spells that are listed here. Anything else will be skipped
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
-- bad ex : only interrupt Exorcism if target has Holy Avenger ( this doubles the damage of Exorcism )
local ConditionalInterruptsList = {}
--ConditionalInterruptsList["Fireball"] = "Arcane Brilliance,Arcane Missiles!" -- i'm debugging the script, chill
-- list of spells that you wish to interrupt as soon as possible without any latency or cast bar conditioning
local InterruptAsSoonAsPossibleTargetSpells = ""
--local InterruptAsSoonAsPossibleTargetSpells = "Fireball"	-- just debugging, ignore this line
---------------------------------------------------------------
-- End of config section
---------------------------------------------------------------
-- You can edit function "AdviseNextBestActionPQR" if you want to update this addon to a DPS rotation addon while keeping the interrupt feature
---------------------------------------------------------------

-- listing possible texts here so we can take screenshots of them using autoit
local TargetTypes = {}
TargetTypes[0] = "target"
TargetTypes[1] = "focus"
TargetTypes[2] = "arena1"
TargetTypes[3] = "arena2"
TargetTypes[4] = "arena3"
TargetTypes[5] = "arena4"
TargetTypes[6] = "arena5"
local SpellNameTargetTypeKeyBinds = {}
local SpellRGBStep = 4		
local IndexCounter = 0

local SPELL_NAME_INDEX = 7

local function RegisterKickerSpell( SpellName, MainTargetKeyBind, FocusTargetKeybind, Arena1KeyBind, Arena2KeyBind, Arena3KeyBind, Arena4KeyBind, Arena5KeyBind, PlayerClass )
--	SpellNames[IndexCounter] = SpellName
	SpellNameTargetTypeKeyBinds[0 + IndexCounter * 100 ] = string.byte( MainTargetKeyBind )
	SpellNameTargetTypeKeyBinds[1 + IndexCounter * 100 ] = string.byte( FocusTargetKeybind )
	SpellNameTargetTypeKeyBinds[2 + IndexCounter * 100 ] = string.byte( Arena1KeyBind )
	SpellNameTargetTypeKeyBinds[3 + IndexCounter * 100 ] = string.byte( Arena2KeyBind )
	SpellNameTargetTypeKeyBinds[4 + IndexCounter * 100 ] = string.byte( Arena3KeyBind )
	SpellNameTargetTypeKeyBinds[5 + IndexCounter * 100 ] = string.byte( Arena4KeyBind )
	SpellNameTargetTypeKeyBinds[6 + IndexCounter * 100 ] = string.byte( Arena5KeyBind )
	SpellNameTargetTypeKeyBinds[SPELL_NAME_INDEX + IndexCounter * 100 ] = SpellName
	SpellNameTargetTypeKeyBinds[8 + IndexCounter * 100 ] = PlayerClass
	SpellNameTargetTypeKeyBinds[9 + IndexCounter * 100 ] = IndexCounter * SpellRGBStep
--	SpellPlayerClass[ IndexCounter ] = PlayerClass
--	SpellColorRGB[IndexCounter] = IndexCounter * SpellRGBStep
	IndexCounter = IndexCounter + 1
end

local SecondsUntilSpellCastEndToInterruptStartBackup = SecondsUntilSpellCastEndToInterruptStart
local SpellNamesCanInterruptOnPlayersBackup = SpellNamesCanInterruptOnPlayers
local SpellNamesCanNotInterruptBackup = SpellNamesCanNotInterrupt
local OnlyInterruptOnBurstBackup = OnlyInterruptOnBurst
local SecondsChanneledSpellCastStartToInterruptStartBackup = SecondsChanneledSpellCastStartToInterruptStart

local function LoadDefaultSettings()

	for i in pairs( SpellNameTargetTypeKeyBinds ) do
--print( "reseting "..i.." with val "..SpellNameTargetTypeKeyBinds[i] )
		SpellNameTargetTypeKeyBinds[i] = nil
		table.remove( SpellNameTargetTypeKeyBinds, i )
	end
	SpellNameTargetTypeKeyBinds = {}
	
	IndexCounter = 0
	
	-- when we do nothing we will show this
	RegisterKickerSpell( "Idle state(do not change me)", "", "", "", "", "", "", "" )
	
	-- interrupt spells
	InterruptSpellsStartAt = IndexCounter

	-- add spells that LUA should try to use to interrupt enemy spell cast. Also add the keybind LUA should use for that specific target type to cast the spell. 
	-- the order of the spells will say what the LUA should try to cast first. You might want to cast Rebuke more than Hammer of Justice...
	RegisterKickerSpell( "Rebuke", '8', '', '', '', '', '', '', "PALADIN" )
	RegisterKickerSpell( "Fist of Justice", '9', '', '', '', '', '', '', "PALADIN" )
	RegisterKickerSpell( "Hammer of Justice", '9', '', '', '', '', '', '', "PALADIN" )
	RegisterKickerSpell( "Repentance", '8', '', '', '', '', '', '', "PALADIN" )
	RegisterKickerSpell( "Avenger's Shield", '8', '', '', '', '', '', '', "PALADIN" )

	RegisterKickerSpell( "Counterspell", '8', '', '', '', '', '', '', "MAGE" )
	RegisterKickerSpell( "Deep Freeze", '9', '', '', '', '', '', '', "MAGE" )
	RegisterKickerSpell( "Dragon's Breath", '0', '', '', '', '', '', '', "MAGE" )

	RegisterKickerSpell( "Wind Shear", '8', '', '', '', '', '', '', "SHAMAN" )
	RegisterKickerSpell( "Thunderstorm", '9', '', '', '', '', '', '', "SHAMAN" )

	RegisterKickerSpell( "Kick", '8', '', '', '', '', '', '', "ROGUE" )
	RegisterKickerSpell( "Blind", '9', '', '', '', '', '', '', "ROGUE" )
	RegisterKickerSpell( "Kidney Shot", '0', '', '', '', '', '', '', "ROGUE" )
	RegisterKickerSpell( "Cheap Shot", '-', '', '', '', '', '', '', "ROGUE" )
	RegisterKickerSpell( "Gouge", '=', '', '', '', '', '', '', "ROGUE" )
	RegisterKickerSpell( "Garrote", '7', '', '', '', '', '', '', "ROGUE" )

	RegisterKickerSpell( "Counter Shot", '8', '', '', '', '', '', '', "HUNTER" )
	RegisterKickerSpell( "Silencing Shot", '9', '', '', '', '', '', '', "HUNTER" )
	RegisterKickerSpell( "Intimidation", '0', '', '', '', '', '', '', "HUNTER" )
	RegisterKickerSpell( "Wyvern Sting", '-', '', '', '', '', '', '', "HUNTER" )

	RegisterKickerSpell( "Pummel", '8', '', '', '', '', '', '', "WARRIOR" )
	RegisterKickerSpell( "Intimidating Shout", '9', '', '', '', '', '', '', "WARRIOR" )
	RegisterKickerSpell( "Shockwave", '0', '', '', '', '', '', '', "WARRIOR" )

	RegisterKickerSpell( "Howl of Terror", '8', '','','','', '', '', "WARLOCK" )
	RegisterKickerSpell( "Shadowfury", '9', '','','','', '', '', "WARLOCK" )
	RegisterKickerSpell( "Fear", '0', '','','','', '', '', "WARLOCK" )

	RegisterKickerSpell( "Spear Hand Strike", '8', '','','','', '', '', "MONK" )

	RegisterKickerSpell( "Mind Freeze", '8', '','','','', '', '', "DEATHKNIGHT" )
	RegisterKickerSpell( "Strangulate", '9', '','','','', '', '', "DEATHKNIGHT" )
	RegisterKickerSpell( "Death Grip", '0', '','','','', '', '', "DEATHKNIGHT" )
	RegisterKickerSpell( "Dark Simulacrum", '-', '','','','', '', '', "DEATHKNIGHT" )

	RegisterKickerSpell( "Bash", '8', '','','','', '', '', "DRUID" )
	RegisterKickerSpell( "Skull Bash", '9', '','','','', '', '', "DRUID" )
	RegisterKickerSpell( "Maim", '0', '','','','', '', '', "DRUID" )
	RegisterKickerSpell( "Cyclone", '-', '','','','', '', '', "DRUID" )
	RegisterKickerSpell( "Maim", '=', '','','','', '', '', "DRUID" )
	RegisterKickerSpell( "Typhoon", '7', '','','','', '', '', "DRUID" )
	RegisterKickerSpell( "Solar Beam", '6', '','','','', '', '', "DRUID" )

	RegisterKickerSpell( "Psychic Scream", '8', '','','','', '', '', "PRIEST" )
	RegisterKickerSpell( "Silence", '9', '','','','', '', '', "PRIEST" )
	RegisterKickerSpell( "Psychic Horror", '0', '','','','', '', '', "PRIEST" )
	RegisterKickerSpell( "Silence", '-', '','','','', '', '', "PRIEST" )
	RegisterKickerSpell( "Holy Word: Chastise", '=', '','','','', '', '', "PRIEST" )

	RegisterKickerSpell( "Arcane Torrent", '0', '', '', '', '', '', '' )
	RegisterKickerSpell( "War Stomp", '0', '', '', '', '', '', '' )
	
	--RegisterKickerSpell( "Fireball", '8', '','','','', '', '', "MAGE" )	--just debugging
	InterruptSpellsEndAt = IndexCounter
	
	SpellNameTargetTypeKeyBinds[ 20 ] = SecondsUntilSpellCastEndToInterruptStartBackup
	SecondsUntilSpellCastEndToInterruptStart = SecondsUntilSpellCastEndToInterruptStartBackup

	SpellNameTargetTypeKeyBinds[ 21 ] = SpellNamesCanInterruptOnPlayersBackup
	SpellNamesCanInterruptOnPlayers = SpellNamesCanInterruptOnPlayersBackup

	SpellNameTargetTypeKeyBinds[ 22 ] = SpellNamesCanNotInterruptBackup
	SpellNamesCanNotInterrupt = SpellNamesCanNotInterruptBackup
	
	SpellNameTargetTypeKeyBinds[ 23 ] = OnlyInterruptOnBurstBackup
	OnlyInterruptOnBurst = OnlyInterruptOnBurstBackup
	
	SpellNameTargetTypeKeyBinds[ 24 ] = SecondsChanneledSpellCastStartToInterruptStart
	SecondsChanneledSpellCastStartToInterruptStart = SecondsChanneledSpellCastStartToInterruptStartBackup
end
LoadDefaultSettings()

--print("Index Counter : "..IndexCounter )

function KickBot_OnLoad(self)
	KickBotFrame = self
	KickBotFrame:RegisterForDrag("LeftButton")
	KickBotFrame:SetScript("OnUpdate",KickBot_onUpdate)
	KickBotFrame:RegisterEvent("ADDON_LOADED");

	KickBotFrame.texture = KickBotFrame:CreateTexture( nil, "BACKGROUND" )
	KickBotFrame.texture:SetTexture( 1, 1, 1, 1 )
	KickBotFrame.texture:SetAllPoints()

    print("KickBot loaded.Don't forget to start AU3 script. To stop AU3 press '['. To pause AU3 press '\\'. For advanced settings edit KickBot.lua");
end

local function SendToAU3KeyPress( AsciiChar )
		local KeyToPress = string.byte( AsciiChar ) / 255.0
		KickBotFrame.texture:SetVertexColor( SpellRGBStep / 255.0, SpellRGBStep / 255.0, KeyToPress, 1 )
end

local DebugLastValue = -1
local function SignalBestAction( Index, TargetTypeIndex )
--	AutoIt will monitor the colors and send back keys based on it
--	KickBotFrame.text:SetText( Index.." "..SpellColorRGB[ Index ] )
	if( Index <= 0 ) then 
		KickBotFrame.texture:SetVertexColor( 16 / 255.0, 255 / 255.0, 128 / 255.0, 1 ) -- magic number to allow AU3 to find it
		DebugLastValue = -1
	elseif( Index < IndexCounter ) then
		local SpellNameIndex = SpellNameTargetTypeKeyBinds[ Index * 100 + 9 ] / 255.0
		local TargetType = ( TargetTypeIndex + 1 ) * SpellRGBStep / 255.0
		local KeyBindToPress = SpellNameTargetTypeKeyBinds[ Index * 100 + TargetTypeIndex ] / 255.0
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
	
	-- we can not interrupt this spell
	if( spell and InterruptDeny == true ) then
		return
	end
	
	-- we can not interrupt this spell
	if( cspell and cInterruptDeny == true ) then
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
	if( cspell and cInterruptDeny == false ) then
		SecondsSinceStartedCasting = GetTime() - cstartTime / 1000
--		print( "channeling : "..cspell.." seconds passed "..SecondsSinceStartedCasting );
		if( SecondsSinceStartedCasting >= SecondsChanneledSpellCastStartToInterruptStart ) then
			RemainingSecondsToFinishCast = SecondsUntilSpellCastEndToInterruptStart
		end
--		 print( "channeling : "..cspell.." cstartTime "..tostring(cstartTime).." cendTime "..tostring(cendTime).." cInterruptDeny "..tostring(cInterruptDeny).." RemainingSecondsToFinishCast "..tostring(RemainingSecondsToFinishCast)..".");
	end
	
	-- we wish to interrupt this spell as soon as it gets started. Exceptional cases when for some reason the channeling check fails
	if( string.find( InterruptAsSoonAsPossibleTargetSpells, "("..SpellName..")" ) ~= nil ) then
		RemainingSecondsToFinishCast = SecondsUntilSpellCastEndToInterruptStart
--		print("spell "..SpellName.." is marked to be interrupted asp "..RemainingSecondsToFinishCast.." <= "..SecondsUntilSpellCastEndToInterruptStart.." and "..RemainingSecondsToFinishCast.." >= "..SecondsUntilSpellCastEndToInterruptEnd  )
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
				local NextSpellName = SpellNameTargetTypeKeyBinds[ SPELL_NAME_INDEX + N * 100 ];
				local KeyBindToPress = SpellNameTargetTypeKeyBinds[ N * 100 + TargetTypeIndex ];
--				print( N.." "..NextSpellName )
				if( NextSpellName ~= nil and KeyBindToPress ~= nil ) then
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
						if( ConditionalInterruptsList[ SpellName ] ~= nil ) then
--							print( " target needs to have one of these buffs : "..ConditionalInterruptsList[ SpellName ].." to interrupt spell '"..SpellName.."'" );
							local FoundAnyBuff = 0
							local RequiredBuffsList = { strsplit( ",", ConditionalInterruptsList[ SpellName ] ) }
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

-- Right now this is only added as a demo function !
function AdviseNextBestActionPQR()

--[[
	if( time() % 10 == 0 ) then 
		SendToAU3KeyPress( '5' )
		return 1
	end
	]]--
	
--[[
	-- if divine storm is buffed than try to use it 
	local unit = "target";
--	 print(" exists "..tostring(UnitExists( unit )).." canattack "..tostring(UnitCanAttack( "player", unit )).." visible "..tostring(UnitIsVisible(unit)).." dead "..tostring(UnitIsDeadOrGhost(unit)));
	if( UnitExists( unit ) == true and UnitCanAttack( "player", unit ) == true and UnitIsVisible(unit) == true and UnitIsDeadOrGhost( unit ) == false and ( InCombatLockdown() == 1 or checkCombat() == 1 ) ) then
		local name, rank, icon, count, debuffType, auraduration, expirationTime, unitCaster, isStealable, shouldConsolidate, spellId = UnitAura( "player", "Divine Crusader" )
		if( spellId ~= nil and spellId > 0 ) then 
			local name, rank, icon, count, debuffType, auraduration, expirationTime, unitCaster, isStealable, shouldConsolidate, spellId = UnitAura( "player", "Final Verdict" )
			if( spellId ~= nil and spellId > 0 ) then 
--				print("we have Divine Crusader and final verdict");
				local NextSpellName = "Divine Storm";
				local usable, nomana = IsUsableSpell( NextSpellName )
				local inRange = IsSpellInRange( "Rebuke", unit )	-- divine storm is AOE, but we want melee range
				local start, duration, enabled = GetSpellCooldown( NextSpellName )
--				print(" "..NextSpellName.." usable "..tostring(usable).." nomana "..tostring(nomana).." inrange "..tostring(inRange).." cooldown "..tostring(duration).." isactive "..tostring(spellId)..".");
				if( usable == true and nomana == false and ( inRange == 1 or inrange == nil ) and duration <= SpellCastAllowLatency ) then
--					print( " advising : "..NextSpellName )
					SendToAU3KeyPress( '5' )
					return 1
				end
			end
		end
	end
	]]--
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
		SignalBestAction( 0, 0 )
	end
end

----------------------------------
-- All the code below is the shit to make the editbox appear and work. Could bt trowh out if you ask me, but you gotto think about the noobs also
----------------------------------

local StorageSystemVersion = 4
local function BuildSpellNameKeyBindsFromListToSave()
	SpellNameKeyBinds = SpellNameTargetTypeKeyBinds
	SpellNameKeyBinds[999] = StorageSystemVersion
end

local function BuildSpellNameKeyBindsFromSaveToList()
	if( SpellNameKeyBinds == nil or SpellNameKeyBinds[999] ~= StorageSystemVersion or SpellNameKeyBinds[24] == nil ) then
		BuildSpellNameKeyBindsFromListToSave()
	end
	
	SpellNameTargetTypeKeyBinds[ 20 ] = SecondsUntilSpellCastEndToInterruptStart
	SpellNameTargetTypeKeyBinds[ 21 ] = SpellNamesCanInterruptOnPlayers
	SpellNameTargetTypeKeyBinds[ 22 ] = SpellNamesCanNotInterrupt
	SpellNameTargetTypeKeyBinds[ 23 ] = OnlyInterruptOnBurst
	SpellNameTargetTypeKeyBinds[ 24 ] = SecondsChanneledSpellCastStartToInterruptStart
	
	SpellNameTargetTypeKeyBinds = SpellNameKeyBinds
end

local ScriptLoaded = 0
function KickBot_OnEvent( Obj, event, arg1)
--	print( "Got event "..tostring(Obj).." "..tostring(event).." "..tostring(arg1) );
	if event == "ADDON_LOADED" and ScriptLoaded == 0 then
		ScriptLoaded = 1
		BuildSpellNameKeyBindsFromSaveToList()
	end
end

function KickBot_OnClick( Obj, Button )
	if( EditBoxFrame:IsShown() ) then
		EditBoxFrame:Hide()
	else
		EditBoxFrame:Show()
	end
end

EditBoxFrame = nil
function EditForm_OnLoad( Obj )
	
	EditBoxFrame = Obj

	local ShowHideEditbox = CreateFrame("Button", "TestButton", KickBotFrame, "UIPanelButtonTemplate")
	ShowHideEditbox:RegisterForClicks("LeftButtonUp", "RightButtonDown");
	ShowHideEditbox:SetPoint("CENTER", 0, -KickBotFrame:GetHeight() / 2 )
	ShowHideEditbox:SetWidth( 20 )
	ShowHideEditbox:SetHeight( 12 )
	ShowHideEditbox:HookScript("OnClick", KickBot_OnClick )

	local pc, EnglishClass = UnitClass( "player" )
--print( "player class is "..pc.." "..EnglishClass )
	local VisualRow = 0
	for j = 1, IndexCounter do
		if( ( SpellNameTargetTypeKeyBinds[8 + j * 100 ] == nil or SpellNameTargetTypeKeyBinds[8 + j * 100 ] == EnglishClass ) and SpellNameTargetTypeKeyBinds[SPELL_NAME_INDEX + j * 100 ] ~= nil ) then
			VisualRow = VisualRow + 1
			for i = 0, 7 do
				local TempEditBox = CreateFrame("EditBox", "EditBoxTemplateEdit"..i, EditBoxFrame, "EditBoxTemplateEditB")
				TempEditBox:SetPoint("TOPLEFT", 20 + ( i * 60 ), -50 - ( ( VisualRow - 1 ) * 30 ) )
				TempEditBox.Row = j
				TempEditBox.Col = i
				if( i == SPELL_NAME_INDEX ) then 
					TempEditBox:SetWidth( 130 )
					TempEditBox:SetMaxLetters( 110 )
				end
			end
		end
	end

	-- edit kickbot precision
	VisualRow = VisualRow + 1
	local TempLabel = CreateFrame( "frame", "LabelTemplateCastbar", EditBoxFrame, "LabelTemplate" )
	TempLabel:SetPoint("TOPLEFT", 20, -50 - ( ( VisualRow - 1 ) * 30 ) )
	TempLabel:SetWidth( 50 * 6 )
	TempLabel.text = TempLabel:CreateFontString( nil, "ARTWORK", "GameFontNormal" )
	TempLabel.text:SetText( "Cast bar remaining seconds to start interrupt" )
    TempLabel.text:SetJustifyH("LEFT")
	TempLabel.text:SetAllPoints();
	local TempEditBox = CreateFrame("EditBox", "EditBoxTemplateEdit", EditBoxFrame, "EditBoxTemplateEditB")
	TempEditBox:SetPoint("TOPLEFT", 400, -50 - ( ( VisualRow - 1 ) * 30 ) )
	TempEditBox.Col = 20
	TempEditBox:SetWidth( 6 * 12 )
	TempEditBox:SetMaxLetters( 6 )

	VisualRow = VisualRow + 1
	local TempLabel = CreateFrame( "frame", "LabelTemplateCastbarChanneled", EditBoxFrame, "LabelTemplate" )
	TempLabel:SetPoint("TOPLEFT", 20, -50 - ( ( VisualRow - 1 ) * 30 ) )
	TempLabel:SetWidth( 80 * 6 )
	TempLabel.text = TempLabel:CreateFontString( nil, "ARTWORK", "GameFontNormal" )
	TempLabel.text:SetText( "Seconds of castbar to interrupt channeled spell" )
    TempLabel.text:SetJustifyH("LEFT")
	TempLabel.text:SetAllPoints();
	local TempEditBox = CreateFrame("EditBox", "EditBoxTemplateEditChannelstart", EditBoxFrame, "EditBoxTemplateEditB")
	TempEditBox:SetPoint("TOPLEFT", 400, -50 - ( ( VisualRow - 1 ) * 30 ) )
	TempEditBox.Col = 24
	TempEditBox:SetWidth( 6 * 12 )
	TempEditBox:SetMaxLetters( 6 )
	
	VisualRow = VisualRow + 1
	local TempLabel = CreateFrame( "frame", "LabelTemplateWhiteList", EditBoxFrame, "LabelTemplate" )
	TempLabel:SetPoint("TOPLEFT", 20, -50 - ( ( VisualRow - 1 ) * 30 ) )
	TempLabel:SetWidth( 50 * 6 )
	TempLabel.text = TempLabel:CreateFontString( nil, "ARTWORK", "GameFontNormal" )
	TempLabel.text:SetText( "Only interrupt these spell names" )
    TempLabel.text:SetJustifyH("LEFT")
	TempLabel.text:SetAllPoints();
	local TempEditBox = CreateFrame("EditBox", "EditBoxTemplateEdita", EditBoxFrame, "EditBoxTemplateEditB")
	TempEditBox:SetPoint("TOPLEFT", 300, -50 - ( ( VisualRow - 1 ) * 30 ) )
	TempEditBox.Col = 21
	TempEditBox:SetWidth( 250 )
	TempEditBox:SetMaxLetters( 1500 )

	VisualRow = VisualRow + 1
	local TempLabel = CreateFrame( "frame", "LabelTemplateBlackList", EditBoxFrame, "LabelTemplate" )
	TempLabel:SetPoint("TOPLEFT", 20, -50 - ( ( VisualRow - 1 ) * 30 ) )
	TempLabel:SetWidth( 50 * 6 )
	TempLabel.text = TempLabel:CreateFontString( nil, "ARTWORK", "GameFontNormal" )
	TempLabel.text:SetText( "Do NOT interrupt these spell names" )
    TempLabel.text:SetJustifyH("LEFT")
	TempLabel.text:SetAllPoints();
	local TempEditBox = CreateFrame("EditBox", "EditBoxTemplateEditb", EditBoxFrame, "EditBoxTemplateEditB")
	TempEditBox:SetPoint("TOPLEFT", 300, -50 - ( ( VisualRow - 1 ) * 30 ) )
	TempEditBox.Col = 22
	TempEditBox:SetWidth( 250 )
	TempEditBox:SetMaxLetters( 1500 )

	VisualRow = VisualRow + 1
	local TempLabel = CreateFrame( "frame", "LabelTemplateBurst", EditBoxFrame, "LabelTemplate" )
	TempLabel:SetPoint("TOPLEFT", 20, -50 - ( ( VisualRow - 1 ) * 30 ) )
	TempLabel:SetWidth( 80 * 6 )
	TempLabel.text = TempLabel:CreateFontString( nil, "ARTWORK", "GameFontNormal" )
	TempLabel.text:SetText( "Only interrupt on burst(edit 'BurstAuraList' in kickbot.lua)" )
    TempLabel.text:SetJustifyH("LEFT")
	TempLabel.text:SetAllPoints();
	local TempEditBox = CreateFrame("EditBox", "EditBoxTemplateEditc", EditBoxFrame, "EditBoxTemplateEditB")
	TempEditBox:SetPoint("TOPLEFT", 400, -50 - ( ( VisualRow - 1 ) * 30 ) )
	TempEditBox.Col = 23
	TempEditBox:SetWidth( 20 )
	TempEditBox:SetMaxLetters( 1 )

	VisualRow = VisualRow + 1
	local TempLabel = CreateFrame( "frame", "LabelTemplateBurstSpecific", EditBoxFrame, "LabelTemplate" )
	TempLabel:SetPoint("TOPLEFT", 20, -50 - ( ( VisualRow - 1 ) * 30 ) )
	TempLabel:SetWidth( 100 * 6 )
	TempLabel.text = TempLabel:CreateFontString( nil, "ARTWORK", "GameFontNormal" )
	TempLabel.text:SetText( "Only interrupt if casted spell is buffed(edit 'ConditionalInterrupts' in kickbot.lua)" )
    TempLabel.text:SetJustifyH("LEFT")
	TempLabel.text:SetAllPoints();

end

function GetEditboxValue( Obj )
	local Row = Obj.Row
	local Col = Obj.Col
--	print( " val "..tostring( SpellNameTargetTypeKeyBinds[ 4 + 6 * 100 ] ).." "..tostring( SpellNameTargetTypeKeyBinds[ SPELL_NAME_INDEX + 6 * 100 ] ) )
--	print( "cur val "..tostring( Obj ).." "..tostring( Obj.Row ).." "..tostring( Obj.Col ).." "..tostring( Row ).." "..tostring( Col ) )
--	print( "get ind "..Col.." row "..Row.." val "..tostring( SpellNameTargetTypeKeyBinds[ Col + Row * 100 ] ).." "..tostring( SpellNameTargetTypeKeyBinds[ 7 + Row * 100 ] ) )
	if( Col >= 0 and Col <= 6 ) then
		if( SpellNameTargetTypeKeyBinds[ Col + Row * 100 ] == nil ) then
			Obj:SetText( "" )
		else
			Obj:SetText( strchar( SpellNameTargetTypeKeyBinds[ Col + Row * 100 ] ) )
		end
	elseif( Col == SPELL_NAME_INDEX and SpellNameTargetTypeKeyBinds[ Col + Row * 100 ] ~= nil ) then
		Obj:SetText( SpellNameTargetTypeKeyBinds[ Col + Row * 100 ] )
	elseif( Col >= 20 and Col <= 24 ) then
		Obj:SetText( SpellNameTargetTypeKeyBinds[ Col ] )
	end
end

function SetEditboxValue( Obj )
	local Row = Obj.Row
	local Col = Obj.Col
	if( Col >= 0 and Col <= 6 ) then
		SpellNameTargetTypeKeyBinds[ Col + Row * 100 ] = string.byte( Obj:GetText( ) )
	elseif( Col == SPELL_NAME_INDEX ) then
		SpellNameTargetTypeKeyBinds[ Col + Row * 100 ] = Obj:GetText( )
		if( SpellNameTargetTypeKeyBinds[ Col + Row * 100 ] == tostring( tonumber( SpellNameTargetTypeKeyBinds[ Col + Row * 100 ] ) ) ) then
			local name, rank, icon, castTime, minRange, maxRange = GetSpellInfo( tonumber( SpellNameTargetTypeKeyBinds[ Col + Row * 100 ] ) )
			SpellNameTargetTypeKeyBinds[ Col + Row * 100 ] = name
		end
	elseif( Col == 20 ) then
		SecondsUntilSpellCastEndToInterruptStart = tonumber( Obj:GetText( ) )
		if( SecondsUntilSpellCastEndToInterruptStart < 0.1 ) then
			SecondsUntilSpellCastEndToInterruptStart = 0.1
		end
		SpellNameTargetTypeKeyBinds[ 20 ] = SecondsUntilSpellCastEndToInterruptStart
		SecondsUntilSpellCastEndToInterruptEnd = SecondsUntilSpellCastEndToInterruptStart * 30 / 100
		if( SecondsUntilSpellCastEndToInterruptEnd < 0.05 ) then
			SecondsUntilSpellCastEndToInterruptEnd = 0.05
		end
		-- this should never happen
		if( SecondsUntilSpellCastEndToInterruptStart < SecondsUntilSpellCastEndToInterruptEnd ) then
			SecondsUntilSpellCastEndToInterruptStart = SecondsUntilSpellCastEndToInterruptEnd
		end
--print(SecondsUntilSpellCastEndToInterruptEnd)		
	elseif( Col == 21 ) then
		SpellNamesCanInterruptOnPlayers = Obj:GetText( )
		SpellNameTargetTypeKeyBinds[ 21 ] = SpellNamesCanInterruptOnPlayers
		if( #SpellNamesCanInterruptOnPlayers > 0 ) then
			AllowAnyPlayerSpellInterrupt = 0
		else
			AllowAnyPlayerSpellInterrupt = 1
		end
--print( AllowAnyPlayerSpellInterrupt )
	elseif( Col == 22 ) then
		SpellNamesCanNotInterrupt = Obj:GetText( )
		SpellNameTargetTypeKeyBinds[ 22 ] = SpellNamesCanNotInterrupt
	elseif( Col == 23 ) then
		OnlyInterruptOnBurst = tonumber( Obj:GetText( ) )
		SpellNameTargetTypeKeyBinds[ 23 ] = OnlyInterruptOnBurst
	elseif( Col == 24 ) then
		SecondsChanneledSpellCastStartToInterruptStart = tonumber( Obj:GetText( ) )
		if( SecondsChanneledSpellCastStartToInterruptStart < 0 ) then 
			SecondsChanneledSpellCastStartToInterruptStart = 0
		end
		SpellNameTargetTypeKeyBinds[ 24 ] = SecondsChanneledSpellCastStartToInterruptStart
	end
--	print( " val "..tostring( SpellNameTargetTypeKeyBinds[ 4 + 6 * 100 ] ).." "..tostring( SpellNameTargetTypeKeyBinds[ SPELL_NAME_INDEX + 6 * 100 ] ) )
--	print( "set ind "..Col.." row "..Row.." val "..tostring( SpellNameTargetTypeKeyBinds[ Col + Row * 100 ] ).." "..tostring( SpellNameTargetTypeKeyBinds[ SPELL_NAME_INDEX + Row * 100 ] ) )
--	print( "cur val "..tostring(  ) )
--    Obj:GetText( )
end

function SaveEditBoxData()
	EditBoxFrame:Hide()
end

function ResetEditBoxData()
	EditBoxFrame:Hide()
--	print( " val "..tostring( SpellNameTargetTypeKeyBinds[ 4 + 6 * 100 ] ).." "..tostring( SpellNameTargetTypeKeyBinds[ SPELL_NAME_INDEX + 6 * 100 ] ) )
	LoadDefaultSettings()
	SpellNameTargetTypeKeyBinds[ 20 ] = SecondsUntilSpellCastEndToInterruptStartBackup
--	print( " val "..tostring( SpellNameTargetTypeKeyBinds[ 4 + 6 * 100 ] ).." "..tostring( SpellNameTargetTypeKeyBinds[ SPELL_NAME_INDEX + 6 * 100 ] ) )
end