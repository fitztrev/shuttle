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

--to open in new tab have 3 conditions 
--iTerm app is not open.
--iTerm app is open with no windows.
--iTerm app is open with at least one window.
on CommandRun(withCmd, withTheme, theTitle)
	tell application "iTerm"
		if it is not running then
			--activate opens iTerm using default settings
			activate
			delay 0.2
			close first window
			--we don't want the defaults. 
			--lets close the first window and make our own
			set newTerm to (make new terminal)
			tell newTerm
				set newSession to (launch session withTheme)
				tell newSession
					write text withCmd
					set name to theTitle
					activate
				end tell
			end tell
		else
			--iTerm is running get the window count
			set windowCount to (count every window)
			set curTerm to (current terminal)
			if windowCount = 0 then
				--app is running with no windows
				--reopen opens iTerm using default settings
				reopen
				--we dont want the defaults.
				--lets close this and make our own
				terminate the first session of the first terminal
				set newTerm to (make new terminal)
				tell newTerm
					set newSession to (launch session withTheme)
					tell newSession
						write text withCmd
						set name to theTitle
						activate
					end tell
				end tell
			else
				--app is running with open windows
				--so do things in the current terminal
				tell curTerm
					set newSession to (launch session withTheme)
					tell the last session
						reopen
						activate
						write text "clear"
						write text withCmd
						set name to theTitle
					end tell
				end tell
			end if
		end if
	end tell
end CommandRun