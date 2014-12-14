; In case you did not do it yet : set $IsFirstRun = 1, take a full screenshot of your ingame wow so you can regenerate "Resync.bmp"
; If you have a valid "Resync.bmp" than set $IsFirstRun = 0 and generate images you will search later
$IsFirstRun = 0

;The minimum pixel count for image width so you can search for images without confusing them. Maybe even 2 characters are enough if you do not have too many actions ?
$ImagePixelCount = 49

global $MB_SYSTEMMODAL = 4096

; wait until you alt+tab to wow window
WinWaitActive( "World of Warcraft" )

; these can be static. Declared them just because i was experimenting with stuff
$SkipSearchOnColor = 0x01000000
$colorTolerance = 0
$ColorToleranceFaultsAccepted = 0
$ExitAfterNMatchesFound = 1

$dllhandle = DllOpen( "release/ImageSearchDLL.dll" )
;$dllhandle = DllOpen( "debug/ImageSearchDLL.dll" )

DllCall( $dllhandle,"str","TakeScreenshot","int",0,"int",0,"int",2000,"int",2000)
if( $IsFirstRun <> 0 ) then
	MsgBox( $MB_SYSTEMMODAL, "", "Saving is slow. Wait a sec" )
	DllCall( $dllhandle,"str","SaveScreenshot")
	MsgBox( $MB_SYSTEMMODAL, "", "Screenshot saved. Cut out the new 'Resync.bmp'" )
endif

if( $IsFirstRun <> 1 ) then

	global $EndX = 0
	global $EndY = 0
	$result = DllCall( $dllhandle,"str","GetImageSize","str","Resync.bmp")
	$array = StringSplit($result[0],"|")
	$EndX = Int(Number($array[1]))
	$EndY = Int(Number($array[2]))
	;MsgBox( $MB_SYSTEMMODAL, "", "TextSize " & $EndX & " " & $EndY )
	
	; where is our output textbox ?
	global $StartX = 0
	global $StartY = 0
	$result = DllCall( $dllhandle,"str","ImageSearchOnScreenshot","str","Resync.bmp","int",$SkipSearchOnColor,"int",$colorTolerance,"int",$ColorToleranceFaultsAccepted,"int",$ExitAfterNMatchesFound)
	HandleResult( $result )
	
	if( $StartX <> 0 and $StartY <> 0 ) then
		;Start taking screenshots
		$EndX = $ImagePixelCount
		$ScreenshotsRemaining = 18
		while( $ScreenshotsRemaining >= 0 )
			;MsgBox( $MB_SYSTEMMODAL, "", "Compare region" & $StartX & "," & $StartY & " " & $EndX & "," & $EndY & " " )
			DllCall( $dllhandle,"str","TakeScreenshot","int",$StartX,"int",$StartY,"int",$StartX + $EndX,"int",$StartY + $EndY)
			$result = DllCall( $dllhandle,"str","IsAnythingChanced","int", 0,"int", 0,"int",$EndX,"int",$EndY)
			$array = StringSplit( $result[0], "|" )
			$resCount = Number( $array[1] )
	;		MsgBox( $MB_SYSTEMMODAL, "", "Could not find sync location! " & $result[0] & " " & $resCount & " " & $array[0] & " " & $array[1] & " " & $array[2] & " " & $array[3] )
			if( $resCount > 0 ) then
				DllCall( $dllhandle,"str","SaveScreenshot")
				$ScreenshotsRemaining = $ScreenshotsRemaining - 1
	;			MsgBox( $MB_SYSTEMMODAL, "", "found sync location! " & $resCount )
			endif
		wend
		MsgBox( $MB_SYSTEMMODAL, "", "Finished taking screenshots. You need to assign them in TranslateActions.au3" )
	endif
endif

DllClose( $dllhandle )

func HandleResult( $result )
;	MsgBox( $MB_SYSTEMMODAL, "", "result " & $result )
	$array = StringSplit($result[0],"|")
	$resCount = Number( $array[1] )
	if( $resCount > 0 ) then
		$StartX = Int(Number($array[2]))
		$StartY = Int(Number($array[3]))
;		MouseMove( $StartX, $StartY );
		MsgBox( $MB_SYSTEMMODAL, "", "found at " & $StartX & " " & $StartY )
	else
		MsgBox( $MB_SYSTEMMODAL, "", "Could not find sync location! " )
	endif
endfunc


