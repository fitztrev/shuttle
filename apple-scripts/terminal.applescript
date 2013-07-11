on ApplicationIsRunning(appName)
	tell application "System Events" to set appNameIsRunning to exists (processes where name is appName)
	return appNameIsRunning
end ApplicationIsRunning

set isRunning to ApplicationIsRunning("Terminal")

tell application "Terminal"
	if isRunning then
		activate
		tell application "System Events" to tell process "Terminal.app" to keystroke "t" using command down
		do script "clear" in front window
		do script "%1$@" in front window
	else
		do script "clear" in window 1
		do script "%1$@" in window 1
		activate
	end if
end tell
