on ApplicationIsRunning(appName)
	tell application "System Events" to set appNameIsRunning to exists (processes where name is appName)
	return appNameIsRunning
end ApplicationIsRunning

set isRunning to ApplicationIsRunning("iTerm")

tell application "iTerm"
	tell the current terminal
		if (isRunning = false) then
			tell the current session
				write text "clear"
				write text "%1$@"
				activate
			end tell
		else
			set newSession to (launch session "Default Session")
			tell newSession
				write text "clear"
				write text "%1$@"
			end tell
		end if
	end tell
end tell
