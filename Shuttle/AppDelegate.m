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
- (NSArray*) parseSSHConfigFile {
    
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
    NSMutableArray *servers = [NSMutableArray array];
    
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
            
            [self addHost:host withComponents:[host componentsSeparatedByString:@"/"] toArray:servers];
        }
    }
    
    return servers;
}

// Build a Host Table equivalent to the JSON representation
- (void) addHost:(NSString*)host withComponents:(NSArray*)comps toArray:(NSMutableArray*)servers
{
    // Ignore entrys that contain wildcard characters or begin with a dot
    if ([host rangeOfString:@"*"].length != 0 || [host hasPrefix:@"."])
        return;
    
    if([comps count] == 1)
    {
        // Create ahost entry
        NSString* cmd = [NSString stringWithFormat:@"ssh %@", host];
        NSString* name = [self humanize:[comps firstObject]];
        
        [servers addObject:@{ @"Host" : host, @"cmd" : cmd, @"name" : name }];
    }
    else
    {
        // Create a submenu
        NSMutableArray *ar = [comps mutableCopy];
        [ar removeObjectAtIndex:0];
        NSString *groupName = [comps firstObject];
        
        // Check for existing submenus
        NSArray *existing = [servers filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:[NSString stringWithFormat:@"%@ != nil", groupName]]];
        
        NSMutableArray *groupArray;
        
        if([existing count])
        {
            groupArray = [[existing firstObject] valueForKey:groupName];
        }
        else
        {
            groupArray = [NSMutableArray array];
            [servers addObject:@{groupName: groupArray}];
        }
        
        [self addHost:host withComponents:ar toArray:groupArray];
    }
}

// Replaces Underscores with Spaces for better readable names
- (NSString*) humanize: (NSString*) val{
    return [val stringByReplacingOccurrencesOfString:@"_" withString:@" "];
}

- (void) loadMenu {
    
    // System configuration
    NSArray* servers = [self parseSSHConfigFile];
    
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
    
    // Read global config keys
    terminalPref = [json[@"terminal"] lowercaseString];
    shuttleHosts = [json[@"hosts"] mutableCopy];

    launchAtLoginController.launchAtLogin = [json[@"launch_at_login"] boolValue];

    if([json valueForKey:@"sort_alphabetical"])
    {
        sortAlphabetical = [json[@"sort_alphabetical"] boolValue];
    }
    else
    {
        sortAlphabetical = YES;
    }

    // Add SSH Config Servers
    [shuttleHosts addObjectsFromArray:servers];
    
    // Build your local menu representation
    SHMenu *mainMenu = [[SHMenu alloc] init];
    
    mainMenu.items = [self buildMenu:shuttleHosts];
    
    // Add everything
    [self buildMenuItems:mainMenu forMenu:menu];
}

// Build a SHMenu definition out of JSON
- (NSArray*) buildMenu:(NSArray*)hosts {
    
    NSMutableArray* tempMenu = [NSMutableArray array];
    
    for (id key in hosts) {
        // If it has a `cmd`, it's a top-level item
        // otherwise, create a submenu & call buildMenu recursive
        if ( [key valueForKey:@"cmd"] ) {
            SHMenuItem *item = [[SHMenuItem alloc] init];
            item.name = [key valueForKey:@"name"];
            item.command = [key valueForKey:@"cmd"];
            item.iconPath = [key valueForKey:@"icon"];
            [tempMenu addObject:item];
        } else  {
            for ( id group in key ) {
                SHMenu *submenu = [[SHMenu alloc] init];
                submenu.name = group;
                submenu.items = [self buildMenu:key[group]];
                [tempMenu addObject:submenu];
            }
        }
    }
    
    return tempMenu;
}

// Build a NSMenu from the SHMenu definition
- (void) buildMenuItems:(SHMenu*)mainMenu forMenu:(NSMenu*)tempMenu {
    
    int i = 0;
    
    NSArray *items = [mainMenu items];
    
    if(sortAlphabetical)
    {
        items = [items sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            NSString* name1 = [obj1 valueForKey:@"name"];
            NSString* name2 = [obj2 valueForKey:@"name"];
            
            return [name1 compare:name2 options:NSCaseInsensitiveSearch];
        }];
    }
    
    for(id m in items) {
        
        // We have a submenu
        
        if([m isKindOfClass:[SHMenu class]])
        {
            SHMenu *m1 = (SHMenu*)m;
            NSMenuItem *item = [[NSMenuItem alloc] init];
            item.title = m1.name;
            item.representedObject = m1;
            
            NSMenu *submenu = [[NSMenu alloc] init];
            [self buildMenuItems:m1 forMenu:submenu];
            [item setSubmenu:submenu];
            
            [tempMenu insertItem:item atIndex:i];
        }
        else if([m isKindOfClass:[SHMenuItem class]])
        {
            SHMenuItem *m2 = (SHMenuItem*)m;
            NSMenuItem *item = [tempMenu insertItemWithTitle:m2.name action:@selector(openHost:) keyEquivalent:@"" atIndex:i];
            item.representedObject = m2;
            
            if(m2.iconPath && [[NSFileManager defaultManager] fileExistsAtPath:m2.iconPath])
            {
                NSImage* image = [[NSImage alloc] initWithContentsOfFile:m2.iconPath];
                [image setSize:NSMakeSize(15, 15)];
                [item setImage:image];
            }
        }
        
        i++;
    }
}

- (void) openHost:(NSMenuItem *) sender {
    SHMenuItem *item = sender.representedObject;
    
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
                                    , item.command]];
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
                                       , item.command]];
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
