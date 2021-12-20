//
//  AppDelegate.m
//  Shuttle
//

#import "AppDelegate.h"
#import "AboutWindowController.h"

@implementation AppDelegate

- (void) awakeFromNib {
    
    // The location for the JSON path file. This is a simple file that contains the hard path to the *.json settings file.
    shuttleJSONPathPref = [NSHomeDirectory() stringByAppendingPathComponent:@".shuttle.path"];
    shuttleJSONPathAlt = [NSHomeDirectory() stringByAppendingPathComponent:@".shuttle-alt.path"];
    
    //if file shuttle.path exists in ~/.shuttle.path then read this file as it should contain the custom path to *.json
    if( [[NSFileManager defaultManager] fileExistsAtPath:shuttleJSONPathPref] ) {
        
        //Read the shuttle.path file which contains the path to the json file
        NSString *jsonConfigPath = [NSString stringWithContentsOfFile:shuttleJSONPathPref encoding:NSUTF8StringEncoding error:NULL];
        
        //Remove the white space if any.
        jsonConfigPath = [ jsonConfigPath stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        shuttleConfigFile = jsonConfigPath;
    }else{
        // The path for the configuration file (by default: ~/.shuttle.json)
        shuttleConfigFile = [NSHomeDirectory() stringByAppendingPathComponent:@".shuttle.json"];
        
        // if the config file does not exist, create a default one
        if ( ![[NSFileManager defaultManager] fileExistsAtPath:shuttleConfigFile] ) {
            NSString *cgFileInResource = [[NSBundle mainBundle] pathForResource:@"shuttle.default" ofType:@"json"];
            [[NSFileManager defaultManager] copyItemAtPath:cgFileInResource toPath:shuttleConfigFile error:nil];
        }
    }
    
    // if the custom alternate json file exists then read the file and use set the output as the alt path.
    if ( [[NSFileManager defaultManager] fileExistsAtPath:shuttleJSONPathAlt] ) {
        
        //Read shuttle-alt.path file which contains the custom path to the alternate json file
        NSString *jsonConfigAltPath = [NSString stringWithContentsOfFile:shuttleJSONPathAlt encoding:NSUTF8StringEncoding error:NULL];
        
        //Remove whitespace if any
        jsonConfigAltPath = [ jsonConfigAltPath stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        //set the global var that contains the alternate path
        shuttleAltConfigFile = jsonConfigAltPath;
        
        //flag the bool for later parsing
        parseAltJSON = YES;
    }else{
        //the custom alt path does not exist. Assume the default for alt path; if existing flag for later parsing
        shuttleAltConfigFile = [NSHomeDirectory() stringByAppendingPathComponent:@".shuttle-alt.json"];
        
        if ( [[NSFileManager defaultManager] fileExistsAtPath:shuttleAltConfigFile] ){
            //the default path exists. Flag for later parsing
            parseAltJSON = YES;
        }else{
            //The user does not want to parse an additional json file.
            parseAltJSON = NO;
        }
    }
    
    // Define Icons
    //only regular icon is needed for 10.10 and higher. OS X changes the icon for us.
    regularIcon = [NSImage imageNamed:@"StatusIcon"];
    altIcon = [NSImage imageNamed:@"StatusIconAlt"];
    
    // Create the status bar item
    statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
    [statusItem setMenu:menu];
    [statusItem setImage: regularIcon];
    
    // Check for AppKit Version, add support for darkmode if > 10.9
    BOOL oldAppKitVersion = (floor(NSAppKitVersionNumber) <= 1265);
    
    // 10.10 or higher, dont load the alt image let OS X style it.
    if (!oldAppKitVersion)
    {
        regularIcon.template = YES;
    }
    // Load the alt image for OS X < 10.10
    else{
        [statusItem setHighlightMode:YES];
        [statusItem setAlternateImage: altIcon];
    }
    
    launchAtLoginController = [[LaunchAtLoginController alloc] init];
    // Needed to trigger the menuWillOpen event
    [menu setDelegate:self];
}

- (BOOL) needUpdateFor: (NSString*) file with: (NSDate*) old {
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:[file stringByExpandingTildeInPath]])
        return false;
    
    if (old == NULL)
        return true;
    
    NSDate *date = [self getMTimeFor:file];
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
        [self needUpdateFor:shuttleAltConfigFile with:configModified2] ||
        [self needUpdateFor: @"/etc/ssh/ssh_config" with:sshConfigSystem] ||
        [self needUpdateFor: @"~/.ssh/config" with:sshConfigUser]) {
        
        configModified = [self getMTimeFor:shuttleConfigFile];
        configModified2 = [self getMTimeFor:shuttleAltConfigFile];
        sshConfigSystem = [self getMTimeFor: @"/etc/ssh/ssh_config"];
        sshConfigUser = [self getMTimeFor: @"~/.ssh/config"];
        
        [self loadMenu];
    }
}

// Parsing of the SSH Config File
// Courtesy of https://gist.github.com/geeksunny/3376694
- (NSDictionary<NSString *, NSDictionary *> *)parseSSHConfigFile {
    
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
    return [self parseSSHConfig:configFile];
}

- (NSDictionary<NSString *, NSDictionary *> *)parseSSHConfig:(NSString *)filepath {
    // Get file contents into fh.
    NSString *fh = [NSString stringWithContentsOfFile:filepath encoding:NSUTF8StringEncoding error:nil];
    
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
        if ([matches numberOfRanges] != 4) {
            continue;
        }
        
        BOOL isComment = [[trimmed substringWithRange:[matches rangeAtIndex:1]] isEqualToString:@"#"];
        NSString* first = [trimmed substringWithRange:[matches rangeAtIndex:2]];
        NSString* second = [trimmed substringWithRange:[matches rangeAtIndex:3]];
        
        // check for special comment key/value pairs
        if (isComment && key && [first hasPrefix:@"shuttle."]) {
            servers[key][[first substringFromIndex:8]] = second;
        }
        
        // other comments must be skipped
        if (isComment) {
            continue;
        }
        
        if ([first isEqualToString:@"Include"]) {
            // Support for ssh_config Include directive.
            NSString *includePath = ([second isAbsolutePath])
                ? [second stringByExpandingTildeInPath]
                : [[filepath stringByDeletingLastPathComponent] stringByAppendingPathComponent:second];
            
            [servers addEntriesFromDictionary:[self parseSSHConfig:includePath]];
        }
        
        if ([first isEqualToString:@"Host"]) {
            // a new host section
            
            // split multiple aliases on space and only save the first
            NSArray* hostAliases = [second componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            hostAliases = [hostAliases filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF != ''"]];
            key = [hostAliases firstObject];
            servers[key] = [[NSMutableDictionary alloc] init];
        }
    }
    
    return servers;
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
        NSMenuItem *menuItem = [menu insertItemWithTitle:NSLocalizedString(@"Error parsing config",nil)
                                                  action:false
                                           keyEquivalent:@""
                                                 atIndex:0
                                ];
        [menuItem setEnabled:false];
        return;
    }
    
    terminalPref = [json[@"terminal"] lowercaseString];
    editorPref = [json[@"editor"] lowercaseString];
    iTermVersionPref = [json[@"iTerm_version"] lowercaseString];
    openInPref = [json[@"open_in"] lowercaseString];
    themePref = json[@"default_theme"];
    launchAtLoginController.launchAtLogin = [json[@"launch_at_login"] boolValue];
    shuttleHosts = json[@"hosts"];
    ignoreHosts = json[@"ssh_config_ignore_hosts"];
    ignoreKeywords = json[@"ssh_config_ignore_keywords"];
    
    //add hosts from the alternate json config
    if (parseAltJSON) {
        NSData *dataAlt = [NSData dataWithContentsOfFile:shuttleAltConfigFile];
        id jsonAlt = [NSJSONSerialization JSONObjectWithData:dataAlt options:NSJSONReadingMutableContainers error:nil];
        shuttleHostsAlt = jsonAlt[@"hosts"];
        [shuttleHosts addObjectsFromArray:shuttleHostsAlt];
    }
    
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
//    NSMutableDictionary* leafs = [[NSMutableDictionary alloc] init];
    
    for (NSDictionary* item in data) {
        if (item[@"cmd"] && item[@"name"]) {
            // this is a leaf
//            [leafs setObject:item forKey:item[@"name"]];
            [menus setObject:item forKey:item[@"name"]];
        } else {
            // must be a menu - add all instances
            for (NSString* key in item) {
                [menus setObject:item[key] forKey:key];
            }
        }
    }
    
    NSArray* menuKeys = [[menus allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
//    NSArray* leafKeys = [[leafs allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    
    NSInteger pos = 0;
    
    // create menus first
    for (NSString* key in menuKeys) {
        if([menus[key] isKindOfClass:[NSDictionary class]]){
            NSDictionary* cfg = menus[key];
            //Get the command we are going to run in termainal
            NSString *menuCmd = cfg[@"cmd"];
            //Get the theme for this terminal session
            NSString *termTheme = cfg[@"theme"];
            //Get the name for the terminal session
            NSString *termTitle = cfg[@"title"];
            //Get the value of setting inTerminal
            NSString *termWindow = cfg[@"inTerminal"];
            //Get the menu name will will use this as the title if title is null.
            [self separatorSortRemoval:cfg[@"name"]];
            
            //Place the terminal command, theme, and title into an comma delimited string
            NSString *menuRepObj = [NSString stringWithFormat:@"%@¬_¬%@¬_¬%@¬_¬%@¬_¬%@", menuCmd, termTheme, termTitle, termWindow, menuName];
            
            NSMenuItem* menuItem = [[NSMenuItem alloc] init];
            [menuItem setTitle:menuName];
            [menuItem setRepresentedObject:menuRepObj];
            [menuItem setAction:@selector(openHost:)];
            [m insertItem:menuItem atIndex:pos++];
            if (addSeparator) {
                [m insertItem:[NSMenuItem separatorItem] atIndex:pos++];
            }
        }else{
            NSMenuItem* menuItem = [[NSMenuItem alloc] init];
            NSMenu* subMenu = [[NSMenu alloc] init];
            [self separatorSortRemoval:key];
            [menuItem setTitle:menuName];
            [menuItem setSubmenu:subMenu];
            [m insertItem:menuItem atIndex:pos++];
            if (addSeparator) {
                [m insertItem:[NSMenuItem separatorItem] atIndex:pos++];
            }
            // build submenu
            [self buildMenu:menus[key] addToMenu:subMenu];
        }
    }
}

- (void) separatorSortRemoval:(NSString *)currentName {
    NSError *regexError = nil;
    addSeparator = NO;
    
    NSRegularExpression *regexSort = [NSRegularExpression regularExpressionWithPattern:@"([\\[][a-z]{3}[\\]])" options:0 error:&regexError];
    NSRegularExpression *regexSeparator = [NSRegularExpression regularExpressionWithPattern:@"([\\[][-]{3}[\\]])" options:0 error:&regexError];
    
    NSUInteger sortMatches = [regexSort numberOfMatchesInString:currentName options:0 range:NSMakeRange(0,[currentName length])];
    NSUInteger separatorMatches = [regexSeparator  numberOfMatchesInString:currentName options:0 range:NSMakeRange(0,[currentName length])];
    //NSUInteger *totalMatches = sortMatches + separatorMatches;
    
    
    
    if ( sortMatches == 1 || separatorMatches == 1 ) {
        if (sortMatches == 1 && separatorMatches == 1 ) {
            menuName = [regexSort stringByReplacingMatchesInString:currentName options:0 range:NSMakeRange(0, [currentName length]) withTemplate:@""];
            menuName = [regexSeparator stringByReplacingMatchesInString:menuName options:0 range:NSMakeRange(0, [menuName length]) withTemplate:@""];
            addSeparator = YES;
        } else {
            
            if( sortMatches == 1) {
                menuName = [regexSort stringByReplacingMatchesInString:currentName options:0 range:NSMakeRange(0, [currentName length]) withTemplate:@""];
                addSeparator = NO;
            }
            if ( separatorMatches == 1 ) {
                menuName = [regexSeparator stringByReplacingMatchesInString:currentName options:0 range:NSMakeRange(0, [currentName length]) withTemplate:@""];
                addSeparator = YES;
            }
        }
    } else {
        menuName = currentName;
        addSeparator = NO;
    }
}

- (void) openHost:(NSMenuItem *) sender {
    //NSLog(@"sender: %@", sender);
    //NSLog(@"Command: %@",[sender representedObject]);
    
    NSString *errorMessage;
    NSString *errorInfo;
    
    
    //Place the comma delimited string of menu item settings into an array
    NSArray *objectsFromJSON = [[sender representedObject] componentsSeparatedByString:(@"¬_¬")];
    
    //This is our command that will be run in the terminal window
    NSString *escapedObject;
    //The theme for the terminal window
    NSString *terminalTheme;
    //The title for the terminal window
    NSString *terminalTitle;
    //Are commands run in a new tab (default) a new terminal window (new), or in the current tab of the last used window (current).
    NSString *terminalWindow;
    
    escapedObject = [objectsFromJSON objectAtIndex:0];
    
    //if terminalTheme is not set then check for a global setting.
    if( [[objectsFromJSON objectAtIndex:1] isEqualToString:@"(null)"] ){
        if(themePref == 0) {
            if( [terminalPref isEqualToString:@"iterm"] ){
                //we have no global theme and there is no theme in the command settings.
                //Forcing the Default profile for iTerm and the basic profile for Terminal.app
                terminalTheme = @"Default";
            }else{
                terminalTheme = @"basic";
            }
            //We have a global setting using this as the theme.
        }else {
            terminalTheme = themePref;
        }
        //we have command level theme override the Global default_theme settings.
    }else{
        terminalTheme = [objectsFromJSON objectAtIndex:1];
    }
    
    //Check if terminalTitle is null
    if( [[objectsFromJSON objectAtIndex:2] isEqualToString:@"(null)"]){
        //setting the empty title to that of the menu item.
        terminalTitle = [objectsFromJSON objectAtIndex:4];
    }else{
        terminalTitle = [objectsFromJSON objectAtIndex:2];
    }
    
    //Check if inTerminal is null if so then use the default settings of open_in
    if( [[objectsFromJSON objectAtIndex:3] isEqualToString:@"(null)"]){
        
        //if open_in is not "tab" or "new" then force the default of "tab".
        if( ![openInPref isEqualToString:@"tab"] && ![openInPref isEqualToString:@"new"]){
            openInPref = @"tab";
        }
        //open_in was not empty or bad value we are passing the settings.
        terminalWindow = openInPref;
    }else{
        //inTerminal is not null and overrides the default values of open_in
        terminalWindow = [objectsFromJSON objectAtIndex:3];
        if( ![terminalWindow isEqualToString:@"new"] && ![terminalWindow isEqualToString:@"current"] && ![terminalWindow isEqualToString:@"tab"] && ![terminalWindow isEqualToString:@"virtual"])
        {
            errorMessage = [NSString stringWithFormat:@"%@%@%@ %@",@"'",terminalWindow,@"'", NSLocalizedString(@"is not a valid value for inTerminal. Please fix this in the JSON file",nil)];
            errorInfo = NSLocalizedString(@"bad \"inTerminal\":\"VALUE\" in the JSON settings",nil);
            [self throwError:errorMessage additionalInfo:errorInfo continueOnErrorOption:NO];
        }
    }
    
    //Set Paths to iTerm Stable AppleScripts
    NSString *iTermStableNewWindow =  [[NSBundle mainBundle] pathForResource:@"iTerm2-stable-new-window" ofType:@"scpt"];
    NSString *iTermStableCurrentWindow = [[NSBundle mainBundle] pathForResource:@"iTerm2-stable-current-window" ofType:@"scpt"];
    NSString *iTermStableNewTabDefault = [[NSBundle mainBundle] pathForResource:@"iTerm2-stable-new-tab-default" ofType:@"scpt"];
    
    //Set Paths to iTerm Nightly AppleScripts
    NSString *iTerm2NightlyNewWindow =  [[NSBundle mainBundle] pathForResource:@"iTerm2-nightly-new-window" ofType:@"scpt"];
    NSString *iTerm2NightlyCurrentWindow = [[NSBundle mainBundle] pathForResource:@"iTerm2-nightly-current-window" ofType:@"scpt"];
    NSString *iTerm2NightlyNewTabDefault = [[NSBundle mainBundle] pathForResource:@"iTerm2-nightly-new-tab-default" ofType:@"scpt"];
    
    //Set Paths to terminalScripts
    NSString *terminalNewWindow =  [[NSBundle mainBundle] pathForResource:@"terminal-new-window" ofType:@"scpt"];
    NSString *terminalCurrentWindow = [[NSBundle mainBundle] pathForResource:@"terminal-current-window" ofType:@"scpt"];
    NSString *terminalNewTabDefault = [[NSBundle mainBundle] pathForResource:@"terminal-new-tab-default" ofType:@"scpt"];
    
    //Set Path to virtual with screen AppleScripts
    NSString *terminalVirtualWithScreen = [[NSBundle mainBundle] pathForResource:@"virtual-with-screen" ofType:@"scpt"];
    
    //Set the name of the handler that we are passing parameters too in the apple script
    NSString *handlerName = @"scriptRun";
    
    //script expects the following order: Command, Theme, Title unless its virtual which bypasses the url check and expects Command, Title
    NSArray *passParameters;
    NSURL *url;
    if ( ![terminalWindow isEqualToString:@"virtual"] ) {
        passParameters = @[escapedObject, terminalTheme, terminalTitle];
        url = [NSURL URLWithString:escapedObject];
    }
    else {
        passParameters = @[escapedObject, terminalTitle];
    }
    // Check if Url
    if (url)
        {
            [[NSWorkspace sharedWorkspace] openURL:url];
            
        }
    //If the JSON file is set to use iTerm
    else if ( [terminalPref rangeOfString: @"iterm"].location !=NSNotFound ) {
        
        //If the JSON prefs for iTermVersion are not stable or nightly throw an error
        if( ![iTermVersionPref isEqualToString: @"stable"] && ![iTermVersionPref isEqualToString:@"nightly"] ) {
            
            if( iTermVersionPref == 0 ) {
                errorMessage = NSLocalizedString(@"\"iTerm_version\": \"VALUE\", is missing.\n\n\"VALUE\" can be:\n\"stable\" targeting new versions.\n\"nightly\" targeting nightly builds.\n\nPlease fix your shuttle JSON settings.\nSee readme.md on shuttle's github for help.",nil);
                errorInfo = NSLocalizedString(@"Press Continue to try iTerm stable applescripts.\n              -->(not recommended)<--\nThis could fail if you have another version of iTerm installed.\n\nPlease fix the JSON settings.\nPress Quit to exit shuttle.",nil);
                [self throwError:errorMessage additionalInfo:errorInfo continueOnErrorOption:YES];
                iTermVersionPref = @"stable";
                
            }else{
                errorMessage = [NSString stringWithFormat:@"%@%@%@ %@",@"'",iTermVersionPref,@"'", NSLocalizedString(@"is not a valid value for iTerm_version. Please fix this in the JSON file",nil)];
                errorInfo = NSLocalizedString(@"bad \"iTerm_version\": \"VALUE\" in the JSON settings",nil);
                [self throwError:errorMessage additionalInfo:errorInfo continueOnErrorOption:NO];
            }
        }
        
        if( [iTermVersionPref isEqualToString:@"stable"]) {
            
            //run the applescript that works with iTerm Stable
            //if we are running in a new iTerm "Stable" Window
            if ( [terminalWindow isEqualToString:@"new"] ) {
                [self runScript:iTermStableNewWindow handler:handlerName parameters:passParameters];
            }
            //if we are running in the current iTerm "Stable" Window
            if ( [terminalWindow isEqualToString:@"current"] ) {
                [self runScript:iTermStableCurrentWindow handler:handlerName parameters:passParameters];
            }
            //we are using the default action of shuttle... The active window in a new tab
            if ( [terminalWindow isEqualToString:@"tab"] ) {
                [self runScript:iTermStableNewTabDefault handler:handlerName parameters:passParameters];
            }
            //don't spawn a terminal run the command in the background using screen
            if ( [terminalWindow isEqualToString:@"virtual"] ) {
                [self runScript:terminalVirtualWithScreen handler:handlerName parameters:passParameters];
            }
        }
        //iTermVersion is not set to "stable" using applescripts Configured for Nightly
        if( [iTermVersionPref isEqualToString:@"nightly"]) {
            //if we are running in a new iTerm "Nightly" Window
            if ( [terminalWindow isEqualToString:@"new"] ) {
                [self runScript:iTerm2NightlyNewWindow handler:handlerName parameters:passParameters];
            }
            //if we are running in the current iTerm "Nightly" Window
            if ( [terminalWindow isEqualToString:@"current"] ) {
                [self runScript:iTerm2NightlyCurrentWindow handler:handlerName parameters:passParameters];
            }
            //we are using the default action of shuttle... The active window in a new tab
            if ( [terminalWindow isEqualToString:@"tab"] ) {
                [self runScript:iTerm2NightlyNewTabDefault handler:handlerName parameters:passParameters];
            }
            //don't spawn a terminal run the command in the background using screen
            if ( [terminalWindow isEqualToString:@"virtual"] ) {
                [self runScript:terminalVirtualWithScreen handler:handlerName parameters:passParameters];
            }
        }
    }
    //If JSON settings are set to use Terminal.app
    else {
        //if we are running in a new terminal Window
        if ( [terminalWindow isEqualToString:@"new"] ) {
            [self runScript:terminalNewWindow handler:handlerName parameters:passParameters];
        }
        //if we are running in the current terminal Window
        if ( [terminalWindow isEqualToString:@"current"] ) {
            [self runScript:terminalCurrentWindow handler:handlerName parameters:passParameters];
        }
        //we are using the default action of shuttle... The active window in a new tab
        if ( [terminalWindow isEqualToString:@"tab"] ) {
            [self runScript:terminalNewTabDefault handler:handlerName parameters:passParameters];
        }
        //don't spawn a terminal run the command in the background using screen
        if ( [terminalWindow isEqualToString:@"virtual"] ) {
            [self runScript:terminalVirtualWithScreen handler:handlerName parameters:passParameters];
        }
    }
}

- (void) runScript:(NSString *)scriptPath handler:(NSString*)handlerName parameters:(NSArray*)parametersInArray {
    //special thanks to stackoverflow.com/users/316866/leandro for pointing me the right direction.
    //see http://goo.gl/olcpaX
    NSAppleScript           * appleScript;
    NSAppleEventDescriptor  * thisApplication, *containerEvent;
    NSURL                   * pathURL = [NSURL fileURLWithPath:scriptPath];
    
    NSDictionary * appleScriptCreationError = nil;
    appleScript = [[NSAppleScript alloc] initWithContentsOfURL:pathURL error:&appleScriptCreationError];
    
    if (handlerName && [handlerName length])
    {
        /* If we have a handlerName (and potentially parameters), we build
         * an NSAppleEvent to execute the script. */
        
        //Get a descriptor
        int pid = [[NSProcessInfo processInfo] processIdentifier];
        thisApplication = [NSAppleEventDescriptor descriptorWithDescriptorType:typeKernelProcessID
                                                                         bytes:&pid
                                                                        length:sizeof(pid)];
        
        //Create the container event
        
        //We need these constants from the Carbon OpenScripting framework, but we don't actually need Carbon.framework...
#define kASAppleScriptSuite 'ascr'
#define kASSubroutineEvent  'psbr'
#define keyASSubroutineName 'snam'
        containerEvent = [NSAppleEventDescriptor appleEventWithEventClass:kASAppleScriptSuite
                                                                  eventID:kASSubroutineEvent
                                                         targetDescriptor:thisApplication
                                                                 returnID:kAutoGenerateReturnID
                                                            transactionID:kAnyTransactionID];
        //Set the target handler
        [containerEvent setParamDescriptor:[NSAppleEventDescriptor descriptorWithString:handlerName]
                                forKeyword:keyASSubroutineName];
        
        //Pass parameters - parameters is expecting an NSArray with only NSString objects
        if ([parametersInArray count])
        {
            
            NSAppleEventDescriptor  *arguments = [[NSAppleEventDescriptor alloc] initListDescriptor];
            NSString                *object;
            
            for (object in parametersInArray) {
                [arguments insertDescriptor:[NSAppleEventDescriptor descriptorWithString:object]
                                    atIndex:([arguments numberOfItems] +1)];
            }
            
            [containerEvent setParamDescriptor:arguments forKeyword:keyDirectObject];
        }
        //Execute the event
        [appleScript executeAppleEvent:containerEvent error:nil];
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

-(void) throwError:(NSString*)errorMessage additionalInfo:(NSString*)errorInfo continueOnErrorOption:(BOOL)continueOption {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setInformativeText:errorInfo];
    [alert setMessageText:errorMessage];
    [alert setAlertStyle:NSWarningAlertStyle];
    
    if (continueOption) {
        [alert addButtonWithTitle:NSLocalizedString(@"Quit",nil)];
        [alert addButtonWithTitle:NSLocalizedString(@"Continue",nil)];
        
    }else{
        [alert addButtonWithTitle:NSLocalizedString(@"Quit",nil)];
    }
    
    if ([alert runModal] == NSAlertFirstButtonReturn) {
        [NSApp terminate:NSApp];
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
    
    //if the editor setting is omitted or contains 'default' open using the default editor.
    if([editorPref rangeOfString:@"default"].location != NSNotFound) {
        
        [[NSWorkspace sharedWorkspace] openFile:shuttleConfigFile];
    }
    else{
        //build the editor command
        NSString *editorCommand = [NSString stringWithFormat:@"%@ %@", editorPref, shuttleConfigFile];
        
        //build the reprensented object. It's expecting menuCmd, termTheme, termTitle, termWindow, menuName
        NSString *editorRepObj = [NSString stringWithFormat:@"%@¬_¬%@¬_¬%@¬_¬%@¬_¬%@", editorCommand, nil, @"Editing shuttle JSON", nil, nil];
        
        //make a menu item for the command selector(openHost:) runs in a new terminal window.
        NSMenuItem *editorMenu = [[NSMenuItem alloc] initWithTitle:@"editJSONconfig" action:@selector(openHost:) keyEquivalent:(@"")];
        
        //set the command for the menu item
        [editorMenu setRepresentedObject:editorRepObj];
        
        //open the JSON file in the terminal editor.
        [self openHost:editorMenu];
    }
}

- (IBAction)showAbout:(id)sender {
    
    //Call the windows controller
    AboutWindowController *aboutWindow = [[AboutWindowController alloc] initWithWindowNibName:@"AboutWindowController"];
    
    //Set the window to stay on top
    [aboutWindow.window makeKeyAndOrderFront:nil];
    [aboutWindow.window setLevel:NSFloatingWindowLevel];
    
    //Show the window
    [aboutWindow showWindow:self];
}

- (IBAction)quit:(id)sender {
    [[NSStatusBar systemStatusBar] removeStatusItem:statusItem];
    [NSApp terminate:NSApp];
}

@end
