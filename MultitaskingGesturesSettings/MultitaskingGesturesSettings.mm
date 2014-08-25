#import "Preferences.h"

@interface MultitaskingGesturesSettingsListController: PSListController <UIAlertViewDelegate> {
    NSMutableArray *_switchAppSectionExtraSpecifiers;
    NSMutableArray *_swipeUpSectionExtraSpecifiers;
}
@end

@implementation MultitaskingGesturesSettingsListController

- (NSArray *)specifiers {
	if(_specifiers == nil) {
		NSMutableArray *specifiers = [[self loadSpecifiersFromPlistName:@"MultitaskingGesturesSettings" target:self]mutableCopy];
        
        _switchAppSectionExtraSpecifiers = [[NSMutableArray alloc]init];
        for (int i = [specifiers indexOfObject:[specifiers specifierForID:@"SWITCH_APP_GROUP"]]+2; i < specifiers.count; i++) {
            PSSpecifier *currentSpec = specifiers[i];
            if ([[PSTableCell stringFromCellType:currentSpec.cellType]isEqualToString:@"PSGroupCell"])
                break;
            [_switchAppSectionExtraSpecifiers addObject:currentSpec];
        }
        
        _swipeUpSectionExtraSpecifiers = [[NSMutableArray alloc]init];
        for (int i = [specifiers indexOfObject:[specifiers specifierForID:@"SWIPE_UP_GROUP"]]+2; i < specifiers.count; i++) {
            PSSpecifier *currentSpec = specifiers[i];
            if ([[PSTableCell stringFromCellType:currentSpec.cellType]isEqualToString:@"PSGroupCell"])
                break;
            [_swipeUpSectionExtraSpecifiers addObject:currentSpec];
        }
        
        Boolean keyExists = false;
        if (!CFPreferencesGetAppBooleanValue(CFSTR("SwitchAppEnabled"), CFSTR("com.hamzasood.multitaskinggestures"), &keyExists) && keyExists)
            [specifiers removeObjectsInArray:_switchAppSectionExtraSpecifiers];
        if (!CFPreferencesGetAppBooleanValue(CFSTR("SwipeUpEnabled"), CFSTR("com.hamzasood.multitaskinggestures"), &keyExists) && keyExists)
            [specifiers removeObjectsInArray:_swipeUpSectionExtraSpecifiers];
        
        _specifiers = specifiers.copy;
        [specifiers release];
	}
	return _specifiers;
}


- (void)setSwitchAppGestureEnabled:(NSNumber *)value forSpecifier:(PSSpecifier *)specifier {
    [self setPreferenceValue:value specifier:specifier];
    if (value.boolValue)
        [self insertContiguousSpecifiers:_switchAppSectionExtraSpecifiers atIndex:[_specifiers indexOfObject:[_specifiers specifierForID:@"SWITCH_APP_GROUP"]]+2 animated:YES];
    else
        [self removeContiguousSpecifiers:_switchAppSectionExtraSpecifiers animated:YES];
}


- (void)setSwipeUpGestureEnabled:(NSNumber *)value forSpecifier:(PSSpecifier *)specifier {
    [self setPreferenceValue:value specifier:specifier];
    if (value.boolValue)
        [self insertContiguousSpecifiers:_swipeUpSectionExtraSpecifiers atIndex:[_specifiers indexOfObject:[_specifiers specifierForID:@"SWIPE_UP_GROUP"]]+2 animated:YES];
    else
        [self removeContiguousSpecifiers:_swipeUpSectionExtraSpecifiers animated:YES];
}


- (void)respring:(PSSpecifier *)specifier {
    UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:nil message:@"Are you sure you want to respring?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Respring", nil];
    [alertView show];
    [alertView release];
}

- (void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (buttonIndex != alertView.cancelButtonIndex)
        PSKillProcessNamed(@"SpringBoard");
}

@end