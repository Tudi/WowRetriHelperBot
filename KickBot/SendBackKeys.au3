Opt('MustDeclareVars', 1)

; this is required to not try to casts spells 1000 times per second while silenced :(
global $MaxFPS = 4

; Keyboard shortcut to kill this script
HotKeySet("[", "Terminate")
; do not take any actions unles script is set to run
HotKeySet("\", "TogglePause")

global $LuaFramePosX = -1
global $LuaFramePosy = -1
global $RGBStep = 4
global $FirstValidRGB = 1 * $RGBStep
global $SendKeyForMainTarget[20]
global $SendKeyForFocusTarget[20]
global $ExpectedLUAIdleValue = 0x0010FF80

; the list of spell names is in the same order as in KickBot.lua. KickBot.lua will send us the index to this vector.
; you can find key values here : https://www.autoitscript.com/autoit3/docs/appendix/SendKeys.htm
$SendKeyForMainTarget[0] = "9"		;Fist of Justice
$SendKeyForMainTarget[1] = "8"		;Rebuke
$SendKeyForMainTarget[2] = "0"		;Arcane Torrent
$SendKeyForMainTarget[3] = "9"		;Counterspell
$SendKeyForMainTarget[4] = "9"		;Wind Shear
$SendKeyForMainTarget[5] = "9"		;Kick
$SendKeyForMainTarget[6] = "9"		;Counter Shot
$SendKeyForMainTarget[7] = "9"		;Pummel
$SendKeyForMainTarget[8] = "9"		;Spear Hand Strike
$SendKeyForMainTarget[9] = "9"		;Mind Freeze
$SendKeyForMainTarget[10] = "9"		;Strangulate
$SendKeyForMainTarget[11] = "9"		;Hammer of Justice
; List is very similar, we only send different key for the spell as you will probably be using a macro like : /cast @focustarget Rebuke
$SendKeyForFocusTarget[0] = "-"		;Fist of Justice
$SendKeyForFocusTarget[1] = "="		;Rebuke
$SendKeyForFocusTarget[2] = "0"		;Arcane Torrent
$SendKeyForFocusTarget[3] = "="		;Counterspell
$SendKeyForFocusTarget[4] = "="		;Wind Shear
$SendKeyForFocusTarget[5] = "="		;Kick
$SendKeyForFocusTarget[6] = "="		;Counter Shot
$SendKeyForFocusTarget[7] = "="		;Pummel
$SendKeyForFocusTarget[8] = "="		;Spear Hand Strike
$SendKeyForFocusTarget[9] = "="		;Mind Freeze
$SendKeyForFocusTarget[10] = "="	;Strangulate
$SendKeyForFocusTarget[11] = "-"	;Hammer of Justice
global $MaxIndexInVector = UBound( $SendKeyForMainTarget )

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Anything below should be working without any changes. If not.....it's bad
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
#include <Misc.au3>
#include <Date.au3>

global $ScriptIsRunning = 1
global $ScriptIsPaused = 0

Func Terminate()
    $ScriptIsRunning = 0
EndFunc

Func TogglePause()
    $ScriptIsPaused = 1 - $ScriptIsPaused
EndFunc

; wait until you alt+tab to wow window
WinWaitActive( "World of Warcraft" )

; Debugging. Can delete this
if( IsDeclared( "MB_SYSTEMMODAL" ) <> 1 ) then 
	global $MB_SYSTEMMODAL = 4096
endif

; probably did not set manually a value
if( $LuaFramePosX == -1 ) then
	TryToGuessLocation()
endif

; Debugging. Can delete this
if( PixelGetColor( $LuaFramePosX, $LuaFramePosY ) <> $ExpectedLUAIdleValue ) then
	MsgBox( $MB_SYSTEMMODAL, "", "KickBot Lua frame has an unexpected value. Manually set $LuaFramePosX and $LuaFramePosY" )
endif

global $FrameHandleDuration = 1000 / $MaxFPS

;MsgBox( $MB_SYSTEMMODAL, "", " but1 " & $KeyToAllowScriptToTakeActionsHex & " but 2 " & $KeyToAllowScriptToTakeActionsHex2 )

local $PrevValue = 0
;loop until the end of days
local $LastActionCheckStamp = _Date_Time_GetTickCount( )
; monitor that part of the screen and check if something changed. If it did, than we take actions 
while( $ScriptIsRunning == 1 )
	local $TickNow = _Date_Time_GetTickCount( )
	
	; get the color of our LUA frame
	local $LuaColor = PixelGetColor( $LuaFramePosX, $LuaFramePosY )
	
	; do not spam same keys
	if( $PrevValue <> $LuaColor ) then 
		local $ColorB = Mod( $LuaColor, 256 )
		local $ColorG = Mod( Int( $LuaColor / 256 ), 256 )
		local $ColorR = Mod( Int( $LuaColor / 65536 ), 256 )
		local $SpellNameIndex = Int( ( $ColorB - $FirstValidRGB ) / $RGBStep )
		local $TargetIndex = Int( ( $ColorR - $FirstValidRGB ) / $RGBStep )
		
		if( WinActive( "World of Warcraft" ) ) then 
			; Debugging. Can delete this
;			MsgBox( $MB_SYSTEMMODAL, "", "change detected " & $ColorR & " " & $ColorG & " " & $ColorB )
;			Send( "{ENTER}" & " change detected " & $ColorR & " " & $ColorG & " " & $ColorB & " with index " & $SpellNameIndex & " " & $TargetIndex & " {ENTER}" )	
			EventImageFound( $SpellNameIndex, $TargetIndex )
		endif
		
		$PrevValue = $LuaColor
	endif
	
	;this is required to not overspam unusable actions
	local $TickAtEnd = _Date_Time_GetTickCount( )
	local $DeltaTime = $TickAtEnd - $TickNow
	if( $DeltaTime < $FrameHandleDuration ) then
		Sleep( $FrameHandleDuration - $DeltaTime )
	endif
wend

func EventImageFound( $SpellNameIndex, $TargetIndex )
;	MsgBox( $MB_SYSTEMMODAL, "", "found img " & $SendKeyForMainTarget[ $SpellNameIndex ] & " at index " & $SpellNameIndex )
	if( $ScriptIsPaused <> 0 ) then
		return
	endif
	
	if( $TargetIndex > 6 ) then
		return
	endif
	
	if( $TargetIndex == 1 and $SpellNameIndex >= 0 and $SpellNameIndex < UBound( $SendKeyForFocusTarget ) and $SendKeyForFocusTarget[ $SpellNameIndex ] ) then
		Send( $SendKeyForFocusTarget[ $SpellNameIndex ] )
;		Send( "{ENTER}" & "1 1) target index " & $TargetIndex & " name index " & $SpellNameIndex & " key " & $SendKeyForFocusTarget[ $SpellNameIndex ] & " {ENTER}" )	
	elseif( $SpellNameIndex >= 0 and $SpellNameIndex < UBound( $SendKeyForMainTarget ) and $SendKeyForMainTarget[ $SpellNameIndex ] ) then 
		Send( $SendKeyForMainTarget[ $SpellNameIndex ] )
;		Send( "{ENTER}" & "2 2) target index " & $TargetIndex & " name index " & $SpellNameIndex & " key " & $SendKeyForMainTarget[ $SpellNameIndex ] & " {ENTER}" )	
	endif
endfunc

Func TryToGuessLocation()
	MsgBox( $MB_SYSTEMMODAL, "", "Location of KickBot Lua frame is not defined. Trying to search for it" )
	Local $set = PixelSearch( 0, 0, @DesktopWidth, @DesktopHeight, $ExpectedLUAIdleValue, 0 )
	If Not @error Then
		$LuaFramePosX = $set[0] + 8
		$LuaFramePosY = $set[1] + 8
		MouseMove( $LuaFramePosX, $LuaFramePosY )
		MsgBox( $MB_SYSTEMMODAL, "", "Location of KickBot Lua frame found at : " & $LuaFramePosX & " " & $LuaFramePosY )
	endif
endfunc
