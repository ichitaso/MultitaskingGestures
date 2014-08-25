#import "UIKitPrivate.h"

@class BKSWorkspace;

typedef struct {
    int type;
    int modifier;
    NSUInteger pathIndex;
    NSUInteger pathIdentity;
    CGPoint location;
    CGPoint previousLocation;
    CGPoint unrotatedLocation;
    CGPoint previousUnrotatedLocation;
    double totalDistanceTraveled;
    UIInterfaceOrientation interfaceOrientation;
    UIInterfaceOrientation previousInterfaceOrientation;
    double timestamp;
    BOOL isValid;
} SBActiveTouch;

@interface SBAssistantController : NSObject
+ (BOOL)isAssistantVisible;
@end

@interface SBLockScreenView : UIView
@property (readonly, nonatomic) UIScrollView *scrollView;
@end

@interface SBLockScreenManager : NSObject
+ (instancetype)sharedInstance;
@property (readonly) BOOL isUILocked;
@end

@interface SBAppSwitcherPageView : UIView
+ (CGSize)sizeForOrientation:(UIInterfaceOrientation)orientation;
@end

@interface SBHandMotionExtractor : NSObject <_UIScreenEdgePanRecognizerDelegate>
- (void)extractHandMotionForActiveTouches:(SBActiveTouch *)activeTouches count:(NSUInteger)count centroid:(CGPoint)centroid;
- (void)clear;
@end

@interface SBWorkspaceEvent : NSObject
+ (instancetype)eventWithLabel:(NSString *)label handler:(id)handler;
@end

@interface SBWorkspaceEventQueue : NSObject
+ (instancetype)sharedInstance;
- (void)executeOrAppendEvent:(SBWorkspaceEvent *)event;
@end

@interface SBWallpaperController : NSObject
+ (instancetype)sharedInstance;
- (void)endRequiringWithReason:(id)reason;
- (void)beginRequiringWithReason:(id)reason;
@end

@interface SBWindowContextHostManager : NSObject
- (void)disableHostingForRequester:(NSString *)requestor;
@end

@interface SBApplication : NSObject
- (id)_displayFlags;
- (BOOL)displayFlag:(unsigned int)flag;
- (void)setDeactivationSetting:(unsigned int)setting value:(id)value;
- (void)setDeactivationSetting:(unsigned int)setting flag:(BOOL)flag;
@property (copy) NSString *displayIdentifier;
- (SBWindowContextHostManager *)mainScreenContextHostManager;
@end

@interface SBApplicationController : NSObject
+ (instancetype)sharedInstance;
- (SBApplication *)applicationWithDisplayIdentifier:(NSString *)displayId;
@end

@interface SBNotificationCenterController : NSObject
+ (instancetype)sharedInstance;
- (void)dismissAnimated:(BOOL)animated;
@property (readonly, nonatomic, getter=isVisible) BOOL visible;
@end

@interface SBControlCenterController : UIViewController
+ (instancetype)sharedInstance;
- (void)dismissAnimated:(BOOL)animated;
- (BOOL)isVisible;
- (id)_createDynamicAnimationForShow:(BOOL)forShow currentValue:(double)currentValue velocity:(double)velocity unitSize:(double)unitSize;
@end

@interface SBGestureViewVendor : NSObject
+ (instancetype)sharedInstance;
- (UIView *)viewForApp:(SBApplication *)app gestureType:(NSUInteger)gestureType includeStatusBar:(BOOL)includeStatusBar;
- (UIView *)viewForApp:(SBApplication *)app gestureType:(NSUInteger)gestureType includeStatusBar:(BOOL)includeStatusBar decodeImage:(BOOL)decodeImage;
@end

@interface SBSwitchAppGestureView : UIView
- (instancetype)initWithInterfaceOrientation:(UIInterfaceOrientation)orientation startingApp:(SBApplication *)startingApp leftwardApp:(SBApplication *)leftwardApp rightwardApp:(SBApplication *)rightwardApp;
- (void)updatePaging:(CGFloat)amount;
- (void)beginPaging;
@end

@interface SpringBoard : UIApplication
- (SBApplication *)_accessibilityFrontMostApplication;
- (UIInterfaceOrientation)activeInterfaceOrientation;
- (void)noteInterfaceOrientationChanged:(UIInterfaceOrientation)orientation;
- (void)_reloadDemoAndDebuggingDefaultsAndCapabilities;
@end

@interface SBAppSliderController : UIViewController
- (void)_updateForAnimationFrame:(CGFloat)frame withAnchor:(NSUInteger)anchor;
- (void)_updatePageViewScale:(CGFloat)scale xTranslation:(CGFloat)translation;
- (void)_quitAppAtIndex:(unsigned int)index;
- (BOOL)allowShowHide;
@property (retain, nonatomic) NSDictionary *startingViews;
@end

@interface SBUIController : NSObject
- (UIWindow *)window;
- (BOOL)_activateAppSwitcherFromSide:(int)side;
- (void)dismissSwitcherAnimated:(BOOL)animated;
- (SBAppSliderController *)switcherController;
- (BOOL)isAppSwitcherShowing;
- (int)_dismissSheetsAndDetermineAlertStateForMenuClickOrSystemGesture;
- (NSMutableArray *)_calculateSwitchAppList;
- (NSMutableArray *)_makeSwitchAppValidList:(NSMutableArray *)oldList;
- (NSMutableArray *)_makeSwitchAppFilteredList:(NSMutableArray *)switchAppList initialApp:(SBApplication *)initialApp;
- (void)_getSwitchAppPrefetchApps:(NSMutableArray *)switchAppList initialApp:(SBApplication *)initialApp outLeftwardAppIdentifier:(NSString **)leftwardAppId outRightwardAppIdentifier:(NSString **)rightwardAppId;
- (void)_clearPendingAppActivatedByGesture:(BOOL)arg1;
- (void)_lockOrientationForSystemGesture;
- (void)cleanupSwitchAppGestureViews;
- (void)notifyAppResignActive:(SBApplication *)app;
- (void)notifyAppResumeActive:(SBApplication *)app;
- (void)_installSystemGestureView:(UIView *)gestureView forKey:(id<NSCopying>)key forGesture:(NSUInteger)gestureType;
- (void)_clearInstalledSystemGestureViewForKey:(id<NSCopying>)key;
- (void)showSystemGestureBackdrop;
- (void)_setHidden:(BOOL)hidden;
- (BOOL)isAppSwitcherShowing;
- (void)_switchAppGestureBegan:(CGFloat)percentage;
- (void)_switchAppGestureChanged:(CGFloat)percentage;
- (void)_switchAppGestureEndedWithCompletionType:(NSInteger)completionType cumulativePercentage:(CGFloat)percentage;
- (BOOL)allowSystemGestureType:(NSUInteger)type atLocation:(CGPoint)location;
- (void)restoreContentAndUnscatterIconsAnimated:(BOOL)animated;
- (void)stopRestoringIconList;
- (void)tearDownIconListAndBar;
- (void)setFakeSpringBoardStatusBarVisible:(BOOL)visible;
@end

@interface SBOffscreenSwipeGestureRecognizer : NSObject
- (instancetype)initForOffscreenEdge:(UIRectEdge)offscreenEdge;
- (CGPoint)centroidPoint;
@property (nonatomic) BOOL shouldUseUIKitHeuristics;
@property (nonatomic) NSUInteger minTouches;
@property (copy, nonatomic) id canBeginCondition;
@property (nonatomic) BOOL sendsTouchesCancelledToApplication;
@property (copy, nonatomic) id handler;
@property (nonatomic) int state;
@property (nonatomic) NSUInteger types;
@end

@interface SBWorkspace : NSObject
- (SBApplication *)_applicationForBundleIdentifier:(NSString *)identifier frontmost:(BOOL)frontmost;
@property (readonly, nonatomic) BKSWorkspace *bksWorkspace;
@property(retain, nonatomic) id currentTransaction;
@end

@interface SBAppToAppWorkspaceTransaction : NSObject
- (instancetype)initWithWorkspace:(id)workspace alertManager:(id)alertManager from:(SBApplication *)fromApp to:(SBApplication *)toApp activationHandler:(id)activationHandler;
@end

typedef BOOL(^EdgeObserverConditionBlock)(CGPoint location);
typedef void(^EdgeObserverCallbackBlock)(UIGestureRecognizerState state, CGPoint location, CGPoint velocity);
void RegisterEdgeObserverBlock(UIRectEdge edge, EdgeObserverConditionBlock condition, EdgeObserverCallbackBlock observer);

SBApplication *TopActivatingApplication();