this project has 2 components :
1) addon for wow that will show a window that will periodically tell you what to do
2) autoit script that can "read text" and take actions accordingly

Requirements :
- wow running in win32 mode ( it's called wow.exe in task manager not wow-64.exe ) -noautolaunch64bit
- autoit
- VS2008 runtime libraries
- images are made for a specific resolution. In case you have different resolution you most probably need to remake images. 

Install :
- copy files into ?????\World of Warcraft\Interface\AddOns\NextBestSpell\
- make sure you have the "NextBestSpell" addon enabled
- after login .. character ingame.... start "TranslateActions.au3"

How to check if it is working :
- "NextBestSpell" addon should write different text based on your spell cooldowns / positioning
- "TranslateActions.au3" should be able to find those "text" images and send button push actions accordingly


Setup :
This is only required if default setup is not working for you
- login ingame
- make sure "NextBestSpell" addon is running. There should be a gray background text window saying "waiting for combat"
- start addon demo mode by typing ingame chat message : "/nbs demo". If you did it right than the "textwindow" should cycle available text messages
- open "TakeScreenshots.au3"
- make sure $IsFirstRun = 1
- start "TakeScreenshots.au3"
- alt tab back to game so it can take 1 screenshot of your whole game window. Image name is probably "Screenshot_0000_2000_2000.bmp"
- open "paint" and cut out something that looks like provided "Resync.bmp". Make sure edges only contain the "gray color" + "you included the dot"
- save your new "Resync.bmp" as 24bit color bmp 
- $IsFirstRun = 0
- start "TakeScreenshots.au3"
- alt tab back to game, wait for "TakeScreenshots.au3" to say he is done taking screenshots
- rename the images so TranslateActions.au3 can load them
- edit "TranslateActions.au3" to map images to your keybinds