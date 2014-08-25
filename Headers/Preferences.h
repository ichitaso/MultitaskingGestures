extern "C" BOOL PreferencesGetSwitchAppEnabled();
extern "C" BOOL PreferencesGetSwipeUpEnabled();

extern "C" NSInteger PreferencesGetSwipeUpActions();

extern "C" BOOL PreferencesGetSwitchAppGestureAllowedInApp(NSString *appId);
extern "C" BOOL PreferencesGetSwipeUpGestureAllowedInApp(NSString *appId);

extern "C" BOOL PreferencesGetSwitchAppGestureShouldActivateWithStartingLocation(CGPoint location);
extern "C" BOOL PreferencesGetSwipeUpGestureShouldActivateWithStartingLocation(CGPoint location);