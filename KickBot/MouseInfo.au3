; ~~ Mouse Hook ~~ 
;For more info, Visit: http://msdn.microsoft.com/en-us/library/ms644986(VS.85).aspx 
;Include GUI Consts 
#include <GUIConstants.au3> 
;for $GUI_EVENT_CLOSE 
#Include <WinAPI.au3> 
;for HIWORD 
;These constants found in the helpfile under Windows Message Codes 
Global Const $WM_MOUSEMOVE = 0x0200 ;mouse move 
Global Const $WM_MOUSEWHEEL = 0x020A ;wheel up/down 
Global Const $WM_LBUTTONDBLCLK = 0x0203 ;left button 
Global Const $WM_LBUTTONDOWN = 0x0201 
Global Const $WM_LBUTTONUP = 0x0202 
Global Const $WM_RBUTTONDBLCLK = 0x0206 ;right button 
Global Const $WM_RBUTTONDOWN = 0x0204 
Global Const $WM_RBUTTONUP = 0x0205 
Global Const $WM_MBUTTONDBLCLK = 0x0209 ;wheel clicks 
Global Const $WM_MBUTTONDOWN = 0x0207 
Global Const $WM_MBUTTONUP = 0x0208 ;Consts/structs from msdn 
Global Const $MSLLHOOKSTRUCT = $tagPOINT & ";dword mouseData;dword flags;dword time;ulong_ptr dwExtraInfo" 
;~ Global Const $WH_MOUSE_LL = 14           ;already declared 
;~ Global Const $tagPOINT = "int X;int Y"   ;already declared 
;Create GUI 
$GUI = GUICreate("Mouse Hook", 178, 224, @DesktopWidth-178, 0) ;Top-Left corner 
$_Event = GUICtrlCreateLabel("Event: ", 8, 8, 158, 17) 
$_XYpos = GUICtrlCreateLabel("X=     Y=", 8, 32, 157, 17) 
$_MData = GUICtrlCreateLabel("Mouse Data: ", 8, 56, 165, 17) 
$_Flags = GUICtrlCreateLabel("Flags: ", 8, 80, 168, 17) 
$_Timestamp = GUICtrlCreateLabel("Timestamp: ", 8, 104, 162, 17) 
$_Extra = GUICtrlCreateLabel("Extra Info: ", 8, 128, 167, 17) 
$_Pixel = GUICtrlCreateLabel("Pixel: ", 8, 152, 167, 17) 
$_PixelPos = GUICtrlCreateLabel("Mark: ", 8, 176, 167, 17) 
$_PixelAtPos = GUICtrlCreateLabel("Pixel At Mark: ", 8, 200, 167, 17) 
GUISetState() 
WinSetOnTop($GUI, "", 1) ;make GUI stay on top of other windows 

global $MonitoredMousePos = MouseGetPos()
HotKeySet("-", "RegisterMonitoredPixelPos")

Func RegisterMonitoredPixelPos()
		$MonitoredMousePos = MouseGetPos()
EndFunc 

;Register callback 
$hKey_Proc = DllCallbackRegister("_Mouse_Proc", "int", "int;ptr;ptr") 
$hM_Module = DllCall("kernel32.dll", "hwnd", "GetModuleHandle", "ptr", 0) 
$hM_Hook = DllCall("user32.dll", "hwnd", "SetWindowsHookEx", "int", $WH_MOUSE_LL, "ptr", DllCallbackGetPtr($hKey_Proc), "hwnd", $hM_Module[0], "dword", 0) 

While 1     
	If $GUI_EVENT_CLOSE = GUIGetMsg() Then Exit ;idle until exit is pressed 
WEnd 

Func _Mouse_Proc($nCode, $wParam, $lParam) ;function called for mouse events..     
	;define local vars     
	Local $info, $ptx, $pty, $mouseData, $flags, $time, $dwExtraInfo     
	Local $xevent = "Unknown", $xmouseData = ""         
	If $nCode < 0 Then ;recommended, see http://msdn.microsoft.com/en-us/library/ms644986(VS.85).aspx         
		$ret = DllCall("user32.dll", "long", "CallNextHookEx", "hwnd", $hM_Hook[0], "int", $nCode, "ptr", $wParam, "ptr", $lParam) ;recommended         
		Return $ret[0]     
	EndIf         
	$info = DllStructCreate($MSLLHOOKSTRUCT, $lParam) ;used to get all data in the struct ($lParam is the ptr)     
	$ptx = DllStructGetData($info, 1) ;see notes below..     
	$pty = DllStructGetData($info, 2)     
	$mouseData = DllStructGetData($info, 3)     
	$flags = DllStructGetData($info, 4)     
	$time = DllStructGetData($info, 5)     
	$dwExtraInfo = DllStructGetData($info, 6)     
	; $ptx = Mouse x position     
	; $pty = Mouse y position     
	; $mouseData = can specify click states, and wheel directions     
	; $flags = Specifies the event-injected flag     
	; $time = Specifies the time stamp for this message     
	; $dwExtraInfo = Specifies extra information associated with the message.     
	;Find which event happened     
	Select         
		Case $wParam = $WM_MOUSEMOVE             
		$xevent = "Mouse Move"         
		Case $wParam = $WM_MOUSEWHEEL             
		$xevent = "Mouse Wheel"            
		If _WinAPI_HiWord($mouseData) > 0 Then                 
		$xmouseData = "Wheel Forward"             
		Else                 
		$xmouseData = "Wheel Backward"            
		EndIf         
		Case $wParam = $WM_LBUTTONDBLCLK             
		$xevent = "Double Left Click"        
		Case $wParam = $WM_LBUTTONDOWN             
		$xevent = "Left Down"         
		Case $wParam = $WM_LBUTTONUP             
		$xevent = "Left Up"         
		Case $wParam = $WM_RBUTTONDBLCLK             
		$xevent = "Double Right Click"         
		Case $wParam = $WM_RBUTTONDOWN             
		$xevent = "Right Down"         
		Case $wParam = $WM_RBUTTONUP             
		$xevent = "Right Up"         
		Case $wParam = $WM_MBUTTONDBLCLK             
		$xevent = "Double Wheel Click"         
		Case $wParam = $WM_MBUTTONDOWN             
		$xevent = "Wheel Down"         
		Case $wParam = $WM_MBUTTONUP             
		$xevent = "Wheel Up"     
	EndSelect         
	; Set GUI control data..     
	GUICtrlSetData($_Event, "Event: " & $xevent)     
	GUICtrlSetData($_XYpos, "X=" & $ptx & "     Y=" & $pty)     

	GUICtrlSetData($_Pixel, "Pixel: " & PixelGetColor( $ptx, $pty ) & " " & Hex( PixelGetColor( $ptx, $pty ), 6 ) )     
	GUICtrlSetData($_PixelPos, "MonitoredPos: " & $MonitoredMousePos[0] & " " & $MonitoredMousePos[1] )     
	GUICtrlSetData($_PixelAtPos, "Pixel at mark: " & PixelGetColor( $MonitoredMousePos[0], $MonitoredMousePos[1] ) & " " & Hex( PixelGetColor( $MonitoredMousePos[0], $MonitoredMousePos[1] ), 6 ) )     

	If $xmouseData <> "" Then         
		GUICtrlSetData($_MData, "Mouse Data: " & $xmouseData)     
	Else         
		GUICtrlSetData($_MData, "Mouse Data: " & $mouseData)    
	EndIf     
	GUICtrlSetData($_Flags, "Flags: " & $flags)     
	GUICtrlSetData($_Timestamp, "Timestamp: " & $time)     
	GUICtrlSetData($_Extra, "Extra Info: " & $dwExtraInfo)         ;This is recommended instead of Return 0     
	$ret = DllCall("user32.dll", "long", "CallNextHookEx", "hwnd", $hM_Hook[0], "int", $nCode, "ptr", $wParam, "ptr", $lParam)     
	Return $ret[0] 
EndFunc   ;==>_Mouse_Proc 

Func OnAutoItExit()     
	DllCall("user32.dll", "int", "UnhookWindowsHookEx", "hwnd", $hM_Hook[0])     
	$hM_Hook[0] = 0     
	DllCallbackFree($hKey_Proc)     
	$hKey_Proc = 0 
EndFunc   ;==>OnAutoItExit