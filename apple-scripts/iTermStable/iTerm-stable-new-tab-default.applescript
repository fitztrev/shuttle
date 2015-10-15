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
		if it is running then
			tell the current terminal
				set newSession to (launch session withTheme)
				tell the last session
					reopen
					activate
					write text "clear"
					write text withCmd
					set name to theTitle
				end tell
			end tell
		else
			activate
			delay 0.2
			close first window
			set newTerm to (make new terminal)
			tell newTerm
				set newSession to (launch session withTheme)
				tell newSession
					write text withCmd
					set name to theTitle
					activate
				end tell
			end tell
		end if
	end tell
end CommandRun