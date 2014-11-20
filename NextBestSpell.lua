NextBestSpellSavedMacros = {};
local OneUpdateThisStamp = 0;
local PreviousAction = "";

----------------------
-- 		FRAME SETUP
----------------------
local frame = CreateFrame("FRAME", "NextBestSpell");

frame:SetHeight( 36 )
frame:SetWidth( 12 * 17 )
frame:SetPoint("CENTER", 0, 0)

frame.texture = frame:CreateTexture( nil, "BACKGROUND" )
-- magic RGB for us to search for 64,64,64
frame.texture:SetVertexColor( 0.5, 0.5, 0.5 );
frame.texture:SetTexture( 0.5, 0.5, 0.5, 1 )
frame.texture:SetAllPoints()

frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

frame.text = frame:CreateFontString( nil, "ARTWORK", "GameFontNormal" )
--local file, size, flags = frame.text:GetFont()
frame.text:SetFont( "Fonts\\Arialn.TTF", 18, "BOLD")
frame.text:SetJustifyH("LEFT")
frame.text:SetShadowColor( 0, 0, 0, 0 )

frame.text:SetAllPoints();
frame.text:SetAlpha( 1 );

--always start with a "." so Autoit can search + focus on it
frame.text:SetText(".0123456789")

--frame:RegisterEvent("PLAYER_ENTERING_WORLD");
frame:RegisterEvent("ADDON_LOADED");
--frame:RegisterEvent("LFG_ROLE_UPDATE");
--frame:RegisterEvent("PLAYER_ROLES_ASSIGNED");
--frame:RegisterEvent("PARTY_MEMBERS_CHANGED");
--frame:RegisterEvent("PLAYER_REGEN_ENABLED");
frame:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN");
frame:RegisterEvent("PLAYER_TARGET_CHANGED");

local function SignalBestAction( NewAction )
	frame.text:SetText( "."..NewAction )
end

local function resetSavedMacros()
  for macroName, macroBody in pairs(NextBestSpellSavedMacros) do
    local macroIndex = GetMacroIndexByName(macroName);
    EditMacro(macroIndex, nil, nil, macroBody);
    print("'"..macroName.."' has been reset");
  end
end

local function updateMacros( NewSpellName )
  for macroName, macroBody in pairs(NextBestSpellSavedMacros) do

	if( string.find( macroBody, "VariableSpell" ) ~= nil ) then 
		local NewMacroBody = string.gsub( macroBody, "VariableSpell", NewSpellName )
		local macroIndex = GetMacroIndexByName( macroName );
	--	print("Old body "..macroBody.." ")
	--	print("New body "..NewMacroBody.." ")
		EditMacro( macroIndex, nil, nil, NewMacroBody );
	end
	
  end
end

local function AdviseNextBestAction()
  local runtime = time();
  if OneUpdateThisStamp == runtime then
	return
  end
  OneUpdateThisStamp = runtime;

  --search an attack spell
	local SpellNames = {};
	SpellNames[0] = "Templar's Verdict";
	SpellNames[1] = "Hammer of Wrath";
	SpellNames[2] = "Crusader Strike";
	SpellNames[3] = "Exorcism";
	SpellNames[4] = "Judgment";
	
	-- /target [@targettarget,harm,nodead,exists] [@focus,harm,nodead,exists] [@focustarget,harm,exists] [harm,nodead,exists]
	
	local unit = "target";
	local SelectedAttackSpell = "Attack"
	
	if( UnitExists( unit ) == false or UnitCanAttack( "player", unit ) == false ) then
		SignalBestAction( "Aquire new target<b>1" );
		return
	end
	
    for N=1,4,1 do
		local NextSpellName = SpellNames[ N ];
		if( NextSpellName ~= nil ) then
			local usable, nomana = IsUsableSpell( NextSpellName );
	-- seems to give always false ?
	--		local Isdead = UnitIsDead(unit)
	-- seems to function like UnitIsDead
--			local Exists = UnitExists(unit)
			local IsVisible = UnitIsVisible(unit)
	-- Neutral creatures are not considered enemy !
	--		local IsEnemy = UnitIsEnemy( "player", unit )
--			local CanAttack = UnitCanAttack( "player", unit )
			local inRange = IsSpellInRange( NextSpellName, unit )
	--		 print(" "..NextSpellName.." usable "..tostring(usable).." nomana "..tostring(nomana).." Isdead "..tostring(Isdead).." Exists "..tostring(Exists).." IsVisible "..tostring(IsVisible).." IsEnemy "..tostring(IsEnemy).." CanAttack "..tostring(CanAttack)..".");
--			 print(" "..NextSpellName.." usable "..tostring(usable).." nomana "..tostring(nomana).." Exists "..tostring(Exists).." IsVisible "..tostring(IsVisible).." CanAttack "..tostring(CanAttack).." inRange "..tostring(inRange)..".");
--			if( usable == true and nomana == false and Exists and IsVisible and CanAttack and inRange == 1 ) then
			if( usable == true and nomana == false and IsVisible and inRange == 1 ) then
				SelectedAttackSpell = NextSpellName
				break
			end
		end
	end
--if( SelectedAttackSpell ~= "none" ) then
--		updateMacros( SelectedAttackSpell );
		SignalBestAction( SelectedAttackSpell );
--	end
end

SLASH_TARGETROLE1 = '/NextBestSpell';
SLASH_TARGETROLE2 = '/NBS';
local function slashHandler(msg, editbox)
  local command, rest = msg:match("^(%S*)%s*(.-)$");
  if command == "add" and rest ~= "" then
    local macroBody = GetMacroBody(rest);
    if macroBody == nil then     
      print("no macro named '"..rest.."' found");
    else
      NextBestSpellSavedMacros[rest] = macroBody;
      print("added '"..rest.."'");
      AdviseNextBestAction();
    end
  elseif command == "remove" and rest ~= "" then   
    NextBestSpellSavedMacros[rest] = nil;
    print("removed '"..rest.."'");
  elseif command == "reset" then
    resetSavedMacros();
  elseif command == "run" then
    AdviseNextBestAction();
  else
    print("Syntax: /NextBestSpell add [macro name]");
    print("Syntax: /NextBestSpell remove [macro name]");
    print("Syntax: /NextBestSpell reset");
    print("Syntax: /NextBestSpell run");
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

