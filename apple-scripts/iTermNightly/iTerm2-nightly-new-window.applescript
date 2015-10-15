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
	tell application "iTerm"
		if it is not running then
			activate
			delay 0.2
			close first window
		end if
	end tell
	tell application "iTerm"
		create window with profile withTheme
		tell the current window
			tell the current session
				set name to theTitle
				set profile to withTheme
				write text withCmd
			end tell
		end tell
	end tell
end CommandRun
