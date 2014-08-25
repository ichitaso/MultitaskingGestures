@interface PSSpecifier : NSObject
@property(nonatomic) NSInteger cellType;
@end

@interface NSArray (PreferencesAdditions)
- (PSSpecifier *)specifierForID:(NSString *)specId;
@end

@interface PSListController : UIViewController {
    NSArray *_specifiers;
}
- (PSSpecifier *)specifierForID:(NSString *)specId;
- (void)removeSpecifier:(PSSpecifier *)specifier animated:(BOOL)animated;
- (void)insertSpecifier:(PSSpecifier *)specifier atEndOfGroup:(NSInteger)groupIndex animated:(BOOL)animated;
- (void)insertSpecifier:(PSSpecifier *)specifier afterSpecifierID:(NSString *)specId animated:(BOOL)animated;
- (void)removeContiguousSpecifiers:(NSArray *)soecifiers animated:(BOOL)animated;
- (void)insertContiguousSpecifiers:(NSArray *)specifiers atEndOfGroup:(NSInteger)groupIndex animated:(BOOL)animated;
- (void)insertContiguousSpecifiers:(NSArray *)specifiers atIndex:(NSInteger)index animated:(BOOL)animated;
- (NSArray *)specifiersInGroup:(NSInteger)groupIndex;
- (NSArray *)specifiers;
- (NSArray *)loadSpecifiersFromPlistName:(NSString *)plist target:(id)target;
- (id)readPreferenceValue:(NSString *)key;
- (void)setPreferenceValue:(id)value specifier:(PSSpecifier *)specifier;
@end

@interface PSTableCell : UITableViewCell
+ (NSString *)stringFromCellType:(NSInteger)cellType;
+ (NSInteger)cellTypeFromString:(NSString *)string;
@end

extern "C" void PSKillProcessNamed(NSString *processName);