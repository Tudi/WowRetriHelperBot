Opt('MustDeclareVars', 1)

; you want to set this the same value as you used in "TakeScreenshots.au3"
global $ImagePixelCount = 49
; this is required to not try to casts spells 1000 times per second while silenced :(
global $MaxFPS = 4

; Keyboard shortcut to kill this script
HotKeySet("[", "Terminate")
; do not take any actions unles script is set to run
HotKeySet("\", "TogglePause")

global $MonitoredImages[14]
$MonitoredImages[0] = "Judgement.bmp"
$MonitoredImages[1] = "Attack.bmp"
$MonitoredImages[2] = "AquireTarget.bmp"
$MonitoredImages[3] = "TemplarVerdict.bmp"
$MonitoredImages[4] = "HammerOfJustice.bmp"
$MonitoredImages[5] = "CrusaderStrike.bmp"
$MonitoredImages[6] = "Exorcism.bmp"

$MonitoredImages[7] = "SacredShield.bmp"
$MonitoredImages[8] = "HandofPurity.bmp"
$MonitoredImages[9] = "DivineProtection.bmp"

$MonitoredImages[10] = "ArcaneTorrent.bmp"
$MonitoredImages[11] = "FistofJustice.bmp"
$MonitoredImages[12] = "Rebuke.bmp"

$MonitoredImages[13] = "WaitingForCombat.bmp"

func EventImageFound( $ImageIndex )
;	MsgBox( $MB_SYSTEMMODAL, "", "found img " & $MonitoredImages[ $ImageIndex ] & " at index " & $ImageIndex )
	if( $ScriptIsPaused <> 0 ) then
		return
	endif
	
	if( $ImageIndex == 0 ) then
		Send( "5" )
	elseif( $ImageIndex == 1 ) then
;		Send( "5" )
	elseif( $ImageIndex == 2 ) then
;/cleartarget [dead]
;/assist [@focus, exists]
;/startattack
		Send( "9" )
	elseif( $ImageIndex == 3 ) then
		Send( "1" )
	elseif( $ImageIndex == 4 ) then
		Send( "2" )
	elseif( $ImageIndex == 5 ) then
		Send( "3" )
	elseif( $ImageIndex == 6 ) then
		Send( "4" )
	elseif( $ImageIndex == 7 ) then
		Send( "0" )
	elseif( $ImageIndex == 8 ) then
		Send( "-" )
	elseif( $ImageIndex == 9 ) then
		Send( "=" )
	elseif( $ImageIndex == 10 ) then
		Send( "8" )
	elseif( $ImageIndex == 11 ) then
		Send( "6" )
	elseif( $ImageIndex == 12 ) then
		Send( "7" )
	elseif( $ImageIndex == 13 ) then
		; do nothing. Wow addon thinks our best action is to melee ( ranged ) autoswing OR simply wait until combat will happen
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

global $dllhandle = DllOpen( "release/ImageSearchDLL.dll" )
;global $dllhandle = DllOpen( "debug/ImageSearchDLL.dll" )
global $KeyDLL = DllOpen("user32.dll")

; wait until you alt+tab to wow window
WinWaitActive( "World of Warcraft" )

; these can be static. Declared them just because i was experimenting with stuff
global $MB_SYSTEMMODAL = 4096
global $SkipSearchOnColor = 0x01000000
global $colorTolerance = 0
global $ColorToleranceFaultsAccepted = 0
global $ExitAfterNMatchesFound = 1

global $FrameHandleDuration = 1000 / $MaxFPS

; only monitor the part of the window where our addon is putting out text
FindAndSetNBSWindowPosition()
;MsgBox( $MB_SYSTEMMODAL, "", " but1 " & $KeyToAllowScriptToTakeActionsHex & " but 2 " & $KeyToAllowScriptToTakeActionsHex2 )

;loop until the end of days
if( $StartX <> 0 and $StartY <> 0 ) then
	local $LastActionCheckStamp = _Date_Time_GetTickCount( )
	; monitor that part of the screen and check if something changed. If it did, than we take actions 
	while( $ScriptIsRunning == 1 )
			local $TickNow = _Date_Time_GetTickCount( )
			
			; continuesly take screenshots
			DllCall( $dllhandle,"str","TakeScreenshot","int",$StartX,"int",$StartY,"int",$StartX + $EndX + 1,"int",$StartY + $EndY + 1)
			; quick check if we need to check for specific actions
			local $result = DllCall( $dllhandle,"str","IsAnythingChanced","int", 0,"int", 0,"int",$EndX,"int",$EndY)
			if( GetResCount( $result ) > 0 or $TickNow - $LastActionCheckStamp > 1000 ) then
;				MsgBox( $MB_SYSTEMMODAL, "", "change detected" )
				InvestigateNextActionToBeTaken()
				; this is required in case we get CC and can't press the "action" when it was signaled
				$LastActionCheckStamp = $TickNow
			endif
			
			;this is required to not overspam unusable actions
			local $TickAtEnd = _Date_Time_GetTickCount( )
			local $DeltaTime = $TickAtEnd - $TickNow
			if( $DeltaTime < $FrameHandleDuration ) then
				Sleep( $FrameHandleDuration - $DeltaTime )
			endif
	wend
endif

DllClose( $dllhandle )
DllClose( $KeyDLL )

func InvestigateNextActionToBeTaken()
	local $Index = 0
	local $iMax = UBound( $MonitoredImages )
	while( $Index < $iMax )
;		MsgBox( $MB_SYSTEMMODAL, "", "Check img " & $MonitoredImages[ $Index ] )
		local $result = DllCall( $dllhandle,"str","ImageSearchOnScreenshot","str",$MonitoredImages[ $Index ],"int",$SkipSearchOnColor,"int",$colorTolerance,"int",$ColorToleranceFaultsAccepted,"int",$ExitAfterNMatchesFound)
		if( GetResCount( $result ) > 0 ) then
			EventImageFound( $Index )
			$Index = 666
		endif
		$Index = $Index + 1
	wend
endfunc

func FindAndSetNBSWindowPosition()
	global $StartX = 0
	global $StartY = 0
	global $EndX = 0
	global $EndY = 0
	global $dllhandle
	DllCall( $dllhandle,"str","TakeScreenshot","int",0,"int",0,"int",2000,"int",2000)
	local $result = DllCall( $dllhandle, "str","ImageSearchOnScreenshot","str","Resync.bmp","int",$SkipSearchOnColor,"int",$colorTolerance,"int",$ColorToleranceFaultsAccepted,"int",$ExitAfterNMatchesFound)
	local $array = StringSplit( $result[0], "|" )
	local $resCount = Number( $array[1] )
	if( $resCount > 0 ) then
		$StartX = Int(Number($array[2]))
		$StartY = Int(Number($array[3]))
		$result = DllCall( $dllhandle,"str","GetImageSize","str","Resync.bmp")
		$array = StringSplit($result[0],"|")
		$EndX = Int(Number($array[1]))
		$EndY = Int(Number($array[2]))
		; number of pixels should be small as possible to avoid CPU overload
		$EndX = $ImagePixelCount
		MsgBox( $MB_SYSTEMMODAL, "", "found Resync.bmp at " & $StartX & " " & $StartY )
;		MsgBox( $MB_SYSTEMMODAL, "", "search width & height " & $EndX & " " & $EndY )
	else
		MsgBox( $MB_SYSTEMMODAL, "", "Could not find sync location! Make sure Resync.bmp is generated for this WOW resolution " )
	endif
endfunc

func GetResCount( $result )
	if( IsArray( $result ) ) Then
		local $array = StringSplit( $result[0], "|" )
		local $resCount = Number( $array[1] )
		return $resCount
	endif
	return 0
endfunc