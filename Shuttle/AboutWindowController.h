//
//  AboutWindowController.h
//  Shuttle
//
//  Created by Matthew Turner on 5/9/14.
//  Copyright (c) 2014 fitztrev. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AboutWindowController : NSWindowController

@property (strong) NSWindowController *aboutWindow;

@property (strong) IBOutlet NSTextField *appName;
@property (strong) IBOutlet NSTextField *appVersion;
@property (strong) IBOutlet NSTextField *appCopyright;

- (IBAction)btnHomepage:(id)sender;

@end
