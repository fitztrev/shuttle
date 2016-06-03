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
			tell application "iTerm"
				activate
				delay 0.2
				try
					close first window
				end try
			end tell
			
			tell application "iTerm"
				try
					create window with profile withTheme
				on error msg
					create window with profile "Default"
				end try
				tell the current window
					tell the current session
						set name to theTitle
						set profile to withTheme
						write text withCmd
					end tell
				end tell
			end tell
		else
			--assume that iTerm is open and open a new tab
			try
				tell application "iTerm"
					activate
					tell the current window
						try
							create tab with profile withTheme
						on error msg
							create tab with profile "Default"
						end try
						tell the current tab
							tell the current session
								set name to theTitle
								write text withCmd
							end tell
						end tell
					end tell
				end tell
			on error msg
				--if all iTerm windows are closed the app stays open. In this scenario iTerm has no "current window" and will give an error when trying to create the new tab.  
				tell application "iTerm"
					try
						create window with profile withTheme
					on error msg
						create window with profile "Default"
					end try
					tell the current window
						tell the current session
							set name to theTitle
							write text withCmd
						end tell
					end tell
				end tell
			end try
		end if
	end tell
end CommandRun
