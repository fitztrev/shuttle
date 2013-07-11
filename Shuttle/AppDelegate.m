//
//  AppDelegate.m
//  Shuttle
//

#import "AppDelegate.h"

@implementation AppDelegate

- (void) awakeFromNib {
    // The path for the configuration file (by default: ~/.shuttle.json)
    shuttleConfigFile = [NSHomeDirectory() stringByAppendingPathComponent:@".shuttle.json"];
    
    // Load the menu content
    // [self loadMenu];

    // Create the status bar item
    statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    [statusItem setMenu:menu];
    [statusItem setHighlightMode:YES];
    [statusItem setTitle:@"SSH"];
    
    // Needed to trigger the menuWillOpen event
    [menu setDelegate:self];
}

- (void)menuWillOpen:(NSMenu *)menu {
    // Check when the config was last modified
    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:shuttleConfigFile error:nil];
    NSDate *date = [attributes fileModificationDate];
    
    // If it has been updated, refresh the menu
    NSComparisonResult result;
    result = [date compare:configModified];
    
    if ( configModified == NULL || result == NSOrderedDescending ) {
        configModified = date;
        [self loadMenu];
    }
}

- (void) loadMenu {
    // Clear out the hosts so we can start over
    NSUInteger n = [[menu itemArray] count];
    for (int i=0;i<n-4;i++) {
        [menu removeItemAtIndex:0];
    }

    // if the config file does not exist, create a default one
    if ( ![[NSFileManager defaultManager] fileExistsAtPath:shuttleConfigFile] ) {
        NSString *cgFileInResource = [[NSBundle mainBundle] pathForResource:@"shuttle.default" ofType:@"json"];
        [[NSFileManager defaultManager] copyItemAtPath:cgFileInResource toPath:shuttleConfigFile error:nil];
    }
    
    // Parse the config file
    NSData *data = [NSData dataWithContentsOfFile:shuttleConfigFile];
    id json = [NSJSONSerialization JSONObjectWithData:data
                                              options:kNilOptions
                                                error:nil];
    // Check valid JSON syntax
    if ( !json ) {
        NSMenuItem *menuItem = [menu insertItemWithTitle:@"Error parsing config"
                           action:false
                   keyEquivalent:@""
                         atIndex:0
        ];
        [menuItem setEnabled:false];
        return;
    }
    
    terminalPref = [json[@"terminal"] lowercaseString];
    shuttleHosts = json[@"hosts"];

    // Rebuild the menu
    int i = 0;
    
    for (id key in shuttleHosts) {
        // If it has a `cmd`, it's a top-level item
        // otherwise, create a submenu for it
        if ( [key valueForKey:@"cmd"] ) {
            NSMenuItem *menuItem = [menu insertItemWithTitle:[key valueForKey:@"name"]
                                                      action:@selector(openHost:)
                                               keyEquivalent:@""
                                                     atIndex:i
            ];
            // Save that item's SSH command as its represented object
            // so we can call it when it's clicked
            [menuItem setRepresentedObject:[key valueForKey:@"cmd"]];
        } else {
            for ( id group in key ) {
                //Create a group as the main item
                NSMenuItem *mainItem = [[NSMenuItem alloc] init];
                [mainItem setTitle:group];
                
                // Build a submenu under that group
                NSMenu *submenu = [[NSMenu alloc] init];
                for ( id subKey in [key valueForKey:group]) {
                    NSMenuItem *menuItem = [submenu addItemWithTitle:[subKey valueForKey:@"name"]
                                                              action:@selector(openHost:)
                                                       keyEquivalent:@""
                     ];
                    // Save that item's SSH command as its represented object
                    // so we can call it when it's clicked
                    [menuItem setRepresentedObject:[subKey valueForKey:@"cmd"]];
                }
                // Attach the submenu
                [mainItem setSubmenu:submenu];
                
                [menu insertItem:mainItem atIndex:i];
            }
            
        }

        i++;
    }
}

- (void) openHost:(NSMenuItem *) sender {
    //NSLog(@"sender: %@", sender);
    //NSLog(@"Command: %@",[sender representedObject]);
    
    if ( [terminalPref isEqualToString: @"iterm"] ) {
        NSAppleScript* iTerm2 = [[NSAppleScript alloc] initWithSource:
                                   [NSString stringWithFormat:
                                    @"on ApplicationIsRunning(appName) \n"
                                    @"  tell application \"System Events\" to set appNameIsRunning to exists (processes where name is appName) \n"
                                    @"  return appNameIsRunning \n"
                                    @"end ApplicationIsRunning \n"
                                    @" \n"
                                    @"set isRunning to ApplicationIsRunning(\"iTerm\") \n"
                                    @" \n"
                                    @"tell application \"iTerm\" \n"
                                    @"  tell the current terminal \n"
                                    @"      if (isRunning = false) then \n"
                                    @"          tell the current session \n"
                                    @"              write text \"clear\" \n"
                                    @"              write text \"%1$@\" \n"
                                    @"              activate \n"
                                    @"          end tell \n"
                                    @"      else \n"
                                    @"          set newSession to (launch session \"Default Session\") \n"
                                    @"          tell newSession \n"
                                    @"              write text \"clear\" \n"
                                    @"              write text \"%1$@\" \n"
                                    @"          end tell \n"
                                    @"      end if \n"
                                    @"  end tell \n"
                                    @"end tell \n"
                                    , [sender representedObject]]];
        [iTerm2 executeAndReturnError:nil];
    } else {
        NSAppleScript* terminalapp = [[NSAppleScript alloc] initWithSource:
                                      [NSString stringWithFormat:
                                       @"on ApplicationIsRunning(appName) \n"
                                       @"  tell application \"System Events\" to set appNameIsRunning to exists (processes where name is appName) \n"
                                       @"  return appNameIsRunning \n"
                                       @"end ApplicationIsRunning \n"
                                       @" \n"
                                       @"set isRunning to ApplicationIsRunning(\"Terminal\") \n"
                                       @" \n"
                                       @"tell application \"Terminal\" \n"
                                       @"  if isRunning then \n"
                                       @"      activate \n"
                                       @"      tell application \"System Events\" to tell process \"Terminal.app\" to keystroke \"t\" using command down \n"
                                       @"      do script \"clear\" in front window \n"
                                       @"      do script \"%1$@\" in front window \n"
                                       @"  else \n"
                                       @"      do script \"clear\" in window 1 \n"
                                       @"      do script \"%1$@\" in window 1 \n"
                                       @"      activate \n"
                                       @"  end if \n"
                                       @"end tell \n"
                                       , [sender representedObject]]];
        [terminalapp executeAndReturnError:nil];
    }
}

- (IBAction)configure:(id)sender {
    [[NSWorkspace sharedWorkspace] openFile:shuttleConfigFile];
}

- (IBAction)showAbout:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL: [NSURL URLWithString:@"http://fitztrev.github.io/shuttle"]];
}

- (IBAction)quit:(id)sender {
    [NSApp terminate:nil];
}

@end