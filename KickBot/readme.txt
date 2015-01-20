This project has 2 components :
1) LUA addon for wow that will show a window that will periodically tell you what to do
2) autoit script that can "read info"(pixel color) and take actions accordingly

Install :
- copy files into ?????\World of Warcraft\Interface\AddOns\KickBot\
- make sure you have the "KickBot" addon enabled
- Optional : rename :kickbot to something else. rainbowdash ? Replace file names and all strings....

Setup :
- log ingame
- position the small greenish box ( that is in the middle of the screen ) somewhere where it does not bother you. It's not covered by other window. You will not later move this window
- Optional, if "SendBackKeys.au3" can not automatically find the greenish box correctly :
	- start "MouseInfo.au3" and get the location( aprox middle ) of the grey box
	- edit SendBackKeys.au3. Set proper $LuaFramePosX and $LuaFramePosY
- Optional : 
	- edit RegisterKickerSpell lines so the script will send proper keypress to the client. By default "Rebuke" is on key "8"....

How to check if it is working :
- The greenish box should change it's color when the AU3 file should do something
- AU3 file should send keys presses to the client when greenish box changes color

Possible bugs :
- it's not interrupting anything : Check SpellCastAllowLatency + SecondsUntilSpellCastEndToInterruptStart to be smaller than the spell you want to interrupt. Check SecondsUntilSpellCastEndToInterruptEnd to be small enough. 
- it's interrupting even instant cast spells : Check SecondsUntilSpellCastEndToInterruptStart to be larger than 1 second


Q : What wow version can i use it ?
A : I tested on 4.3.4. In theory it should work on 3.x, 5.x, 6.x also. Might need to change the "KickBot.toc" for it

Q : I can not see the addon in my addon list. 
A : You might need to put correct interface version in KickBot.toc file. Wotlk : 30000, Cataclysm 40000, MOP 50000, WOD 60000

Q : Can it be detected by blizzard ?
A : In theory this uses same method as for example mouse with macro. If you get banned you should make a complaint ticket. Ofc if start abusing the bot by interrupting instant cast spells than you might get in trouble

Q : Anything you recommend to not get reported by other players?
A : Add a random factor to it. Do not use it always at the same cast bar position and maybe do not interrupt every same spell...

Q : Can i use it to interrupt focus target casts ?
A : Yes. Make an apropriate macro for it. /cast @focustarget manlykick

Q : Can i improve it to become a PQR bot ?
A : This was initially a PQR bot, i nerfed it to a kickbot

Q : Is there a way to run this bot without autoit installed ?
A : Yes, you can use the compiled exe. It's the same as the autoit version

Q : My interrupt spell is missing from a list, how do i add it ?
A : Edit "KickBot.lua" and add your spell there. Example row : RegisterKickerSpell( "Rebuke", '8', '-', '=', '', '', '', '' )

Q : Can i use advanced scripting in AU3 ? 
A : Yes, you can try to do fancy stuff like send multiple keys. Example : target your focus target, cast a spell, target arena1 target cast another spell, retarget first target. All done by sending a list of key combinations for 1 single LUA feedback

Q : How do i disable spell casting on focus target ?
A : You can clear ingame castbar for that keybind. Or you can edit RegisterKickerSpell and remove the keybind there

Q : How do i add a spell to the whitelist ?
A : Edit "KickBot.lua". Variable "SpellNamesCanInterruptOnPlayers" contains the list of spells that the bot can interrupt IF AllowAnyPlayerSpellInterrupt = 0. Each spell name should be surounded by "[]"

Q : How do i add a spell to the blacklist ?
A : Edit "KickBot.lua". Variable "SpellNamesCanNotInterrupt" contains the list of spells that the bot can NOT interrupt. Each spell name should be surounded by "[]"