$IsFirstRun = 0
global $MB_SYSTEMMODAL = 4096

WinWaitActive( "World of Warcraft" )

$SkipSearchOnColor = 0x01000000
$colorTolerance = 1
$ColorToleranceFaultsAccepted = 1
$ExitAfterNMatchesFound = 1

$dllhandle = DllOpen( "debug/ImageSearchDLL.dll" )
;$dllhandle = DllOpen( "ImageSearchDLL.dll" )

DllCall( $dllhandle,"str","TakeScreenshot","int",0,"int",0,"int",2000,"int",2000)
if( $IsFirstRun <> 0 ) then
	DllCall( $dllhandle,"str","SaveScreenshot")
endif

if( $IsFirstRun <> 1 ) then
	$result = DllCall( $dllhandle,"str","ImageSearchOnScreenshot","str","Resync.bmp","int",$SkipSearchOnColor,"int",$colorTolerance,"int",$ColorToleranceFaultsAccepted,"int",$ExitAfterNMatchesFound)
	HandleResult( $result )
endif

DllClose( $dllhandle )

func HandleResult( $result )
	$array = StringSplit($result[0],"|")
	$resCount = Number( $array[1] )
	MsgBox( $MB_SYSTEMMODAL, "", "res count " & $resCount )
	if( $resCount > 0 ) then
		$x=Int(Number($array[2]))
		$y=Int(Number($array[3]))
		MouseMove( $x, $y );
		MsgBox( $MB_SYSTEMMODAL, "", "found at " & $x & " " & $y )
	endif
endfunc


