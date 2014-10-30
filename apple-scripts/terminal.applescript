tell application "Terminal"
	if running then
		activate
		tell application "System Events" to tell process "Terminal.app" to keystroke "t" using command down
	end if
	do script "clear" in front window
	do script "%1$@" in front window
	activate
end tell