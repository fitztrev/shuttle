on ApplicationIsRunning(appName)
	tell application "System Events" to set appNameIsRunning to exists (processes where name is appName)
	return appNameIsRunning
end ApplicationIsRunning

set isRunning to ApplicationIsRunning("iTerm")

tell application "iTerm"
	tell the current terminal
		if isRunning then
			set newSession to (launch session "%1$@")
			tell the last session
				write text "clear"
				write text "%2$@"
			end tell
		else
			tell the current session
				write text "clear"
				write text "%2$@"
				activate
			end tell
		end if
	end tell
end tell
