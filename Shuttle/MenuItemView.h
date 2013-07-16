//
//  MenuItemView.h
//  Shuttle
//
//  Created by Andreas Haufler on 16.07.13.
//  Copyright (c) 2013 scturtle. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MenuItemView : NSView <NSMenuDelegate> {
    NSStatusItem *statusItem;
    BOOL highlight;
    NSImage* image;
    NSImage* alternateImage;
}
- (void)setImage:(NSImage*)image;
- (void)setAlternateImage:(NSImage*)image;
- (void)setStatusItem:(NSStatusItem*)item;
@end
