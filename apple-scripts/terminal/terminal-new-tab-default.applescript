--for testing uncomment the "on run" block
--on run
--	set argsCmd to "ps aux | grep [s]creen"
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
	tell application "Terminal"
		if it is not running then
			--if this is the first time Terminal is running you have specify window 1
			--if you dont do this you will get two windows and the title wont be set
			activate
			set newTerm to do script withCmd in window 1
			set newTerm's current settings to settings set withTheme
			set custom title of front window to theTitle
		else
			--Terminal is running get the window count
			set windowCount to (count every window)
			if windowCount = 0 then
				--Terminal is running but no windows are open
				--run our script in a new window
				reopen
				activate
				do script withCmd in selected tab of window 1
			else
				--Terminal is running and we have a window run in a new tab
				reopen
				activate
				tell application "System Events"
					tell process "Terminal"
						delay 0.3
						keystroke "t" using {command down}
					end tell
				end tell
				activate
				do script withCmd in selected tab of front window
			end if
			set current settings of selected tab of front window to settings set withTheme
			set title displays custom title of front window to true
			set custom title of selected tab of front window to theTitle
		end if
	end tell
end CommandRun