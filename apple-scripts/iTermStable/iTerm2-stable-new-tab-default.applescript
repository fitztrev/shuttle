--for testing uncomment the "on run" block
--on run
--	set argsCmd to "ps aux | grep xcode"
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
			SetWinParam(theTitle, withCmd) of me
		else if (count windows) is 0 then
			NewWin(withTheme) of me
			SetWinParam(theTitle, withCmd) of me
		else
			NewTab(withTheme) of me
			SetTabParam(theTitle, withCmd) of me
		end if
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

on SetWinParam(argsTitle, argsCmd)
	tell application "iTerm"
		tell the current window
			tell the current session
				set name to argsTitle
				write text argsCmd
			end tell
		end tell
	end tell
end SetWinParam

on NewTab(argsTheme)
	tell application "iTerm"
		tell the current window
			try
				create tab with profile withTheme
			on error msg
				create tab with profile "Default"
			end try
		end tell
	end tell
end NewTab

on SetTabParam(argsTitle, argsCmd)
	tell application "iTerm"
		tell the current window
			tell the current tab
				tell the current session
					set name to argsTitle
					write text argsCmd
				end tell
			end tell
		end tell
	end tell
end SetTabParam
