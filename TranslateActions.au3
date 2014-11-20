Opt('MustDeclareVars', 1)

; you want to set this the same value as you used in "TakeScreenshots.au3"
global $ImagePixelCount = 32

; Keyboard shortcut to kill this script
HotKeySet("=", "Terminate")
; do not take any actions unles script is set to run
HotKeySet("-", "TogglePause")

;script will only monitor ingame actions as long as you have this key pressed ingame
;global $KeyToAllowScriptToTakeActions = 'q'
;global $KeyToAllowScriptToTakeActions2 = 'Q'
;global $KeyToAllowScriptToTakeActionsHex = Asc( $KeyToAllowScriptToTakeActions )
;global $KeyToAllowScriptToTakeActionsHex2 = Asc( $KeyToAllowScriptToTakeActions2 )

global $MonitoredImages[7]
$MonitoredImages[0] = "Judgement.bmp"
$MonitoredImages[1] = "Attack.bmp"
$MonitoredImages[2] = "AquireTarget.bmp"
$MonitoredImages[3] = "TemplarVerdict.bmp"
$MonitoredImages[4] = "HammerOfJustice.bmp"
$MonitoredImages[5] = "CrusaderStrike.bmp"
$MonitoredImages[6] = "Exorcism.bmp"

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
		;/target [@targettarget,harm,nodead,exists] [@focus,harm,nodead,exists] [@focustarget,harm,exists] [harm,nodead,exists]
	elseif( $ImageIndex == 3 ) then
		Send( "1" )
	elseif( $ImageIndex == 4 ) then
		Send( "2" )
	elseif( $ImageIndex == 5 ) then
		Send( "3" )
	elseif( $ImageIndex == 6 ) then
		Send( "4" )
	endif
endfunc

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Anything below should be working without any changes. If not.....it's bad
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
#include <Misc.au3>

global $ScriptIsRunning = 1
global $ScriptIsPaused = 0

Func Terminate()
    $ScriptIsRunning = 0
EndFunc

Func TogglePause()
    $ScriptIsPaused = 1 - $ScriptIsPaused
EndFunc

;HotKeySet( $KeyToAllowScriptToTakeActions, "EatIngameKeyUsage")
;HotKeySet( $KeyToAllowScriptToTakeActions2, "EatIngameKeyUsage")
;func EatIngameKeyUsage()
	; you are right, we are not doing anything
;endfunc

;global $dllhandle = DllOpen( "ImageSearchDLL.dll" )
global $dllhandle = DllOpen( "debug/ImageSearchDLL.dll" )
global $KeyDLL = DllOpen("user32.dll")

; wait until you alt+tab to wow window
WinWaitActive( "World of Warcraft" )

; these can be static. Declared them just because i was experimenting with stuff
global $MB_SYSTEMMODAL = 4096
global $SkipSearchOnColor = 0x01000000
global $colorTolerance = 1
global $ColorToleranceFaultsAccepted = 1
global $ExitAfterNMatchesFound = 1

; only monitor the part of the window where our addon is putting out text
FindAndSetNBSWindowPosition()
;MsgBox( $MB_SYSTEMMODAL, "", " but1 " & $KeyToAllowScriptToTakeActionsHex & " but 2 " & $KeyToAllowScriptToTakeActionsHex2 )

;loop until the end of days
if( $StartX <> 0 and $StartY <> 0 ) then
	; monitor that part of the screen and check if something changed. If it did, than we take actions 
	while( $ScriptIsRunning == 1 )
;		If ( _IsPressed( $KeyToAllowScriptToTakeActionsHex, $KeyDLL ) or _IsPressed( $KeyToAllowScriptToTakeActionsHex2, $KeyDLL ) )Then
			; continuesly take screenshots
			DllCall( $dllhandle,"str","TakeScreenshot","int",$StartX,"int",$StartY,"int",$StartX + $EndX + 1,"int",$StartY + $EndY + 1)
			; quick check if we need to check for specific actions
			local $result = DllCall( $dllhandle,"str","IsAnythingChanced","int", 0,"int", 0,"int",$EndX,"int",$EndY)
			if( GetResCount( $result ) > 0 ) then
;				MsgBox( $MB_SYSTEMMODAL, "", "change detected" )
				InvestigateNextActionToBeTaken()
			endif
;		endif
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
;		MsgBox( $MB_SYSTEMMODAL, "", "found at " & $StartX & " " & $StartY )
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