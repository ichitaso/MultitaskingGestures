#import "SpringBoard.h"
#import "Preferences.h"




static SBWorkspace *mainWorkspace;

%hook SBWorkspace

- (id)init {
    self = %orig;
    mainWorkspace = self;
    return self;
}

%end




%subclass HSAppToAppWorkspaceTransaction : SBAppToAppWorkspaceTransaction
- (void)_transactionComplete {
    %orig;
    [[%c(SBWallpaperController) sharedInstance]endRequiringWithReason:@"HSCloseAppGesture"];
}
%end




static void HandleCloseAppGesture(SBUIController *self, SBApplication *frontApp, UIGestureRecognizerState state, CGFloat location, CGFloat velocity) {
    
    static UIView *gestureView;
    
    if (state == UIGestureRecognizerStateBegan) {
        gestureView = [[%c(SBGestureViewVendor) sharedInstance]viewForApp:frontApp gestureType:1 includeStatusBar:YES];
        [gestureView.layer setShadowOpacity:0.8];
        [gestureView.layer setShadowRadius:5];
        [gestureView.layer setShadowOffset:CGSizeMake(0, 10)];
        [gestureView.layer setShadowPath:[[UIBezierPath bezierPathWithRect:gestureView.bounds]CGPath]];
        
        [self _installSystemGestureView:gestureView forKey:frontApp.displayIdentifier forGesture:1];
        [self notifyAppResignActive:frontApp];
        [[%c(SBWallpaperController) sharedInstance]beginRequiringWithReason:@"HSCloseAppGesture"];
        [self restoreContentAndUnscatterIconsAnimated:NO];
    }
    
    else if (state == UIGestureRecognizerStateChanged) {
        CGRect gestureViewFrame = gestureView.frame;
        gestureViewFrame.origin.y = -location;
        [gestureView setFrame:gestureViewFrame];
    }
    
    else if (state == UIGestureRecognizerStateEnded) {
        [UIView animateWithDuration:0.3 animations:^{
            
            CGRect gestureViewFrame = gestureView.frame;
            gestureViewFrame.origin.y = (velocity > 0 ? 0 : -[[UIScreen mainScreen]bounds].size.height);
            [gestureView setFrame:gestureViewFrame];
            
        } completion:^(BOOL finished){
            
            [frontApp.mainScreenContextHostManager disableHostingForRequester:@"LaunchSuspend"];
            [self _clearInstalledSystemGestureViewForKey:frontApp.displayIdentifier];
            
            if (velocity > 0) {
                [self notifyAppResumeActive:frontApp];
                [self stopRestoringIconList];
                [self tearDownIconListAndBar];
            }
            
            else {
                SBWorkspaceEvent *event = [%c(SBWorkspaceEvent) eventWithLabel:@"ActivateSpringBoard" handler:^{
                    SBApplication *frontApp = [(SpringBoard *)[UIApplication sharedApplication]_accessibilityFrontMostApplication];
                    [frontApp setDeactivationSetting:20/*viaSystemGesture*/ flag:YES];
                    [frontApp setDeactivationSetting:2/*animated*/ flag:NO];
                    SBAppToAppWorkspaceTransaction *transaction = [[%c(HSAppToAppWorkspaceTransaction) alloc]initWithWorkspace:mainWorkspace.bksWorkspace alertManager:nil from:frontApp to:nil activationHandler:nil];
                    [mainWorkspace setCurrentTransaction:transaction];
                    [transaction release];
                }];
                [[%c(SBWorkspaceEventQueue) sharedInstance]executeOrAppendEvent:event];
            }
            
        }];
        
    }
}




static BOOL interceptSliderAnimation = NO;
static void (^presentSliderCompletionBlock)() = nil;

%hook SBFSpringAnimationFactory

- (void)animateWithDelay:(NSTimeInterval)delay options:(UIViewAnimationOptions)options animations:(id)animations completion:(id)completion {
    if (interceptSliderAnimation) {
        [presentSliderCompletionBlock release];
        presentSliderCompletionBlock = [completion copy];
        return;
    }
    %orig;
}

%end

static void HandleOpenSliderGesture(SBUIController *self, UIGestureRecognizerState state, CGFloat location, CGFloat velocity) {
    if (state == UIGestureRecognizerStateBegan) {
        interceptSliderAnimation = YES;
        [self _activateAppSwitcherFromSide:2];
        interceptSliderAnimation = NO;
        [[NSNotificationCenter defaultCenter]postNotificationName:@"SBAppSliderAnimatePresentationNotification" object:nil];
    }
    else if (state == UIGestureRecognizerStateChanged) {
        NSMutableDictionary *appList = MSHookIvar<NSMutableDictionary*>(self.switcherController, "_appList");
        UIView *wallpaperView = MSHookIvar<UIView*>(self.switcherController.startingViews[@"com.apple.springboard"], "_wallpaperView");
        CGSize pageSize = [%c(SBAppSwitcherPageView) sizeForOrientation:UIInterfaceOrientationPortrait];
        CGFloat completedHeight = 0.5*([[UIScreen mainScreen]bounds].size.height - pageSize.height);
        CGFloat percentageCompletion = location/completedHeight;
        if (percentageCompletion > 1)
            percentageCompletion = 1 + 0.05*(percentageCompletion-1);
        [self.switcherController _updateForAnimationFrame:(1-percentageCompletion) withAnchor:(appList.count > 1 ? -1 : 0)];
        [wallpaperView setAlpha:percentageCompletion];
    }
    else if (state == UIGestureRecognizerStateEnded) {
        if (velocity > 0) {
            presentSliderCompletionBlock();
            [presentSliderCompletionBlock release];
            presentSliderCompletionBlock = nil;
            [UIView animateWithDuration:0.3 animations:^{
                NSMutableDictionary *appList = MSHookIvar<NSMutableDictionary*>(self.switcherController, "_appList");
                UIView *wallpaperView = MSHookIvar<UIView*>(self.switcherController.startingViews[@"com.apple.springboard"], "_wallpaperView");
                [self.switcherController _updateForAnimationFrame:1 withAnchor:(appList.count > 1 ? -1 : 0)];
                [wallpaperView setAlpha:0];
            } completion:^(BOOL finished) {
                [self dismissSwitcherAnimated:NO];
                [[UIApplication sharedApplication]showSpringBoardStatusBar];
            }];
        }
        else {
            [UIView animateWithDuration:0.3 animations:^{
                UIView *wallpaperView = MSHookIvar<UIView*>(self.switcherController.startingViews[@"com.apple.springboard"], "_wallpaperView");
                [self.switcherController _updateForAnimationFrame:0 withAnchor:0];
                [wallpaperView setAlpha:1];
            } completion:^(BOOL finished) {
                if (presentSliderCompletionBlock) {
                    presentSliderCompletionBlock();
                    [presentSliderCompletionBlock release];
                    presentSliderCompletionBlock = nil;
                }
            }];
        }
    }
}





static BOOL blockCC = NO;

%hook SBUIController

- (id)init {
    if ((self = %orig)) {
        __block typeof(self) bself = self;
        
        RegisterEdgeObserverBlock(UIRectEdgeBottom, ^(CGPoint location){
            if (PreferencesGetSwipeUpEnabled() == NO)
                return NO;
            SBApplication *frontApp = [(SpringBoard *)[UIApplication sharedApplication]_accessibilityFrontMostApplication];
            if (frontApp) {
                if (PreferencesGetSwipeUpActions()&1) {
                    if ([frontApp displayFlag:1] == NO || [frontApp displayFlag:2])
                        return NO;
                    if (PreferencesGetSwipeUpGestureAllowedInApp(frontApp.displayIdentifier) == NO)
                        return NO;
                }
                else
                    return NO;
            }
            else if ((PreferencesGetSwipeUpActions()&2) == NO)
                return NO;
            if (PreferencesGetSwipeUpGestureShouldActivateWithStartingLocation(location) == NO)
                return NO;
            if ([[%c(SBNotificationCenterController) sharedInstance]isVisible])
                return NO;
            if (bself.switcherController.allowShowHide == NO)
                return NO;
            if ([[%c(SBIconController) sharedInstance]isScrolling] || [[%c(SBIconController) sharedInstance]hasAnimatingFolder])
                return NO;
            if ([bself _switcherGestureIsBlockedByAppLaunchOrIgnoringEvents])
                return NO;
            if (bself.isAppSwitcherShowing)
                return NO;
            return YES;
        }, ^(UIGestureRecognizerState state, CGPoint location, CGPoint velocity) {
            
            static float startingY = 0;
            if (state == UIGestureRecognizerStateBegan) {
                startingY = location.y;
                blockCC = YES;
            }
            else if (state == UIGestureRecognizerStateChanged)
                location.y = startingY - location.y;
            else if (state == UIGestureRecognizerStateEnded)
                blockCC = NO;
            
            SBApplication *frontApp = [(SpringBoard *)[UIApplication sharedApplication]_accessibilityFrontMostApplication];
            if (frontApp)
                HandleCloseAppGesture(bself, frontApp, state, location.y, velocity.y);
            else {
                if (MSHookIvar<SBApplication*>(bself, "_pendingAppActivatedByGesture") == nil)
                    HandleOpenSliderGesture(bself, state, location.y, velocity.y);
            }
        });
        
    }
    return self;
}


- (BOOL)allowSystemGestureType:(unsigned int)gestureType atLocation:(CGPoint)location {
    if (gestureType == 0x40 && blockCC)
        return NO;
    return %orig;
}

%end