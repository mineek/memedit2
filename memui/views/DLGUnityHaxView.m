#import "DLGUnityHaxView.h"
#import "DLGUnityHaxAlert.h"
#import "../../RemoteLog.h"
#include "../../il2cpp/il2cpp_helper.h"

#define UNITY_LOG(fmt, ...) RLog(@"[UnityHax] " fmt, ##__VA_ARGS__)

typedef enum {
    UNITY_VIEW_MODE_CLASSES,
    UNITY_VIEW_MODE_METHODS,
    UNITY_VIEW_MODE_FIELDS,
    UNITY_VIEW_MODE_INSTANCES
} UnityViewMode;

@interface DLGUnityHaxView () <UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate>

@property (nonatomic) UnityViewMode viewMode;
@property (nonatomic) UIView *backgroundView;
@property (nonatomic) UIView *containerView;
@property (nonatomic) UILabel *titleLabel;
@property (nonatomic) UIButton *btnClose;
@property (nonatomic) UIButton *btnBack;
@property (nonatomic) UISegmentedControl *viewModeControl;
@property (nonatomic) UISegmentedControl *instanceModeControl;
@property (nonatomic) UISearchBar *searchBar;
@property (nonatomic) UITableView *tableView;
@property (nonatomic) UIActivityIndicatorView *loadingIndicator;

@property (nonatomic) Il2CppEnumResult *classResults;
@property (nonatomic) Il2CppMethodEnumResult *methodResults;
@property (nonatomic) Il2CppFieldEnumResult *fieldResults;
@property (nonatomic) Il2CppInstanceEnumResult *instanceResults;
@property (nonatomic) Il2CppClass *selectedClass;
@property (nonatomic) void *selectedInstance;

@end

@implementation DLGUnityHaxView

- (instancetype)init {
    UNITY_LOG(@"Init called");
    self = [super init];
    if (self) {
        self.viewMode = UNITY_VIEW_MODE_CLASSES;
        self.classResults = NULL;
        self.methodResults = NULL;
        self.fieldResults = NULL;
        self.instanceResults = NULL;
        self.selectedClass = NULL;
        self.selectedInstance = NULL;
        [self initViews];
    }
    return self;
}

- (void)dealloc {
    if (self.classResults) {
        il2cpp_free_enum_result(self.classResults);
    }
    if (self.methodResults) {
        il2cpp_free_method_enum_result(self.methodResults);
    }
    if (self.fieldResults) {
        il2cpp_free_field_enum_result(self.fieldResults);
    }
    if (self.instanceResults) {
        il2cpp_free_instance_enum_result(self.instanceResults);
    }
}

- (void)initViews {
    self.backgroundColor = [UIColor clearColor];
    self.translatesAutoresizingMaskIntoConstraints = NO;

    [self initBackgroundView];
    [self initContainerView];
    [self initTitleBar];
    [self initViewModeControl];
    [self initInstanceModeControl];
    [self initSearchBar];
    [self initTableView];
    [self initLoadingIndicator];
}

- (void)initBackgroundView {
    UIView *bg = [[UIView alloc] init];
    bg.translatesAutoresizingMaskIntoConstraints = NO;
    bg.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.8];
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

- (void)initContainerView {
    UIView *container = [[UIView alloc] init];
    container.translatesAutoresizingMaskIntoConstraints = NO;
    container.backgroundColor = [UIColor colorWithWhite:0.08 alpha:0.98];
    container.layer.cornerRadius = 16;
    container.layer.shadowColor = [UIColor blackColor].CGColor;
    container.layer.shadowOffset = CGSizeMake(0, 8);
    container.layer.shadowRadius = 24;
    container.layer.shadowOpacity = 0.7;
    [self addSubview:container];

    [NSLayoutConstraint activateConstraints:@[
        [container.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
        [container.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
        [container.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.leadingAnchor constant:20],
        [container.trailingAnchor constraintLessThanOrEqualToAnchor:self.trailingAnchor constant:-20],
        [container.topAnchor constraintGreaterThanOrEqualToAnchor:self.topAnchor constant:40],
        [container.bottomAnchor constraintLessThanOrEqualToAnchor:self.bottomAnchor constant:-40],
        [container.widthAnchor constraintEqualToAnchor:self.widthAnchor multiplier:0.9 constant:0],
        [container.heightAnchor constraintEqualToAnchor:self.heightAnchor multiplier:0.85 constant:0]
    ]];

    NSLayoutConstraint *maxWidth = [container.widthAnchor constraintLessThanOrEqualToConstant:600];
    maxWidth.priority = UILayoutPriorityDefaultHigh;
    maxWidth.active = YES;

    NSLayoutConstraint *maxHeight = [container.heightAnchor constraintLessThanOrEqualToConstant:700];
    maxHeight.priority = UILayoutPriorityDefaultHigh;
    maxHeight.active = YES;

    self.containerView = container;
}

- (void)initTitleBar {
    UILabel *label = [[UILabel alloc] init];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.text = @"Unity Hax";
    label.textColor = [UIColor whiteColor];
    label.font = [UIFont systemFontOfSize:24 weight:UIFontWeightBold];
    label.textAlignment = NSTextAlignmentCenter;
    [self.containerView addSubview:label];

    [NSLayoutConstraint activateConstraints:@[
        [label.topAnchor constraintEqualToAnchor:self.containerView.topAnchor constant:20],
        [label.leadingAnchor constraintEqualToAnchor:self.containerView.leadingAnchor constant:60],
        [label.trailingAnchor constraintEqualToAnchor:self.containerView.trailingAnchor constant:-60]
    ]];

    self.titleLabel = label;

    // close button
    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    closeBtn.translatesAutoresizingMaskIntoConstraints = NO;
    if (@available(iOS 13.0, *)) {
        [closeBtn setImage:[UIImage systemImageNamed:@"xmark.circle.fill"] forState:UIControlStateNormal];
    } else {
        [closeBtn setTitle:@"✕" forState:UIControlStateNormal];
    }
    closeBtn.tintColor = [UIColor whiteColor];
    [closeBtn addTarget:self action:@selector(onCloseButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.containerView addSubview:closeBtn];

    [NSLayoutConstraint activateConstraints:@[
        [closeBtn.trailingAnchor constraintEqualToAnchor:self.containerView.trailingAnchor constant:-20],
        [closeBtn.centerYAnchor constraintEqualToAnchor:label.centerYAnchor],
        [closeBtn.widthAnchor constraintEqualToConstant:32],
        [closeBtn.heightAnchor constraintEqualToConstant:32]
    ]];

    self.btnClose = closeBtn;

    // back button
    UIButton *backBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    backBtn.translatesAutoresizingMaskIntoConstraints = NO;
    if (@available(iOS 13.0, *)) {
        [backBtn setImage:[UIImage systemImageNamed:@"chevron.left.circle.fill"] forState:UIControlStateNormal];
    } else {
        [backBtn setTitle:@"←" forState:UIControlStateNormal];
    }
    backBtn.tintColor = [UIColor whiteColor];
    backBtn.hidden = YES;
    [backBtn addTarget:self action:@selector(onBackButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.containerView addSubview:backBtn];

    [NSLayoutConstraint activateConstraints:@[
        [backBtn.leadingAnchor constraintEqualToAnchor:self.containerView.leadingAnchor constant:20],
        [backBtn.centerYAnchor constraintEqualToAnchor:label.centerYAnchor],
        [backBtn.widthAnchor constraintEqualToConstant:32],
        [backBtn.heightAnchor constraintEqualToConstant:32]
    ]];

    self.btnBack = backBtn;
}

- (void)initViewModeControl {
    UISegmentedControl *control = [[UISegmentedControl alloc] initWithItems:@[@"Classes"]];
    control.translatesAutoresizingMaskIntoConstraints = NO;
    control.selectedSegmentIndex = 0;
    control.hidden = YES; //we only haev classes anyway
    [control addTarget:self action:@selector(onViewModeChanged:) forControlEvents:UIControlEventValueChanged];
    [self.containerView addSubview:control];

    [NSLayoutConstraint activateConstraints:@[
        [control.topAnchor constraintEqualToAnchor:self.titleLabel.bottomAnchor constant:16],
        [control.leadingAnchor constraintEqualToAnchor:self.containerView.leadingAnchor constant:20],
        [control.trailingAnchor constraintEqualToAnchor:self.containerView.trailingAnchor constant:-20],
        [control.heightAnchor constraintEqualToConstant:32]
    ]];

    self.viewModeControl = control;
}

- (void)initInstanceModeControl {
    UISegmentedControl *control = [[UISegmentedControl alloc] initWithItems:@[@"Fields", @"Methods"]];
    control.translatesAutoresizingMaskIntoConstraints = NO;
    control.selectedSegmentIndex = 0;
    control.hidden = YES;
    [control addTarget:self action:@selector(onInstanceModeChanged:) forControlEvents:UIControlEventValueChanged];
    [self.containerView addSubview:control];

    [NSLayoutConstraint activateConstraints:@[
        [control.topAnchor constraintEqualToAnchor:self.titleLabel.bottomAnchor constant:16],
        [control.leadingAnchor constraintEqualToAnchor:self.containerView.leadingAnchor constant:20],
        [control.trailingAnchor constraintEqualToAnchor:self.containerView.trailingAnchor constant:-20],
        [control.heightAnchor constraintEqualToConstant:32]
    ]];

    self.instanceModeControl = control;
}

- (void)initSearchBar {
    UISearchBar *searchBar = [[UISearchBar alloc] init];
    searchBar.translatesAutoresizingMaskIntoConstraints = NO;
    searchBar.placeholder = @"Search classes...";
    searchBar.delegate = self;
    searchBar.searchBarStyle = UISearchBarStyleMinimal;
    searchBar.barTintColor = [UIColor colorWithWhite:0.15 alpha:1.0];
    [self.containerView addSubview:searchBar];

    [NSLayoutConstraint activateConstraints:@[
        [searchBar.topAnchor constraintEqualToAnchor:self.viewModeControl.bottomAnchor constant:8],
        [searchBar.leadingAnchor constraintEqualToAnchor:self.containerView.leadingAnchor constant:12],
        [searchBar.trailingAnchor constraintEqualToAnchor:self.containerView.trailingAnchor constant:-12]
    ]];

    self.searchBar = searchBar;
}

- (void)initTableView {
    UITableView *tableView = [[UITableView alloc] init];
    tableView.translatesAutoresizingMaskIntoConstraints = NO;
    tableView.delegate = self;
    tableView.dataSource = self;
    tableView.backgroundColor = [UIColor clearColor];
    tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    tableView.separatorColor = [UIColor colorWithWhite:1.0 alpha:0.1];
    tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    [self.containerView addSubview:tableView];

    [NSLayoutConstraint activateConstraints:@[
        [tableView.topAnchor constraintEqualToAnchor:self.searchBar.bottomAnchor constant:8],
        [tableView.leadingAnchor constraintEqualToAnchor:self.containerView.leadingAnchor constant:20],
        [tableView.trailingAnchor constraintEqualToAnchor:self.containerView.trailingAnchor constant:-20],
        [tableView.bottomAnchor constraintEqualToAnchor:self.containerView.bottomAnchor constant:-20]
    ]];

    self.tableView = tableView;
}

- (void)initLoadingIndicator {
    UIActivityIndicatorView *indicator;
    if (@available(iOS 13.0, *)) {
        indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    } else {
        indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    }
    indicator.translatesAutoresizingMaskIntoConstraints = NO;
    indicator.color = [UIColor whiteColor];
    indicator.hidesWhenStopped = YES;
    [self.containerView addSubview:indicator];

    [NSLayoutConstraint activateConstraints:@[
        [indicator.centerXAnchor constraintEqualToAnchor:self.containerView.centerXAnchor],
        [indicator.centerYAnchor constraintEqualToAnchor:self.containerView.centerYAnchor]
    ]];

    self.loadingIndicator = indicator;
}

#pragma mark - Actions

- (void)onCloseButtonTapped:(id)sender {
    [self hideAnimated:YES];
}

- (void)onBackButtonTapped:(id)sender {
    self.viewMode = UNITY_VIEW_MODE_CLASSES;
    self.selectedClass = NULL;
    self.selectedInstance = NULL;
    if (self.methodResults) {
        il2cpp_free_method_enum_result(self.methodResults);
        self.methodResults = NULL;
    }
    if (self.fieldResults) {
        il2cpp_free_field_enum_result(self.fieldResults);
        self.fieldResults = NULL;
    }
    self.btnBack.hidden = YES;
    self.instanceModeControl.hidden = YES;
    self.titleLabel.text = @"Unity Hax";
    self.searchBar.placeholder = @"Search classes...";
    [self.tableView reloadData];
}

- (void)onBackgroundTapped:(id)sender {
    [self onCloseButtonTapped:sender];
}

- (void)onViewModeChanged:(UISegmentedControl *)sender {
    self.viewMode = UNITY_VIEW_MODE_CLASSES;
    self.searchBar.placeholder = @"Search classes...";
    [self.tableView reloadData];
}

- (void)onInstanceModeChanged:(UISegmentedControl *)sender {
    if (sender.selectedSegmentIndex == 0) {
        // fields
        [self showFieldsForInstance:self.selectedInstance];
    } else {
        // methods
        [self showMethodsForInstance:self.selectedInstance];
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.viewMode == UNITY_VIEW_MODE_CLASSES) {
        return self.classResults ? self.classResults->class_count : 0;
    } else if (self.viewMode == UNITY_VIEW_MODE_METHODS) {
        return self.methodResults ? self.methodResults->method_count : 0;
    } else if (self.viewMode == UNITY_VIEW_MODE_FIELDS) {
        return self.fieldResults ? self.fieldResults->field_count : 0;
    } else if (self.viewMode == UNITY_VIEW_MODE_INSTANCES) {
        return self.instanceResults ? self.instanceResults->instance_count : 0;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"UnityHaxCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];

    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
        cell.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.5];
        cell.textLabel.textColor = [UIColor whiteColor];
        cell.textLabel.font = [UIFont monospacedSystemFontOfSize:13 weight:UIFontWeightRegular];
        cell.detailTextLabel.textColor = [UIColor colorWithWhite:0.7 alpha:1.0];
        cell.detailTextLabel.font = [UIFont systemFontOfSize:11];
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;

        UIView *selectedBg = [[UIView alloc] init];
        selectedBg.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.1];
        cell.selectedBackgroundView = selectedBg;
    }

    if (self.viewMode == UNITY_VIEW_MODE_CLASSES) {
        if (self.classResults && indexPath.row < self.classResults->class_count) {
            Il2CppClassInfo info = self.classResults->classes[indexPath.row];
            cell.textLabel.text = [NSString stringWithUTF8String:info.name];
            if (strlen(info.namespace) > 0) {
                cell.detailTextLabel.text = [NSString stringWithUTF8String:info.namespace];
            } else {
                cell.detailTextLabel.text = @"(global)";
            }
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
    } else if (self.viewMode == UNITY_VIEW_MODE_METHODS) {
        if (self.methodResults && indexPath.row < self.methodResults->method_count) {
            Il2CppMethodInfo info = self.methodResults->methods[indexPath.row];
            cell.textLabel.text = [NSString stringWithUTF8String:info.name];
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%s → %s",
                                         info.is_static ? "static" : "instance",
                                         info.return_type];
            cell.accessoryType = UITableViewCellAccessoryDetailButton;
        }
    } else if (self.viewMode == UNITY_VIEW_MODE_FIELDS) {
        if (self.fieldResults && indexPath.row < self.fieldResults->field_count) {
            Il2CppFieldInfo info = self.fieldResults->fields[indexPath.row];
            cell.textLabel.text = [NSString stringWithUTF8String:info.name];
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%s%s",
                                         info.is_static ? "static " : "",
                                         info.type_name];
            cell.accessoryType = UITableViewCellAccessoryDetailButton;
        }
    } else if (self.viewMode == UNITY_VIEW_MODE_INSTANCES) {
        if (self.instanceResults && indexPath.row < self.instanceResults->instance_count) {
            Il2CppInstanceInfo info = self.instanceResults->instances[indexPath.row];
            cell.textLabel.text = [NSString stringWithFormat:@"Instance %d", indexPath.row];
            cell.detailTextLabel.text = [NSString stringWithFormat:@"0x%lx", (unsigned long)info.instance];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
    }

    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if (self.viewMode == UNITY_VIEW_MODE_CLASSES) {
        if (self.classResults && indexPath.row < self.classResults->class_count) {
            Il2CppClassInfo info = self.classResults->classes[indexPath.row];
            [self showClassOptionsForClass:info.klass className:[NSString stringWithUTF8String:info.full_name]];
        }
    } else if (self.viewMode == UNITY_VIEW_MODE_METHODS) {
        if (self.methodResults && indexPath.row < self.methodResults->method_count) {
            Il2CppMethodInfo info = self.methodResults->methods[indexPath.row];
            [self showInvokeOptionsForMethod:info];
        }
    } else if (self.viewMode == UNITY_VIEW_MODE_INSTANCES) {
        if (self.instanceResults && indexPath.row < self.instanceResults->instance_count) {
            Il2CppInstanceInfo info = self.instanceResults->instances[indexPath.row];
            [self showInstanceDetailsForInstance:info.instance];
        }
    }
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    if (self.viewMode == UNITY_VIEW_MODE_METHODS) {
        if (self.methodResults && indexPath.row < self.methodResults->method_count) {
            Il2CppMethodInfo info = self.methodResults->methods[indexPath.row];
            [self showMethodDetails:info];
        }
    } else if (self.viewMode == UNITY_VIEW_MODE_FIELDS) {
        if (self.fieldResults && indexPath.row < self.fieldResults->field_count) {
            Il2CppFieldInfo info = self.fieldResults->fields[indexPath.row];
            [self showFieldDetails:info];
        }
    }
}

#pragma mark - UISearchBarDelegate

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    if (searchText.length == 0) {
        if (self.classResults) {
            il2cpp_free_enum_result(self.classResults);
        }
        self.classResults = il2cpp_enumerate_classes();
        [self.tableView reloadData];
    } else {
        if (self.classResults) {
            il2cpp_free_enum_result(self.classResults);
        }
        self.classResults = il2cpp_search_classes([searchText UTF8String]);
        [self.tableView reloadData];
    }
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
    searchBar.text = @"";
    if (self.viewMode == UNITY_VIEW_MODE_CLASSES) {
        if (self.classResults) {
            il2cpp_free_enum_result(self.classResults);
        }
        self.classResults = il2cpp_enumerate_classes();
        [self.tableView reloadData];
    }
}

#pragma mark - Helper Methods

- (void)showMethodsForClass:(Il2CppClass *)klass className:(NSString *)className {
    self.selectedClass = klass;
    self.viewMode = UNITY_VIEW_MODE_METHODS;

    [self.loadingIndicator startAnimating];
    self.tableView.hidden = YES;

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        Il2CppMethodEnumResult* methods = il2cpp_enumerate_methods(klass);

        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.methodResults) {
                il2cpp_free_method_enum_result(self.methodResults);
            }
            self.methodResults = methods;

            self.titleLabel.text = className;
            self.btnBack.hidden = NO;
            self.instanceModeControl.hidden = YES;
            self.searchBar.placeholder = @"Search methods...";

            [self.loadingIndicator stopAnimating];
            self.tableView.hidden = NO;
            [self.tableView reloadData];
        });
    });
}

- (void)showMethodDetails:(Il2CppMethodInfo)info {
    NSString *message = [NSString stringWithFormat:@"Signature:\n%s\n\nReturn Type: %s\nParameters: %d\nType: %s",
                         info.signature,
                         info.return_type,
                         info.param_count,
                         info.is_static ? "Static" : "Instance"];

    DLGUnityHaxAlert *alert = [[DLGUnityHaxAlert alloc] init];
    alert.titleText = @"Method Details";
    alert.messageText = message;
    alert.buttonTitles = @[@"OK"];

    [alert showInView:self animated:YES];
}

- (void)showInvokeOptionsForMethod:(Il2CppMethodInfo)info {
    UNITY_LOG(@"showInvokeOptionsForMethod: %s", info.name);

    int param_count = 0;
    Il2CppParamInfo* params = il2cpp_get_method_params(info.method, &param_count);

    UNITY_LOG(@"showInvokeOptionsForMethod: has %d parameters", param_count);

    if (param_count == 0) {
        [self invokeMethodWithInfo:info params:NULL paramCount:0 paramInfo:NULL];
        if (params) il2cpp_free_param_info(params, param_count);
        return;
    }

    NSMutableString *message = [NSMutableString stringWithFormat:@"Method: %s\nParameters: %d\n\n", info.name, param_count];

    NSMutableArray<NSString *> *placeholders = [NSMutableArray array];
    NSMutableArray *keyboardTypes = [NSMutableArray array];

    for (int i = 0; i < param_count; i++) {
        NSString *paramName = params[i].param_name && strlen(params[i].param_name) > 0
            ? [NSString stringWithUTF8String:params[i].param_name]
            : [NSString stringWithFormat:@"arg%d", i];
        [message appendFormat:@"%d. %s %@\n", i+1, params[i].type_name, paramName];

        NSString *placeholder = paramName;
        UIKeyboardType keyboardType = UIKeyboardTypeDefault;

        switch (params[i].type_enum) {
            case IL2CPP_TYPE_BOOLEAN:
                placeholder = [NSString stringWithFormat:@"%@ (true/false)", paramName];
                break;
            case IL2CPP_TYPE_I1:
            case IL2CPP_TYPE_I2:
            case IL2CPP_TYPE_I4:
            case IL2CPP_TYPE_I8:
            case IL2CPP_TYPE_U1:
            case IL2CPP_TYPE_U2:
            case IL2CPP_TYPE_U4:
            case IL2CPP_TYPE_U8:
                keyboardType = UIKeyboardTypeNumberPad;
                break;
            case IL2CPP_TYPE_R4:
            case IL2CPP_TYPE_R8:
                keyboardType = UIKeyboardTypeDecimalPad;
                break;
            default:
                keyboardType = UIKeyboardTypeDefault;
                break;
        }

        [placeholders addObject:placeholder];
        [keyboardTypes addObject:@(keyboardType)];
    }

    DLGUnityHaxAlert *alert = [[DLGUnityHaxAlert alloc] init];
    alert.titleText = @"Invoke Method";
    alert.messageText = message;
    alert.alertStyle = DLGUnityHaxAlertStyleInput;
    alert.inputPlaceholders = placeholders;
    alert.inputKeyboardTypes = keyboardTypes;
    alert.buttonTitles = @[@"Invoke", @"Cancel"];
    alert.buttonHandler = ^(NSInteger buttonIndex) {
        if (buttonIndex == 0) {
            [self invokeMethodWithInfo:info params:alert.textFields paramCount:param_count paramInfo:params];
        }
        if (params) il2cpp_free_param_info(params, param_count);
    };

    [alert showInView:self animated:YES];
}

- (void)invokeMethodWithInfo:(Il2CppMethodInfo)info params:(NSArray<UITextField *> *)textFields paramCount:(int)paramCount paramInfo:(Il2CppParamInfo *)paramInfo {
    UNITY_LOG(@"invokeMethodWithInfo: %s with %d params", info.name, paramCount);

    void** params = NULL;
    void* param_values[paramCount];

    if (paramCount > 0) {
        params = param_values;

        // parse parameters
        for (int i = 0; i < paramCount; i++) {
            NSString *input = textFields[i].text;
            UNITY_LOG(@"Parameter %d: type=%d, value='%s'", i, paramInfo[i].type_enum, [input UTF8String]);

            switch (paramInfo[i].type_enum) {
                case IL2CPP_TYPE_BOOLEAN: {
                    static bool bval;
                    bval = [input.lowercaseString isEqualToString:@"true"] || [input intValue] != 0;
                    params[i] = &bval;
                    break;
                }
                case IL2CPP_TYPE_I1: {
                    static int8_t i1val;
                    i1val = (int8_t)[input intValue];
                    params[i] = &i1val;
                    break;
                }
                case IL2CPP_TYPE_U1: {
                    static uint8_t u1val;
                    u1val = (uint8_t)[input intValue];
                    params[i] = &u1val;
                    break;
                }
                case IL2CPP_TYPE_I2: {
                    static int16_t i2val;
                    i2val = (int16_t)[input intValue];
                    params[i] = &i2val;
                    break;
                }
                case IL2CPP_TYPE_U2: {
                    static uint16_t u2val;
                    u2val = (uint16_t)[input intValue];
                    params[i] = &u2val;
                    break;
                }
                case IL2CPP_TYPE_I4: {
                    static int32_t i4val;
                    i4val = (int32_t)[input intValue];
                    params[i] = &i4val;
                    break;
                }
                case IL2CPP_TYPE_U4: {
                    static uint32_t u4val;
                    u4val = (uint32_t)[input integerValue];
                    params[i] = &u4val;
                    break;
                }
                case IL2CPP_TYPE_I8: {
                    static int64_t i8val;
                    i8val = (int64_t)[input longLongValue];
                    params[i] = &i8val;
                    break;
                }
                case IL2CPP_TYPE_U8: {
                    static uint64_t u8val;
                    u8val = (uint64_t)[input longLongValue];
                    params[i] = &u8val;
                    break;
                }
                case IL2CPP_TYPE_R4: {
                    static float f4val;
                    f4val = [input floatValue];
                    params[i] = &f4val;
                    break;
                }
                case IL2CPP_TYPE_R8: {
                    static double f8val;
                    f8val = [input doubleValue];
                    params[i] = &f8val;
                    break;
                }
                case IL2CPP_TYPE_STRING: {
                    if (il2cpp_string_new) {
                        static Il2CppString* strval;
                        strval = il2cpp_string_new([input UTF8String]);
                        params[i] = strval;
                    } else {
                        params[i] = NULL;
                    }
                    break;
                }
                default:
                    UNITY_LOG(@"Unsupported parameter type: %d", paramInfo[i].type_enum);
                    params[i] = NULL;
                    break;
            }
        }
    }

    // get target object
    void* obj = NULL;
    if (!info.is_static) {
        if (self.selectedInstance) {
            obj = self.selectedInstance;
        } else {
            DLGUnityHaxAlert *alert = [[DLGUnityHaxAlert alloc] init];
            alert.titleText = @"Error";
            alert.messageText = @"Please run this on a live instance.";
            alert.buttonTitles = @[@"OK"];
            [alert showInView:self animated:YES];
            return;
        }
    }

    // invoke method and show result
    char* result = il2cpp_invoke_method(info.method, obj, params);
    NSString *resultStr = result ? [NSString stringWithUTF8String:result] : @"(null)";

    DLGUnityHaxAlert *alert = [[DLGUnityHaxAlert alloc] init];
    alert.titleText = @"Method Result";
    alert.messageText = [NSString stringWithFormat:@"Method: %s\n\nResult: %@", info.name, resultStr];
    alert.buttonTitles = @[@"OK"];

    [alert showInView:self animated:YES];

    if (result) free(result);
}

- (void)showClassOptionsForClass:(Il2CppClass *)klass className:(NSString *)className {
    DLGUnityHaxAlert *alert = [[DLGUnityHaxAlert alloc] init];
    alert.titleText = @"Class Options";
    alert.messageText = [NSString stringWithFormat:@"What would you like to do with %@?", className];
    alert.buttonTitles = @[@"View Methods", @"View Fields", @"Find Instances", @"Cancel"];
    alert.buttonHandler = ^(NSInteger buttonIndex) {
        if (buttonIndex == 0) {
            [self showMethodsForClass:klass className:className];
        } else if (buttonIndex == 1) {
            [self showFieldsForClass:klass className:className];
        } else if (buttonIndex == 2) {
            [self showInstanceOptionsForClass:klass className:className];
        }
    };

    [alert showInView:self animated:YES];
}

- (void)showFieldsForClass:(Il2CppClass *)klass className:(NSString *)className {
    self.selectedClass = klass;
    self.viewMode = UNITY_VIEW_MODE_FIELDS;

    [self.loadingIndicator startAnimating];
    self.tableView.hidden = YES;

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        Il2CppFieldEnumResult* fields = il2cpp_enumerate_fields(klass);

        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.fieldResults) {
                il2cpp_free_field_enum_result(self.fieldResults);
            }
            self.fieldResults = fields;

            self.titleLabel.text = className;
            self.btnBack.hidden = NO;
            self.instanceModeControl.hidden = YES;
            self.searchBar.placeholder = @"Search fields...";

            [self.loadingIndicator stopAnimating];
            self.tableView.hidden = NO;
            [self.tableView reloadData];
        });
    });
}

- (void)showInstanceOptionsForClass:(Il2CppClass *)klass className:(NSString *)className {
    self.selectedClass = klass;

    DLGUnityHaxAlert *alert = [[DLGUnityHaxAlert alloc] init];
    alert.titleText = @"Find Instances";
    alert.messageText = @"How would you like to get instances of this class?";
    alert.buttonTitles = @[@"Manual Entry", @"Scan Memory", @"Cancel"];
    alert.buttonHandler = ^(NSInteger buttonIndex) {
        if (buttonIndex == 0) {
            [self showManualInstanceInput:klass className:className];
        } else if (buttonIndex == 1) {
            [self scanForInstances:klass className:className];
        }
    };

    [alert showInView:self animated:YES];
}

- (void)showManualInstanceInput:(Il2CppClass *)klass className:(NSString *)className {
    DLGUnityHaxAlert *alert = [[DLGUnityHaxAlert alloc] init];
    alert.titleText = @"Manual Instance Entry";
    alert.messageText = @"Enter the object pointer address (eg, 0x1234abcd)";
    alert.alertStyle = DLGUnityHaxAlertStyleInput;
    alert.inputPlaceholders = @[@"0x"];
    alert.buttonTitles = @[@"Open", @"Cancel"];
    alert.buttonHandler = ^(NSInteger buttonIndex) {
        if (buttonIndex == 0) {
            UITextField *textField = alert.textFields.firstObject;
            NSString *input = textField.text;

            unsigned long long address = 0;
            NSScanner *scanner = [NSScanner scannerWithString:input];
            if ([scanner scanHexLongLong:&address]) {
                void *instance = (void *)address;
                [self showInstanceDetailsForInstance:instance];
            } else {
                [self showErrorMessage:@"Invalid address format"];
            }
        }
    };

    [alert showInView:self animated:YES];
}

- (void)scanForInstances:(Il2CppClass *)klass className:(NSString *)className {
    self.selectedClass = klass;
    self.viewMode = UNITY_VIEW_MODE_INSTANCES;

    [self.loadingIndicator startAnimating];
    self.tableView.hidden = YES;

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        Il2CppInstanceEnumResult* instances = il2cpp_find_instances(klass);

        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.instanceResults) {
                il2cpp_free_instance_enum_result(self.instanceResults);
            }
            self.instanceResults = instances;

            self.titleLabel.text = [NSString stringWithFormat:@"%@ Instances", className];
            self.btnBack.hidden = NO;

            [self.loadingIndicator stopAnimating];
            self.tableView.hidden = NO;
            [self.tableView reloadData];

            if (!instances || instances->instance_count == 0) {
                [self showInfoMessage:@"Nothing found."];
            }
        });
    });
}

- (void)showInstanceDetailsForInstance:(void *)instance {
    if (!instance || !self.selectedClass) return;

    self.selectedInstance = instance;
    self.instanceModeControl.hidden = NO;
    self.instanceModeControl.selectedSegmentIndex = 0;
    [self showFieldsForInstance:instance];
}

- (void)showFieldsForInstance:(void *)instance {
    self.selectedInstance = instance;
    self.viewMode = UNITY_VIEW_MODE_FIELDS;

    [self.loadingIndicator startAnimating];
    self.tableView.hidden = YES;

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        Il2CppFieldEnumResult* fields = il2cpp_enumerate_fields(self.selectedClass);

        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.fieldResults) {
                il2cpp_free_field_enum_result(self.fieldResults);
            }
            self.fieldResults = fields;

            self.titleLabel.text = [NSString stringWithFormat:@"Instance 0x%lx", (unsigned long)instance];
            self.btnBack.hidden = NO;
            self.instanceModeControl.hidden = NO;
            self.instanceModeControl.selectedSegmentIndex = 0; // fields tab

            [self.loadingIndicator stopAnimating];
            self.tableView.hidden = NO;
            [self.tableView reloadData];
        });
    });
}

- (void)showMethodsForInstance:(void *)instance {
    self.selectedInstance = instance;
    self.viewMode = UNITY_VIEW_MODE_METHODS;

    [self.loadingIndicator startAnimating];
    self.tableView.hidden = YES;

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        Il2CppMethodEnumResult* methods = il2cpp_enumerate_methods(self.selectedClass);

        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.methodResults) {
                il2cpp_free_method_enum_result(self.methodResults);
            }
            self.methodResults = methods;

            self.titleLabel.text = [NSString stringWithFormat:@"Instance 0x%lx", (unsigned long)instance];
            self.btnBack.hidden = NO;
            self.instanceModeControl.hidden = NO;
            self.instanceModeControl.selectedSegmentIndex = 1; // methods tab
            self.searchBar.placeholder = @"Search methods...";

            [self.loadingIndicator stopAnimating];
            self.tableView.hidden = NO;
            [self.tableView reloadData];
        });
    });
}

- (void)showFieldDetails:(Il2CppFieldInfo)info {
    char* value_str = il2cpp_get_field_value_string(self.selectedInstance, info.field, self.selectedClass);
    NSString *valueString = value_str ? [NSString stringWithUTF8String:value_str] : @"(unable to read)";
    if (value_str) free(value_str);

    NSString *message = [NSString stringWithFormat:@"Field: %s\nType: %s\n%s\n\nCurrent Value:\n%@",
                         info.name,
                         info.type_name,
                         info.is_static ? "Static" : "Instance",
                         valueString];

    DLGUnityHaxAlert *alert = [[DLGUnityHaxAlert alloc] init];
    alert.titleText = @"Field Details";
    alert.messageText = message;

    if (il2cpp_can_edit_field_type(info.type_enum)) {
        alert.buttonTitles = @[@"Edit Value", @"Cancel"];
        alert.buttonHandler = ^(NSInteger buttonIndex) {
            if (buttonIndex == 0) {
                [self showEditFieldDialog:info];
            }
        };
    } else {
        alert.buttonTitles = @[@"OK"];
    }

    [alert showInView:self animated:YES];
}

- (void)showEditFieldDialog:(Il2CppFieldInfo)info {
    DLGUnityHaxAlert *alert = [[DLGUnityHaxAlert alloc] init];
    alert.titleText = @"Edit Field Value";
    alert.messageText = [NSString stringWithFormat:@"Enter new value for %s:", info.name];
    alert.alertStyle = DLGUnityHaxAlertStyleInput;

    UIKeyboardType keyboardType = UIKeyboardTypeDefault;
    NSString *placeholder = @"value";

    switch (info.type_enum) {
        case IL2CPP_TYPE_BOOLEAN:
            placeholder = @"true/false";
            break;
        case IL2CPP_TYPE_I1:
        case IL2CPP_TYPE_I2:
        case IL2CPP_TYPE_I4:
        case IL2CPP_TYPE_I8:
        case IL2CPP_TYPE_U1:
        case IL2CPP_TYPE_U2:
        case IL2CPP_TYPE_U4:
        case IL2CPP_TYPE_U8:
            keyboardType = UIKeyboardTypeNumberPad;
            break;
        case IL2CPP_TYPE_R4:
        case IL2CPP_TYPE_R8:
            keyboardType = UIKeyboardTypeDecimalPad;
            break;
        default:
            break;
    }

    alert.inputPlaceholders = @[placeholder];
    alert.inputKeyboardTypes = @[@(keyboardType)];
    alert.buttonTitles = @[@"Set Value", @"Cancel"];
    alert.buttonHandler = ^(NSInteger buttonIndex) {
        if (buttonIndex == 0) {
            UITextField *textField = alert.textFields.firstObject;
            bool success = il2cpp_set_field_value_from_string(self.selectedInstance, info.field, self.selectedClass, [textField.text UTF8String], info.type_enum);
            if (success) {
                [self showInfoMessage:@"Value updated successfully!"];
                [self.tableView reloadData];
            } else {
                [self showErrorMessage:@"Failed to set value"];
            }
        }
    };

    [alert showInView:self animated:YES];
}

- (void)showInfoMessage:(NSString *)message {
    DLGUnityHaxAlert *alert = [[DLGUnityHaxAlert alloc] init];
    alert.titleText = @"Info";
    alert.messageText = message;
    alert.buttonTitles = @[@"OK"];
    [alert showInView:self animated:YES];
}

- (void)showErrorMessage:(NSString *)message {
    DLGUnityHaxAlert *alert = [[DLGUnityHaxAlert alloc] init];
    alert.titleText = @"Error";
    alert.messageText = message;
    alert.buttonTitles = @[@"OK"];
    [alert showInView:self animated:YES];
}

#pragma mark - Show/Hide

- (void)showInView:(UIView *)view animated:(BOOL)animated {
    if (!view) {
        return;
    }
    [view addSubview:self];

    [NSLayoutConstraint activateConstraints:@[
        [self.leadingAnchor constraintEqualToAnchor:view.leadingAnchor],
        [self.trailingAnchor constraintEqualToAnchor:view.trailingAnchor],
        [self.topAnchor constraintEqualToAnchor:view.topAnchor],
        [self.bottomAnchor constraintEqualToAnchor:view.bottomAnchor]
    ]];

    // init IL2CPP
    [self.loadingIndicator startAnimating];
    self.tableView.hidden = YES;

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @try {
            bool success = il2cpp_helper_init();
            dispatch_async(dispatch_get_main_queue(), ^{
                if (success) {
                    self.classResults = il2cpp_enumerate_classes();
                    [self.tableView reloadData];
                    self.tableView.hidden = NO;
                } else {
                    DLGUnityHaxAlert *alert = [[DLGUnityHaxAlert alloc] init];
                    alert.titleText = @"Error";
                    alert.messageText = @"Failed to initialize IL2CPP. Make sure the target app is using IL2CPP.";
                    alert.buttonTitles = @[@"OK"];
                    alert.buttonHandler = ^(NSInteger buttonIndex) {
                        [self hideAnimated:YES];
                    };
                    [alert showInView:self animated:YES];
                }
                [self.loadingIndicator stopAnimating];
            });
        } @catch (NSException *exception) {
            UNITY_LOG(@"Exception in init thread: %@", exception);
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.loadingIndicator stopAnimating];
                DLGUnityHaxAlert *alert = [[DLGUnityHaxAlert alloc] init];
                alert.titleText = @"Error";
                alert.messageText = [NSString stringWithFormat:@"Exception: %@", exception.reason];
                alert.buttonTitles = @[@"OK"];
                alert.buttonHandler = ^(NSInteger buttonIndex) {
                    [self hideAnimated:YES];
                };
                [alert showInView:self animated:YES];
            });
        }
    });

    if (animated) {
        self.alpha = 0;
        self.containerView.transform = CGAffineTransformMakeScale(0.8, 0.8);

        [UIView animateWithDuration:0.3
                              delay:0
             usingSpringWithDamping:0.8
              initialSpringVelocity:0.5
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
            self.alpha = 1;
            self.containerView.transform = CGAffineTransformIdentity;
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
            self.containerView.transform = CGAffineTransformMakeScale(0.9, 0.9);
        } completion:^(BOOL finished) {
            [self removeFromSuperview];
        }];
    } else {
        [self removeFromSuperview];
    }
}

@end
