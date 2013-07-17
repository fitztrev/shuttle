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
    
    // if the config file does not exist, create a default one
    if ( ![[NSFileManager defaultManager] fileExistsAtPath:shuttleConfigFile] ) {
        NSString *cgFileInResource = [[NSBundle mainBundle] pathForResource:@"shuttle.default" ofType:@"json"];
        [[NSFileManager defaultManager] copyItemAtPath:cgFileInResource toPath:shuttleConfigFile error:nil];
    }
    
    // Create the status bar item
    statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:25.0];
    [statusItem setMenu:menu];
    [statusItem setHighlightMode:YES];
    [statusItem setImage:[NSImage imageNamed:@"StatusIcon"]];
    [statusItem setAlternateImage:[NSImage imageNamed:@"StatusIconAlt"]];

    launchAtLoginController = [[LaunchAtLoginController alloc] init];
    
    // Needed to trigger the menuWillOpen event
    [menu setDelegate:self];
}

- (BOOL) needUpdateFor: (NSString*) file with: (NSDate*) old {
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:[file stringByExpandingTildeInPath]])
        return false;
    
    if (old == NULL)
        return true;
    
    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[file stringByExpandingTildeInPath]
                                                                                error:nil];
    NSDate *date = [attributes fileModificationDate];
    return [date compare: old] == NSOrderedDescending;
}

- (NSDate*) getMTimeFor: (NSString*) file {
    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:[file stringByExpandingTildeInPath]
                                                                                error:nil];
    return [attributes fileModificationDate];
}

- (void)menuWillOpen:(NSMenu *)menu {
    // Check when the config was last modified
    if ( [self needUpdateFor:shuttleConfigFile with:configModified] ||
        [self needUpdateFor: @"/etc/ssh/ssh_config" with:sshConfigSystem] ||
        [self needUpdateFor: @"~/.ssh/config" with:sshConfigUser]) {
        
        configModified = [self getMTimeFor:shuttleConfigFile];
        sshConfigSystem = [self getMTimeFor: @"/etc/ssh_config"];
        sshConfigUser = [self getMTimeFor: @"~/.ssh/config"];
        
        [self loadMenu];
    }
}

// Parsing of the SSH Config File
// Courtesy of https://gist.github.com/geeksunny/3376694
- (NSDictionary*) parseSSHConfigFile {
    
    NSString *configFile = nil;
    NSFileManager *fileMgr = [[NSFileManager alloc] init];
    
    // First check the system level configuration
    if ([fileMgr fileExistsAtPath: @"/etc/ssh_config"]) {
        configFile = @"/etc/ssh_config";
    }
    
    // Fallback to check if actually someone used /etc/ssh/ssh_config
    if ([fileMgr fileExistsAtPath: [@"~/.ssh/config" stringByExpandingTildeInPath]]) {
        configFile = [@"~/.ssh/config" stringByExpandingTildeInPath];
    }
    
    if (configFile == nil) {
        // We did not find any config file so we gracefully die
        return nil;
    }
    
    
    // Get file contents into fh.
    NSString *fh = [NSString stringWithContentsOfFile:configFile encoding:NSUTF8StringEncoding error:nil];
    // Initialize our server list as an empty dictionary variable.
    NSMutableDictionary *servers = [NSMutableDictionary dictionaryWithObjects:nil forKeys:nil];
    
    // Loop through each line and parse the file.
    for (NSString *line in [fh componentsSeparatedByString:@"\n"]) {
        
        // Strip line
        NSString *cleanedLine = [line stringByTrimmingCharactersInSet:[ NSCharacterSet whitespaceCharacterSet]];
        
        // Empty lines and lines starting with `#' are comments.
        if ([cleanedLine length] == 0 || [line characterAtIndex:0] == '#')
            continue;
        
        // Since there might be the possibility that someone thought it might be useful to use = for separating properties
        // we have to check that. And of course for now, we are only looking into the host
        // section and gently ignore the rest
        NSError* error = NULL;
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^Host\\b" options:0 error: &error];
        NSUInteger num = [regex numberOfMatchesInString:cleanedLine options:0 range:NSMakeRange(0, [cleanedLine length])];
        if (num == 1) {
            
            // Somebody really used =
            NSArray* components = nil;
            if ([cleanedLine rangeOfString:@"="].length != 0) {
                components = [cleanedLine componentsSeparatedByString:@"="];
                
            } else {
                components = [cleanedLine componentsSeparatedByCharactersInSet:
                                        [NSCharacterSet whitespaceCharacterSet]];
            }
            NSString* host = [[components objectAtIndex:1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            
            [servers setObject:[NSDictionary dictionaryWithObject: host forKey:@"Host"] forKey:host] ;
        }
    }
    
    return servers;    
}

// Replaces Underscores with Spaces for better readable names
- (NSString*) humanize: (NSString*) val{
    return [val stringByReplacingOccurrencesOfString:@"_" withString:@" "];
}

- (void) loadMenu {
    
    // System configuration
    NSDictionary* servers = [self parseSSHConfigFile];
    
    // Clear out the hosts so we can start over
    NSUInteger n = [[menu itemArray] count];
    for (int i=0;i<n-4;i++) {
        [menu removeItemAtIndex:0];
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
    
    launchAtLoginController.launchAtLogin = [json[@"launch_at_login"] boolValue];

    // Rebuild the menu
    int i = 0;
    
    NSMutableDictionary* fullMenu = [NSMutableDictionary dictionary];
    
    // First add all the system serves we know
    for (id key in servers) {
        NSDictionary* data = [servers objectForKey:key];

        // Ignore entrys that contain wildcard characters
        NSString* host= [data valueForKey:@"Host"];
        if ([host rangeOfString:@"*"].length != 0)
            continue;
        
        // Parse hosts...
        NSRange ns = [host rangeOfString:@"/"];
        if (ns.length == 0) {
            [fullMenu setObject:[NSString stringWithFormat:@"ssh %@", host] forKey:[self humanize:host]];
            
        } else {
            NSString *part = [host substringToIndex: ns.location];
            host = [host substringFromIndex:ns.location + 1];

            if ([fullMenu objectForKey:part] == nil) {
                NSMutableDictionary *tmp = [NSMutableDictionary dictionary];
                [fullMenu setObject:tmp forKey:part];
            }

            [[fullMenu objectForKey:part] setObject:[NSString stringWithFormat:@"ssh %@", [data valueForKey:@"Host"]] forKey:host];
        }
    }
    
    
    // Now add the JSON Configured Hosts
    for (id key in shuttleHosts) {
        // If it has a `cmd`, it's a top-level item
        // otherwise, create a submenu for it
        if ( [key valueForKey:@"cmd"] ) {
            [fullMenu setObject:[key valueForKey:@"cmd"] forKey: [key valueForKey:@"name"]];
        } else {
            for ( id group in key ) {
                if ([fullMenu valueForKey:group] == nil)
                    [fullMenu setObject:[NSMutableDictionary dictionary] forKey:group];
                
                // Get the subpart
                NSMutableDictionary* submenu = [fullMenu objectForKey:group];
                for ( id subKey in [key valueForKey:group]) {
                    [submenu setObject:[subKey valueForKey:@"cmd"] forKey:[subKey valueForKey:@"name"]];
                }
            }
            
        }

    }
    
    // Finally add everything
    NSArray* keys = [[fullMenu allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    
    
    for(id key in keys) {
        id object = [fullMenu valueForKey:key];
        
        // We have a submenu
        if ([object isKindOfClass: [NSDictionary class]]) {
            NSMenuItem *mainItem = [[NSMenuItem alloc] init];
            [mainItem setTitle:key];
            
            NSMenu *submenu = [[NSMenu alloc] init];
            NSArray* subkeys = [[object allKeys]  sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
            for (id sub in subkeys) {
                NSMenuItem *menuItem = [submenu addItemWithTitle:sub
                                                          action:@selector   (openHost:)
                                                   keyEquivalent:@""];
                [menuItem setRepresentedObject:[object valueForKey:sub]];
            }
            [mainItem setSubmenu:submenu];
            [menu insertItem:mainItem atIndex:i];
            
        } else {
            NSMenuItem *menuItem = [menu insertItemWithTitle:key
                                                      action:@selector(openHost:)
                                               keyEquivalent:@""
                                                     atIndex:i
                                    ];
            // Save that item's SSH command as its represented object
            // so we can call it when it's clicked
            [menuItem setRepresentedObject:object];
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
                                    @"      if isRunning then \n"
                                    @"          set newSession to (launch session \"Default Session\") \n"
                                    @"          tell newSession \n"
                                    @"              write text \"clear\" \n"
                                    @"              write text \"%1$@\" \n"
                                    @"          end tell \n"
                                    @"      else \n"
                                    @"          tell the current session \n"
                                    @"              write text \"clear\" \n"
                                    @"              write text \"%1$@\" \n"
                                    @"              activate \n"
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
