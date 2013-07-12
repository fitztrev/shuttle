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
    NSDate *configModified;
    
    NSString *terminalPref;
    NSMutableArray* shuttleHosts;
    
    LaunchAtLoginController *launchAtLoginController;
    
}

- (void)menuWillOpen:(NSMenu *)menu;

@end