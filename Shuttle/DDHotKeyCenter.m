/*
 DDHotKey -- DDHotKeyCenter.m
 
 Copyright (c) 2012, Dave DeLong <http://www.davedelong.com>
 
 Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is hereby granted, provided that the above copyright notice and this permission notice appear in all copies.
 
 The software is  provided "as is", without warranty of any kind, including all implied warranties of merchantability and fitness. In no event shall the author(s) or copyright holder(s) be liable for any claim, damages, or other liability, whether in an action of contract, tort, or otherwise, arising from, out of, or in connection with the software or the use or other dealings in the software.
 */

#import "DDHotKeyCenter.h"
#import <Carbon/Carbon.h>
#import <objc/runtime.h>

#if __has_feature(objc_arc)

#define DDHK_HAS_ARC 1
#define DDHK_RETAIN(_o) (_o)
#define DDHK_RELEASE(_o)
#define DDHK_AUTORELEASE(_o) (_o)

#else

#define DDHK_HAS_ARC 0
#define DDHK_RETAIN(_o) [(_o) retain]
#define DDHK_RELEASE(_o) [(_o) release]
#define DDHK_AUTORELEASE(_o) [(_o) autorelease]

#endif

#pragma mark Private Global Declarations

OSStatus dd_hotKeyHandler(EventHandlerCallRef nextHandler, EventRef theEvent, void *userData);
UInt32 dd_translateModifierFlags(NSUInteger flags);

#pragma mark DDHotKey

@interface DDHotKey ()

@property (nonatomic, retain) NSValue *hotKeyRef;
@property (nonatomic) UInt32 hotKeyID;

@end

@implementation DDHotKey {
    id _target;
    SEL _action;
    id _object;
    
    unsigned short _keyCode;
    NSUInteger _modifierFlags;
    DDHotKeyTask _task;
}

- (void) dealloc {
    [[DDHotKeyCenter sharedHotKeyCenter] unregisterHotKey:self];
#if !DDHK_HAS_ARC
    DDHK_RELEASE(_target); _target = nil;
    DDHK_RELEASE(_object); _object = nil;
    DDHK_RELEASE(_hotKeyRef); _hotKeyRef = nil;
    DDHK_RELEASE(_task); _task = nil;
    [super dealloc];
#endif
}

- (void)_setTarget:(id)target {
    if (target != _target) {
        DDHK_RELEASE(_target);
        _target = DDHK_RETAIN(target);
    }
}

- (void)_setAction:(SEL)action {
    _action = action;
}

- (void)_setObject:(id)object {
    if (object != _object) {
        DDHK_RELEASE(_object);
        _object = DDHK_RETAIN(object);
    }
}

- (void)_setKeyCode:(unsigned short)keyCode {
    _keyCode = keyCode;
}

- (void)_setModifierFlags:(NSUInteger)modifierFlags {
    _modifierFlags = modifierFlags;
}

- (void)_setTask:(DDHotKeyTask)task {
    DDHK_RELEASE(_task);
    _task = [task copy];
}

- (NSUInteger)hash {
    return [self keyCode] ^ [self modifierFlags];
}

- (BOOL)isEqual:(id)object {
    BOOL equal = NO;
    if ([object isKindOfClass:[DDHotKey class]]) {
        equal = ([object keyCode] == [self keyCode]);
        equal &= ([object modifierFlags] == [self modifierFlags]);
    }
    return equal;
}

- (NSString *)description {
    NSMutableArray *bits = [NSMutableArray array];
    if ((_modifierFlags & NSControlKeyMask) > 0) { [bits addObject:@"NSControlKeyMask"]; }
    if ((_modifierFlags & NSCommandKeyMask) > 0) { [bits addObject:@"NSCommandKeyMask"]; }
    if ((_modifierFlags & NSShiftKeyMask) > 0) { [bits addObject:@"NSShiftKeyMask"]; }
    if ((_modifierFlags & NSAlternateKeyMask) > 0) { [bits addObject:@"NSAlternateKeyMask"]; }
    
    NSString *flags = [NSString stringWithFormat:@"(%@)", [bits componentsJoinedByString:@" | "]];
    NSString *invokes = @"(block)";
    if ([self target] != nil && [self action] != nil) {
        invokes = [NSString stringWithFormat:@"[%@ %@]", [self target], NSStringFromSelector([self action])];
    }
    return [NSString stringWithFormat:@"%@\n\t(key: %hu\n\tflags: %@\n\tinvokes: %@)", [super description], [self keyCode], flags, invokes];
}

- (void)invokeWithEvent:(NSEvent *)event {
    if (_target != nil && _action != nil && [_target respondsToSelector:_action]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [_target performSelector:_action withObject:event withObject:_object];
#pragma clang diagnostic pop
    } else if (_task != nil) {
        _task(event);
    }
}

- (NSString *)actionString {
    return NSStringFromSelector(_action);
}

@end

#pragma mark DDHotKeyCenter

static DDHotKeyCenter *center = nil;

@implementation DDHotKeyCenter {
    NSMutableSet *_registeredHotKeys;
    UInt32 _nextHotKeyID;
}

+ (id)sharedHotKeyCenter {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        center = [[DDHotKeyCenter _alloc] _init];
    });
    return center;
}

+ (id)_alloc {
    return [super allocWithZone:nil];
}

+ (id)allocWithZone:(NSZone *)zone {
    return DDHK_RETAIN([self sharedHotKeyCenter]);
}

- (id)_init {
    self = [super init];
    if (self) {
        _registeredHotKeys = [[NSMutableSet alloc] init];
        _nextHotKeyID = 1;
        
		EventTypeSpec eventSpec;
		eventSpec.eventClass = kEventClassKeyboard;
		eventSpec.eventKind = kEventHotKeyReleased;
		InstallApplicationEventHandler(&dd_hotKeyHandler, 1, &eventSpec, NULL, NULL);
    }
    return self;
}

- (NSSet *)hotKeysMatchingPredicate:(NSPredicate *)predicate {
    return [_registeredHotKeys filteredSetUsingPredicate:predicate];
}

- (BOOL)hasRegisteredHotKeyWithKeyCode:(unsigned short)keyCode modifierFlags:(NSUInteger)flags {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"keyCode = %hu AND modifierFlags = %lu", keyCode, flags];
    return ([[self hotKeysMatchingPredicate:predicate] count] > 0);
}

- (BOOL)_registerHotKey:(DDHotKey *)hotKey {
    EventHotKeyID keyID;
    keyID.signature = 'htk1';
    keyID.id = _nextHotKeyID;
    
    EventHotKeyRef carbonHotKey;
    UInt32 flags = dd_translateModifierFlags([hotKey modifierFlags]);
    OSStatus err = RegisterEventHotKey([hotKey keyCode], flags, keyID, GetEventDispatcherTarget(), 0, &carbonHotKey);
    
    //error registering hot key
    if (err != 0) { return NO; }
    
    NSValue *refValue = [NSValue valueWithPointer:carbonHotKey];
    [hotKey setHotKeyRef:refValue];
    [hotKey setHotKeyID:_nextHotKeyID];
    
    _nextHotKeyID++;
    [_registeredHotKeys addObject:hotKey];
    
    return YES;
}

- (void)unregisterHotKey:(DDHotKey *)hotKey {
    NSValue *hotKeyRef = [hotKey hotKeyRef];
    if (hotKeyRef) {
        EventHotKeyRef carbonHotKey = (EventHotKeyRef)[hotKeyRef pointerValue];
        UnregisterEventHotKey(carbonHotKey);
        [hotKey setHotKeyRef:nil];
        
        [_registeredHotKeys removeObject:hotKey];
    }
}

- (BOOL)registerHotKeyWithKeyCode:(unsigned short)keyCode modifierFlags:(NSUInteger)flags task:(DDHotKeyTask)task {
    //we can't add a new hotkey if something already has this combo
    if ([self hasRegisteredHotKeyWithKeyCode:keyCode modifierFlags:flags]) { return NO; }
    
    DDHotKey *newHotKey = DDHK_AUTORELEASE([[DDHotKey alloc] init]);
    [newHotKey _setTask:task];
    [newHotKey _setKeyCode:keyCode];
    [newHotKey _setModifierFlags:flags];
    
    return [self _registerHotKey:newHotKey];
}

- (BOOL)registerHotKeyWithKeyCode:(unsigned short)keyCode modifierFlags:(NSUInteger)flags target:(id)target action:(SEL)action object:(id)object {
    //we can't add a new hotkey if something already has this combo
    if ([self hasRegisteredHotKeyWithKeyCode:keyCode modifierFlags:flags]) { return NO; }
    
    //build the hotkey object:
    DDHotKey *newHotKey = DDHK_AUTORELEASE([[DDHotKey alloc] init]);
    [newHotKey _setTarget:target];
    [newHotKey _setAction:action];
    [newHotKey _setObject:object];
    [newHotKey _setKeyCode:keyCode];
    [newHotKey _setModifierFlags:flags];
    return [self _registerHotKey:newHotKey];
}

- (void)unregisterHotKeysMatchingPredicate:(NSPredicate *)predicate {
    //explicitly unregister the hotkey, since relying on the unregistration in -dealloc can be problematic
    @autoreleasepool {
        NSSet *matches = [self hotKeysMatchingPredicate:predicate];
        for (DDHotKey *hotKey in matches) {
            [self unregisterHotKey:hotKey];
        }
    }
}

- (void)unregisterHotKeysWithTarget:(id)target {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"target = %@", target];
    [self unregisterHotKeysMatchingPredicate:predicate];
}

- (void)unregisterHotKeysWithTarget:(id)target action:(SEL)action {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"target = %@ AND actionString = %@", target, NSStringFromSelector(action)];
    [self unregisterHotKeysMatchingPredicate:predicate];
}

- (void)unregisterHotKeyWithKeyCode:(unsigned short)keyCode modifierFlags:(NSUInteger)flags {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"keyCode = %hu AND modifierFlags = %lu", keyCode, flags];
    [self unregisterHotKeysMatchingPredicate:predicate];
}

- (void)unregisterAllHotKeys {
    NSSet *keys = [_registeredHotKeys copy];
    for (DDHotKey *key in keys) {
        [self unregisterHotKey:key];
    }
    DDHK_RELEASE(keys);
}

- (NSSet *)registeredHotKeys {
    return [self hotKeysMatchingPredicate:[NSPredicate predicateWithFormat:@"hotKeyRef != NULL"]];
}

@end

OSStatus dd_hotKeyHandler(EventHandlerCallRef nextHandler, EventRef theEvent, void *userData) {
    @autoreleasepool {
        EventHotKeyID hotKeyID;
        GetEventParameter(theEvent, kEventParamDirectObject, typeEventHotKeyID, NULL, sizeof(hotKeyID),NULL,&hotKeyID);
        
        UInt32 keyID = hotKeyID.id;
        
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"hotKeyID = %u", keyID];
        NSSet *matchingHotKeys = [[DDHotKeyCenter sharedHotKeyCenter] hotKeysMatchingPredicate:predicate];
        if ([matchingHotKeys count] > 1) { NSLog(@"ERROR!"); }
        DDHotKey *matchingHotKey = [matchingHotKeys anyObject];
        
        NSEvent *event = [NSEvent eventWithEventRef:theEvent];
        NSEvent *keyEvent = [NSEvent keyEventWithType:NSKeyUp
                                             location:[event locationInWindow]
                                        modifierFlags:[event modifierFlags]
                                            timestamp:[event timestamp]
                                         windowNumber:-1
                                              context:nil
                                           characters:@""
                          charactersIgnoringModifiers:@""
                                            isARepeat:NO
                                              keyCode:[matchingHotKey keyCode]];
        
        [matchingHotKey invokeWithEvent:keyEvent];
    }
    
    return noErr;
}

UInt32 dd_translateModifierFlags(NSUInteger flags) {
    UInt32 newFlags = 0;
    if ((flags & NSControlKeyMask) > 0) { newFlags |= controlKey; }
    if ((flags & NSCommandKeyMask) > 0) { newFlags |= cmdKey; }
    if ((flags & NSShiftKeyMask) > 0) { newFlags |= shiftKey; }
    if ((flags & NSAlternateKeyMask) > 0) { newFlags |= optionKey; }
    return newFlags;
}
