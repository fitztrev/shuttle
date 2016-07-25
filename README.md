# Shuttle

[![Join the chat at https://gitter.im/fitztrev/shuttle](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/fitztrev/shuttle?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

A simple SSH shortcut menu for OS X

[http://fitztrev.github.io/shuttle/](http://fitztrev.github.io/shuttle/)

![How Shuttle works](https://raw.github.com/fitztrev/shuttle/gh-pages/img/how-shuttle-works.gif)

**Sidenote**: *Many people ask, so here's how I have [my terminal setup](https://github.com/fitztrev/shuttle/wiki/My-Terminal-Prompt).*

## Installation

1. Download [Shuttle](http://fitztrev.github.io/shuttle/)
2. Copy to Applications

## JSON Path Change

In your home directory create a file called ```~/.shuttle.path```
In this file should be a single line with the path to the JSON settings file. 

```
/Users/thshdw/Dropbox/shuttle/shuttle.json
``` 
shuttle will read ```~/.shuttle.path``` first and use its contents as the path to your JSON file.

## JSON Options
### Global settings
#### ```"editor": "VALUE",```
_This changes the app that opens settings.json for editing (Global Setting)_

Possible values are ```default```, ```nano```, ```vi```, ```vim``` or any terminal based editor. 
```default``` opens settings.json in whatever app is registered as the default for extension ```.json```
```
"editor": "vim",
``` 
would open ```~/.shuttle.json``` in vim

----

#### ```"launch_at_login": VALUE,```
_This allows you to flag the shuttle.app to start automatically (Global Setting)_

Possible values are ```true``` or ```false```

----

#### ```"terminal": "VALUE",```
_This allows you to set the default terminal (Global Setting)_

Possible values are ```Terminal.app``` or ```iTerm```

----

#### ```"iTerm_version": "VALUE",```
_This changes the applescripts for iTerm (Global Setting)_

Possible values are ```legacy``` or ```stable``` or ```nightly```

**If ```terminal``` is set to ```iTerm``` this setting is mandatory**

```"iTerm_version": "legacy",``` targeting iTerm 2.14

```"iTerm_version": "stable",``` targeting new versions of iTerm

```"iTerm_version": "nightly",```targeting only the nightly build of iTerm

_This setting is ignored if your terminal is set to ```Terminal.app```_

----

#### ```"default_theme": "Homebrew",```
_This sets the Terminal theme for all windows. (Global Setting)_ 

Possible values are the Profile names in your terminal preferences. iTerm ships with one Profile named "Default". OS X Terminal ships with several. To see the names see the preferences area of the terminal you are using.

In iTerm the profile names are case sensitive.

**Please ensure the theme names you set are valid. If shuttle passes theme "Dagobah" and it does not exist in iTerm, shuttle's applescripts fall back to the default profile. In iTerm this profile is called ```Default```.
If you have removed ```Default``` or renamed it shuttle may not open your command.** 

This setting can be overwritten by the command level ```"theme"``` settings

----

#### ```"open_in": "VALUE",```
_This changes the default action for how commands are opened (Global Setting)_

Possible values are ```tab``` or ```new```. 

```tab``` opens the command in the active terminal in a new tab. 

```new``` opens the command in a new window. 

This setting can be overwritten by the command level ```"inTerminal"``` settings

----

#### ```"show_ssh_config_hosts": VALUE,```
_This changes parsing ssh config. By default, Shuttle will parse your ```~/.ssh/config``` file for hosts. (Global Setting)_

Possible values are ```false``` or ```true```

----

#### ```"ssh_config_ignore_hosts": ["VALUE", "VALUE"],```
_This will ignore hosts in the ssh config. (Global Setting)_

Possible values are the hosts in your config that you want to ignore. If you had github.com and git.example.com in your ssh config, to ignore them you set:

```"ssh_config_ignore_hosts": ["github.com", "git.example.com"],```

----

#### ```"ssh_config_ignore_keywords": ["VALUE"],```
_This will ignore keywords in your ssh config. (Global Setting)_

Possible values are the keywords in your ssh config that you want to ignore.

----

**Additional ssh config customization** 
#### Nested menus for `~/.ssh/config` hosts

##### Create a menu item at "work" > "servers" > "web01"

```
Host work/servers/web01
        HostName user@web01.example.com
```
\- *or* -

```
Host gandalf
        # shuttle.name = work/servers/web01 (webserver)
        HostName user@web01.example.com
```

### Command level settings
_Command level settings are unique to your command and will overwrite the Global setting equivalent_

#### ```"cmd": "VALUE"```
_This is the command / script that will be launched in the terminal. (Command setting)_

Where Value is a command or script. 
```
"cmd": "ps aux | grep [s]sh"
```
Would check for ssh processes.

----

#### ```"name": "VALUE"```
_This sets the text that will appear in shuttles drop down menu. (Command setting)_

Were Value is the text you want to see in the drop down menu for this command. 
```
"name": "SSH to my wordpress blog"
```

This value can also set the title of the terminal window if ```"title" :"VALUE"``` is not set.

----

#### ```"inTerminal": "VALUE",```
_This sets how command will open in the terminal window. (Command setting)_

Possible values are ```new```, ```tab```, or ```current```

```new``` opens the command in a new terminal window. 

```tab``` opens the command in the active terminal window in a new tab. 

```current``` opens the command in the active terminal's window. 

When using using ```current``` I recommend that you wrap the command in some user input like this:

```
echo "are you sure y/n"; read sure; if [ "$sure" == "y" ]; then echo "running command" && ps aux | grep [s]sh; else echo "exiting..."; fi
```

Do this as a precaution as it could be possible to run a command on the wrong host. 

----

#### ```"theme": "VALUE",```
_This sets the theme for the terminal window. (Command setting)_

Possible values are the profile names for iTerm or OS X Terminal.

If ```"theme"``` is not set and ```"default_theme"``` is not set then shuttle passes Profile ```Default``` for iTerm and Profile ```basic``` for OS X terminal.

----

#### ```"title": "VALUE"```
_This sets the text that will appear in the terminal's title bar. (Command setting)_

Where VALUE is the text you want to set in the terminals title bar. 

If ```title``` is missing shuttle uses the menu's name and sets this as ```title```

## Roadmap

* Cloud hosting integration
  * AWS, Rackspace, Digital Ocean, etc
  * Using their APIs, automatically add all of your machines to the menu
* Preferences panel for easier configuration
* Update notifications
* Keyboard hotkeys
  * Open menu
  * Select host option within menu

## Contributors

This project was created by [Trevor Fitzgerald](https://github.com/fitztrev). I owe many thanks to the following people who have helped make Shuttle even better.

(In alphabetical order)

* [Alex Carter](https://github.com/blazeworx)
* [Dave Eddy](https://github.com/bahamas10)
* [Dmitry Filimonov](https://github.com/petethepig)
* [Frank Enderle](https://github.com/fenderle)
* [Jack Weeden](https://github.com/jackbot)
* [Justin Swanson](https://github.com/geeksunny)
* [Kees Fransen](https://github.com/keesfransen)
* Marco Aurélio
* [Martin Grund](https://github.com/grundprinzip)
* [Matt Turner](https://github.com/thshdw)
* [Michael Davis](https://github.com/mpdavis)
* [Morton Fox](https://github.com/mortonfox)
* [Pluwen](https://github.com/pluwen)
* [Rui Rodrigues](https://github.com/rmrodrigues)
* [Ryan Cohen](https://github.com/imryan)
* [Stefan Jansen](https://github.com/steffex)
* Thomas Rosenstein
* [Thoro](https://github.com/Thoro)
* [Tibor Bödecs](https://github.com/tib)
* [welsonla](https://github.com/welsonla)

## Credits

Shuttle was inspired by [SSHMenu](http://sshmenu.sourceforge.net/), the GNOME applet for Linux.

I also looked to projects such as [MLBMenu](https://github.com/markolson/MLB-Menu) and [QuickSmileText](https://github.com/scturtle/QuickSmileText) for direction on building a Cocoa app for the status bar.
