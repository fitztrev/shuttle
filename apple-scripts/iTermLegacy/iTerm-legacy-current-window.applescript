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
		if it is running then
			tell the current terminal
				tell the current session
					reopen
					activate
					write text withCmd
				end tell
			end tell
		else
			tell the current terminal
				tell the current session
					write text withCmd
					activate
				end tell
			end tell
		end if
	end tell
end CommandRun