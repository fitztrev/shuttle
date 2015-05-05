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

### Disabling `~/.ssh/config` hosts

By default, Shuttle will parse your `~/.ssh/config` file for hosts.

##### To disable all ~/.ssh/config entries:

```
"show_ssh_config_hosts": false,
```

#### Disable specific hosts:

```
"ssh_config_ignore_hosts": ["github.com", "git.example.com"],
```

#### Disable hosts that contain a keyword:

```
"ssh_config_ignore_keywords": ["git"],
```

### Nested menus for `~/.ssh/config` hosts

#### Create a menu item at "work" > "servers" > "web01"

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
