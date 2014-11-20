#include <Misc.au3>

Global $fPaused = 1
global $ActivationKey = "q"
global $hDLL = DllOpen("user32.dll")

HotKeySet("=", "Terminate")
Func Terminate()
	DllClose($hDLL)
    Exit
EndFunc   

HotKeySet( $ActivationKey, "Togglespamrandomstuff")

While 1
	while( $fPaused == 0 )
		Sleep(1000)
	wend
	Sleep( 100 )
WEnd

Func Togglespamrandomstuff()
    $fPaused = 1 - $fPaused
	while( _IsPressed( "51", $hDLL ) )
		Send("12345")
		Sleep( 500 )
	wend
EndFunc  

DllClose($hDLL)

