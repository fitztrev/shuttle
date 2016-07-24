#!/bin/bash
echo "compiling applescripts for iTerm Stable..."
osacompile -o ~/Git/shuttle/Shuttle/apple-scpt/iTerm2-stable-new-window.scpt -x ~/Git/shuttle/apple-scripts/iTermStable/iTerm2-stable-new-window.applescript
osacompile -o ~/Git/shuttle/Shuttle/apple-scpt/iTerm2-stable-current-window.scpt -x ~/Git/shuttle/apple-scripts/iTermStable/iTerm2-stable-current-window.applescript
osacompile -o ~/Git/shuttle/Shuttle/apple-scpt/iTerm2-stable-new-tab-default.scpt -x ~/Git/shuttle/apple-scripts/iTermStable/iTerm2-stable-new-tab-default.applescript


