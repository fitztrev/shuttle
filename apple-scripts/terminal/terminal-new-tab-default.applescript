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
	tell application "Terminal"
		if it is running then
			reopen
			activate
			tell application "System Events"
				tell process "Terminal"
					delay 0.2
					keystroke "t" using {command down}
				end tell
			end tell
		end if
		my CommandRun(withCmd, withTheme, theTitle)
		activate
	end tell
end preLoad

on CommandRun(withCmd, withTheme, theTitle)
	tell application "Terminal"
		do script withCmd in front window
		set current settings of selected tab of front window to settings set withTheme
		set title displays custom title of front window to true
		set custom title of selected tab of front window to theTitle
	end tell
end CommandRun
