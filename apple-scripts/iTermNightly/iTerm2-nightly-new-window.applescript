--for testing uncomment the "on run" block
--on run
--	set argsCmd to "ps aux | grep [s]sh"
--	set argsTheme to "Homebrew"
--	set argsTitle to "Custom title"
--	scriptRun(argsCmd, argsTheme, argsTitle)
--end run

on scriptRun(argsCmd, argsTheme, argsTitle)
	set withCmd to (argsCmd)
	set withTheme to (argsTheme)
	set theTitle to (argsTitle)
	CommandRun(withCmd, withTheme, theTitle)
end scriptRun

on CommandRun(withCmd, withTheme, theTitle)
	tell application "iTerm"
		if it is not running then
			activate
			if (count windows) is 0 then
				NewWin(withTheme) of me
			end if
		else
			NewWin(withTheme) of me
		end if
		tell the current window
			tell the current session
				set name to theTitle
				write text withCmd
			end tell
		end tell
	end tell
end CommandRun

on NewWin(argsTheme)
	tell application "iTerm"
		try
			create window with profile argsTheme
		on error msg
			create window with profile "Default"
		end try
	end tell
end NewWin
