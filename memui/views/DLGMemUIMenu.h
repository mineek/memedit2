#import <UIKit/UIKit.h>

@class DLGMemUIMenu;

@protocol DLGMemUIMenuDelegate <NSObject>

@optional
- (void)DLGMemUIMenuDidSelectMemoryEditor:(DLGMemUIMenu *)menu;
- (void)DLGMemUIMenuDidSelectUnityHax:(DLGMemUIMenu *)menu;
- (void)DLGMemUIMenuDidCancel:(DLGMemUIMenu *)menu;

@end

@interface DLGMemUIMenu : UIView

@property (nonatomic, weak) id<DLGMemUIMenuDelegate> delegate;

- (void)showInView:(UIView *)view animated:(BOOL)animated;
- (void)hideAnimated:(BOOL)animated;

@end
