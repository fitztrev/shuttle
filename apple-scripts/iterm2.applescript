tell application "iTerm"
	set isRunning to running
	tell the current terminal
		if isRunning then
			launch session "Default Session"
		end if
		tell the last session
			write text "clear"
			write text "%1$@"
			activate
		end tell
	end tell
end tell
