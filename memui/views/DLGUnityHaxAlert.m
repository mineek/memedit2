#import "DLGUnityHaxAlert.h"

@interface DLGUnityHaxAlert () <UITextFieldDelegate>

@property (nonatomic) UIView *backgroundView;
@property (nonatomic) UIView *alertContainer;
@property (nonatomic) UILabel *titleLabel;
@property (nonatomic) UILabel *messageLabel;
@property (nonatomic) UIScrollView *contentScrollView;
@property (nonatomic) UIView *contentView;
@property (nonatomic) NSMutableArray<UITextField *> *mutableTextFields;
@property (nonatomic) NSMutableArray<UIButton *> *buttons;

@end

@implementation DLGUnityHaxAlert

- (instancetype)init {
    self = [super init];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    self.backgroundColor = [UIColor clearColor];
    self.translatesAutoresizingMaskIntoConstraints = NO;
    self.alertStyle = DLGUnityHaxAlertStyleDefault;
    self.mutableTextFields = [NSMutableArray array];
    self.buttons = [NSMutableArray array];
}

- (NSArray<UITextField *> *)textFields {
    return [self.mutableTextFields copy];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    if (!self.backgroundView) {
        [self buildAlert];
    }
}

- (void)buildAlert {
    [self initBackgroundView];
    [self initAlertContainer];
    [self initTitleLabel];
    [self initContentScrollView];
    [self initMessageLabel];

    if (self.alertStyle == DLGUnityHaxAlertStyleInput) {
        [self initTextFields];
    }

    [self initButtons];
}

- (void)initBackgroundView {
    UIView *bg = [[UIView alloc] init];
    bg.translatesAutoresizingMaskIntoConstraints = NO;
    bg.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.6];
    [self addSubview:bg];

    [NSLayoutConstraint activateConstraints:@[
        [bg.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [bg.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [bg.topAnchor constraintEqualToAnchor:self.topAnchor],
        [bg.bottomAnchor constraintEqualToAnchor:self.bottomAnchor]
    ]];

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onBackgroundTapped:)];
    [bg addGestureRecognizer:tap];

    self.backgroundView = bg;
}

- (void)initAlertContainer {
    UIView *container = [[UIView alloc] init];
    container.translatesAutoresizingMaskIntoConstraints = NO;
    container.backgroundColor = [UIColor colorWithWhite:0.12 alpha:0.95];
    container.layer.cornerRadius = 16;
    container.layer.shadowColor = [UIColor blackColor].CGColor;
    container.layer.shadowOffset = CGSizeMake(0, 4);
    container.layer.shadowRadius = 12;
    container.layer.shadowOpacity = 0.5;
    [self addSubview:container];

    CGFloat maxWidth = 340;
    if (self.alertStyle == DLGUnityHaxAlertStyleInput && self.inputPlaceholders.count > 2) {
        maxWidth = 360;
    }

    [NSLayoutConstraint activateConstraints:@[
        [container.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
        [container.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
        [container.widthAnchor constraintLessThanOrEqualToConstant:maxWidth],
        [container.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.leadingAnchor constant:20],
        [container.trailingAnchor constraintLessThanOrEqualToAnchor:self.trailingAnchor constant:-20]
    ]];

    self.alertContainer = container;
}

- (void)initTitleLabel {
    UILabel *label = [[UILabel alloc] init];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.text = self.titleText ?: @"Alert";
    label.textColor = [UIColor whiteColor];
    label.font = [UIFont systemFontOfSize:20 weight:UIFontWeightBold];
    label.textAlignment = NSTextAlignmentCenter;
    label.numberOfLines = 0;
    [self.alertContainer addSubview:label];

    [NSLayoutConstraint activateConstraints:@[
        [label.topAnchor constraintEqualToAnchor:self.alertContainer.topAnchor constant:20],
        [label.leadingAnchor constraintEqualToAnchor:self.alertContainer.leadingAnchor constant:20],
        [label.trailingAnchor constraintEqualToAnchor:self.alertContainer.trailingAnchor constant:-20]
    ]];

    self.titleLabel = label;
}

- (void)initContentScrollView {
    UIScrollView *scrollView = [[UIScrollView alloc] init];
    scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    scrollView.showsVerticalScrollIndicator = YES;
    scrollView.alwaysBounceVertical = NO;
    scrollView.backgroundColor = [UIColor clearColor];
    [self.alertContainer addSubview:scrollView];

    UIView *contentView = [[UIView alloc] init];
    contentView.translatesAutoresizingMaskIntoConstraints = NO;
    contentView.backgroundColor = [UIColor clearColor];
    [scrollView addSubview:contentView];

    NSLayoutConstraint *contentHeightConstraint = [scrollView.heightAnchor constraintEqualToAnchor:contentView.heightAnchor];
    contentHeightConstraint.priority = UILayoutPriorityDefaultHigh - 1;

    NSLayoutConstraint *maxHeightConstraint = [scrollView.heightAnchor constraintLessThanOrEqualToConstant:300];
    maxHeightConstraint.priority = UILayoutPriorityRequired;

    [NSLayoutConstraint activateConstraints:@[
        [scrollView.topAnchor constraintEqualToAnchor:self.titleLabel.bottomAnchor constant:12],
        [scrollView.leadingAnchor constraintEqualToAnchor:self.alertContainer.leadingAnchor],
        [scrollView.trailingAnchor constraintEqualToAnchor:self.alertContainer.trailingAnchor],
        contentHeightConstraint,
        maxHeightConstraint,

        [contentView.topAnchor constraintEqualToAnchor:scrollView.topAnchor],
        [contentView.leadingAnchor constraintEqualToAnchor:scrollView.leadingAnchor],
        [contentView.trailingAnchor constraintEqualToAnchor:scrollView.trailingAnchor],
        [contentView.bottomAnchor constraintEqualToAnchor:scrollView.bottomAnchor],
        [contentView.widthAnchor constraintEqualToAnchor:scrollView.widthAnchor]
    ]];

    self.contentScrollView = scrollView;
    self.contentView = contentView;
}

- (void)initMessageLabel {
    UILabel *label = [[UILabel alloc] init];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.text = self.messageText ?: @"";
    label.textColor = [UIColor colorWithWhite:0.95 alpha:1.0];
    label.font = [UIFont systemFontOfSize:15 weight:UIFontWeightRegular];
    label.textAlignment = NSTextAlignmentLeft;
    label.numberOfLines = 0;
    label.lineBreakMode = NSLineBreakByWordWrapping;
    label.alpha = 1.0;
    label.opaque = NO;
    label.backgroundColor = [UIColor clearColor];

    [label setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisVertical];
    [label setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisVertical];

    [self.contentView addSubview:label];

    NSMutableArray *constraints = [NSMutableArray arrayWithArray:@[
        [label.topAnchor constraintEqualToAnchor:self.contentView.topAnchor constant:12],
        [label.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:20],
        [label.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-20]
    ]];

    // if no text fields will be added, set bottom constraint
    if (self.alertStyle != DLGUnityHaxAlertStyleInput || !self.inputPlaceholders || self.inputPlaceholders.count == 0) {
        [constraints addObject:[label.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-12]];
    }

    [NSLayoutConstraint activateConstraints:constraints];

    self.messageLabel = label;
}

- (void)initTextFields {
    if (!self.inputPlaceholders || self.inputPlaceholders.count == 0) return;

    UIView *lastView = self.messageLabel;

    for (NSInteger i = 0; i < self.inputPlaceholders.count; i++) {
        UITextField *textField = [[UITextField alloc] init];
        textField.translatesAutoresizingMaskIntoConstraints = NO;
        textField.placeholder = self.inputPlaceholders[i];
        textField.textColor = [UIColor whiteColor];
        textField.font = [UIFont systemFontOfSize:15];
        textField.backgroundColor = [UIColor colorWithWhite:0.2 alpha:0.8];
        textField.layer.cornerRadius = 8;
        textField.delegate = self;
        textField.returnKeyType = (i == self.inputPlaceholders.count - 1) ? UIReturnKeyDone : UIReturnKeyNext;
        textField.tag = i;
        textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        textField.autocorrectionType = UITextAutocorrectionTypeNo;

        if (self.inputKeyboardTypes && i < self.inputKeyboardTypes.count) {
            textField.keyboardType = [self.inputKeyboardTypes[i] integerValue];
        }

        UIView *paddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 12, 40)];
        textField.leftView = paddingView;
        textField.leftViewMode = UITextFieldViewModeAlways;
        textField.rightView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 12, 40)];
        textField.rightViewMode = UITextFieldViewModeAlways;

        [self.contentView addSubview:textField];
        [self.mutableTextFields addObject:textField];

        [NSLayoutConstraint activateConstraints:@[
            [textField.topAnchor constraintEqualToAnchor:lastView.bottomAnchor constant:12],
            [textField.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:20],
            [textField.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-20],
            [textField.heightAnchor constraintEqualToConstant:44]
        ]];

        lastView = textField;
    }

    [lastView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor constant:-12].active = YES;
}

- (void)initButtons {
    if (!self.buttonTitles || self.buttonTitles.count == 0) {
        self.buttonTitles = @[@"OK"];
    }

    UIView *buttonContainer = [[UIView alloc] init];
    buttonContainer.translatesAutoresizingMaskIntoConstraints = NO;
    [self.alertContainer addSubview:buttonContainer];

    // Separator line
    UIView *separator = [[UIView alloc] init];
    separator.translatesAutoresizingMaskIntoConstraints = NO;
    separator.backgroundColor = [UIColor colorWithWhite:0.3 alpha:0.5];
    [self.alertContainer addSubview:separator];

    [NSLayoutConstraint activateConstraints:@[
        [separator.topAnchor constraintEqualToAnchor:self.contentScrollView.bottomAnchor constant:12],
        [separator.leadingAnchor constraintEqualToAnchor:self.alertContainer.leadingAnchor constant:16],
        [separator.trailingAnchor constraintEqualToAnchor:self.alertContainer.trailingAnchor constant:-16],
        [separator.heightAnchor constraintEqualToConstant:0.5],

        [buttonContainer.topAnchor constraintEqualToAnchor:separator.bottomAnchor],
        [buttonContainer.leadingAnchor constraintEqualToAnchor:self.alertContainer.leadingAnchor],
        [buttonContainer.trailingAnchor constraintEqualToAnchor:self.alertContainer.trailingAnchor],
        [buttonContainer.bottomAnchor constraintEqualToAnchor:self.alertContainer.bottomAnchor],
        [buttonContainer.heightAnchor constraintEqualToConstant:54]
    ]];

    // create buttons
    NSInteger buttonCount = MIN(self.buttonTitles.count, 3);

    for (NSInteger i = 0; i < buttonCount; i++) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
        btn.translatesAutoresizingMaskIntoConstraints = NO;
        btn.tag = i;

        [btn setTitle:self.buttonTitles[i] forState:UIControlStateNormal];
        [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];

        if (i == buttonCount - 1) {
            btn.titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
        } else {
            btn.titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightRegular];
            [btn setTitleColor:[UIColor colorWithRed:0.0 green:0.478 blue:1.0 alpha:1.0] forState:UIControlStateNormal];
        }

        [btn addTarget:self action:@selector(onButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [buttonContainer addSubview:btn];
        [self.buttons addObject:btn];

        if (buttonCount == 1) {
            [NSLayoutConstraint activateConstraints:@[
                [btn.topAnchor constraintEqualToAnchor:buttonContainer.topAnchor],
                [btn.leadingAnchor constraintEqualToAnchor:buttonContainer.leadingAnchor],
                [btn.trailingAnchor constraintEqualToAnchor:buttonContainer.trailingAnchor],
                [btn.bottomAnchor constraintEqualToAnchor:buttonContainer.bottomAnchor]
            ]];
        } else if (buttonCount == 2) {
            if (i == 0) {
                [NSLayoutConstraint activateConstraints:@[
                    [btn.topAnchor constraintEqualToAnchor:buttonContainer.topAnchor],
                    [btn.leadingAnchor constraintEqualToAnchor:buttonContainer.leadingAnchor],
                    [btn.bottomAnchor constraintEqualToAnchor:buttonContainer.bottomAnchor],
                    [btn.widthAnchor constraintEqualToAnchor:buttonContainer.widthAnchor multiplier:0.5]
                ]];

                UIView *sep = [[UIView alloc] init];
                sep.translatesAutoresizingMaskIntoConstraints = NO;
                sep.backgroundColor = [UIColor colorWithWhite:0.3 alpha:0.5];
                [buttonContainer addSubview:sep];
                [NSLayoutConstraint activateConstraints:@[
                    [sep.centerXAnchor constraintEqualToAnchor:buttonContainer.centerXAnchor],
                    [sep.topAnchor constraintEqualToAnchor:buttonContainer.topAnchor constant:8],
                    [sep.bottomAnchor constraintEqualToAnchor:buttonContainer.bottomAnchor constant:-8],
                    [sep.widthAnchor constraintEqualToConstant:0.5]
                ]];
            } else {
                [NSLayoutConstraint activateConstraints:@[
                    [btn.topAnchor constraintEqualToAnchor:buttonContainer.topAnchor],
                    [btn.trailingAnchor constraintEqualToAnchor:buttonContainer.trailingAnchor],
                    [btn.bottomAnchor constraintEqualToAnchor:buttonContainer.bottomAnchor],
                    [btn.widthAnchor constraintEqualToAnchor:buttonContainer.widthAnchor multiplier:0.5]
                ]];
            }
        } else {
            CGFloat buttonHeight = 54.0;
            if (i == 0) {
                [NSLayoutConstraint activateConstraints:@[
                    [btn.topAnchor constraintEqualToAnchor:buttonContainer.topAnchor],
                    [btn.leadingAnchor constraintEqualToAnchor:buttonContainer.leadingAnchor],
                    [btn.trailingAnchor constraintEqualToAnchor:buttonContainer.trailingAnchor],
                    [btn.heightAnchor constraintEqualToConstant:buttonHeight]
                ]];
            } else if (i == 1) {
                UIButton *prevBtn = self.buttons[0];
                [NSLayoutConstraint activateConstraints:@[
                    [btn.topAnchor constraintEqualToAnchor:prevBtn.bottomAnchor],
                    [btn.leadingAnchor constraintEqualToAnchor:buttonContainer.leadingAnchor],
                    [btn.trailingAnchor constraintEqualToAnchor:buttonContainer.trailingAnchor],
                    [btn.heightAnchor constraintEqualToConstant:buttonHeight]
                ]];

                UIView *sep = [[UIView alloc] init];
                sep.translatesAutoresizingMaskIntoConstraints = NO;
                sep.backgroundColor = [UIColor colorWithWhite:0.3 alpha:0.5];
                [buttonContainer addSubview:sep];
                [NSLayoutConstraint activateConstraints:@[
                    [sep.topAnchor constraintEqualToAnchor:btn.topAnchor],
                    [sep.leadingAnchor constraintEqualToAnchor:buttonContainer.leadingAnchor constant:16],
                    [sep.trailingAnchor constraintEqualToAnchor:buttonContainer.trailingAnchor constant:-16],
                    [sep.heightAnchor constraintEqualToConstant:0.5]
                ]];
            } else {
                UIButton *prevBtn = self.buttons[1];
                [NSLayoutConstraint activateConstraints:@[
                    [btn.topAnchor constraintEqualToAnchor:prevBtn.bottomAnchor],
                    [btn.leadingAnchor constraintEqualToAnchor:buttonContainer.leadingAnchor],
                    [btn.trailingAnchor constraintEqualToAnchor:buttonContainer.trailingAnchor],
                    [btn.bottomAnchor constraintEqualToAnchor:buttonContainer.bottomAnchor],
                    [btn.heightAnchor constraintEqualToConstant:buttonHeight]
                ]];

                UIView *sep = [[UIView alloc] init];
                sep.translatesAutoresizingMaskIntoConstraints = NO;
                sep.backgroundColor = [UIColor colorWithWhite:0.3 alpha:0.5];
                [buttonContainer addSubview:sep];
                [NSLayoutConstraint activateConstraints:@[
                    [sep.topAnchor constraintEqualToAnchor:btn.topAnchor],
                    [sep.leadingAnchor constraintEqualToAnchor:buttonContainer.leadingAnchor constant:16],
                    [sep.trailingAnchor constraintEqualToAnchor:buttonContainer.trailingAnchor constant:-16],
                    [sep.heightAnchor constraintEqualToConstant:0.5]
                ]];

                for (NSLayoutConstraint *constraint in buttonContainer.constraints) {
                    if (constraint.firstAttribute == NSLayoutAttributeHeight) {
                        constraint.constant = buttonHeight * 3;
                    }
                }
            }
        }
    }
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    NSInteger nextTag = textField.tag + 1;
    UITextField *nextField = nil;

    for (UITextField *field in self.mutableTextFields) {
        if (field.tag == nextTag) {
            nextField = field;
            break;
        }
    }

    if (nextField) {
        [nextField becomeFirstResponder];
    } else {
        [textField resignFirstResponder];
        if (self.buttons.count > 0) {
            [self onButtonTapped:self.buttons[0]];
        }
    }

    return YES;
}

#pragma mark - Actions

- (void)onButtonTapped:(UIButton *)sender {
    [self dismissKeyboard];

    if (self.buttonHandler) {
        self.buttonHandler(sender.tag);
    }

    [self hideAnimated:YES];
}

- (void)onBackgroundTapped:(id)sender {
    [self dismissKeyboard];
}

- (void)dismissKeyboard {
    for (UITextField *field in self.mutableTextFields) {
        [field resignFirstResponder];
    }
}

#pragma mark - Show/Hide

- (void)showInView:(UIView *)view animated:(BOOL)animated {
    if (!view) return;

    [view addSubview:self];

    [NSLayoutConstraint activateConstraints:@[
        [self.leadingAnchor constraintEqualToAnchor:view.leadingAnchor],
        [self.trailingAnchor constraintEqualToAnchor:view.trailingAnchor],
        [self.topAnchor constraintEqualToAnchor:view.topAnchor],
        [self.bottomAnchor constraintEqualToAnchor:view.bottomAnchor]
    ]];

    [self layoutIfNeeded];

    if (animated) {
        self.alpha = 0;
        self.alertContainer.transform = CGAffineTransformMakeScale(0.9, 0.9);

        [UIView animateWithDuration:0.3
                              delay:0
             usingSpringWithDamping:0.8
              initialSpringVelocity:0.5
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
            self.alpha = 1;
            self.alertContainer.transform = CGAffineTransformIdentity;
        } completion:nil];
    }
}

- (void)hideAnimated:(BOOL)animated {
    if (animated) {
        [UIView animateWithDuration:0.2
                              delay:0
                            options:UIViewAnimationOptionCurveEaseIn
                         animations:^{
            self.alpha = 0;
            self.alertContainer.transform = CGAffineTransformMakeScale(0.95, 0.95);
        } completion:^(BOOL finished) {
            [self removeFromSuperview];
        }];
    } else {
        [self removeFromSuperview];
    }
}

@end
