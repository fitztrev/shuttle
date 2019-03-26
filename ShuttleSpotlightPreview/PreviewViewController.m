//
//  PreviewViewController.m
//  ShuttleSpotlightPreview
//
//  Created by Arthur B Olsen on 3/25/19.
//  Copyright © 2019 fitztrev. All rights reserved.
//

#import "PreviewViewController.h"
#import <Quartz/Quartz.h>

@interface PreviewViewController () <QLPreviewingController> {
    IBOutlet NSTextField *label;
    IBOutlet NSTextField *command;
}

@end

@implementation PreviewViewController

- (NSString *)nibName {
    return @"PreviewViewController";
}

- (void)loadView {
    [super loadView];
    // Do any additional setup after loading the view from its nib.
}

- (void)preparePreviewOfSearchableItemWithIdentifier:(NSString *)identifier queryString:(NSString *)queryString completionHandler:(void (^)(NSError * _Nullable))handler {
    NSArray *objectsFromJSON = [identifier componentsSeparatedByString:(@"¬_¬")];
    if([objectsFromJSON count] > 3) {
        [label setStringValue:[objectsFromJSON objectAtIndex:2]];
        
        [command setStringValue:[objectsFromJSON objectAtIndex:0]];
    }
    handler(nil);
}

@end

