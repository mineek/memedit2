#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, DLGUnityHaxAlertStyle) {
    DLGUnityHaxAlertStyleDefault,
    DLGUnityHaxAlertStyleInput
};

@interface DLGUnityHaxAlert : UIView

@property (nonatomic, copy) NSString *titleText;
@property (nonatomic, copy) NSString *messageText;
@property (nonatomic) DLGUnityHaxAlertStyle alertStyle;

@property (nonatomic, copy) NSArray<NSString *> *inputPlaceholders;
@property (nonatomic, copy) NSArray<NSNumber *> *inputKeyboardTypes;
@property (nonatomic, readonly) NSArray<UITextField *> *textFields;

@property (nonatomic, copy) NSArray<NSString *> *buttonTitles;
@property (nonatomic, copy) void (^buttonHandler)(NSInteger buttonIndex);

- (void)showInView:(UIView *)view animated:(BOOL)animated;
- (void)hideAnimated:(BOOL)animated;

@end
