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
- hold button "q" for automatic action taking