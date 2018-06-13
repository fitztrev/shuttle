# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [Unreleased]
- The ability to add a second json.config file 
- The ability to add ```[---]``` in the name of a command to add a line seperator 
- Adding a new apple script which will allow running commands in the background with screen
- @philippetev Changes to iTerm applescripts to fix issues with settings in iTerm's Preferences/General
- French translations by @anivon
- @anivon localize Error parsing config message is JSON is invalid 
- @blackadmin version typos in about window. 

## [1.2.9] - 2016-10-18
### Added
- @pluwen added Chinese language translations #185

### Changed 
- All the documentation has been moved out of the readme.md and placed in the wiki.

### Fixed 
- Corrected by @pluwen icon changes changes #184
- Corrected by @bihicheng config file edits not working #199

## [1.2.8] - 2016-10-18
### Added
- Menus have been translated to Spanish
- Added a bash script to the default JSON file that allows writing a command to terminal without execution #200

### Fixed
- Fixed an issue that prevented character escapes #194
- Fixed an issue that prevented tabs from opening in terminal on macOS #198
- Fixed an issue where english was not the default language.

## [1.2.7] - 2016-07-24
### Added
- Now that iTerm stable is at version 3, the version 2 applescripts no longer apply to the stable branch. shuttle still supports iTerm 2.14. If you still want to use this legacy version you will have to change your iTerm_version setting to legacy. Valid settings are:

```"iTerm_version": "legacy",``` targeting iTerm 2.14

```"iTerm_version": "stable",``` targeting new versions of iTerm

```"iTerm_version": "nightly",``` targeting only the nightly build of iTerm

Please make sure to change your shuttle.JSON file accordingly. For more on this see #181

### Fixed 
- corrected by @mortonfox -- when iTerm startup preferences are set to "Don't Open Any Windows" nothing happens #175.
- corrected by @pluwen shuttle icon contains unwanted artifacts #141
- Fixed an issue where commas were not getting parsed #173

## [1.2.6] - 2016-02-24
### Added
- added by @keesfransen -- ssh config file parsing only keeps the first alias. This change keeps the menu clean as it only keeps the first argument to Host and will allow for hosts defined like:
```
Host prod/host host.prod
    HostName myserver.local
```
- Added the script files that compile the applescript files for inclusion in shuttle.app

### Fixed 
- corrected by @mortonfox -- when iTerm stable is running but no windows are open nothing happens.
- iTerm Stable and Terminal apple scripts were not correctly handling events where the app was open but no windows were open.
- Fixed an issue were iTerm Nightly applescripts would not open if a theme was not set.
- Fixed an issue with the URL detection. shuttle checks the command to see if its a URL then opens that URL in the default app.
Example:
```
"cmd": "cifs://myServer/c$"
```
Should open the above path in finder.

## [1.2.5] - 2015-11-05
### Added
- Added a new feature ```"open_in": "VALUE"``` is a global setting which sets how commands are open. Do they open in new tabs or new windows? This setting accepts the value of ```"tab"``` or ```"new"```
- Added a new feature ```"default_theme": "VALUE"``` is a global setting which sets the default theme for all terminal windows.
- Cleaned up the default JSON file and changed the names to reflect the action.
- Added alert boxes on errors for ```"iTerm_version": "VALUE"``` and ```"inTerminal": "VALUE"```

### Changed
- Changed the readme.md to reflect all options. Please see the new wiki it explains all of the settings.

## [1.2.4] - 2015-10-17
### Added
- If ```"title":"Terminal Title"``` is empty then the title becomes the same as the commands menu name.

### Fixed
- Fixed the icon it was not turning white.
- Fixed iTerm2 variable
- About window on top changes

## [1.2.3] - 2015-10-15
### Added
- Applescript Changes allow for iTerm Stable and Nightly support. Note that this only works with Nightly versions starting after 2.9.20150414
- Open a Command in a new window. In your JSON for the command add this directive:
```"inTerminal": "new",```
- Open a Command in the existing window. In your JSON for the command add this directive:
```"inTerminal": "current",```
- Add a Title to your window: In your JSON for the command add this directive:
```"title": "Dev Server - SSH"```
- Add a Theme to your window: In your JSON for the command add this directive:
```"theme": "Homebrew",```
- Change the Path to the JSON file. In your home directory create a file called ```~/.shuttle.path``` In this file is the path to the JSON settings. Mine currently reads ```/Users/thshdw/Desktop/shuttle.json```
- Change the default editor. In the JSON settings change ```“editor”: “default”``` will open the settings file from the Settings > edit menu in that editor. Set the editor to 'nano', 'vi', or any terminal based editor.
- Shuttle About Opens a GUI window that shows the version with a button to the home page.

## [1.2.2] - 2014-11-01
### Added
- Adds support for dark mode in Yosemite

## [1.2.0] - 2013-12-02
### Added
- Include option to show/hide servers from SSH config files
- Include option to ignore hosts based on name or keyword
- Ability to Import/Export settings file
- Support for multiple nested menus

### Fixed
- Remove status icon from status bar on quit

## [1.1.2] - 2013-07-23
### Fixed
- Fix issue with parsing the default JSON config file

## [1.1.1] - 2013-07-19
### Added
- cmd in .shuttle.json now supports URLs (http://, smb://, vnc://, etc.)
Opens in your OS default applications
- Added test configuration files

### Changed
- Create default config file on application load, instead of menu open

### Fixed
- Fix issue with iTerm running command in the previous tab's split, instead of the new tab.
- Escape double quote characters in cmd

## [1.1.0] - 2013-07-16
### Added
- Option to automatically launch at login
- In addition to the JSON config, also generate menu items from hosts in .ssh/config

## [1.0.1] - 2013-07-11
### Added
- OS X 10.7 support
- Change menu bar item to use an icon instead of "SSH".

## [1.0.0] - 2013-07-10
### Added
- Initial Release
