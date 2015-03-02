//
//  AppDelegate.m
//  Shuttle
//

#import "AppDelegate.h"
#import "AboutWindowController.h"

@implementation AppDelegate

- (void) awakeFromNib {
    // The path for the configuration file (by default: ~/.shuttle.json)
    shuttleConfigFile = [NSHomeDirectory() stringByAppendingPathComponent:@".shuttle.json"];
    
    // if the config file does not exist, create a default one
    if ( ![[NSFileManager defaultManager] fileExistsAtPath:shuttleConfigFile] ) {
        NSString *cgFileInResource = [[NSBundle mainBundle] pathForResource:@"shuttle.default" ofType:@"json"];
        [[NSFileManager defaultManager] copyItemAtPath:cgFileInResource toPath:shuttleConfigFile error:nil];
    }

    // Load the menu content
    // [self loadMenu];

    // Define Icons
    regularIcon = [NSImage imageNamed:@"StatusIcon"];
    altIcon = [NSImage imageNamed:@"StatusIconAlt"];
    
    // Check for AppKit Version, add support for darkmode if > 10.9
    BOOL oldAppKitVersion = (floor(NSAppKitVersionNumber) <= 1265);
    
    if (!oldAppKitVersion)
    {
        // 10.10 or higher, add support to icon for auto detection of Regular/Dark mode
        [regularIcon setTemplate:YES];
        [altIcon setTemplate:YES];
    }
    
    // Create the status bar item
    statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:25.0];
    
    [statusItem setMenu:menu];
    [statusItem setHighlightMode:YES];
    [statusItem setImage: regularIcon];
    [statusItem setAlternateImage: altIcon];

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
    
    // build the regex for matching
    NSError* error = NULL;
    NSRegularExpression* rx = [NSRegularExpression regularExpressionWithPattern:@"^(#?)[ \\t]*([^ \\t=]+)[ \\t=]+(.*)$"
                                                                        options:0
                                                                          error:&error];
    
    // create data store
    NSMutableDictionary* servers = [[NSMutableDictionary alloc] init];
    NSString* key = nil;
    
    // Loop through each line and parse the file.
    for (NSString *line in [fh componentsSeparatedByString:@"\n"]) {
        
        // Strip line
        NSString *trimmed = [line stringByTrimmingCharactersInSet:[ NSCharacterSet whitespaceCharacterSet]];
        
        // run the regex against the line
        NSTextCheckingResult* matches = [rx firstMatchInString:trimmed
                                                       options:0
                                                         range:NSMakeRange(0, [trimmed length])];
        if ([matches numberOfRanges] != 4)
            continue;
        
        BOOL isComment = [[trimmed substringWithRange:[matches rangeAtIndex:1]] isEqualToString:@"#"];
        NSString* first = [trimmed substringWithRange:[matches rangeAtIndex:2]];
        NSString* second = [trimmed substringWithRange:[matches rangeAtIndex:3]];
        
        // check for special comment key/value pairs
        if (isComment && key && [first hasPrefix:@"shuttle."])
            servers[key][[first substringFromIndex:8]] = second;
        
        // other comments must be skipped
        if (isComment)
            continue;
        
        if ([first isEqualToString:@"Host"]) {
            // a new host section
            key = second;
            servers[key] = [[NSMutableDictionary alloc] init];
        }
    }
    
    return servers;    
}

// Replaces Underscores with Spaces for better readable names
- (NSString*) humanize: (NSString*) val{
    return [val stringByReplacingOccurrencesOfString:@"_" withString:@" "];
}

- (void) loadMenu {
    // Clear out the hosts so we can start over
    NSUInteger n = [[menu itemArray] count];
    for (int i=0;i<n-4;i++) {
        [menu removeItemAtIndex:0];
    }
    
    // Parse the config file
    NSData *data = [NSData dataWithContentsOfFile:shuttleConfigFile];
    id json = [NSJSONSerialization JSONObjectWithData:data
                                              options:NSJSONReadingMutableContainers
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
    launchAtLoginController.launchAtLogin = [json[@"launch_at_login"] boolValue];
    shuttleHosts = json[@"hosts"];
    ignoreHosts = json[@"ssh_config_ignore_hosts"];
    ignoreKeywords = json[@"ssh_config_ignore_keywords"];

    // Should we merge ssh config hosts?
    BOOL showSshConfigHosts = YES;
    if ([[json allKeys] containsObject:(@"show_ssh_config_hosts")] && [json[@"show_ssh_config_hosts"] boolValue] == NO) {
        showSshConfigHosts = NO;
    }

    if (showSshConfigHosts) {
        // Read configuration from ssh config
        NSDictionary* servers = [self parseSSHConfigFile];
        for (NSString* key in servers) {
            BOOL skipCurrent = NO;
            NSDictionary* cfg = [servers objectForKey:key];
            
            // get special name from config if set, fallback to the key
            NSString* name = cfg[@"name"] ? cfg[@"name"] : key;
            
            // Ignore entries that contain wildcard characters
            if ([name rangeOfString:@"*"].length != 0)
                skipCurrent = YES;
            
            // Ignore entries that start with `.`
            if ([name hasPrefix:@"."])
                skipCurrent = YES;
            
            // Ignore entries whose name matches exactly any of the values in ignoreHosts
            for (NSString* ignore in ignoreHosts) {
                if ([name isEqualToString:ignore]) {
                    skipCurrent = YES;
                }
            }
            
            // Ignore entries whose name contains any of the values in ignoreKeywords
            for (NSString* ignore in ignoreKeywords) {
                if ([name rangeOfString:ignore].location != NSNotFound) {
                    skipCurrent = YES;
                }
            }
            
            if (skipCurrent) {
                continue;
            }
            
            // Split the host into parts separated by / - the last part is the name for the leaf in the tree
            NSMutableArray* path = [NSMutableArray arrayWithArray:[name componentsSeparatedByString:@"/"]];
            NSString* leaf = [path lastObject];
            if (leaf == nil)
                continue;
            [path removeLastObject];
            
            NSMutableArray* itemList = shuttleHosts;
            for (NSString *part in path) {
                BOOL createList = YES;
                for (NSDictionary* item in itemList) {
                    // if we encounter an item with cmd/name then we have to bail
                    // since there's no way we can dig deeper here
                    if (item[@"cmd"] || item[@"name"]) {
                        continue;
                    }
                    
                    // if this item has the name of our target check if we can
                    // reuse it (if it's an array) - or if we need to bail
                    if (item[part]) {
                        // make sure this is an array and not an object
                        if ([item[part] isKindOfClass:[NSArray class]]) {
                            itemList = item[part];
                            createList = NO;
                        } else {
                            itemList = nil;
                        }
                        break;
                    }
                }
                
                if (itemList == nil) {
                    // things gone south... there's already something present and it's
                    // not an array...
                    break;
                }
                
                if (createList) {
                    // create a new entry and set it as itemList
                    NSMutableArray *newList = [[NSMutableArray alloc] init];
                    [itemList addObject:[NSDictionary dictionaryWithObject:newList
                                                                    forKey:part]];
                    itemList = newList;
                }
            }
        
            // if everything worked out we will see a non-nil itemList where the
            // system should be appended to. part hold the last part of the splitted string (aka hostname).
            if (itemList) {
                // build the corresponding ssh command
                NSString* cmd = [NSString stringWithFormat:@"ssh %@", key];
                
                // inject the data into the json parser result
                [itemList addObject:[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:leaf, cmd, nil]
                                                                forKeys:[NSArray arrayWithObjects:@"name", @"cmd", nil]]];
            }
        }
    }
    
    // feed the final result into the recursive method which builds the menu
    [self buildMenu:shuttleHosts addToMenu:menu];
}

- (void) buildMenu:(NSArray*)data addToMenu:(NSMenu *)m {
    // go through the array and sort out the menus and the leafs into
    // separate bucks so we can sort them independently.
    NSMutableDictionary* menus = [[NSMutableDictionary alloc] init];
    NSMutableDictionary* leafs = [[NSMutableDictionary alloc] init];
    
    for (NSDictionary* item in data) {
        if (item[@"cmd"] && item[@"name"]) {
            // this is a leaf
            [leafs setObject:item forKey:item[@"name"]];
        } else {
            // must be a menu - add all instances
            for (NSString* key in item) {
                [menus setObject:item[key] forKey:key];
            }
        }
    }
    
    NSArray* menuKeys = [[menus allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    NSArray* leafKeys = [[leafs allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    
    NSInteger pos = 0;
    
    // create menus first
    for (NSString* key in menuKeys) {
        NSMenu* subMenu = [[NSMenu alloc] init];
        NSMenuItem* menuItem = [[NSMenuItem alloc] init];
        [menuItem setTitle:key];
        [menuItem setSubmenu:subMenu];
        [m insertItem:menuItem atIndex:pos++];

        // build submenu
        [self buildMenu:menus[key] addToMenu:subMenu];
    }
    
    // now create leafs
    for (NSString *key in leafKeys) {
        NSDictionary* cfg = leafs[key];
        NSMenuItem* menuItem = [[NSMenuItem alloc] init];
        [menuItem setTitle:cfg[@"name"]];
        [menuItem setRepresentedObject:cfg[@"cmd"]];
        [menuItem setAction:@selector(openHost:)];
        [m insertItem:menuItem atIndex:pos++];
    }
}

- (void) openHost:(NSMenuItem *) sender {
    //NSLog(@"sender: %@", sender);
    //NSLog(@"Command: %@",[sender representedObject]);
    
    NSString *escapedObject = [[sender representedObject] stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
    
    // Check if Url
    NSURL* url = [NSURL URLWithString:[sender representedObject]];
    if(url)
    {
        [[NSWorkspace sharedWorkspace] openURL:url];
    }
    else if ( [terminalPref rangeOfString: @"iterm"].location !=NSNotFound) {
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
                                    @"          tell the last session \n"
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
                                    , escapedObject]];
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
                                       , escapedObject]];
        [terminalapp executeAndReturnError:nil];
    }
}

- (IBAction)showImportPanel:(id)sender {
    NSOpenPanel * openPanelObj	= [NSOpenPanel openPanel];
    NSInteger tvarNSInteger	= [openPanelObj runModal];
    if(tvarNSInteger == NSOKButton){
        //Backup the current configuration
        [[NSFileManager defaultManager] moveItemAtPath:shuttleConfigFile toPath: [NSHomeDirectory() stringByAppendingPathComponent:@".shuttle.json.backup"] error: nil];
        
        NSURL * selectedFileUrl = [openPanelObj URL];
        //Import the selected file
        //NSLog(@"copy filename from %@ to %@",selectedFileUrl.path,shuttleConfigFile);
        [[NSFileManager defaultManager] copyItemAtPath:selectedFileUrl.path toPath:shuttleConfigFile error:nil];
        //Delete the old configuration file
        [[NSFileManager defaultManager] removeItemAtPath:[NSHomeDirectory() stringByAppendingPathComponent:@".shuttle.json.backup"]  error: nil];
    } else {
     	return;
    }
    
}

- (IBAction)showExportPanel:(id)sender {
    NSSavePanel * savePanelObj	= [NSSavePanel savePanel];
    //Display the Save Panel
    NSInteger result	= [savePanelObj runModal];        
        if (result == NSFileHandlingPanelOKButton) {
            NSURL *saveURL = [savePanelObj URL];
            // then copy a previous file to the new location
            [[NSFileManager defaultManager] copyItemAtPath:shuttleConfigFile toPath:saveURL.path error:nil];
        }
}


- (IBAction)configure:(id)sender {
    [[NSWorkspace sharedWorkspace] openFile:shuttleConfigFile];
}

- (IBAction)showAbout:(id)sender {
    
    //Call the windows controller
        AboutWindowController *aboutWindow = [[AboutWindowController alloc] initWithWindowNibName:@"AboutWindowController"];
    
        //Set the window to stay on top
        [aboutWindow.window setLevel:NSFloatingWindowLevel];
    
        //Show the window
        [aboutWindow showWindow:self];
}

- (IBAction)quit:(id)sender {
    [[NSStatusBar systemStatusBar] removeStatusItem:statusItem];
    [NSApp terminate:NSApp];
}

@end
