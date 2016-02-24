#!/bin/bash
echo "compiling applescripts for iTerm Nightly..."
osacompile -o ~/Git/shuttle/Shuttle/apple-scpt/iTerm2-nightly-new-window.scpt -x ~/Git/shuttle/apple-scripts/iTermNightly/iTerm2-nightly-new-window.applescript 
osacompile -o ~/Git/shuttle/Shuttle/apple-scpt/iTerm2-nightly-current-window.scpt -x ~/Git/shuttle/apple-scripts/iTermNightly/iTerm2-nightly-current-window.applescript 
osacompile -o ~/Git/shuttle/Shuttle/apple-scpt/iTerm2-nightly-new-tab-default.scpt -x ~/Git/shuttle/apple-scripts/iTermNightly/iTerm2-nightly-new-tab-default.applescript


