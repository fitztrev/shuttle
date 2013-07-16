//
//  MenuItemView.m
//  Shuttle
//
//  Created by Andreas Haufler on 16.07.13.
//  Copyright (c) 2013 scturtle. All rights reserved.
//

#import "MenuItemView.h"

@implementation MenuItemView


- (void)setImage:(NSImage*)img {
    image = img;
}

- (void)setAlternateImage:(NSImage*)img {
    alternateImage = img;
}

- (void)setStatusItem:(NSStatusItem*)item {
    statusItem = item;
}

- (void)setMenu:(NSMenu *)menu {
    [menu setDelegate:self];
    [super setMenu:menu];
}

- (void)mouseDown:(NSEvent *)event {
    [statusItem popUpStatusItemMenu:[self menu]]; // or another method that returns a menu
}

- (void)menuWillOpen:(NSMenu *)menu {
    highlight = YES;
}

- (void)menuDidClose:(NSMenu *)menu {
    highlight = NO;
}

- (void)drawRect:(NSRect)rect {
    NSImage *img = highlight ? [alternateImage copy] : [image copy];
    NSRect bounds = [self bounds];
    [statusItem drawStatusBarBackgroundInRect:bounds withHighlight:YES];
    [img drawInRect: bounds fromRect:NSZeroRect operation:NSCompositeSourceOver fraction: 1];

    // rest of drawing code goes here, including drawing img where appropriate
}
@end
