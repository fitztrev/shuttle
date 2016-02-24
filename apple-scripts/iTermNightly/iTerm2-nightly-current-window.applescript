--for testing uncomment the "on run" block
--on run
--	set argsCmd to "ps aux | grep [s]sh"
--	scriptRun(argsCmd)
--end run

on scriptRun(argsCmd)
	set withCmd to (argsCmd)
	CommandRun(withCmd)
end scriptRun

on CommandRun(withCmd)
	tell application "iTerm"
		reopen
		activate
		tell the current window
			tell the current session
				--set name to theTitle
				write text withCmd
			end tell
		end tell
	end tell
end CommandRun
