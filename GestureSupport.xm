#import "SpringBoard.h"
#import "Preferences.h"

static NSInteger shouldForcePadIdiom = 0;

%hook UIDevice

- (UIUserInterfaceIdiom)userInterfaceIdiom {
    if (shouldForcePadIdiom > 0)
        return UIUserInterfaceIdiomPad;
    else
        return %orig;
}

%end

static void DoForceReloadGestureStuff() {
    shouldForcePadIdiom++;
    [(SpringBoard *)[UIApplication sharedApplication]_reloadDemoAndDebuggingDefaultsAndCapabilities];
    shouldForcePadIdiom--;
}




%hook SpringBoard

- (void)loadDebuggingAndDemoPrefs {
    if (shouldForcePadIdiom > 1)
        return;
    else
        %orig;
}

- (void)debuggingAndDemoPrefsWereChanged {
    if (shouldForcePadIdiom > 1)
        return;
    else
        %orig;
}

- (void)_reloadDemoAndDebuggingDefaultsAndCapabilities {
    shouldForcePadIdiom++;
    %orig;
    shouldForcePadIdiom--;
}

- (void)applicationDidFinishLaunching:(UIApplication *)application {
    %orig;
    DoForceReloadGestureStuff();
}

- (void)noteInterfaceOrientationChanged:(UIInterfaceOrientation)orientation duration:(CGFloat)duration updateMirroredDisplays:(BOOL)updateMirroredDisplays force:(BOOL)force {
    %orig;
    DoForceReloadGestureStuff();
}

- (void)_accessibilitySetSystemGesturesDisabledByAccessibility:(BOOL)aBool {
    %orig;
    DoForceReloadGestureStuff();
}

%end


%hook SBUIController

- (id)init {
    id retval = %orig;
    DoForceReloadGestureStuff();
    return retval;
}

- (void)cleanupRunningGestureIfNeeded {
    %orig;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.25 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        DoForceReloadGestureStuff();
    });
}

%end




//%hook SBTouchTemplate
//
//- (id)initWithPoints:(CGPoint *)points count:(NSUInteger)count {
//    if (count == 5)
//        count = 3;
//    return %orig;
//}
//
//%end




extern "C" BOOL MGGetBoolAnswer(CFStringRef question);
static BOOL (*orig_GetBoolAnswer)(CFStringRef question);
BOOL replaced_GetBoolAnswer(CFStringRef question) {
    if (CFStringCompare(question, CFSTR("multitasking-gestures"), 0) == kCFCompareEqualTo)
        return YES;
    else
        return orig_GetBoolAnswer(question);
}

static CFPropertyListRef (*orig_CopyAppValue)(CFStringRef key, CFStringRef applicationId);
CFPropertyListRef replaced_CopyAppValue(CFStringRef key, CFStringRef applicationId) {
    if (CFStringCompare(key, CFSTR("SBUseSystemGestures"), 0) == kCFCompareEqualTo)
        return [@YES copy];
    else
        return orig_CopyAppValue(key, applicationId);
}

%ctor {
    %init;
    MSHookFunction((void *)MGGetBoolAnswer, (void *)replaced_GetBoolAnswer, (void **)&orig_GetBoolAnswer);
    MSHookFunction((void *)CFPreferencesCopyAppValue, (void *)replaced_CopyAppValue, (void **)&orig_CopyAppValue);
}