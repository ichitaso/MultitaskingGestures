#import "UIKitPrivate.h"

static void PreferencesChanged() {
    CFPreferencesAppSynchronize(CFSTR("com.hamzasood.multitaskinggestures"));
}




BOOL PreferencesGetSwitchAppEnabled() {
    Boolean keyExists;
    Boolean enabled = CFPreferencesGetAppBooleanValue(CFSTR("SwitchAppEnabled"), CFSTR("com.hamzasood.multitaskinggestures"), &keyExists);
    return (enabled || !keyExists);
}

BOOL PreferencesGetSwipeUpEnabled() {
    Boolean keyExists;
    Boolean enabled = CFPreferencesGetAppBooleanValue(CFSTR("SwipeUpEnabled"), CFSTR("com.hamzasood.multitaskinggestures"), &keyExists);
    if (enabled || !keyExists) {
        Boolean keyboardDisables = CFPreferencesGetAppBooleanValue(CFSTR("KeyboardDisables"), CFSTR("com.hamzasood.multitaskinggestures"), &keyExists);
        if (keyboardDisables && [UIKeyboard isOnScreen])
            return NO;
        else
            return YES;
    }
    else
        return NO;
}




NSInteger PreferencesGetSwipeUpActions() {
    Boolean keyExists;
    CFIndex actions = CFPreferencesGetAppIntegerValue(CFSTR("SwipeUpActions"), CFSTR("com.hamzasood.multitaskinggestures"), &keyExists);
    return (keyExists ? actions : 3);
}




BOOL PreferencesGetSwitchAppGestureAllowedInApp(NSString *appId) {
    BOOL allowed = YES;
    NSArray *allKeys = (NSArray *)CFPreferencesCopyKeyList(CFSTR("com.hamzasood.multitaskinggestures"), kCFPreferencesCurrentUser, kCFPreferencesCurrentHost);
    for (NSString *key in allKeys) {
        if ([key hasPrefix:@"RestrictSwitchApp-"] && CFPreferencesGetAppBooleanValue((CFStringRef)key, CFSTR("com.hamzasood.multitaskinggestures"), NULL)) {
            NSString *restrictedId = [key substringFromIndex:[@"RestrictSwitchApp-" length]];
            if ([restrictedId isEqual:appId]) {
                allowed = NO;
                break;
            }
        }
    }
    [allKeys release];
    return allowed;
}

BOOL PreferencesGetSwipeUpGestureAllowedInApp(NSString *appId) {
    BOOL allowed = YES;
    NSArray *allKeys = (NSArray *)CFPreferencesCopyKeyList(CFSTR("com.hamzasood.multitaskinggestures"), kCFPreferencesCurrentUser, kCFPreferencesCurrentHost);
    for (NSString *key in allKeys) {
        if ([key hasPrefix:@"RestrictSwipeUp-"] && CFPreferencesGetAppBooleanValue((CFStringRef)key, CFSTR("com.hamzasood.multitaskinggestures"), NULL)) {
            NSString *restrictedId = [key substringFromIndex:[@"RestrictSwipeUp-" length]];
            if ([restrictedId isEqual:appId]) {
                allowed = NO;
                break;
            }
        }
    }
    [allKeys release];
    return allowed;
}




BOOL PreferencesGetSwitchAppGestureShouldActivateWithStartingLocation(CGPoint location) {
    Boolean recogniseOnKeyboard = CFPreferencesGetAppBooleanValue(CFSTR("RecogniseOnKeyboardEdges"), CFSTR("com.hamzasood.multitaskinggestures"), NULL);
    if (!recogniseOnKeyboard && [UIKeyboard isOnScreen] && CGRectContainsPoint([UIKeyboard defaultFrameForInterfaceOrientation:UIInterfaceOrientationPortrait], location))
        return NO;
    CFIndex edgeSetting = CFPreferencesGetAppIntegerValue(CFSTR("SwitchAppRecognitionArea"), CFSTR("com.hamzasood.multitaskinggestures"), NULL);
    if (edgeSetting == 0)
        return YES;
    else {
        CGFloat screenHeight = [[UIScreen mainScreen]bounds].size.height;
        if (edgeSetting == 1)
            return (location.y < screenHeight*0.5);
        else if (edgeSetting == 2)
            return (location.y > screenHeight*0.5);
        else
            return NO;
    }
}

BOOL PreferencesGetSwipeUpGestureShouldActivateWithStartingLocation(CGPoint location) {
    CFIndex edgeSetting = CFPreferencesGetAppIntegerValue(CFSTR("SwipeUpRecognitionArea"), CFSTR("com.hamzasood.multitaskinggestures"), NULL);
    if (edgeSetting == 0)
        return YES;
    else {
        CGFloat screenWidth = [[UIScreen mainScreen]bounds].size.width;
        if (edgeSetting == 1)
            return (location.x < screenWidth*0.5);
        else if (edgeSetting == 2)
            return (location.x > screenWidth*0.5);
        else
            return NO;
    }
}




BOOL PreferencesGetPadGesturesEnabled() {
    Boolean keyExists;
    Boolean enabled = CFPreferencesGetAppBooleanValue(CFSTR("PadGesturesEnabled"), CFSTR("com.hamzasood.multitaskinggestures"), &keyExists);
    return (enabled || !keyExists);
}

BOOL PreferencesGetPadGesturesShouldActivateWithThreeFingers() {
    Boolean keyExists;
    Boolean enabled = CFPreferencesGetAppBooleanValue(CFSTR("PadGesturesShouldActivateWithThreeFingers"), CFSTR("com.hamzasood.multitaskinggestures"), &keyExists);
    return (enabled || !keyExists);
}




__attribute__((constructor)) static void PreferencesInit() {
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)PreferencesChanged, CFSTR("com.hamzasood.multitaskinggestures-preferecesChanged"), NULL, CFNotificationSuspensionBehaviorCoalesce);
}