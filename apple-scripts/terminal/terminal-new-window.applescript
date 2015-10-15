--for testing uncomment the "on run" block
--on run
--	set argsCmd to "ps aux | grep [s]sh"
--	set argsTheme to "Homebrew"
--	set argsTitle to "Custom title"
--	CommandRun(argsCmd, argsTheme, argsTitle)
--end run

on scriptRun(argsCmd, argsTheme, argsTitle)
	set withCmd to (argsCmd)
	set withTheme to (argsTheme)
	set theTitle to (argsTitle)
	CommandRun(withCmd, withTheme, theTitle)
end scriptRun

on CommandRun(withCmd, withTheme, theTitle)
	tell application "Terminal"
		if it is not running then
			--if this is the first time Terminal is running you have specify window 1
			--if you dont do this you will get two windows and the title wont be set
			set newTerm to do script withCmd in window 1
		else
			set newTerm to do script withCmd
		end if
		activate
		set newTerm's current settings to settings set withTheme
		set custom title of front window to theTitle
	end tell
end CommandRun
