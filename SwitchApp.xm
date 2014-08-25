#import "SpringBoard.h"
#import "Preferences.h"

static BOOL blockDefaultSwitchAppGesture = NO;

%hook SBUIController

- (id)init {
    if ((self = %orig)) {
        
        __block typeof(self) bself = self;
        
        RegisterEdgeObserverBlock(UIRectEdgeRight, ^(CGPoint location){
            if (PreferencesGetSwitchAppEnabled() == NO)
                return NO;
            SBApplication *frontApp = [(SpringBoard *)[UIApplication sharedApplication]_accessibilityFrontMostApplication];
            if (PreferencesGetSwitchAppGestureAllowedInApp(frontApp.displayIdentifier) == NO)
                return NO;
            if (frontApp == nil && MSHookIvar<SBApplication*>(bself, "_pendingAppActivatedByGesture") == nil)
                return NO;
            if (PreferencesGetSwitchAppGestureShouldActivateWithStartingLocation(location) == NO)
                return NO;
            return (BOOL)([bself allowSystemGestureType:4 atLocation:CGPointZero]);
        }, ^(UIGestureRecognizerState state, CGPoint location, CGPoint velocity) {
            CGSize screenSize = [[UIScreen mainScreen]bounds].size;
            static CGFloat startingPercentage;
            CGFloat percentage;
            percentage = location.x/screenSize.width - 1;
            switch (state) {
                case UIGestureRecognizerStateBegan:
                    blockDefaultSwitchAppGesture = YES;
                    startingPercentage = percentage;
                    [bself _switchAppGestureBegan:0];
                    break;
                case UIGestureRecognizerStateChanged:
                    [bself _switchAppGestureChanged:(percentage-startingPercentage)];
                    break;
                case UIGestureRecognizerStateEnded:
                    [bself _switchAppGestureEndedWithCompletionType:((velocity.x < 0) ? 1 : -1) cumulativePercentage:-0.5];
                    break;
            }
            
        });
        
        RegisterEdgeObserverBlock(UIRectEdgeLeft, ^(CGPoint location){
            if (PreferencesGetSwitchAppEnabled() == NO)
                return NO;
            SBApplication *frontApp = [(SpringBoard *)[UIApplication sharedApplication]_accessibilityFrontMostApplication];
            if (PreferencesGetSwitchAppGestureAllowedInApp(frontApp.displayIdentifier) == NO)
                return NO;
            if (frontApp == nil && MSHookIvar<SBApplication*>(bself, "_pendingAppActivatedByGesture") == nil)
                return NO;
            if (PreferencesGetSwitchAppGestureShouldActivateWithStartingLocation(location) == NO)
                return NO;
            return (BOOL)([bself allowSystemGestureType:4 atLocation:CGPointZero]);
        }, ^(UIGestureRecognizerState state, CGPoint location, CGPoint velocity) {
            static CGFloat startingPercentage;
            CGSize screenSize = [[UIScreen mainScreen]bounds].size;
            CGFloat percentage;
            percentage = location.x/screenSize.width;
            switch (state) {
                case UIGestureRecognizerStateBegan:
                    blockDefaultSwitchAppGesture = YES;
                    startingPercentage = percentage;
                    [bself _switchAppGestureBegan:0];
                    break;
                case UIGestureRecognizerStateChanged:
                    [bself _switchAppGestureChanged:(percentage-startingPercentage)];
                    break;
                case UIGestureRecognizerStateEnded:
                    [bself _switchAppGestureEndedWithCompletionType:((velocity.x > 0) ? 1 : -1) cumulativePercentage:0.5];
                    break;
            }
            
        });
        
    }
    return self;
}

- (void)_switchAppGestureViewAnimationComplete {
    %orig;
    blockDefaultSwitchAppGesture = NO;
}

- (void)handleFluidHorizontalSystemGesture:(id)hey {
    if (blockDefaultSwitchAppGesture)
        return;
    %orig;
}

%end