//
//  AboutWindowController.h
//  Shuttle
//
//  Created by Matthew Turner on 1/7/15.
//  Copyright (c) 2015 fitztrev. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AboutWindowController : NSWindowController

@property (strong) NSWindowController *aboutWindow;

@property (strong) IBOutlet NSTextField *appName;
@property (strong) IBOutlet NSTextField *appVersion;
@property (strong) IBOutlet NSTextField *appCopyright;

- (IBAction)btnHomepage:(id)sender;

@end
