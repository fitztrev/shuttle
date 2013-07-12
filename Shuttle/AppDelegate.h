//
//  AppDelegate.h
//  Shuttle
//

#import <Cocoa/Cocoa.h>

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
    NSMutableArray* shuttleHosts;
}

- (void)menuWillOpen:(NSMenu *)menu;

@end