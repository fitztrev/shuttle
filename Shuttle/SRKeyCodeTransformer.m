//
//  SRKeyCodeTransformer.h
//  ShortcutRecorder
//
//  Copyright 2006-2007 Contributors. All rights reserved.
//
//  License: BSD
//
//  Contributors:
//      David Dauer
//      Jesper
//      Jamie Kirkpatrick

#import "SRKeyCodeTransformer.h"
#import <Carbon/Carbon.h>
#import <CoreServices/CoreServices.h>
#import "SRCommon.h"

static NSMutableDictionary  *stringToKeyCodeDict = nil;
static NSDictionary         *keyCodeToStringDict = nil;
static NSArray              *padKeysArray        = nil;

@interface SRKeyCodeTransformer( Private )
+ (void) regenerateStringToKeyCodeMapping;
@end

#pragma mark -

@implementation SRKeyCodeTransformer

//----------------------------------------------------------
//  initialize
//----------------------------------------------------------
+ (void) initialize;
{
    if ( self != [SRKeyCodeTransformer class] )
        return;
    
    // Some keys need a special glyph
    keyCodeToStringDict = [[NSDictionary alloc] initWithObjectsAndKeys:
                           @"F1", SRInt(122),
                           @"F2", SRInt(120),
                           @"F3", SRInt(99),
                           @"F4", SRInt(118),
                           @"F5", SRInt(96),
                           @"F6", SRInt(97),
                           @"F7", SRInt(98),
                           @"F8", SRInt(100),
                           @"F9", SRInt(101),
                           @"F10", SRInt(109),
                           @"F11", SRInt(103),
                           @"F12", SRInt(111),
                           @"F13", SRInt(105),
                           @"F14", SRInt(107),
                           @"F15", SRInt(113),
                           @"F16", SRInt(106),
                           @"F17", SRInt(64),
                           @"F18", SRInt(79),
                           @"F19", SRInt(80),
                           SRLoc(@"Space"), SRInt(49),
                           SRChar(KeyboardDeleteLeftGlyph), SRInt(51),
                           SRChar(KeyboardDeleteRightGlyph), SRInt(117),
                           SRChar(KeyboardPadClearGlyph), SRInt(71),
                           SRChar(KeyboardLeftArrowGlyph), SRInt(123),
                           SRChar(KeyboardRightArrowGlyph), SRInt(124),
                           SRChar(KeyboardUpArrowGlyph), SRInt(126),
                           SRChar(KeyboardDownArrowGlyph), SRInt(125),
                           SRChar(KeyboardSoutheastArrowGlyph), SRInt(119),
                           SRChar(KeyboardNorthwestArrowGlyph), SRInt(115),
                           SRChar(KeyboardEscapeGlyph), SRInt(53),
                           SRChar(KeyboardPageDownGlyph), SRInt(121),
                           SRChar(KeyboardPageUpGlyph), SRInt(116),
                           SRChar(KeyboardReturnR2LGlyph), SRInt(36),
                           SRChar(KeyboardReturnGlyph), SRInt(76),
                           SRChar(KeyboardTabRightGlyph), SRInt(48),
                           SRChar(KeyboardHelpGlyph), SRInt(114),
                           nil];
    
    // We want to identify if the key was pressed on the numpad
    padKeysArray = [[NSArray alloc] initWithObjects:
                    SRInt(65), // ,
                    SRInt(67), // *
                    SRInt(69), // +
                    SRInt(75), // /
                    SRInt(78), // -
                    SRInt(81), // =
                    SRInt(82), // 0
                    SRInt(83), // 1
                    SRInt(84), // 2
                    SRInt(85), // 3
                    SRInt(86), // 4
                    SRInt(87), // 5
                    SRInt(88), // 6
                    SRInt(89), // 7
                    SRInt(91), // 8
                    SRInt(92), // 9
                    nil];
    
    // generate the string to keycode mapping dict...
    stringToKeyCodeDict = [[NSMutableDictionary alloc] init];
    [self regenerateStringToKeyCodeMapping];
    
    [[NSDistributedNotificationCenter defaultCenter] addObserver:self selector:@selector(regenerateStringToKeyCodeMapping) name:(NSString*)kTISNotifySelectedKeyboardInputSourceChanged object:nil];
}

//----------------------------------------------------------
//  allowsReverseTransformation
//----------------------------------------------------------
+ (BOOL) allowsReverseTransformation
{
    return YES;
}

//----------------------------------------------------------
//  transformedValueClass
//----------------------------------------------------------
+ (Class) transformedValueClass;
{
    return [NSString class];
}


//----------------------------------------------------------
//  init
//----------------------------------------------------------
- (id)init
{
    if((self = [super init]))
    {
    }
    return self;
}

//----------------------------------------------------------
//  dealloc
//----------------------------------------------------------
- (void)dealloc
{
    [super dealloc];
}

//----------------------------------------------------------
//  transformedValue:
//----------------------------------------------------------
- (id) transformedValue:(id)value
{
    if ( ![value isKindOfClass:[NSNumber class]] )
        return nil;
    
    // Can be -1 when empty
    NSInteger keyCode = [value shortValue];
    if ( keyCode < 0 ) return nil;
    
    // We have some special gylphs for some special keys...
    NSString *unmappedString = [keyCodeToStringDict objectForKey: SRInt( keyCode )];
    if ( unmappedString != nil ) return unmappedString;
    
    BOOL isPadKey = [padKeysArray containsObject: SRInt( keyCode )];
    
    OSStatus err;
    TISInputSourceRef tisSource = TISCopyCurrentKeyboardInputSource();
    if(!tisSource) return nil;
    
    CFDataRef layoutData;
    UInt32 keysDown = 0;
    layoutData = (CFDataRef)TISGetInputSourceProperty(tisSource, kTISPropertyUnicodeKeyLayoutData);
    
    CFRelease(tisSource);
    
    // For non-unicode layouts such as Chinese, Japanese, and Korean, get the ASCII capable layout
    if(!layoutData) {
        tisSource = TISCopyCurrentASCIICapableKeyboardLayoutInputSource();
        layoutData = (CFDataRef)TISGetInputSourceProperty(tisSource, kTISPropertyUnicodeKeyLayoutData);
        CFRelease(tisSource);
    }
    
    if (!layoutData) return nil;
    
    const UCKeyboardLayout *keyLayout = (const UCKeyboardLayout *)CFDataGetBytePtr(layoutData);
    
    UniCharCount length = 4, realLength;
    UniChar chars[4];
    
    err = UCKeyTranslate( keyLayout,
                         keyCode,
                         kUCKeyActionDisplay,
                         0,
                         LMGetKbdType(),
                         kUCKeyTranslateNoDeadKeysBit,
                         &keysDown,
                         length,
                         &realLength,
                         chars);
    
    if ( err != noErr ) return nil;
    
    NSString *keyString = [[NSString stringWithCharacters:chars length:1] uppercaseString];
    
    return ( isPadKey ? [NSString stringWithFormat: SRLoc(@"Pad %@"), keyString] : keyString );
}

//----------------------------------------------------------
//  reverseTransformedValue:
//----------------------------------------------------------
- (id) reverseTransformedValue:(id)value
{
    if ( ![value isKindOfClass:[NSString class]] )
        return nil;
    
    // try and retrieve a mapped keycode from the reverse mapping dict...
    return [stringToKeyCodeDict objectForKey:value];
}

@end

#pragma mark -

@implementation SRKeyCodeTransformer( Private )

//----------------------------------------------------------
//  regenerateStringToKeyCodeMapping:
//----------------------------------------------------------
+ (void) regenerateStringToKeyCodeMapping;
{
    SRKeyCodeTransformer *transformer = [[[self alloc] init] autorelease];
    [stringToKeyCodeDict removeAllObjects];
    
    // loop over every keycode (0 - 127) finding its current string mapping...
    NSUInteger i;
    for ( i = 0U; i < 128U; i++ )
    {
        NSNumber *keyCode = [NSNumber numberWithUnsignedInteger:i];
        NSString *string = [transformer transformedValue:keyCode];
        if ( ( string ) && ( [string length] ) )
        {
            [stringToKeyCodeDict setObject:keyCode forKey:string];
        }
    }
}

@end
