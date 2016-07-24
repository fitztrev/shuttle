#!/bin/bash
echo "compiling applescripts for iTerm Legacy..."
osacompile -o ~/Git/shuttle/Shuttle/apple-scpt/iTerm-legacy-new-window.scpt -x ~/Git/shuttle/apple-scripts/iTermlegacy/iTerm-legacy-new-window.applescript
osacompile -o ~/Git/shuttle/Shuttle/apple-scpt/iTerm-legacy-current-window.scpt -x ~/Git/shuttle/apple-scripts/iTermlegacy/iTerm-legacy-current-window.applescript
osacompile -o ~/Git/shuttle/Shuttle/apple-scpt/iTerm-legacy-new-tab-default.scpt -x ~/Git/shuttle/apple-scripts/iTermlegacy/iTerm-legacy-new-tab-default.applescript


