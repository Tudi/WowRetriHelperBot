This project has 2 components :
1) addon for wow that will show a window that will periodically tell you what to do
2) autoit script that can "read info" and take actions accordingly

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
	- edit $SendKeyForMainTarget + $SendKeyForFocusTarget so the script will send proper keypress to the client. By default "Rebuke" is on key "9"

How to check if it is working :
- The greenish box should change it's color when the AU3 file should do something
- AU3 file should send keys presses to the client when greenish box changes color

Q : Can i use advanced scripting in AU3 ? 
A : Yes, you can try to do fancy stuff like send multiple keys. Example : target your focus target, cast a spell, target arena1 target cast another spell, retarget first target. All done by sending a list of key combinations for 1 single LUA feedback

Q : I can not see the addon in my addon list. 
A : You might need to put correct interface version in KickBot.toc file. Wotlk : 30000, Cataclysm 40000, MOP 50000, WOD 60000

Q : How do i disable spell casting on focus target ?
A : You can clear ingame castbar for that keybind. Or you can remove $SendKeyForFocusTarget rows

Q : How do i add a spell to the whitelist ?
A : Edit "KickBot.lua". Variable "SpellNamesCanInterruptOnPlayers" contains the list of spells that the bot can interrupt IF AllowAnyPlayerSpellInterrupt = 0. Each spell name should be surounded by "[]"

Q : How do i add a spell to the blacklist ?
A : Edit "KickBot.lua". Variable "SpellNamesCanNotInterrupt" contains the list of spells that the bot can NOT interrupt. Each spell name should be surounded by "[]"