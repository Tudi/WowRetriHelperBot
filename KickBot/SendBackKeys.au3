Opt('MustDeclareVars', 1)

; this is required to not try to casts spells 1000 times per second while silenced :(
global $MaxFPS = 4
; Resend same key interval. In case of a latency spike, you get "spell not ready yet" than this will force AU3 to send the same key after ex 200ms
global $ResendSameKeyInterval = 500
; Due to latency, when wow client wants to do something, it takes time until server replies. Do not spam multiple interrupt spells due to latency
; This is actually a bad setting. You might want to set it to 0. In my case i need it
global $ForcedSpellCastCooldown = 500

; Keyboard shortcut to kill this script
HotKeySet("[", "Terminate")
; do not take any actions unles script is set to run
HotKeySet("\", "TogglePause")

global $LuaFramePosX = -1
global $LuaFramePosy = -1
global $RGBStep = 4
global $FirstValidRGB = 1 * $RGBStep
global $ExpectedLUAIdleValue = 0x0010FF80

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
	exit
endif

global $FrameHandleDuration = 1000 / $MaxFPS
global $SendKey = ""

;MsgBox( $MB_SYSTEMMODAL, "", " but1 " & $KeyToAllowScriptToTakeActionsHex & " but 2 " & $KeyToAllowScriptToTakeActionsHex2 )

local $PrevValue = 0
;loop until the end of days
local $LastActionCheckStamp = _Date_Time_GetTickCount( )
;monitor when we sent out last key
local $LastForceSendStamp = _Date_Time_GetTickCount( )
; monitor the interval of key spams
local $LastKeySendStamp = _Date_Time_GetTickCount( )
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
		local $SpellNameIndex = Int( ( $ColorG - $FirstValidRGB ) / $RGBStep )
		local $TargetIndex = Int( ( $ColorR - $FirstValidRGB ) / $RGBStep )
		local $SendKeyOrd = Int( $ColorB )
		
		if( WinActive( "World of Warcraft" ) ) then 
			; Debugging. Can delete this
;			MsgBox( $MB_SYSTEMMODAL, "", "change detected " & $ColorR & " " & $ColorG & " " & $ColorB )
;			Send( "{ENTER}" & " RGB " & $ColorR & " " & $ColorG & " " & $ColorB & " with index " & $SpellNameIndex & " " & $TargetIndex & " " & $SendKeyOrd & " {ENTER}" )	
			EventImageFound( $SpellNameIndex, $TargetIndex, $SendKeyOrd )
		endif
		
		$PrevValue = $LuaColor
	endif
	
	; if for some reason "key" was lost ( ex : spell cooldown ) than resend the same key after X ms
	if( $SendKey <> "" and $LastForceSendStamp + $ResendSameKeyInterval < $TickNow ) then
		MySendKey( $SendKey )
;		Send( "{ENTER}" & "resend " & $SendKey & " = " & asc( $SendKey ) & " {ENTER}" )	
	endif
	
	;this is required to not overspam unusable actions
	local $TickAtEnd = _Date_Time_GetTickCount( )
	local $DeltaTime = $TickAtEnd - $TickNow
	if( $DeltaTime < $FrameHandleDuration ) then
		Sleep( $FrameHandleDuration - $DeltaTime )
	endif
wend

func MySendKey( $key )
	if( $ScriptIsPaused <> 0 ) then
		return
	endif
	
	local $TickNow = _Date_Time_GetTickCount( )
	
	; do not cast multiple interrupt spells because the private server did not yet sent us the interrupt cast packet. Wait a bit
	if( $LastKeySendStamp + $ForcedSpellCastCooldown > $TickNow ) then
		return
	endif
	
	; send the key as expected to the client
	if( WinActive( "World of Warcraft" ) ) then 
		; you could script send key if you are using UTF-8 character keyboard. That ? you might see below is a cyrilic character
		; I never tested this code, but according to autoit documentation it should be something similar
;		if( $key == '?' ) then 
;			ControlSend( "World of Warcraft", "", "", "this is my UTF-8 char override" )
;		else
			Send( $key )
;		endif
	endif
	
	; we sent a key, no need to send it again for a while
	$LastKeySendStamp = $TickNow
	$LastForceSendStamp = $TickNow
endfunc

func EventImageFound( $SpellNameIndex, $TargetIndex, $SendKeyFromLUA )
	$SendKey = ""
;	Send( "{ENTER}" & "1 target index " & $TargetIndex & " name index " & $SpellNameIndex & " key " & $SendKeyFromLUA & " key " & chr( $SendKeyFromLUA ) & " {ENTER}" )	
	if( $ScriptIsPaused <> 0 ) then
		return
	endif
	
	if( $SendKeyFromLUA <=0 and( $TargetIndex > 6 or $SpellNameIndex < 0 or $SpellNameIndex >= 20 ) ) then
		return
	endif

	if( $SendKeyFromLUA <> 0 and $SendKeyFromLUA <> Mod( $ExpectedLUAIdleValue, 256 ) ) then
		$SendKey = chr( $SendKeyFromLUA )
	endif
	
	if( $SendKey <> "" ) then
		MySendKey( $SendKey )
;		Send( "{ENTER}" & "2 target index " & $TargetIndex & " name index " & $SpellNameIndex & " key " & $SendKey & " keylua " & $SendKeyFromLUA & " {ENTER}" )	
	endif
endfunc

Func TryToGuessLocation()
;	MsgBox( $MB_SYSTEMMODAL, "", "Location of KickBot Lua frame is not defined. Trying to search for it" )
	Local $set = PixelSearch( 0, 0, @DesktopWidth, @DesktopHeight, $ExpectedLUAIdleValue, 0 )
	If Not @error Then
		$LuaFramePosX = $set[0] + 8
		$LuaFramePosY = $set[1] + 8
		MouseMove( $LuaFramePosX, $LuaFramePosY )
		MsgBox( $MB_SYSTEMMODAL, "", "Location of KickBot Lua frame found at : " & $LuaFramePosX & " " & $LuaFramePosY )
	endif
endfunc
