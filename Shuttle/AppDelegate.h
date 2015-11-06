//
//  AppDelegate.h
//  Shuttle
//

#import <Cocoa/Cocoa.h>
#import "LaunchAtLoginController.h"

@interface AppDelegate : NSObject <NSApplicationDelegate, NSMenuDelegate>{
    IBOutlet NSMenu *menu;
    IBOutlet NSArrayController *arrayController;

    NSImage *regularIcon;
    NSImage *altIcon;
    
    NSStatusItem *statusItem;
    NSString *shuttleConfigFile;
    
    // This is for the JSON File
    NSDate *configModified;
    NSDate *sshConfigUser;
    NSDate *sshConfigSystem;
    
    //Global settings Pref in the JSON file.
    NSString *shuttleJSONPathPref; //alternate path the JSON file
    NSString *terminalPref; //which terminal will we be using iTerm or Terminal.app
    NSString *editorPref; //what app opens the JSON fiile vi, nano...
    NSString *iTermVersionPref; //which version of iTerm nightly or stable
    NSString *openInPref; //by default are commands opened in tabs or new windows.
    NSString *themePref; //The global theme.
    
    //used to gather ssh config settings
    NSMutableArray* shuttleHosts;
    NSMutableArray* ignoreHosts;
    NSMutableArray* ignoreKeywords;
    
    LaunchAtLoginController *launchAtLoginController;
    
}

- (void)menuWillOpen:(NSMenu *)menu;

@end