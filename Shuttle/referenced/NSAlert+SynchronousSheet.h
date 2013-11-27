//
//  NSAlert+SynchronousSheet.h
//
//  Created by Philipp Mayerhofer on 6/10/11.
//  Copyright 2011 Incredible Bee Ltd. Released under the New BSD License.
//

#import <Cocoa/Cocoa.h>

/**
 * Category to allow NSAlert instances to be run synchronously as sheets.
 */
@interface NSAlert (SynchronousSheet)

/**
 * Runs the receiver modally as an alert sheet attached to a specified window
 * and returns the constant positionally identifying the button clicked.
 *
 * \param aWindow The parent window for the sheet
 *
 * \return Response to the alert. See "Button Return Values" in Apple's NSAlert
 *         documentation.
 */
-(NSInteger) runModalSheetForWindow:(NSWindow *)aWindow;

/**
 * Runs the receiver modally as an alert sheet attached to the main window
 * and returns the constant positionally identifying the button clicked.
 */
-(NSInteger) runModalSheet;

@end
