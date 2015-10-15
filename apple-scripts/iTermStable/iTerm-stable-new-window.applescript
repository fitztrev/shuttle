--for testing uncomment the "on run" block
--on run
--	set argsCmd to "ps aux | grep [s]sh"
--	set argsTheme to "Homebrew"
--	set argsTitle to "Custom title"
--	preLoad(argsCmd, argsTheme, argsTitle)
--end run

on scriptRun(argsCmd, argsTheme, argsTitle)
	set withCmd to (argsCmd)
	set withTheme to (argsTheme)
	set theTitle to (argsTitle)
	preLoad(withCmd, withTheme, theTitle)
end scriptRun

on preLoad(withCmd, withTheme, theTitle)
	tell application "iTerm"
		if it is not running then
			activate
			delay 0.2
			close first window
		end if
	end tell
	CommandRun(withCmd, withTheme, theTitle)
end preLoad

on CommandRun(withCmd, withTheme, theTitle)
	tell application "iTerm"
		set newTerm to (make new terminal)
		tell newTerm
			set newSession to (launch session withTheme)
			tell newSession
				write text withCmd
				set name to theTitle
				activate
			end tell
		end tell
	end tell
end CommandRun