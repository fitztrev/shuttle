#!/bin/bash
echo "compiling applescripts for OS X terminal..."
osacompile -o ~/Git/shuttle/Shuttle/apple-scpt/terminal-new-window.scpt -x ~/Git/shuttle/apple-scripts/terminal/terminal-new-window.applescript
osacompile -o ~/Git/shuttle/Shuttle/apple-scpt/terminal-current-window.scpt -x ~/Git/shuttle/apple-scripts/terminal/terminal-current-window.applescript
osacompile -o ~/Git/shuttle/Shuttle/apple-scpt/terminal-new-tab-default.scpt -x ~/Git/shuttle/apple-scripts/terminal/terminal-new-tab-default.applescript

