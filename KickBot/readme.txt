this project has 2 components :
1) addon for wow that will show a window that will periodically tell you what to do
2) autoit script that can "read text" and take actions accordingly

Install :
- copy files into ?????\World of Warcraft\Interface\AddOns\KickBot\
- make sure you have the "KickBot" addon enabled

Setup :
- log ingame
- position the small greenish box ( that is in the middle of the screen ) somewhere where it does not bother you. It's not covered by other window. You will not later move this window
- Optional, if "SendBackKeys.au3" can not automatically find the greenish box correctly :
	- start "MouseInfo.au3" and get the location( aprox middle ) of the grey box
	- edit SendBackKeys.au3. Set proper $LuaFramePosX and $LuaFramePosY
- Optional : 
	- edit $SendKeyForRGB so the script will send proper keypress to the client. By default "Rebuke" is on key "9"

How to check if it is working :
- The greenish box should change it's color when the AU3 file should do something
- AU3 file should send keys presses to the client when greenish box changes color

Q : Can i use advanced scripting in AU3 ? 
A : Yes, you can try to do fancy stuff like send multiple keys. Example : target your focus target, cast a spell, target arena1 target cast another spell, retarget first target. All done by sending a list of key combinations for 1 single LUA feedback