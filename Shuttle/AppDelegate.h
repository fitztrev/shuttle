//
//  AppDelegate.h
//  Shuttle
//

#import <Cocoa/Cocoa.h>
#import "LaunchAtLoginController.h"

@interface AppDelegate : NSObject <NSApplicationDelegate, NSMenuDelegate>{
    IBOutlet NSMenu *menu;
    IBOutlet NSArrayController *arrayController;

    NSStatusItem *statusItem;
    NSString *shuttleConfigFile;
    
    // This is for the JSON File
    NSDate *configModified;
    NSDate *sshConfigUser;
    NSDate *sshConfigSystem;
    
    NSString *terminalPref;
    NSString *editorPref;
    NSMutableArray* shuttleHosts;
    NSMutableArray* shuttleMacros;
    NSMutableArray* ignoreHosts;
    NSMutableArray* ignoreKeywords;
    
    LaunchAtLoginController *launchAtLoginController;
    
}

- (void)menuWillOpen:(NSMenu *)menu;

@end
