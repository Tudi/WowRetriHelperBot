--local OneUpdateThisStamp = 0;
local DemoMode = -1
-- listing possible texts here so we can take screenshots of them using autoit
local SpellNames = {};
SpellNames[0] = "Templar's Verdict";
SpellNames[1] = "Hammer of Wrath";
SpellNames[2] = "Crusader Strike";
SpellNames[3] = "Exorcism";
SpellNames[4] = "Judgment";
SpellNames[5] = "Attack";
SpellNames[6] = "Aquire new target";

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
	
	local unit = "target";
	local SelectedAttackSpell = SpellNames[5]
	
	if( UnitExists( unit ) == false or UnitCanAttack( "player", unit ) == false ) then
		SignalBestAction( SpellNames[6] );
		return
	end
	
    for N=0,4,1 do
		local NextSpellName = SpellNames[ N ];
		if( NextSpellName ~= nil ) then
			local usable, nomana = IsUsableSpell( NextSpellName );
			local IsVisible = UnitIsVisible(unit)
			local inRange = IsSpellInRange( NextSpellName, unit )
--			 print(" "..NextSpellName.." usable "..tostring(usable).." nomana "..tostring(nomana).." Exists "..tostring(Exists).." IsVisible "..tostring(IsVisible).." CanAttack "..tostring(CanAttack).." inRange "..tostring(inRange)..".");
--			 print( NextSpellName );
			if( usable == true and nomana == false and IsVisible and inRange == 1 ) then
				SelectedAttackSpell = NextSpellName
				break
			end
		end
	end
	SignalBestAction( SelectedAttackSpell );
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

