--for testing uncomment the "on run" block
--on run
--	set argsCmd to "top"
--	set argsTitle to "Testing Top In Screen"
--	scriptRun(argsCmd, argsTitle)
--end run

on scriptRun(argsCmd, argsTitle)
	set screenSwitches to "screen -d -m -S "
	set screenSessionName to "'" & argsTitle & "' "
	set withCmd to screenSwitches & screenSessionName & argsCmd
	CommandRun(withCmd)
end scriptRun

on CommandRun(withCmd)
	do shell script withCmd
end CommandRun