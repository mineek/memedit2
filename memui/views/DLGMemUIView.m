//
//  DLGMemUIView.m
//  memui
//
//  Created by Liu Junqi on 11/11/2016.
//  Copyright © 2016 Liu Junqi. All rights reserved.
//

#import "DLGMemUIView.h"
#import "DLGMemUIViewCell.h"
#import "DLGMemUIMenu.h"
#import "DLGUnityHaxView.h"
#import "DLGUnityHaxAlert.h"
#import "../RemoteLog.h"

// #define MaxResultCount  500
#define MaxResultCount  2000

@interface DLGMemUIView () <UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource, DLGMemUIViewCellDelegate, DLGMemUIMenuDelegate> {
    search_result_t *chainArray;
}

@property (nonatomic) UIButton *btnConsole;
@property (nonatomic) UIButton *btnClose;
@property (nonatomic) UITapGestureRecognizer *tapGesture;

@property (nonatomic) CGRect rcCollapsedFrame;
@property (nonatomic) CGRect rcExpandedFrame;

@property (nonatomic) UIView *vContent;
@property (nonatomic) UILabel *lblType;
@property (nonatomic) UIView *vSearch;
@property (nonatomic) UITextField *tfValue;
@property (nonatomic) UIButton *btnSearch;

@property (nonatomic) UIView *vOption;
@property (nonatomic) UISegmentedControl *scComparison;
@property (nonatomic) UISegmentedControl *scUValueType;
@property (nonatomic) UISegmentedControl *scSValueType;

@property (nonatomic) UIView *vResult;
@property (nonatomic) UILabel *lblResult;
@property (nonatomic) UITableView *tvResult;
@property (nonatomic) UIProgressView *progressView;
@property (nonatomic) UIView *progressContainer;

@property (nonatomic) UIView *vMore;
@property (nonatomic) UIButton *btnReset;
@property (nonatomic) UIButton *btnMemory;
@property (nonatomic) UIButton *btnRefresh;
@property (nonatomic) UIButton *btnEditAll;

@property (nonatomic) UIView *vMemoryContent;
@property (nonatomic) UIView *vMemory;
@property (nonatomic) UITextField *tfMemorySize;
@property (nonatomic) UITextField *tfMemory;
@property (nonatomic) UIButton *btnSearchMemory;

@property (nonatomic) UITextView *tvMemory;
@property (nonatomic) UIButton *btnBackFromMemory;

@property (nonatomic, weak) UIView *vShowingContent;

@property (nonatomic) NSLayoutConstraint *lcUValueTypeTopMargin;

@property (nonatomic) BOOL isUnsignedValueType;
@property (nonatomic) NSInteger selectedValueTypeIndex;
@property (nonatomic) NSInteger selectedComparisonIndex;
@property (nonatomic, weak) UITextField *tfFocused;

@property (nonatomic) BOOL editAllMode;
@property (nonatomic) NSMutableSet<NSString *> *selectedAddresses;

@end

@implementation DLGMemUIView

+ (instancetype)instance
{
    static DLGMemUIView *_instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[DLGMemUIView alloc] init];
    });
    return _instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self initVars];
        [self initViews];
    }
    return self;
}

- (void)initVars {
    CGRect screenBounds = [UIScreen mainScreen].bounds;
    self.rcExpandedFrame = screenBounds;
    self.rcCollapsedFrame = CGRectMake(0, 0, DLG_DEBUG_CONSOLE_VIEW_SIZE, DLG_DEBUG_CONSOLE_VIEW_SIZE);
    
    _shouldNotBeDragged = NO;
    _expanded = NO;
    self.isUnsignedValueType = NO;
    self.selectedValueTypeIndex = 2;
    self.selectedComparisonIndex = 2;
    
    self.tintColor = [UIColor colorWithRed:0.0 green:0.478 blue:1.0 alpha:1.0];
    self.backgroundColor = [UIColor blackColor];
}

- (void)initViews {
    self.clipsToBounds = NO;
    self.frame = self.rcCollapsedFrame;
    self.layer.cornerRadius = 12;
    self.layer.shadowColor = [UIColor blackColor].CGColor;
    self.layer.shadowOffset = CGSizeMake(0, 6);
    self.layer.shadowRadius = 16;
    self.layer.shadowOpacity = 0.5;
    
    [self initConsoleButton];
    [self initContents];
    [self initMemoryContents];
    self.vShowingContent = self.vContent;
    
    UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    UIVisualEffectView *blurEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    blurEffectView.frame = self.bounds;
    blurEffectView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self insertSubview:blurEffectView atIndex:0];
}

- (void)initConsoleButton {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    button.layer.masksToBounds = YES;
    
    // icon
    NSURL *imageURL = [NSURL URLWithString:@"https://github.com/mineek.png"];
    NSData *imageData = [NSData dataWithContentsOfURL:imageURL];
    if (!imageData) {
        [button setTitle:@"MEM" forState:UIControlStateNormal];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        button.titleLabel.font = [UIFont systemFontOfSize:14 weight:UIFontWeightBold];
    } else {
        UIImage *image = [UIImage imageWithData:imageData];
        [button setBackgroundImage:image forState:UIControlStateNormal];
    }

    self.layer.cornerRadius = CGRectGetWidth(self.bounds) / 2;
        
    [self addSubview:button];
    
    [NSLayoutConstraint activateConstraints:@[
        [button.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [button.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [button.topAnchor constraintEqualToAnchor:self.topAnchor],
        [button.bottomAnchor constraintEqualToAnchor:self.bottomAnchor]
    ]];
    
    [button addTarget:self action:@selector(onConsoleButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    self.btnConsole = button;
}

- (void)doExpand {
    [self expand];
}

- (void)doCollapse {
    [self collapse];
    self.btnConsole.hidden = NO;
    [self.tfValue resignFirstResponder];
}

#pragma mark - Init Content View
- (void)initContents {
    [self initContentView];
    [self initCloseButton];
    [self initSearchView];
    [self initOptionView];
    [self initResultView];
    [self initMoreView];
    self.vContent.hidden = YES;
}

- (void)initContentView {
    UIView *v = [[UIView alloc] init];
    v.translatesAutoresizingMaskIntoConstraints = NO;
    v.backgroundColor = [UIColor clearColor];
    [self addSubview:v];
    
    NSDictionary *views = @{@"v":v};
    NSArray *ch = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[v]|" options:0 metrics:nil views:views];
    [self addConstraints:ch];
    NSArray *cv = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[v]|" options:0 metrics:nil views:views];
    [self addConstraints:cv];
    
    self.vContent = v;
}

- (void)initCloseButton {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.translatesAutoresizingMaskIntoConstraints = NO;

    if (@available(iOS 13.0, *)) {
        [button setImage:[UIImage systemImageNamed:@"xmark.circle.fill"] forState:UIControlStateNormal];
        button.tintColor = [UIColor whiteColor];
    } else {
        [button setTitle:@"✕" forState:UIControlStateNormal];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        button.titleLabel.font = [UIFont systemFontOfSize:20 weight:UIFontWeightBold];
    }

    button.backgroundColor = [UIColor colorWithWhite:0.15 alpha:0.8];
    button.layer.cornerRadius = 16;
    button.layer.shadowColor = [UIColor blackColor].CGColor;
    button.layer.shadowOffset = CGSizeMake(0, 2);
    button.layer.shadowRadius = 6;
    button.layer.shadowOpacity = 0.3;

    [self.vContent addSubview:button];

    [NSLayoutConstraint activateConstraints:@[
        [button.trailingAnchor constraintEqualToAnchor:self.vContent.trailingAnchor constant:-16],
        [button.topAnchor constraintEqualToAnchor:self.vContent.topAnchor constant:16],
        [button.widthAnchor constraintEqualToConstant:32],
        [button.heightAnchor constraintEqualToConstant:32]
    ]];

    [button addTarget:self action:@selector(onCloseButtonTapped:) forControlEvents:UIControlEventTouchUpInside];

    // long press gesture to make UI transparent
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(closeButtonLongPress:)];
    longPress.minimumPressDuration = 0.3;
    [button addGestureRecognizer:longPress];

    self.btnClose = button;
    button.hidden = YES;
}

- (void)onCloseButtonTapped:(UIButton *)sender {
    [self doCollapse];
}

- (void)closeButtonLongPress:(UILongPressGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateBegan) {
        [UIView animateWithDuration:0.2 animations:^{
            self.alpha = 0.2;
        }];
    } else if (gesture.state == UIGestureRecognizerStateEnded ||
               gesture.state == UIGestureRecognizerStateCancelled ||
               gesture.state == UIGestureRecognizerStateFailed) {
        [UIView animateWithDuration:0.2 animations:^{
            self.alpha = 1.0;
        }];
    }
}

#pragma mark - Init Search View
- (void)initSearchView {
    [self initSearchViewContainer];
    [self initSearchValueType];
    [self initSearchButton];
    [self initSearchValueInput];
}

- (void)initSearchViewContainer {
    UIView *v = [[UIView alloc] init];
    v.translatesAutoresizingMaskIntoConstraints = NO;
    v.backgroundColor = [UIColor colorWithWhite:0.12 alpha:0.6];
    v.layer.cornerRadius = 12;
    v.layer.shadowColor = [UIColor blackColor].CGColor;
    v.layer.shadowOffset = CGSizeMake(0, 3);
    v.layer.shadowRadius = 8;
    v.layer.shadowOpacity = 0.3;
    [self.vContent addSubview:v];

    NSDictionary *views = @{@"v":v};
    [NSLayoutConstraint activateConstraints:@[
        [v.leadingAnchor constraintEqualToAnchor:self.vContent.leadingAnchor constant:16],
        [v.trailingAnchor constraintEqualToAnchor:self.vContent.trailingAnchor constant:-16],
        [v.topAnchor constraintEqualToAnchor:self.btnClose.bottomAnchor constant:12],
        [v.heightAnchor constraintEqualToConstant:44]
    ]];

    self.vSearch = v;
}

- (void)initSearchValueType {
    UILabel *lbl = [[UILabel alloc] init];
    lbl.translatesAutoresizingMaskIntoConstraints = NO;
    lbl.backgroundColor = [UIColor clearColor];
    lbl.textAlignment = NSTextAlignmentCenter;
    lbl.textColor = [UIColor whiteColor];
    lbl.text = @"SInt";
    [self.vSearch addSubview:lbl];
    
    NSDictionary *views = @{@"lbl":lbl};
    NSArray *ch = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[lbl(64)]" options:0 metrics:nil views:views];
    [self.vSearch addConstraints:ch];
    NSArray *cv = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[lbl]|" options:0 metrics:nil views:views];
    [self.vSearch addConstraints:cv];
    
    self.lblType = lbl;
}

- (void)initSearchButton {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    [button setTitle:@"Search" forState:UIControlStateNormal];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    button.backgroundColor = self.tintColor;
    button.layer.cornerRadius = 10;
    button.layer.shadowColor = [UIColor blackColor].CGColor;
    button.layer.shadowOffset = CGSizeMake(0, 2);
    button.layer.shadowRadius = 4;
    button.layer.shadowOpacity = 0.25;

    [self.vSearch addSubview:button];

    [NSLayoutConstraint activateConstraints:@[
        [button.trailingAnchor constraintEqualToAnchor:self.vSearch.trailingAnchor constant:-8],
        [button.centerYAnchor constraintEqualToAnchor:self.vSearch.centerYAnchor],
        [button.widthAnchor constraintEqualToConstant:80],
        [button.heightAnchor constraintEqualToConstant:36]
    ]];

    [button addTarget:self action:@selector(onSearchTapped:) forControlEvents:UIControlEventTouchUpInside];
    self.btnSearch = button;
}

- (void)initSearchValueInput {
    UITextField *tf = [[UITextField alloc] init];
    tf.translatesAutoresizingMaskIntoConstraints = NO;
    tf.backgroundColor = [UIColor clearColor];
    tf.textColor = [UIColor whiteColor];
    tf.font = [UIFont systemFontOfSize:16];
    tf.attributedPlaceholder = [[NSAttributedString alloc] initWithString:@"Enter value..."
        attributes:@{NSForegroundColorAttributeName: [UIColor colorWithWhite:1.0 alpha:0.5]}];
    
    [self.vSearch addSubview:tf];
    
    [NSLayoutConstraint activateConstraints:@[
        [tf.leadingAnchor constraintEqualToAnchor:self.lblType.trailingAnchor constant:8],
        [tf.trailingAnchor constraintEqualToAnchor:self.btnSearch.leadingAnchor constant:-8],
        [tf.centerYAnchor constraintEqualToAnchor:self.vSearch.centerYAnchor],
        [tf.heightAnchor constraintEqualToConstant:36]
    ]];
    
    tf.delegate = self;
    self.tfValue = tf;
}

#pragma mark - Init Option View
- (void)initOptionView {
    [self initOptionViewContainer];
    [self initComparisonSegmentedControl];
    [self initUValueTypeSegmentedControl];
    [self initSValueTypeSegmentedControl];
}

- (void)initOptionViewContainer {
    UIView *v = [[UIView alloc] init];
    v.translatesAutoresizingMaskIntoConstraints = NO;
    v.backgroundColor = [UIColor clearColor];
    [self.vContent addSubview:v];
    
    NSDictionary *views = @{@"vv":self.vSearch, @"v":v};
    NSArray *ch = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-8-[v]-8-|" options:0 metrics:nil views:views];
    [self addConstraints:ch];
    NSArray *cv = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[vv]-8-[v]" options:0 metrics:nil views:views];
    [self.vContent addConstraints:cv];
    
    self.vOption = v;
}

- (void)initComparisonSegmentedControl {
    UISegmentedControl *sc = [[UISegmentedControl alloc] initWithItems:@[@"<", @"<=", @"=", @">=", @">"]];
    sc.translatesAutoresizingMaskIntoConstraints = NO;
    [sc setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]} forState:UIControlStateNormal];
    [sc setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]} forState:UIControlStateSelected];
    sc.selectedSegmentIndex = 2;
    [sc addTarget:self action:@selector(onComparisonChanged:) forControlEvents:UIControlEventValueChanged];
    [self.vOption addSubview:sc];
    
    NSDictionary *views = @{@"sc":sc};
    NSArray *ch = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[sc]|" options:0 metrics:nil views:views];
    [self.vOption addConstraints:ch];
    NSArray *cv = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[sc]" options:0 metrics:nil views:views];
    [self.vOption addConstraints:cv];
    
    self.scComparison = sc;
}

- (void)initUValueTypeSegmentedControl {
    UISegmentedControl *sc = [[UISegmentedControl alloc] initWithItems:@[@"UByte", @"UShort", @"UInt", @"ULong", @"Float"]];
    sc.translatesAutoresizingMaskIntoConstraints = NO;
    [sc setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]} forState:UIControlStateNormal];
    [sc setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]} forState:UIControlStateSelected];
    sc.selectedSegmentIndex = -1;
    sc.selected = NO;
    [sc addTarget:self action:@selector(onValueTypeChanged:) forControlEvents:UIControlEventValueChanged];
    [self.vOption addSubview:sc];
    
    NSDictionary *views = @{@"cmp":self.scComparison, @"sc":sc};
    NSArray *ch = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[sc]|" options:0 metrics:nil views:views];
    [self.vOption addConstraints:ch];
    NSArray *cv = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[cmp]-8-[sc]" options:0 metrics:nil views:views];
    [self.vOption addConstraints:cv];
    self.lcUValueTypeTopMargin = [cv firstObject];
    self.scUValueType = sc;
}

- (void)initSValueTypeSegmentedControl {
    UISegmentedControl *sc = [[UISegmentedControl alloc] initWithItems:@[@"SByte", @"SShort", @"SInt", @"SLong", @"Double"]];
    sc.translatesAutoresizingMaskIntoConstraints = NO;
    [sc setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]} forState:UIControlStateNormal];
    [sc setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]} forState:UIControlStateSelected];
    sc.selectedSegmentIndex = 2;
    sc.selected = YES;
    [sc addTarget:self action:@selector(onValueTypeChanged:) forControlEvents:UIControlEventValueChanged];
    [self.vOption addSubview:sc];
    
    NSDictionary *views = @{@"usc":self.scUValueType, @"sc":sc};
    NSArray *ch = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[sc]|" options:0 metrics:nil views:views];
    [self.vOption addConstraints:ch];
    NSArray *cv = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[usc][sc]|" options:0 metrics:nil views:views];
    [self.vOption addConstraints:cv];
    
    self.scSValueType = sc;
}

#pragma mark - Init Result View
- (void)initResultView {
    UIView *container = [[UIView alloc] init];
    container.translatesAutoresizingMaskIntoConstraints = NO;
    container.backgroundColor = [UIColor colorWithWhite:0.08 alpha:0.5];
    container.layer.cornerRadius = 16;
    container.clipsToBounds = NO;
    container.layer.shadowColor = [UIColor blackColor].CGColor;
    container.layer.shadowOffset = CGSizeMake(0, 5);
    container.layer.shadowRadius = 15;
    container.layer.shadowOpacity = 0.4;

    [self.vContent addSubview:container];

    UILabel *lblTitle = [[UILabel alloc] init];
    lblTitle.translatesAutoresizingMaskIntoConstraints = NO;
    lblTitle.text = @"Search Results";
    lblTitle.textColor = [UIColor whiteColor];
    lblTitle.font = [UIFont systemFontOfSize:16 weight:UIFontWeightBold];
    [container addSubview:lblTitle];

    self.lblResult = lblTitle;

    UITableView *tv = [[UITableView alloc] init];
    tv.translatesAutoresizingMaskIntoConstraints = NO;
    tv.backgroundColor = [UIColor clearColor];
    tv.separatorStyle = UITableViewCellSeparatorStyleNone;
    tv.rowHeight = 68;
    tv.delegate = self;
    tv.dataSource = self;
    tv.showsVerticalScrollIndicator = YES;
    tv.indicatorStyle = UIScrollViewIndicatorStyleWhite;
    tv.layer.cornerRadius = 12;
    tv.clipsToBounds = YES;
    [tv registerClass:[DLGMemUIViewCell class] forCellReuseIdentifier:DLGMemUIViewCellID];
    tv.contentInset = UIEdgeInsetsMake(12, 0, 12, 0);
    [container addSubview:tv];
    
    UIView *progressContainer = [[UIView alloc] init];
    progressContainer.translatesAutoresizingMaskIntoConstraints = NO;
    progressContainer.backgroundColor = [UIColor colorWithWhite:0.15 alpha:0.95];
    progressContainer.layer.cornerRadius = 8;
    progressContainer.hidden = YES;
    [container addSubview:progressContainer];

    UIProgressView *progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    progressView.translatesAutoresizingMaskIntoConstraints = NO;
    progressView.progressTintColor = self.tintColor;
    progressView.trackTintColor = [UIColor colorWithWhite:0.3 alpha:1.0];
    [progressContainer addSubview:progressView];

    UILabel *lblProgress = [[UILabel alloc] init];
    lblProgress.translatesAutoresizingMaskIntoConstraints = NO;
    lblProgress.text = @"Searching...";
    lblProgress.textColor = [UIColor whiteColor];
    lblProgress.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    lblProgress.textAlignment = NSTextAlignmentCenter;
    [progressContainer addSubview:lblProgress];

    [NSLayoutConstraint activateConstraints:@[
        [container.leadingAnchor constraintEqualToAnchor:self.vContent.leadingAnchor constant:16],
        [container.trailingAnchor constraintEqualToAnchor:self.vContent.trailingAnchor constant:-16],
        [container.topAnchor constraintEqualToAnchor:self.vOption.bottomAnchor constant:16],
        [container.bottomAnchor constraintEqualToAnchor:self.vContent.bottomAnchor constant:-50],

        [lblTitle.leadingAnchor constraintEqualToAnchor:container.leadingAnchor constant:16],
        [lblTitle.topAnchor constraintEqualToAnchor:container.topAnchor constant:12],

        [tv.leadingAnchor constraintEqualToAnchor:container.leadingAnchor constant:8],
        [tv.trailingAnchor constraintEqualToAnchor:container.trailingAnchor constant:-8],
        [tv.topAnchor constraintEqualToAnchor:lblTitle.bottomAnchor constant:8],
        [tv.bottomAnchor constraintEqualToAnchor:container.bottomAnchor],

        [progressContainer.centerXAnchor constraintEqualToAnchor:container.centerXAnchor],
        [progressContainer.centerYAnchor constraintEqualToAnchor:container.centerYAnchor],
        [progressContainer.widthAnchor constraintEqualToConstant:250],
        [progressContainer.heightAnchor constraintEqualToConstant:80],

        [lblProgress.topAnchor constraintEqualToAnchor:progressContainer.topAnchor constant:16],
        [lblProgress.leadingAnchor constraintEqualToAnchor:progressContainer.leadingAnchor constant:16],
        [lblProgress.trailingAnchor constraintEqualToAnchor:progressContainer.trailingAnchor constant:-16],

        [progressView.topAnchor constraintEqualToAnchor:lblProgress.bottomAnchor constant:12],
        [progressView.leadingAnchor constraintEqualToAnchor:progressContainer.leadingAnchor constant:16],
        [progressView.trailingAnchor constraintEqualToAnchor:progressContainer.trailingAnchor constant:-16]
    ]];

    self.vResult = container;
    self.tvResult = tv;
    self.progressView = progressView;
    self.progressContainer = progressContainer;
}

#pragma mark - Init More View
- (void)initMoreView {
    [self initMoreViewContainer];
    [self initResetButton];
    [self initEditAllButton];
    [self initMemoryButton];
    [self initRefreshButton];

    NSDictionary *views = @{@"reset":self.btnReset, @"editAll":self.btnEditAll, @"memory":self.btnMemory, @"refresh":self.btnRefresh};
    NSArray *ch = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[reset(==editAll)][editAll(==memory)][memory(==refresh)][refresh(==reset)]|" options:0 metrics:nil views:views];
    [self.vMore addConstraints:ch];
    NSArray *cv1 = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[reset]|" options:0 metrics:nil views:views];
    NSArray *cv2 = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[editAll]|" options:0 metrics:nil views:views];
    NSArray *cv3 = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[memory]|" options:0 metrics:nil views:views];
    NSArray *cv4 = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[refresh]|" options:0 metrics:nil views:views];
    [self.vMore addConstraints:cv1];
    [self.vMore addConstraints:cv2];
    [self.vMore addConstraints:cv3];
    [self.vMore addConstraints:cv4];
}

- (void)initMoreViewContainer {
    UIView *v = [[UIView alloc] init];
    v.translatesAutoresizingMaskIntoConstraints = NO;
    v.backgroundColor = [UIColor clearColor];
    [self.vContent addSubview:v];
    
    NSDictionary *views = @{@"vv":self.vResult, @"v":v};
    NSArray *ch = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-8-[v]-8-|" options:0 metrics:nil views:views];
    [self.vContent addConstraints:ch];
    NSArray *cv = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[vv]-8-[v(32)]|" options:0 metrics:nil views:views];
    [self.vContent addConstraints:cv];
    
    self.vMore = v;
}

- (void)initResetButton {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    btn.translatesAutoresizingMaskIntoConstraints = NO;
    [btn setTitle:@"Reset" forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(onResetTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.vMore addSubview:btn];
    
    NSDictionary *views = @{@"btn":btn};
    NSArray *ch = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[btn(64)]" options:0 metrics:nil views:views];
    [self.vMore addConstraints:ch];
    NSArray *cv = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[btn]|" options:0 metrics:nil views:views];
    [self.vMore addConstraints:cv];
    
    self.btnReset = btn;
}

- (void)initRefreshButton {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    btn.translatesAutoresizingMaskIntoConstraints = NO;
    [btn setTitle:@"Refresh" forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(onRefreshTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.vMore addSubview:btn];
    
    NSDictionary *views = @{@"btn":btn};
    NSArray *ch = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[btn(64)]|" options:0 metrics:nil views:views];
    [self.vMore addConstraints:ch];
    NSArray *cv = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[btn]|" options:0 metrics:nil views:views];
    [self.vMore addConstraints:cv];
    
    self.btnRefresh = btn;
}

- (void)initMemoryButton {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    btn.translatesAutoresizingMaskIntoConstraints = NO;
    [btn setTitle:@"Memory" forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(onMemoryTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.vMore addSubview:btn];
    NSDictionary *views = @{@"btn":btn};
    NSArray *cv = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[btn]|" options:0 metrics:nil views:views];
    [self.vMore addConstraints:cv];
    self.btnMemory = btn;
}

- (void)initEditAllButton {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    btn.translatesAutoresizingMaskIntoConstraints = NO;
    [btn setTitle:@"Edit All" forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(onEditAllTapped:) forControlEvents:UIControlEventTouchUpInside];
    // if edit all is hold, select all
    [btn addGestureRecognizer:[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(onEditAllLongPressed:)]];
    [self.vMore addSubview:btn];
    self.btnEditAll = btn;
}

#pragma mark - Init Memory Content View
- (void)initMemoryContents {
    [self initMemoryContentView];
    [self initMemoryView];
    self.vMemoryContent.hidden = YES;
}

- (void)initMemoryContentView {
    UIView *v = [[UIView alloc] init];
    v.translatesAutoresizingMaskIntoConstraints = NO;
    v.backgroundColor = [UIColor clearColor];
    [self addSubview:v];
    
    NSDictionary *views = @{@"v":v};
    NSArray *ch = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[v]|" options:0 metrics:nil views:views];
    [self addConstraints:ch];
    NSArray *cv = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[v]|" options:0 metrics:nil views:views];
    [self addConstraints:cv];
    
    self.vMemoryContent = v;
}

#pragma mark - Init Memory View
- (void)initMemoryView {
    [self initMemoryViewContainer];
    [self initMemorySearchButton];
    [self initMemorySizeInput];
    [self initMemoryInput];
    [self initMemoryTextView];
    [self initBackFromMemoryButton];
}

- (void)initMemoryViewContainer {
    UIView *v = [[UIView alloc] init];
    v.translatesAutoresizingMaskIntoConstraints = NO;
    v.backgroundColor = [UIColor clearColor];
    [self.vMemoryContent addSubview:v];
    
    NSDictionary *views = @{@"v":v};
    NSArray *ch = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-8-[v]-8-|" options:0 metrics:nil views:views];
    [self.vMemoryContent addConstraints:ch];
    NSArray *cv = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-20-[v(32)]" options:0 metrics:nil views:views];
    [self.vMemoryContent addConstraints:cv];
    
    self.vMemory = v;
}

- (void)initMemorySearchButton {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    btn.translatesAutoresizingMaskIntoConstraints = NO;
    [btn setTitle:@"Search" forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(onSearchMemoryTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.vMemory addSubview:btn];
    
    NSDictionary *views = @{@"btn":btn};
    NSArray *ch = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[btn(64)]|" options:0 metrics:nil views:views];
    [self.vMemory addConstraints:ch];
    NSArray *cv = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[btn]|" options:0 metrics:nil views:views];
    [self.vMemory addConstraints:cv];
    
    self.btnSearchMemory = btn;
}

- (void)initMemorySizeInput {
    UITextField *tf = [[UITextField alloc] init];
    tf.translatesAutoresizingMaskIntoConstraints = NO;
    tf.delegate = self;
    tf.borderStyle = UITextBorderStyleRoundedRect;
    tf.backgroundColor = [UIColor whiteColor];
    tf.textColor = [UIColor blackColor];
    tf.text = @"1024";
    tf.placeholder = @"Size";
    tf.returnKeyType = UIReturnKeyNext;
    tf.keyboardType = UIKeyboardTypeDefault;
    tf.clearButtonMode = UITextFieldViewModeNever;
    tf.spellCheckingType = UITextSpellCheckingTypeNo;
    tf.autocapitalizationType = UITextAutocapitalizationTypeNone;
    tf.autocorrectionType = UITextAutocorrectionTypeNo;
    tf.enabled = YES;
    [self.vMemory addSubview:tf];
    
    NSDictionary *views = @{@"tf":tf};
    NSArray *ch = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[tf(64)]" options:0 metrics:nil views:views];
    [self.vMemory addConstraints:ch];
    NSArray *cv = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[tf]|" options:0 metrics:nil views:views];
    [self.vMemory addConstraints:cv];
    
    self.tfMemorySize = tf;
}

- (void)initMemoryInput {
    UITextField *tf = [[UITextField alloc] init];
    tf.translatesAutoresizingMaskIntoConstraints = NO;
    tf.delegate = self;
    tf.borderStyle = UITextBorderStyleRoundedRect;
    tf.backgroundColor = [UIColor whiteColor];
    tf.textColor = [UIColor blackColor];
    tf.text = @"0";
    tf.placeholder = @"Enter the address";
    tf.returnKeyType = UIReturnKeySearch;
    tf.keyboardType = UIKeyboardTypeDefault;
    tf.clearButtonMode = UITextFieldViewModeWhileEditing;
    tf.spellCheckingType = UITextSpellCheckingTypeNo;
    tf.autocapitalizationType = UITextAutocapitalizationTypeNone;
    tf.autocorrectionType = UITextAutocorrectionTypeNo;
    tf.enabled = YES;
    [self.vMemory addSubview:tf];
    
    NSDictionary *views = @{@"sz":self.tfMemorySize, @"tf":tf, @"btn":self.btnSearchMemory};
    NSArray *ch = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[sz]-8-[tf][btn]" options:0 metrics:nil views:views];
    [self.vMemory addConstraints:ch];
    NSArray *cv = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[tf]|" options:0 metrics:nil views:views];
    [self.vMemory addConstraints:cv];
    
    self.tfMemory = tf;
}

- (void)initMemoryTextView {
    UITextView *tv = [[UITextView alloc] init];
    tv.translatesAutoresizingMaskIntoConstraints = NO;
    tv.font = [UIFont fontWithName:@"Courier New" size:12];
    tv.backgroundColor = [UIColor clearColor];
    tv.textColor = [UIColor whiteColor];
    tv.textAlignment = NSTextAlignmentCenter;
    tv.editable = NO;
    tv.selectable = YES;
    [self.vMemoryContent addSubview:tv];
    
    NSDictionary *views = @{@"v":self.vMemory, @"tv":tv};
    NSArray *ch = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[tv]|" options:0 metrics:nil views:views];
    [self.vMemoryContent addConstraints:ch];
    NSArray *cv = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[v]-8-[tv]" options:0 metrics:nil views:views];
    [self.vMemoryContent addConstraints:cv];
    
    self.tvMemory = tv;
}

- (void)initBackFromMemoryButton {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    btn.translatesAutoresizingMaskIntoConstraints = NO;
    [btn setTitle:@"Back" forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(onBackFromMemoryTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.vMemoryContent addSubview:btn];
    
    NSDictionary *views = @{@"tv":self.tvMemory, @"btn":btn};
    NSArray *ch = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[btn]|" options:0 metrics:nil views:views];
    [self.vMemoryContent addConstraints:ch];
    NSArray *cv = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[tv][btn(32)]|" options:0 metrics:nil views:views];
    [self.vMemoryContent addConstraints:cv];
    
    self.btnBackFromMemory = btn;
}

#pragma mark - Setter / Getter
- (void)setChainCount:(NSInteger)chainCount {
    _chainCount = chainCount;
    self.lblResult.text = [NSString stringWithFormat:@"Found %lld.", (long long)chainCount];
    if (chainCount > 0) {
        self.lcUValueTypeTopMargin.constant = -CGRectGetHeight(self.scUValueType.frame) * 2;
        self.scUValueType.hidden = YES;
        self.scSValueType.hidden = YES;
    } else {
        self.lcUValueTypeTopMargin.constant = 8;
        self.scUValueType.hidden = NO;
        self.scSValueType.hidden = NO;
    }
}

- (void)setChain:(search_result_chain_t)chain {
    _chain = chain;
    if (chainArray) {
        free(chainArray);
        chainArray = NULL;
    }
    
    if (self.chainCount > 0 && self.chainCount <= MaxResultCount) {
        chainArray = malloc(sizeof(search_result_t) * self.chainCount);
        search_result_chain_t c = chain;
        int i = 0;
        while (i < self.chainCount) {
            if (c->result) chainArray[i++] = c->result;
            c = c->next;
            if (c == NULL) break;
        }
        if (i < self.chainCount) self.chainCount = i;
    }
    [self.tvResult reloadData];
}

#pragma mark - Gesture
- (void)addGesture {
    if (self.tapGesture != nil) return;
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleGesture:)];
    tap.numberOfTapsRequired = 1;
    tap.numberOfTouchesRequired = 1;
    [self addGestureRecognizer:tap];
    
    self.tapGesture = tap;
}

- (void)removeGesture {
    if (self.tapGesture == nil) { return; }
    
    [self removeGestureRecognizer:self.tapGesture];
    self.tapGesture = nil;
}

#pragma mark - Events
- (void)onSearchTapped:(id)sender {
    [self.tfValue resignFirstResponder];
    if ([self.delegate respondsToSelector:@selector(DLGMemUISearchValue:type:comparison:)]) {
        NSString *value = self.tfValue.text;
        if (value.length == 0) return;
        DLGMemValueType type = [self currentValueType];
        DLGMemComparison comparison = [self currentComparison];
        switch (self.selectedComparisonIndex) {
            case 0: comparison = DLGMemComparisonLT; break;
            case 1: comparison = DLGMemComparisonLE; break;
            case 2: comparison = DLGMemComparisonEQ; break;
            case 3: comparison = DLGMemComparisonGE; break;
            case 4: comparison = DLGMemComparisonGT; break;
        }
        [self.delegate DLGMemUISearchValue:value type:type comparison:comparison];
    }
}

- (void)onResetTapped:(id)sender {
    if ([self.delegate respondsToSelector:@selector(DLGMemUIReset)]) {
        [self.delegate DLGMemUIReset];
    }
}

- (void)onRefreshTapped:(id)sender {
    if ([self.delegate respondsToSelector:@selector(DLGMemUIRefresh)]) {
        [self.delegate DLGMemUIRefresh];
    }
}

- (void)onMemoryTapped:(id)sender {
    if (self.tvMemory.text.length == 0) {
        [self showMemory:self.tfMemory.text];
    } else {
        [self showMemory];
    }
}

- (void)onComparisonChanged:(id)sender {
    self.selectedComparisonIndex = self.scComparison.selectedSegmentIndex;
}

- (void)onValueTypeChanged:(id)sender {
    BOOL isUnsigned = (sender == self.scUValueType);
    UISegmentedControl *sc = isUnsigned ? self.scUValueType : self.scSValueType;
    UISegmentedControl *sc2 = isUnsigned ? self.scSValueType : self.scUValueType;
    sc.selected = YES;
    sc2.selected = NO;
    sc2.selectedSegmentIndex = -1;
    self.isUnsignedValueType = isUnsigned;
    self.selectedValueTypeIndex = sc.selectedSegmentIndex;
    self.lblType.text = [self stringFromValueType:[self currentValueType]];
}

- (void)onSearchMemoryTapped:(id)sender {
    [self.tfMemory resignFirstResponder];
    [self.tfMemorySize resignFirstResponder];
    NSString *address = self.tfMemory.text;
    NSString *size = self.tfMemorySize.text;
    if (address.length == 0) return;
    if ([self.delegate respondsToSelector:@selector(DLGMemUIMemory:size:)]) {
        NSString *memory = [self.delegate DLGMemUIMemory:address size:size];
        self.tvMemory.text = memory;
    }
}

- (void)onBackFromMemoryTapped:(id)sender {
    self.vMemoryContent.hidden = YES;
    self.vContent.hidden = NO;
    self.vShowingContent = self.vContent;
    self.tvMemory.text = @"";
}

- (void)showMemory {
    self.vContent.hidden = YES;
    self.vMemoryContent.hidden = NO;
    self.vShowingContent = self.vMemoryContent;
}

- (void)showMemory:(NSString *)address {
    [self showMemory];
    self.tfMemory.text = address;
    self.tvMemory.text = @"";
    [self onSearchMemoryTapped:nil];
}

- (void)onConsoleButtonTapped:(id)sender {
    [self showMainMenu];
}

- (void)showMainMenu {
    DLGMemUIMenu *menu = [[DLGMemUIMenu alloc] init];
    menu.delegate = self;

    UIView *targetView = nil;
    if (self.window) {
        targetView = self.window;
    } else if (self.superview) {
        UIView *view = self.superview;
        while (view.superview) {
            view = view.superview;
        }
        targetView = view;
    } else {
        if (@available(iOS 13.0, *)) {
            targetView = [UIApplication sharedApplication].windows.firstObject;
        } else {
            targetView = [UIApplication sharedApplication].keyWindow;
        }
    }

    if (targetView) {
        [menu showInView:targetView animated:YES];
    } else {
        RLog(@"[MemUIView] could not find a view to display the main menu!");
    }

    RLog(@"[MemUIView] showMainMenu completed");
}

#pragma mark - DLGMemUIMenuDelegate

- (void)DLGMemUIMenuDidSelectMemoryEditor:(DLGMemUIMenu *)menu {
    [self doExpand];
}

- (void)DLGMemUIMenuDidSelectUnityHax:(DLGMemUIMenu *)menu {
    DLGUnityHaxView *unityHaxView = [[DLGUnityHaxView alloc] init];
    UIView *targetView = nil;
    if (self.window) {
        targetView = self.window;
    } else if (self.superview) {
        UIView *view = self.superview;
        while (view.superview) {
            view = view.superview;
        }
        targetView = view;
    } else {
        if (@available(iOS 13.0, *)) {
            targetView = [UIApplication sharedApplication].windows.firstObject;
        } else {
            targetView = [UIApplication sharedApplication].keyWindow;
        }
    }

    if (targetView) {
        [unityHaxView showInView:targetView animated:YES];
    } else {
        NSLog(@"[memedit] Could not find a view to display the Unity Hax view!");
    }
}

- (void)DLGMemUIMenuDidCancel:(DLGMemUIMenu *)menu {
}

#pragma mark - Expand & Collapse
- (void)expand {
    [UIView animateWithDuration:0.3
                          delay:0
         usingSpringWithDamping:0.8
          initialSpringVelocity:0.5
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
        self.frame = self.rcExpandedFrame;
        self.layer.cornerRadius = 0;
        self.btnConsole.alpha = 0;
        self.btnClose.alpha = 1;
        self.vContent.hidden = NO;
        self.vContent.alpha = 1;
    } completion:^(BOOL finished) {
        self.btnConsole.hidden = YES;
        self.btnClose.hidden = NO;
        self.expanded = YES;
    }];
}

- (void)collapse {
    [UIView animateWithDuration:0.3
                          delay:0
         usingSpringWithDamping:0.8
          initialSpringVelocity:0.5
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
        self.frame = self.rcCollapsedFrame;
        self.layer.cornerRadius = CGRectGetWidth(self.bounds) / 2;
        self.btnConsole.alpha = 1;
        self.btnClose.alpha = 0;
        self.vContent.alpha = 0;
    } completion:^(BOOL finished) {
        self.vContent.hidden = YES;
        self.btnClose.hidden = YES;
        self.expanded = NO;
    }];
}

#pragma mark - Gesture
- (void)handleGesture:(UITapGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateEnded) {
        CGPoint pt = [sender locationInView:self.window];
        CGRect frameInScreen = self.tfValue.frame;
        frameInScreen.origin.x += CGRectGetMinX(self.frame);
        frameInScreen.origin.y += CGRectGetMinY(self.frame);
        if (CGRectContainsPoint(frameInScreen, pt)) {
            if ([self.tfValue canBecomeFirstResponder]) {
                [self.tfValue becomeFirstResponder];
            }
        } else {
            [self doCollapse];
        }
    }
}

#pragma mark - UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == self.tfValue) {
        if (textField.returnKeyType == UIReturnKeySearch) {
            [self onSearchTapped:nil];
        }
    } else if (textField == self.tfMemory) {
        if (textField.returnKeyType == UIReturnKeySearch) {
            [self onSearchMemoryTapped:nil];
        }
    } else if (textField == self.tfMemorySize) {
        if (textField.returnKeyType == UIReturnKeyNext) {
            [self.tfMemory becomeFirstResponder];
        }
    } else {
        [textField resignFirstResponder];
    }
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    self.tfFocused = textField;
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.chainCount > MaxResultCount) return 0;
    return self.chainCount;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 68; // match the rowHeight set in initResultView
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    DLGMemUIViewCell *cell = [tableView dequeueReusableCellWithIdentifier:DLGMemUIViewCellID forIndexPath:indexPath];
    cell.delegate = self;
    cell.textFieldDelegate = self;
    NSInteger index = indexPath.row;
    search_result_t result = chainArray[index];
    NSString *address = [NSString stringWithFormat:@"%llX", result->address];
    NSString *value = [self valueStringFromResult:result];
    cell.address = address;
    cell.value = value;
    cell.modifying = NO;

    [cell setShowsCheckbox:self.editAllMode];
    [cell setCheckboxChecked:[self.selectedAddresses containsObject:address]];
    __weak typeof(self) weakSelf = self;
    cell.checkboxChanged = ^(BOOL checked) {
        if (checked) {
            [weakSelf.selectedAddresses addObject:address];
        } else {
            [weakSelf.selectedAddresses removeObject:address];
        }
    };
    return cell;
}

#pragma mark - UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSInteger index = indexPath.row;
    search_result_t result = chainArray[index];
    NSString *address = [NSString stringWithFormat:@"%llX", result->address];
    [self showMemory:address];
}

#pragma mark - DLGMemUIViewCellDelegate
- (void)DLGMemUIViewCellModify:(NSString *)address value:(NSString *)value {
    DLGMemValueType type = [self currentValueType];
    if ([self.delegate respondsToSelector:@selector(DLGMemUIModifyValue:address:type:)]) {
        [self.delegate DLGMemUIModifyValue:value address:address type:type];
    }
}

- (void)DLGMemUIViewCellViewMemory:(NSString *)address {
    [self showMemory:address];
}

#pragma mark - Utils
- (NSString *)valueStringFromResult:(search_result_t)result {
    NSString *value = nil;
    int type = result->type;
    if (type == SearchResultValueTypeUInt8) {
        uint8_t v = *(uint8_t *)(result->value);
        value = [NSString stringWithFormat:@"%u", v];
    } else if (type == SearchResultValueTypeSInt8) {
        int8_t v = *(int8_t *)(result->value);
        value = [NSString stringWithFormat:@"%d", v];
    } else if (type == SearchResultValueTypeUInt16) {
        uint16_t v = *(uint16_t *)(result->value);
        value = [NSString stringWithFormat:@"%u", v];
    } else if (type == SearchResultValueTypeSInt16) {
        int16_t v = *(int16_t *)(result->value);
        value = [NSString stringWithFormat:@"%d", v];
    } else if (type == SearchResultValueTypeUInt32) {
        uint32_t v = *(uint32_t *)(result->value);
        value = [NSString stringWithFormat:@"%u", v];
    } else if (type == SearchResultValueTypeSInt32) {
        int32_t v = *(int32_t *)(result->value);
        value = [NSString stringWithFormat:@"%d", v];
    } else if (type == SearchResultValueTypeUInt64) {
        uint64_t v = *(uint64_t *)(result->value);
        value = [NSString stringWithFormat:@"%llu", v];
    } else if (type == SearchResultValueTypeSInt64) {
        int64_t v = *(int64_t *)(result->value);
        value = [NSString stringWithFormat:@"%lld", v];
    } else if (type == SearchResultValueTypeFloat) {
        float v = *(float *)(result->value);
        value = [NSString stringWithFormat:@"%f", v];
    } else if (type == SearchResultValueTypeDouble) {
        double v = *(double *)(result->value);
        value = [NSString stringWithFormat:@"%f", v];
    } else {
        NSMutableString *ms = [NSMutableString string];
        char *v = (char *)(result->value);
        for (int i = 0; i < result->size; ++i) {
            printf("%02X ", v[i]);
            [ms appendFormat:@"%02X ", v[i]];
        }
        value = ms;
    }
    return value;
}

- (DLGMemValueType)currentValueType {
    DLGMemValueType type = DLGMemValueTypeSignedInt;
    switch (self.selectedValueTypeIndex) {
        case 0: type = self.isUnsignedValueType ? DLGMemValueTypeUnsignedByte : DLGMemValueTypeSignedByte; break;
        case 1: type = self.isUnsignedValueType ? DLGMemValueTypeUnsignedShort : DLGMemValueTypeSignedShort; break;
        case 2: type = self.isUnsignedValueType ? DLGMemValueTypeUnsignedInt : DLGMemValueTypeSignedInt; break;
        case 3: type = self.isUnsignedValueType ? DLGMemValueTypeUnsignedLong : DLGMemValueTypeSignedLong; break;
        case 4: type = self.isUnsignedValueType ? DLGMemValueTypeFloat : DLGMemValueTypeDouble; break;
    }
    return type;
}

- (DLGMemComparison)currentComparison {
    DLGMemComparison comparison = DLGMemComparisonEQ;
    switch (self.selectedComparisonIndex) {
        case 0: comparison = DLGMemComparisonLT; break;
        case 1: comparison = DLGMemComparisonLE; break;
        case 2: comparison = DLGMemComparisonEQ; break;
        case 3: comparison = DLGMemComparisonGE; break;
        case 4: comparison = DLGMemComparisonGT; break;
    }
    return comparison;
}

- (NSString *)stringFromValueType:(DLGMemValueType)type {
    switch (type) {
        case DLGMemValueTypeUnsignedByte: return @"UByte";
        case DLGMemValueTypeSignedByte: return @"SByte";
        case DLGMemValueTypeUnsignedShort: return @"UShort";
        case DLGMemValueTypeSignedShort: return @"SShort";
        case DLGMemValueTypeUnsignedInt: return @"UInt";
        case DLGMemValueTypeSignedInt: return @"SInt";
        case DLGMemValueTypeUnsignedLong: return @"ULong";
        case DLGMemValueTypeSignedLong: return @"SLong";
        case DLGMemValueTypeFloat: return @"Float";
        case DLGMemValueTypeDouble: return @"Double";
        default: return @"--";
    }
}

- (void)exitEditAllMode {
    self.editAllMode = NO;
    [self.btnEditAll setTitle:@"Edit All" forState:UIControlStateNormal];
    [self.selectedAddresses removeAllObjects];
    [self.tvResult reloadData];
}

- (void)onEditAllLongPressed:(UILongPressGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateBegan) {
        // select all addresses
        if (!self.editAllMode) {
            self.editAllMode = YES;
        }
        if (!self.selectedAddresses) self.selectedAddresses = [NSMutableSet set];
        [self.selectedAddresses removeAllObjects];
        for (NSInteger i = 0; i < self.chainCount; ++i) {
            search_result_t result = chainArray[i];
            NSString *address = [NSString stringWithFormat:@"%llX", result->address];
            [self.selectedAddresses addObject:address];
        }
    }
    [self.tvResult reloadData];
}

- (void)onEditAllTapped:(id)sender {
    if (!self.editAllMode) {
        self.editAllMode = YES;
        if (!self.selectedAddresses) self.selectedAddresses = [NSMutableSet set];
        [self.btnEditAll setTitle:@"Confirm Edit" forState:UIControlStateNormal];
        [self.tvResult reloadData];
    } else {
        if (self.selectedAddresses.count == 0) {
            [self exitEditAllMode];
            return;
        }

        __weak typeof(self) weakSelf = self;

        DLGUnityHaxAlert *alert = [[DLGUnityHaxAlert alloc] init];
        alert.titleText = @"Edit All";
        alert.messageText = @"Enter new value for selected addresses:";
        alert.alertStyle = DLGUnityHaxAlertStyleInput;
        alert.inputPlaceholders = @[@"New value"];
        alert.buttonTitles = @[@"OK", @"Cancel"];
        alert.buttonHandler = ^(NSInteger buttonIndex) {
            if (buttonIndex == 0) {
                // ok
                UITextField *textField = alert.textFields.firstObject;
                NSString *value = textField.text;
                if (value.length > 0) {
                    for (NSString *address in weakSelf.selectedAddresses) {
                        if ([weakSelf.delegate respondsToSelector:@selector(DLGMemUIModifyValue:address:type:)]) {
                            DLGMemValueType type = [weakSelf currentValueType];
                            [weakSelf.delegate DLGMemUIModifyValue:value address:address type:type];
                        }
                    }
                }
            }
            [weakSelf exitEditAllMode];
        };

        UIView *targetView = self.window;
        if (!targetView) {
            if (@available(iOS 13.0, *)) {
                targetView = [UIApplication sharedApplication].windows.firstObject;
            } else {
                targetView = [UIApplication sharedApplication].keyWindow;
            }
        }

        if (targetView) {
            [alert showInView:targetView animated:YES];
        }
    }
}

#pragma mark - Progress Bar

- (void)updateSearchProgress:(float)progress {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.progressContainer.hidden = NO;
        self.progressView.progress = progress;
    });
}

- (void)hideSearchProgress {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.progressContainer.hidden = YES;
        self.progressView.progress = 0.0;
    });
}

@end
