Opt('MustDeclareVars', 1)

; this is required to not try to casts spells 1000 times per second while silenced :(
global $MaxFPS = 4

; Keyboard shortcut to kill this script
HotKeySet("[", "Terminate")
; do not take any actions unles script is set to run
HotKeySet("\", "TogglePause")

global $LuaFramePosX = -1
global $LuaFramePosy = -1
global $RGBStep = 16
global $FirstValidRGB = 1 * $RGBStep
global $SendKeyForRGB[20]
global $ExpectedLUAIdleValue = 0x0010FF80

$SendKeyForRGB[0] = "8"		;Fist of Justice
$SendKeyForRGB[1] = "9"		;Rebuke
$SendKeyForRGB[3] = "0"		;Arcane Torrent
$SendKeyForRGB[4] = "9"		;Counterspell
$SendKeyForRGB[5] = "9"		;Wind Shear
$SendKeyForRGB[6] = "9"		;Kick
$SendKeyForRGB[7] = "9"		;Counter Shot
$SendKeyForRGB[8] = "9"		;Pummel
$SendKeyForRGB[9] = "9"		;Spear Hand Strike
$SendKeyForRGB[10] = "9"	;Mind Freeze
$SendKeyForRGB[11] = "9"	;Strangulate

func EventImageFound( $ImageIndex )
;	MsgBox( $MB_SYSTEMMODAL, "", "found img " & $SendKeyForRGB[ $ImageIndex ] & " at index " & $ImageIndex )
	if( $ScriptIsPaused <> 0 ) then
		return
	endif
	
	if( $SendKeyForRGB[ $ImageIndex ] ) then
		Send( $SendKeyForRGB[ $ImageIndex ] )
	endif
endfunc

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

; these can be static. Declared them just because i was experimenting with stuff
if( IsDeclared( "MB_SYSTEMMODAL" ) <> 1 ) then 
	global $MB_SYSTEMMODAL = 4096
endif

; probably did not set manually a value
if( $LuaFramePosX == -1 ) then
	TryToGuessLocation()
endif

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
		;MsgBox( $MB_SYSTEMMODAL, "", "change detected " & $ColorB )
		local $ColorB = Int( $LuaColor / 65535 )
		local $ColorIndex = Int( ( $ColorB - $FirstValidRGB ) / $RGBStep )
		
		if( WinActive( "World of Warcraft" ) ) then 
			Send( "{ENTER}" & " change detected " & $ColorB & " with index " & $ColorIndex & " {ENTER}" )	
		endif
		
		EventImageFound( $ColorIndex )
		$PrevValue = $LuaColor
	endif
	
	;this is required to not overspam unusable actions
	local $TickAtEnd = _Date_Time_GetTickCount( )
	local $DeltaTime = $TickAtEnd - $TickNow
	if( $DeltaTime < $FrameHandleDuration ) then
		Sleep( $FrameHandleDuration - $DeltaTime )
	endif
wend

Func TryToGuessLocation()
	MsgBox( $MB_SYSTEMMODAL, "", "Location of KickBot Lua frame is not define. Trying to search for it" )
	Local $set = PixelSearch( 0, 0, @DesktopWidth, @DesktopHeight, $ExpectedLUAIdleValue, 0 )
	If Not @error Then
		$LuaFramePosX = $set[0] + 8
		$LuaFramePosY = $set[1] + 8
		MouseMove( $LuaFramePosX, $LuaFramePosY )
		MsgBox( $MB_SYSTEMMODAL, "", "Location of KickBot Lua frame found at : " & $LuaFramePosX & " " & $LuaFramePosY )
	endif
endfunc