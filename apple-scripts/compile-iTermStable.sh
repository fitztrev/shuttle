#!/bin/bash
echo "compiling applescripts for iTerm Stable..."
osacompile -o ~/Git/shuttle/Shuttle/apple-scpt/iTerm-stable-new-window.scpt -x ~/Git/shuttle/apple-scripts/iTermStable/iTerm-stable-new-window.applescript
osacompile -o ~/Git/shuttle/Shuttle/apple-scpt/iTerm-stable-current-window.scpt -x ~/Git/shuttle/apple-scripts/iTermStable/iTerm-stable-current-window.applescript
osacompile -o ~/Git/shuttle/Shuttle/apple-scpt/iTerm-stable-new-tab-default.scpt -x ~/Git/shuttle/apple-scripts/iTermStable/iTerm-stable-new-tab-default.applescript


