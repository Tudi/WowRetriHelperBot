#include <Date.au3>

HotKeySet("]", "ToggleRunScript" )
HotKeySet("o", "ExitScript" )

global $ScriptIsRunning = 1
global $ScriptIsPaused = 1
global $MB_SYSTEMMODAL = 4096

;global $dllhandle = DllOpen ( "debug/ImageSearchDLL.dll" )
global $dllhandle = DllOpen ( "release/ImageSearchDLL.dll" )

while $ScriptIsRunning == 1
    Sleep( 100 )
wend   
   
DllClose ( $dllhandle )

func ExitScript()
    $ScriptIsRunning = 0
endfunc

func ToggleRunScript()
    $ScriptIsPaused = 1 - $ScriptIsPaused
	if( $ScriptIsPaused == 0 ) then 
		ContinuesFishing()
	endif
endfunc

func ContinuesFishing()
	local $MaxSAD = 0;
    while( $ScriptIsPaused == 0 and $ScriptIsRunning == 1 )
        ; Cast fishing
        Send( 1 )
		local $Timeout = _Date_Time_GetTickCount( ) + 20 * 1000;
		; wait for spawn animation
		Sleep( 3000 )
        ;check where bober landed
		Local $bobberNow[3] = [ 0, 0, 0 ]
        Local $bobberAtStart = GetBoberLocation( $bobberNow )
;		MsgBox( $MB_SYSTEMMODAL, "", "found at " & $bobberAtStart[0] & " " & $bobberAtStart[1] )
		local $MaxDiffY = 0
		local $MaxDiffx = 0
		while( _Date_Time_GetTickCount( ) < $Timeout and $ScriptIsRunning == 1 )
		
			Local $bobberNow = GetBoberLocation( $bobberAtStart )
			
			MouseMove( $bobberNow[0], $bobberNow[1] )
			
			local $diffNowy = $bobberNow[1] - $bobberAtStart[1]
			local $diffNowx = $bobberNow[0] - $bobberAtStart[0]
			
			if( $diffNowy > $MaxDiffY ) then
				$MaxDiffY = $diffNowy
			endif
			if( $diffNowx > $MaxDiffX ) then
				$MaxDiffX = $diffNowx
			endif

			if( $diffNowx < 0 ) then 
				$diffNowx = -$diffNowx;
			endif
			if( $diffNowy < 0 ) then
				$diffNowy = -$diffNowy;
			endif
				
			local $SADNow = $bobberNow[2]
			if( $SADNow > $MaxSAD ) then 
				$MaxSAD = $SADNow
			endif
				
			;this SAD could be only for me, that is why i multiply it by X
;			if( $SADNow < 6206 * 2 and ( $diffNowy > 7 or $diffNowx > 7 ) ) then
			if( $diffNowy > 7 or $diffNowx > 7 ) then
;				MsgBox( $MB_SYSTEMMODAL, "", "Got a big diff. Max x diff " & $MaxDiffX & " y " & $MaxDiffY )
				Sleep( 2000 )
				MouseClick( 'left', $bobberAtStart[0], $bobberAtStart[1], 1)
				$Timeout = 0xFFFFFFFF
			endif
		wend
    wend
	MsgBox( $MB_SYSTEMMODAL, "", "Max sad " & $MaxSAD )
	MsgBox( $MB_SYSTEMMODAL, "", "Fishing session ended" )
endfunc

func GetBoberLocation( $PreviousLocation )
	Local $bobberASearch[3]
	Local $result[3]

	if( $PreviousLocation[0] == 0 ) then
		DllCall( $dllhandle,"NONE","TakeScreenshot","int",370,"int",153,"int",1380,"int",616 )
	else
		DllCall( $dllhandle,"NONE","TakeScreenshot", "int", $PreviousLocation[0] - 10, "int", $PreviousLocation[1] - 10, "int", $PreviousLocation[0] + 10, "int", $PreviousLocation[1] + 10 )
	endif
	$result = DllCall( $dllhandle,"str","ImageSearchOnScreenshotBest","str","bobber_try4.bmp" )
	$array = StringSplit($result[0],"|")
	$resCount = Number( $array[1] )
	if( $resCount > 0 ) then
		$bobberASearch[0]=Int(Number($array[2]))
		$bobberASearch[1]=Int(Number($array[3]))
		$bobberASearch[2]=Int(Number($array[4]))
;		MsgBox( $MB_SYSTEMMODAL, "", "found at " & $bobberASearch[0] & " " & $bobberASearch[1] & " result was " & $result[0])
;		MouseMove( $bobberASearch[0], $bobberASearch[1] );
;	else
;		MsgBox( $MB_SYSTEMMODAL, "", "res count " & $resCount & " from result str " & $result[0] )
	endif

	return $bobberASearch;
endfunc

func GetRGB( $r, $g, $b )
    return $b * 65536 + $g * 256 + $r;
endfunc