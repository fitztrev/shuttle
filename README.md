# Shuttle

A simple SSH shortcut menu for OS X

[http://fitztrev.github.io/shuttle/](http://fitztrev.github.io/shuttle/)

![How Shuttle works](https://raw.github.com/fitztrev/shuttle/gh-pages/img/how-shuttle-works.gif)

***Sidenote***: *Many people ask, so here's how I have [my terminal setup](https://github.com/fitztrev/shuttle/wiki/My-Terminal-Prompt).*

## Installation

1. Download [Shuttle](http://fitztrev.github.io/shuttle/)
2. Copy to Applications


## Customization

The default, out-of-the-box configuration should be good enough to get started. However, if you're looking to customize the appearance further, here are a few advanced tips.

### JSON Options
#### Global settings
##### ```"editor": "default",```
_This changes the app that opens settings.json for editing (Global Setting)_

Valid settings are ```default``` ```nano``` ```vi``` ```vim``` or any terminal based editor. 
```default``` opens settings.json in whatever app is registered as the default for extension ```.json```
```
"editor": "vim",
``` 
would open ```~/.shuttle.json``` in vim

----

##### ```"launch_at_login": false,```
_This allows you to flag the shuttle.app to start automatically (Global Setting)_

Valid settings are ```true``` or ```false```

----

##### ```"terminal": "iTerm",```
_This allows you to set the default terminal (Global Setting)_

Valid settings are ```Terminal.app``` or ```iTerm```

----

##### ```"iTerm_version": "nightly",```
_This changes the applescripts for iTerm (Global Setting)_

Valid settings are ```stable``` or ```nightly```

**If the terminal is set to ```iTerm``` this setting is mandatory**

----

##### ```"open_in": "tab",```
_This changes the default action for how commands are opened (Global Setting)_

Valid settings are ```tab``` or ```new```. ```tab``` opens the command in the active terminal in a new tab. ```new``` opens the command in window. This setting can be overwritten b$

----
##### ``````"show_ssh_config_hosts": false,````
_This changes parsing ssh config. By default, Shuttle will parse your `~/.ssh/config` file for hosts. (Global Setting)_

Valid settings are ```false``` or ```true````

----

##### ```"ssh_config_ignore_hosts": ["github.com", "git.example.com"],```
_This will ignore hosts in the ssh config. (Global Settings)_

Valid settings are the hosts in your config that you want to ignore. 

----

##### ```"ssh_config_ignore_keywords": ["git"],```
_This will ignore keywoards in your ssh config. (Global Settings)_

Valid settings are the keywords in your ssh config that you want to ignore.

----
***Additional ssh config customization** 
##### Nested menus for `~/.ssh/config` hosts

###### Create a menu item at "work" > "servers" > "web01"

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

#### Command level settings
#### ```"inTerminal": "new",```
_This sets how command will open in the terminal window_

Valid settings are ```new```, ```tab```, or ```current```

```new``` opens the command in a new terminal window. 

```tab``` opens the command in the active terminal window in a new tab. 

```current``` opens the command in the active terminal's window. 

When using using ```current``` I recommend that you wrap the command in some user input like this:

```echo "are you sure y/n"; read sure; if [ "$sure" == "y" ]; then echo "running command" && ps aux | grep [s]sh; else echo "exiting..."; fi```

Do this as a precaution as it could be possible to run a command on the wrong host. 
----

##### ```"theme": "Default",```
_This sets the theme for the terminal window_

Valid settings are the profile names for iTerm or Terminal.app

---

##### ```"title": "grep foo"```
_This sets the text that will appear in the terminal's title bar_

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

This project was created by Trevor Fitzgerald. I owe many thanks to the following people who have helped make Shuttle even better.

(In alphabetical order)

* Alex Carter
* Dave Eddy
* Dmitry Filimonov
* Frank Enderle
* Jack Weeden
* Justin Swanson
* Marco Aurélio
* Martin Grund
* Michael Davis
* Rui Rodrigues
* Ryan Cohen
* Thomas Rosenstein
* Tibor Bödecs

## Credits

Shuttle was inspired by [SSHMenu](http://sshmenu.sourceforge.net/), the GNOME applet for Linux.

I also looked to projects such as [MLBMenu](https://github.com/markolson/MLB-Menu) and [QuickSmileText](https://github.com/scturtle/QuickSmileText) for direction on building a Cocoa app for the status bar.
