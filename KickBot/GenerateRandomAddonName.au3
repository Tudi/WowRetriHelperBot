#include <File.au3>

; Work on these files
local $CoreFileNames = StringSplit( "SendBackKeys_x32.exe,SendBackKeys_x64.exe,KickBot.lua,KickBot.toc,KickBot.xml", ',' )
local $CanDeleteFileNames = StringSplit( "SendBackKeys.au3,_Setup_4_KeyBinds_advanced.jpg,MouseInfo_x32.exe,GenerateRandomAddonName.au3,readme.txt,Compile.bat,_Setup_1_Addon.jpg,_Setup_2_Addon_middle_reposition.jpg,_setup_3_start_SendBackKeys.jpg,_Setup_4_KeyBinds.jpg,_Setup_5_Optional_if_error_reposition.jpg,MouseInfo.au3", ',' )
; create backup directory
DirCreate( "BackupFiles" )

;move core files to backup dir
for $i = 1 to ubound( $CoreFileNames ) - 1
	FileMove( $CoreFileNames[ $i ], "BackupFiles/" & $CoreFileNames[ $i ], 1 )
next
;move core files to backup dir
for $i = 1 to ubound( $CanDeleteFileNames ) - 1
	FileMove( $CanDeleteFileNames[ $i ], "BackupFiles/" & $CanDeleteFileNames[ $i ], 1 )
next
; cleanup random generated old addons
local $OldGeneratedRandomFiles;
$OldGeneratedRandomFiles = _FileListToArray ( "./", "*.lua", 1 )
for $i = 1 to ubound( $OldGeneratedRandomFiles ) - 1
	FileDelete( $OldGeneratedRandomFiles[ $i ] )
next
$OldGeneratedRandomFiles = _FileListToArray ( "./", "*.xml", 1 )
for $i = 1 to ubound( $OldGeneratedRandomFiles ) - 1
	FileDelete( $OldGeneratedRandomFiles[ $i ] )
next
$OldGeneratedRandomFiles = _FileListToArray ( "./", "*.toc", 1 )
for $i = 1 to ubound( $OldGeneratedRandomFiles ) - 1
	FileDelete( $OldGeneratedRandomFiles[ $i ] )
next
$OldGeneratedRandomFiles = _FileListToArray ( "./", "*.exe", 1 )
for $i = 1 to ubound( $OldGeneratedRandomFiles ) - 1
	FileDelete( $OldGeneratedRandomFiles[ $i ] )
next
$OldGeneratedRandomFiles = _FileListToArray ( "./", "*.au3", 1 )
for $i = 1 to ubound( $OldGeneratedRandomFiles ) - 1
	FileDelete( $OldGeneratedRandomFiles[ $i ] )
next

;Pick a random addon name
local $AddonNames = StringSplit( "DeadlyBossMods,Recount,MasterPlan,GarrisonMissionManager,SkadaDamageMeter,BigWigsBossmods,Bartender4,ElvUI,Altoholic,Auctionator,Bagnon,Mapster,MiksScrollingBattleText,Postal,OmniCC,Omen,Postal,AddonControlPanel,AutoRepair,TrashCan,GnomishVendorShrinker,BadBoy,MBB,VanasKoS,TargetPercent,WorldBossStatus,HabeebIt,TradeForwarder,BossesKilled,InspectFix,StrataFix,BlizzBugsSuck,CalendarKeyboardFixer", ',' )
local $NrOfNames = ubound( $AddonNames ) - 1
local $MyNewName = $AddonNames[ Random( 1, $NrOfNames ) ] & "Old"

;create the new addon directory name 
DirCreate( "../" & $MyNewName )

;Copy back the files but put new Name
local $NewFileNameList = ""
for $i = 1 to ubound( $CoreFileNames ) - 1
	local $NewFileNameParts
	if( StringInStr( $CoreFileNames[ $i ], '_', 0 ) == 0 ) then
		$NewFileNameParts = StringSplit( $CoreFileNames[ $i ], '.' )
	else
		$NewFileNameParts = StringSplit( $CoreFileNames[ $i ], '_' )
	endif
	local $NewFileName = $MyNewName & "." & $NewFileNameParts[2]
	FileCopy( "BackupFiles/" & $CoreFileNames[ $i ], "../" & $MyNewName & "/" & $NewFileName )
next

; Randomize LUA file so blizzard addon report tool would not hash it correctly
local $LUAFile = FileOpen ( "../" & $MyNewName & "/" & $MyNewName & ".lua", 1 )
FileWriteLine( $LUAFile, @CRLF & @CRLF & "local MyNewAddonNameIs = " & chr(34) & $MyNewName & chr(34) )
FileClose( $LUAFile )

; Randomize XML file so blizzard addon report tool would not hash it correctly
local $XMLFile = FileOpen ( "../" & $MyNewName & "/" & $MyNewName & ".xml", 1 )
FileWriteLine( $XMLFile, @CRLF & @CRLF & "<!-- this is a comment : " & $MyNewName & " --> ")
FileClose( $XMLFile )

; Generate new TOC file
_ReplaceStringInFile( "../" & $MyNewName & "/" & $MyNewName & ".toc", "## Title: KickBot", "## Title: " & $MyNewName )
_ReplaceStringInFile( "../" & $MyNewName & "/" & $MyNewName & ".toc", "KickBot.lua", $MyNewName & ".lua" )
_ReplaceStringInFile( "../" & $MyNewName & "/" & $MyNewName & ".toc", "KickBot.xml", $MyNewName & ".xml" )

; Replace variable names
_ReplaceStringInFile( "../" & $MyNewName & "/" & $MyNewName & ".xml", "KickBot", $MyNewName )
_ReplaceStringInFile( "../" & $MyNewName & "/" & $MyNewName & ".lua", "KickBot", $MyNewName )
_ReplaceStringInFile( "../" & $MyNewName & "/" & $MyNewName & ".toc", "KickBot", $MyNewName )

MsgBox( 4096, "", "New addon name is " & $MyNewName & ". It's in new directory not this one" )
