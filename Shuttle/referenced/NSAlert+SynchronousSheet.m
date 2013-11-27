//
//  NSAlert+SynchronousSheet.h
//
//  Created by Philipp Mayerhofer on 6/10/11.
//  Copyright 2011 Incredible Bee Ltd. Released under the New BSD License.
//

#import "NSAlert+SynchronousSheet.h"


// Private methods -- use prefixes to avoid collisions with Apple's methods
@interface NSAlert (BEPrivateMethods)
-(IBAction) BE_stopSynchronousSheet:(id)sender;   // hide sheet & stop modal
-(void) BE_beginSheetModalForWindow:(NSWindow *)aWindow;
@end


@implementation NSAlert (SynchronousSheet)

-(NSInteger) runModalSheetForWindow:(NSWindow *)aWindow {
	// Set ourselves as the target for button clicks
	for (NSButton *button in [self buttons]) {
		[button setTarget:self];
		[button setAction:@selector(BE_stopSynchronousSheet:)];
	}
	
	// Bring up the sheet and wait until stopSynchronousSheet is triggered by a button click
	[self performSelectorOnMainThread:@selector(BE_beginSheetModalForWindow:) withObject:aWindow waitUntilDone:YES];
	NSInteger modalCode = [NSApp runModalForWindow:[self window]];
	
	// This is called only after stopSynchronousSheet is called (that is,
	// one of the buttons is clicked)
	[NSApp performSelectorOnMainThread:@selector(endSheet:) withObject:[self window] waitUntilDone:YES];
	
	// Remove the sheet from the screen
	[[self window] performSelectorOnMainThread:@selector(orderOut:) withObject:self waitUntilDone:YES];
	
	return modalCode;
}

-(NSInteger) runModalSheet {
	return [self runModalSheetForWindow:[NSApp mainWindow]];
}


#pragma mark Private methods

-(IBAction) BE_stopSynchronousSheet:(id)sender {
	// See which of the buttons was clicked
	NSUInteger clickedButtonIndex = [[self buttons] indexOfObject:sender];
	
	// Be consistent with Apple's documentation (see NSAlert's addButtonWithTitle) so that
	// the fourth button is numbered NSAlertThirdButtonReturn + 1, and so on
	//
	// TODO: handle case when alert created with alertWithMessageText:... where the buttons
	//       have values NSAlertDefaultReturn, NSAlertAlternateReturn, ... instead (see also
	//       the documentation for the runModal method)
	NSInteger modalCode = 0;
	if (clickedButtonIndex == NSAlertFirstButtonReturn)
		modalCode = NSAlertFirstButtonReturn;
	else if (clickedButtonIndex == NSAlertSecondButtonReturn)
		modalCode = NSAlertSecondButtonReturn;
	else if (clickedButtonIndex == NSAlertThirdButtonReturn)
		modalCode = NSAlertThirdButtonReturn;
	else
		modalCode = NSAlertThirdButtonReturn + (clickedButtonIndex - 2);
	
	[NSApp stopModalWithCode:modalCode];
}

-(void) BE_beginSheetModalForWindow:(NSWindow *)aWindow {
	[self beginSheetModalForWindow:aWindow modalDelegate:nil didEndSelector:nil contextInfo:nil];
}

@end
