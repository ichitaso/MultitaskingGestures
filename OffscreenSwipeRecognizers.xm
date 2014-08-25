#import "BackBoardServices.h"
#import "SpringBoard.h"
#import "UIKitPrivate.h"




%hook _UIScreenEdgePanRecognizer

static char LastLocationKey;
static char LastTimestampKey;
static char VelocityKey;

- (void)incorporateTouchSampleAtLocation:(CGPoint)location timestamp:(double)timestamp modifier:(NSInteger)modifier interfaceOrientation:(UIInterfaceOrientation)orientation {
    %orig;
    
    CGPoint lastLocation = CGPointZero;
    if (NSValue *lastLocationValue = objc_getAssociatedObject(self, &LastLocationKey))
        lastLocation = lastLocationValue.CGPointValue;
        
    double lastTimestamp = 0;
    if (NSNumber *lastTimestampValue = objc_getAssociatedObject(self, &LastTimestampKey))
        lastTimestamp = lastTimestampValue.doubleValue;
    
    CGPoint velocity = CGPointMake((location.x-lastLocation.x)/(timestamp-lastTimestamp), (location.y-lastLocation.y)/(timestamp-lastTimestamp));
    objc_setAssociatedObject(self, &VelocityKey, [NSValue valueWithCGPoint:velocity], OBJC_ASSOCIATION_COPY_NONATOMIC);
    
    objc_setAssociatedObject(self, &LastLocationKey, [NSValue valueWithCGPoint:location], OBJC_ASSOCIATION_COPY_NONATOMIC);
    objc_setAssociatedObject(self, &LastTimestampKey, @(timestamp), OBJC_ASSOCIATION_COPY_NONATOMIC);
}

%new
- (CGPoint)_velocity {
    CGPoint velocity = CGPointZero;
    if (NSValue *velocityValue = objc_getAssociatedObject(self, &VelocityKey))
        velocity = velocityValue.CGPointValue;
    return velocity;
}

%end




static NSMutableDictionary *edgeObserverConditions;
static NSMutableDictionary *edgeObserverCallbacks;
void RegisterEdgeObserverBlock(UIRectEdge edge, EdgeObserverConditionBlock condition, EdgeObserverCallbackBlock callback) {
    if (condition)
        [edgeObserverConditions setObject:[[condition copy]autorelease] forKey:@(edge)];
    else
        [edgeObserverConditions removeObjectForKey:@(edge)];
    if (callback)
        [edgeObserverCallbacks setObject:[[callback copy]autorelease] forKey:@(edge)];
    else
        [edgeObserverCallbacks removeObjectForKey:@(edge)];
}




%hook SBHandMotionExtractor

static BOOL isTracking = NO;
static NSMutableSet *gestureRecognizers;
static _UIScreenEdgePanRecognizer *recognizerToTrack;

- (id)init {
    if ((self = %orig)) {
        for (_UIScreenEdgePanRecognizer *recognizer in gestureRecognizers)
            [recognizer setDelegate:self];
    }
    return self;
}

- (void)extractHandMotionForActiveTouches:(SBActiveTouch *)activeTouches count:(NSUInteger)count centroid:(CGPoint)centroid {
    %orig;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (count) {
            SBActiveTouch touch = activeTouches[0];
            if (touch.type == 0) {
                //Touches Began
                for (_UIScreenEdgePanRecognizer *recognizer in gestureRecognizers)
                    [recognizer incorporateTouchSampleAtLocation:touch.unrotatedLocation timestamp:CACurrentMediaTime() modifier:touch.modifier interfaceOrientation:touch.interfaceOrientation];
                isTracking = YES;
            }
            else if (isTracking) {
                //Touches Moved
                for (_UIScreenEdgePanRecognizer *recognizer in gestureRecognizers) {
                    [recognizer incorporateTouchSampleAtLocation:touch.unrotatedLocation timestamp:CACurrentMediaTime() modifier:touch.modifier interfaceOrientation:touch.interfaceOrientation];
                    if (recognizer == recognizerToTrack) {
                        EdgeObserverCallbackBlock callback = edgeObserverCallbacks[@(recognizer.targetEdges)];
                        if (callback)
                            callback(UIGestureRecognizerStateChanged, touch.location, recognizer._velocity);
                    }
                }
            }
        }
    });
}

%new
- (void)screenEdgePanRecognizerStateDidChange:(_UIScreenEdgePanRecognizer *)screenEdgePanRecognizer {
    if (screenEdgePanRecognizer.state == 1) {
        CGPoint location = MSHookIvar<CGPoint>(screenEdgePanRecognizer, "_lastTouchLocation");
        if (recognizerToTrack == nil) {
            EdgeObserverConditionBlock condition = edgeObserverConditions[@(screenEdgePanRecognizer.targetEdges)];
            if (condition && condition(location) && [(SpringBoard *)[UIApplication sharedApplication]activeInterfaceOrientation] == UIInterfaceOrientationPortrait)
                recognizerToTrack = screenEdgePanRecognizer;
        }
        if (screenEdgePanRecognizer == recognizerToTrack) {
            EdgeObserverCallbackBlock callback = edgeObserverCallbacks[@(screenEdgePanRecognizer.targetEdges)];
            if (callback) {
                callback(UIGestureRecognizerStateBegan, location, screenEdgePanRecognizer._velocity);
                BKSHIDServicesCancelTouchesOnMainDisplay();
            }
        }
    }
}

- (void)clear {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (isTracking) {
            //Touches ended
            for (_UIScreenEdgePanRecognizer *recognizer in gestureRecognizers) {
                if (recognizer == recognizerToTrack) {
                    EdgeObserverCallbackBlock callback = edgeObserverCallbacks[@(recognizer.targetEdges)];
                    if (callback)
                        callback(UIGestureRecognizerStateEnded, CGPointZero, recognizer._velocity);
                }
                [recognizer reset];
            }
            recognizerToTrack = nil;
            isTracking = NO;
        }
    });
    %orig;
}

%end




%ctor {
    class_addProtocol(objc_getClass("SBHandMotionExtractor"), @protocol(_UIScreenEdgePanRecognizerDelegate));
    
    edgeObserverCallbacks = [[NSMutableDictionary alloc]init];
    edgeObserverConditions = [[NSMutableDictionary alloc]init];
    
    UIRectEdge edgesToWatch[] = {UIRectEdgeBottom, UIRectEdgeLeft, UIRectEdgeRight};
    int edgeCount = sizeof(edgesToWatch)/sizeof(UIRectEdge);
    gestureRecognizers = [[NSMutableSet alloc]initWithCapacity:edgeCount];
    for (int i = 0; i < edgeCount; i++) {
        _UIScreenEdgePanRecognizer *recognizer = [[_UIScreenEdgePanRecognizer alloc]initWithType:2];
        [recognizer setTargetEdges:edgesToWatch[i]];
        [recognizer setScreenBounds:[[UIScreen mainScreen]bounds]];
        [gestureRecognizers addObject:recognizer];
        [recognizer release];
    }
    
    %init;
}