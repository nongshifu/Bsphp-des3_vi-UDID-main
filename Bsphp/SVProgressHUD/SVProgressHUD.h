//
//  SVProgressHUD.h
//  SVProgressHUD, https://github.com/SVProgressHUD/SVProgressHUD
//
//  Copyright (c) 2011-2023 Sam Vermette and contributors. All rights reserved.
//
#import <UIKit/UIKit.h>
#import <AvailabilityMacros.h>

extern NSString * _Nonnull const SVProgressHUDDidReceiveTouchEventNotification; // HUD 接收到触摸事件的通知
extern NSString * _Nonnull const SVProgressHUDDidTouchDownInsideNotification; // HUD 内部控件接收到触摸事件的通知
extern NSString * _Nonnull const SVProgressHUDWillDisappearNotification; // HUD 将要消失的通知
extern NSString * _Nonnull const SVProgressHUDDidDisappearNotification; // HUD 已经消失的通知
extern NSString * _Nonnull const SVProgressHUDWillAppearNotification; // HUD 将要显示的通知
extern NSString * _Nonnull const SVProgressHUDDidAppearNotification; // HUD 已经显示的通知

extern NSString * _Nonnull const SVProgressHUDStatusUserInfoKey; // HUD 状态信息的用户信息键

/// 表示HUD的外观样式。
typedef NS_ENUM(NSInteger, SVProgressHUDStyle) {
    /// 白色HUD，黑色文本，背景模糊。
    SVProgressHUDStyleLight NS_SWIFT_NAME(light),
    
    /// 黑色HUD，白色文本，背景模糊。
    SVProgressHUDStyleDark NS_SWIFT_NAME(dark),
    
    /// 使用前景和背景颜色属性。
    SVProgressHUDStyleCustom NS_SWIFT_NAME(custom),
    
    /// 自动根据当前模式切换外观。
    SVProgressHUDStyleAutomatic NS_SWIFT_NAME(automatic)
};

/// 表示在显示HUD时应用的遮罩类型。
typedef NS_ENUM(NSUInteger, SVProgressHUDMaskType) {
    /// 允许用户与HUD显示期间进行交互。
    SVProgressHUDMaskTypeNone NS_SWIFT_NAME(none) = 1,
    
    /// 不允许用户与背景对象进行交互。
    SVProgressHUDMaskTypeClear NS_SWIFT_NAME(clear),
    
    /// 不允许用户与背景对象进行交互，并使HUD后面的UI变暗（适用于iOS 7+）。
    SVProgressHUDMaskTypeBlack NS_SWIFT_NAME(black),
    
    /// 不允许用户与背景对象进行交互，并在HUD后面使用类似UIAlertView的背景渐变（适用于iOS 6）。
    SVProgressHUDMaskTypeGradient NS_SWIFT_NAME(gradient),
    
    /// 不允许用户与背景对象进行交互，并在HUD后面使用自定义颜色。
    SVProgressHUDMaskTypeCustom NS_SWIFT_NAME(custom)
};

/// 表示显示或隐藏HUD时的动画类型。
typedef NS_ENUM(NSUInteger, SVProgressHUDAnimationType) {
    /// 自定义平面动画（无限动画的圆环）。
    SVProgressHUDAnimationTypeFlat NS_SWIFT_NAME(flat),
    
    /// iOS原生UIActivityIndicatorView。
    SVProgressHUDAnimationTypeNative NS_SWIFT_NAME(native)
};

typedef void (^SVProgressHUDShowCompletion)(void);
typedef void (^SVProgressHUDDismissCompletion)(void);

@interface SVProgressHUD : UIView

#pragma mark - 自定义设置

/// HUD的默认样式。
/// @discussion 默认值：SVProgressHUDStyleAutomatic。
@property (assign, nonatomic) SVProgressHUDStyle defaultStyle UI_APPEARANCE_SELECTOR;

/// 显示HUD时应用的遮罩类型。
/// @discussion 默认值：SVProgressHUDMaskTypeNone。
@property (assign, nonatomic) SVProgressHUDMaskType defaultMaskType UI_APPEARANCE_SELECTOR;

/// 显示HUD时使用的动画类型。
/// @discussion 默认值：SVProgressHUDAnimationTypeFlat。
@property (assign, nonatomic) SVProgressHUDAnimationType defaultAnimationType UI_APPEARANCE_SELECTOR;

/// 用于显示HUD的容器视图。如果为nil，则使用默认的窗口层级。
@property (strong, nonatomic, nullable) UIView *containerView;

/// HUD的最小尺寸。当消息可能导致HUD大小变化时很有用。
/// @discussion 默认值：CGSizeZero。
@property (assign, nonatomic) CGSize minimumSize UI_APPEARANCE_SELECTOR;

/// HUD中显示的圆环的厚度。
/// @discussion 默认值：2 pt。
@property (assign, nonatomic) CGFloat ringThickness UI_APPEARANCE_SELECTOR;

/// 当存在关联文本时，在HUD中显示的圆环的半径。
/// @discussion 默认值：18 pt。
@property (assign, nonatomic) CGFloat ringRadius UI_APPEARANCE_SELECTOR;

/// 当没有关联文本时，在HUD中显示的圆环的半径。
/// @discussion 默认值：24 pt。
@property (assign, nonatomic) CGFloat ringNoTextRadius UI_APPEARANCE_SELECTOR;

/// HUD视图的圆角半径。
/// @discussion 默认值：14 pt。
@property (assign, nonatomic) CGFloat cornerRadius UI_APPEARANCE_SELECTOR;

/// HUD中文本的字体。
/// @discussion 默认值：[UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]。
@property (strong, nonatomic, nonnull) UIFont *font UI_APPEARANCE_SELECTOR;

/// HUD的背景颜色。
/// @discussion 默认值：[UIColor whiteColor]。
@property (strong, nonatomic, nonnull) UIColor *backgroundColor UI_APPEARANCE_SELECTOR;

/// HUD内容中使用的前景色。
/// @discussion 默认值：[UIColor blackColor]。
@property (strong, nonatomic, nonnull) UIColor *foregroundColor UI_APPEARANCE_SELECTOR;

/// HUD中前景图像的颜色。
/// @discussion 默认值：与foregroundColor相同。
@property (strong, nonatomic, nullable) UIColor *foregroundImageColor UI_APPEARANCE_SELECTOR;

/// HUD背景层的颜色。
/// @discussion 默认值：[UIColor colorWithWhite:0 alpha:0.4]。
@property (strong, nonatomic, nonnull) UIColor *backgroundLayerColor UI_APPEARANCE_SELECTOR;

/// HUD中显示的图像的大小。
/// @discussion 默认值：28x28 pt。
@property (assign, nonatomic) CGSize imageViewSize UI_APPEARANCE_SELECTOR;

/// 指示是否应给HUD中的图像着色。
/// @discussion 默认值：YES。
@property (assign, nonatomic) BOOL shouldTintImages UI_APPEARANCE_SELECTOR;

/// 显示信息消息时显示的图像。
/// @discussion 默认值：iOS 13+的info.circle或提供的bundle中的info图像。
@property (strong, nonatomic, nonnull) UIImage *infoImage UI_APPEARANCE_SELECTOR;

/// 显示成功消息时显示的图像。
/// @discussion 默认值：iOS 13+的checkmark或提供的bundle中的success图像。
@property (strong, nonatomic, nonnull) UIImage *successImage UI_APPEARANCE_SELECTOR;

/// 显示错误消息时显示的图像。
/// @discussion 默认值：iOS 13+的xmark或提供的bundle中的error图像。
@property (strong, nonatomic, nonnull) UIImage *errorImage UI_APPEARANCE_SELECTOR;

/// 用于扩展的特定视图。仅当#define SV_APP_EXTENSIONS被设置时使用。
/// @discussion 默认值：nil。
@property (strong, nonatomic, nonnull) UIView *viewForExtension UI_APPEARANCE_SELECTOR;

/// 显示HUD之前等待的时间间隔（以秒为单位）。如果在此时间段内显示了HUD，则会重置计时器。
/// @discussion 默认值：0秒。
@property (assign, nonatomic) NSTimeInterval graceTimeInterval;

/// HUD将显示的最短时间量（以秒为单位）。
/// @discussion 默认值：5.0秒。
@property (assign, nonatomic) NSTimeInterval minimumDismissTimeInterval;

/// HUD将显示的最长时间量（以秒为单位）。
/// @discussion 默认值：CGFLOAT_MAX。
@property (assign, nonatomic) NSTimeInterval maximumDismissTimeInterval;

/// 从中心位置的偏移量，可用于调整HUD的位置。
/// @discussion 默认值：0, 0。
@property (assign, nonatomic) UIOffset offsetFromCenter UI_APPEARANCE_SELECTOR;

/// 显示HUD时淡入动画的持续时间。
/// @discussion 默认值：0.15。
@property (assign, nonatomic) NSTimeInterval fadeInAnimationDuration UI_APPEARANCE_SELECTOR;

/// 隐藏HUD时淡出动画的持续时间。
/// @discussion 默认值：0.15。
@property (assign, nonatomic) NSTimeInterval fadeOutAnimationDuration UI_APPEARANCE_SELECTOR;

/// HUD可以显示的最大窗口层级。
/// @discussion 默认值：UIWindowLevelNormal。
@property (assign, nonatomic) UIWindowLevel maxSupportedWindowLevel;

/// 指示是否应使用触觉反馈。
/// @discussion 默认值：NO。
@property (assign, nonatomic) BOOL hapticsEnabled;

/// 指示是否应将动态效果应用于HUD。
/// @discussion 默认值：YES。
@property (assign, nonatomic) BOOL motionEffectEnabled;

@property (class, strong, nonatomic, readonly, nonnull) NSBundle *imageBundle;

/// 设置HUD的默认样式。
/// @param style 所需的HUD样式。
+ (void)setDefaultStyle:(SVProgressHUDStyle)style;

/// 设置HUD的默认遮罩类型。
/// @param maskType 要应用的遮罩类型。
+ (void)setDefaultMaskType:(SVProgressHUDMaskType)maskType;

/// 设置HUD的默认动画类型。
/// @param type 所需的动画类型。
+ (void)setDefaultAnimationType:(SVProgressHUDAnimationType)type;

/// 设置HUD的容器视图。
/// @param containerView 用于包含HUD的视图。
+ (void)setContainerView:(nullable UIView*)containerView;

/// 设置HUD的最小尺寸。
/// @param minimumSize HUD的最小尺寸。
+ (void)setMinimumSize:(CGSize)minimumSize;

/// 设置HUD中圆环的厚度。
/// @param ringThickness 圆环的厚度。
+ (void)setRingThickness:(CGFloat)ringThickness;

/// 设置HUD中带有文本时圆环的半径。
/// @param radius 带有文本时的圆环半径。
+ (void)setRingRadius:(CGFloat)radius;

/// 设置HUD中无文本时圆环的半径。
/// @param radius 无文本时的圆环半径。
+ (void)setRingNoTextRadius:(CGFloat)radius;

/// 设置HUD视图的圆角半径。
/// @param cornerRadius 所需的圆角半径。
+ (void)setCornerRadius:(CGFloat)cornerRadius;

/// 设置HUD的边框颜色。
/// @param color 所需的边框颜色。
+ (void)setBorderColor:(nonnull UIColor*)color;

/// 设置HUD的边框宽度。
/// @param width 所需的边框宽度。
+ (void)setBorderWidth:(CGFloat)width;

/// 设置HUD文本的字体。
/// @param font 所需的文本字体。
+ (void)setFont:(nonnull UIFont*)font;

/// 设置HUD的前景色。
/// @param color 所需的前景色。
/// @discussion 这些隐式设置HUD的样式为`SVProgressHUDStyleCustom`。
+ (void)setForegroundColor:(nonnull UIColor*)color;

/// 设置HUD中前景图像的颜色。
/// @param color 所需的图像颜色。
/// @discussion 这些隐式设置HUD的样式为`SVProgressHUDStyleCustom`。
+ (void)setForegroundImageColor:(nullable UIColor*)color;

/// 设置HUD的背景色。
/// @param color 所需的背景色。
/// @discussion 这些隐式设置HUD的样式为`SVProgressHUDStyleCustom`。
+ (void)setBackgroundColor:(nonnull UIColor*)color;

/// 设置HUD视图的自定义模糊效果。
/// @param blurEffect 所需的模糊效果。
/// @discussion 这些隐式设置HUD的样式为`SVProgressHUDStyleCustom`。
+ (void)setHudViewCustomBlurEffect:(nullable UIBlurEffect*)blurEffect;

/// 设置HUD背景层的颜色。
/// @param color 所需的背景层颜色。
+ (void)setBackgroundLayerColor:(nonnull UIColor*)color;

/// 设置HUD中显示的图像的大小。
/// @param size 所需的图像大小。
+ (void)setImageViewSize:(CGSize)size;

/// 确定HUD中的图像是否应着色。
/// @param shouldTintImages 图像是否应着色。
+ (void)setShouldTintImages:(BOOL)shouldTintImages;

/// 设置HUD的信息图像。
/// @param image 所需的信息图像。
+ (void)setInfoImage:(nonnull UIImage*)image;

/// 设置HUD的成功图像。
/// @param image 所需的成功图像。
+ (void)setSuccessImage:(nonnull UIImage*)image;

/// 设置HUD的错误图像。
/// @param image 所需的错误图像。
+ (void)setErrorImage:(nonnull UIImage*)image;

/// 设置扩展的视图。
/// @param view 所需的扩展视图。
+ (void)setViewForExtension:(nonnull UIView*)view;

/// 设置HUD的宽限时间间隔。
/// @param interval 所需的宽限时间间隔。
+ (void)setGraceTimeInterval:(NSTimeInterval)interval;

/// 设置HUD的最小消失时间间隔。
/// @param interval HUD应显示的最小时间间隔（以秒为单位）。
+ (void)setMinimumDismissTimeInterval:(NSTimeInterval)interval;

/// 设置HUD的最大消失时间间隔。
/// @param interval HUD应显示的最大时间间隔（以秒为单位）。
+ (void)setMaximumDismissTimeInterval:(NSTimeInterval)interval;

/// 设置淡入动画的持续时间。
/// @param duration 淡入动画的持续时间（以秒为单位）。
+ (void)setFadeInAnimationDuration:(NSTimeInterval)duration;

/// 设置淡出动画的持续时间。
/// @param duration 淡出动画的持续时间（以秒为单位）。
+ (void)setFadeOutAnimationDuration:(NSTimeInterval)duration;

/// 设置HUD可以显示的最大窗口层级。
/// @param windowLevel HUD应显示的UIWindowLevel。
+ (void)setMaxSupportedWindowLevel:(UIWindowLevel)windowLevel;

/// 确定是否启用触觉反馈。
/// @param hapticsEnabled 一个布尔值，确定是否启用触觉反馈。
+ (void)setHapticsEnabled:(BOOL)hapticsEnabled;

/// 确定是否应用动态效果到HUD。
/// @param motionEffectEnabled 一个布尔值，确定是否启用动态效果。
+ (void)setMotionEffectEnabled:(BOOL)motionEffectEnabled;



#pragma mark - Show Methods

/// 显示HUD，不显示额外的状态消息。
+ (void)show;

/// 显示带有指定状态消息的HUD。
/// @param status 要显示在HUD旁边的消息。
+ (void)showWithStatus:(nullable NSString*)status;

/// 显示带有进度指示器的HUD。
/// @param progress 一个介于0.0和1.0之间的浮点值，表示进度。
+ (void)showProgress:(float)progress;

/// 显示带有进度指示器和指定状态消息的HUD。
/// @param progress 一个介于0.0和1.0之间的浮点值，表示进度。
/// @param status 要显示在进度指示器旁边的消息。
+ (void)showProgress:(float)progress status:(nullable NSString*)status;

/// 更新加载HUD的当前状态。
/// @param status 要更新HUD的新状态消息。
+ (void)setStatus:(nullable NSString*)status;

/// 显示带有信息状态和提供的消息的HUD。
/// @param status 要显示的信息消息。
+ (void)showInfoWithStatus:(nullable NSString*)status;

/// 显示带有成功状态和提供的消息的HUD。
/// @param status 要显示的成功消息。
+ (void)showSuccessWithStatus:(nullable NSString*)status;

/// 显示带有错误状态和提供的消息的HUD。
/// @param status 要显示的错误消息。
+ (void)showErrorWithStatus:(nullable NSString*)status;

/// 显示带有自定义图像和提供的状态消息的HUD。
/// @param image 要显示的自定义图像。
/// @param status 与自定义图像一起显示的消息。
+ (void)showImage:(nonnull UIImage*)image status:(nullable NSString*)status;

/// 设置HUD的中心偏移量。
/// @param offset 表示HUD应该从其中心位置偏移多少的UIOffset值。
+ (void)setOffsetFromCenter:(UIOffset)offset;

/// 重置偏移量以将HUD居中显示。
+ (void)resetOffsetFromCenter;

/// 减少活动计数，如果计数达到0则隐藏HUD。
+ (void)popActivity;

/// 立即关闭HUD。
+ (void)dismiss;

/// 关闭HUD并触发完成块。
/// @param completion HUD关闭后执行的块。
+ (void)dismissWithCompletion:(nullable SVProgressHUDDismissCompletion)completion;

/// 延迟指定时间后关闭HUD。
/// @param delay HUD应在多少秒后关闭。
+ (void)dismissWithDelay:(NSTimeInterval)delay;

/// 延迟指定时间后关闭HUD并触发完成块。
/// @param delay HUD应在多少秒后关闭。
/// @param completion HUD关闭后执行的块。
+ (void)dismissWithDelay:(NSTimeInterval)delay completion:(nullable SVProgressHUDDismissCompletion)completion;

/// 检查HUD当前是否可见。
/// @return 表示HUD是否可见的布尔值。
+ (BOOL)isVisible;

/// 根据给定字符串的长度计算显示持续时间。
/// @param string 决定显示持续时间的字符串。
/// @return 表示显示持续时间的时间间隔。
+ (NSTimeInterval)displayDurationForString:(nullable NSString*)string;


@end

#define angleMaskBase64 @"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"
#define ErrorBase64 @"iVBORw0KGgoAAAANSUhEUgAAAFQAAABUCAMAAAArteDzAAAANlBMVEUAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAC3dmhyAAAAEnRSTlMAMNL2kgYv/63T8pOur7CY9c9OMeGqAAAA9UlEQVR42u3XOQ6DQBAFUWAYDzvm/pe1JZKWKiwSW90ZP3gZiOryfun6oYzVInUswys8D621qUpz+iJzGEoLqjDbEpa1BVWYbYzTFlRhbhGg6k2q3qTqTarepGpNr9L0Kk2v0vQqTa/S9CpNr9L0Kk2v0vQqTa/S9CpNr9L0Kk2v0vQqTa/S9CpNr9L0Kk2v0vQqTa/S9Oq+0/QqTK3S9OpxmwdMg+43uluU77uvDZpUvXkcXuV3qW5UfXdQ9SZVb1L1JlRtZhtmG2YbZhtmG2YbZhv+TRt251NteIapPNWG77AMT7XhFYZ+Xlb/g7iWq+/yfug+XhYjYODv3gkAAAAASUVORK5CYII="
#define infoBase64 @"iVBORw0KGgoAAAANSUhEUgAAAFQAAABUCAQAAAC2YthKAAAEd0lEQVR4Ae2bBWzkRhSGP9uqU6kLhY2oIM56T7qAsAzHJzi+E5dBWOaKj5mZSQxlZmZmZmZuwxk9WTsH2XjGFCnfiNZrv/lNs/Pe/Is5I4xQZAxXsJF7eI0v+Zn/+ZNv+ZAXuYeNXMEYimSKxzks4RW66G3QuniFJZyDR+q0sZZv6Y3YvmUtbaSEywye0rr/lyfZxFVMpkoFBwCHClUmcxWbeJJ/tf2fYgYuCTOV1+u6/JgljKGJRjQxhiV8XHfkG0wjMUbzSNjRn2zhFKJyClv4K4zxCK3Ejs88/pcOfmM+zZjSzHx+k0j/Mw+fGGnhJQn9HwspY0uZhfwnEV+iSkxMC6/AQ9SIi4CHwjs0nRi4kh4V7h8uI24u5R8Vu4crscJhkZz1u7STBO28Iz0swjGXuU2C3EmBpChwr/SyzVTqWgmwBY8k8dkvPa3FgBvl4NU4JI3DGuntRiIyQ16hfTikgcM+ea1mEIEqv6rD7sMnLXx5Vn8lGPohL8qbXiRNCryl+n0RnyExT+3+N22YMItXeZU5mFDlD9X3PIZAq/ymX4oJNZlGd1HDhItkDtBKQx6RH0szzqNX2nmY8bDMrBowTaYeAWaMCq/oKMwIZLoynUFwZVq8ECHdZ1RYqDS8jtvoev7K0WTJ0TI4TuOwPKN2WEDWLFA6nuEwtKqv/6KZrGmWhKV1sEnIDvLAjsNPUjzJ088mD5wtdQCPgzhHffUZLracxEnY4vKZ0nMOB7FEfbEMW1aqOCuxZamKs5SDeEXOwI4avdJqWCF3+BV0KNGlErgjseP0UOjp2NGkEr8uSmiMUcGfhNwIRSpcY9C4QoaDHAmV4fIKNDaojZflSuhlKs4GNO5WG8fnSuh4FedeNF5VG6u5Etqi4ryGxldqYyVXQisqztfUIxMrN1dCHZl01iPFa3IlFMk2hqVQufXlXAkta7dee5lOyJXQE7SXSRuearkSGsjwNLwG/Pz/hG4cppOSYTPNK8vEuSl3E+eyfSpiL9QgFUGSqWUZC22cbMoZfIqbC6Eun8odNihApChUChDf4dmXdAyF2pd0oF1W4iuZC5UiGW32ZUcLofZlR5iOFHIzFSqFXKYblMZTFbpQXCcugzAdWWxIS6jBYoPwqCzfZCRUfBGPmi+ImQs1XxBLcInxJFmV7jEq5rYgS4xRF20LROcmOunkJqJT4E3x7fgMkUAGiNvwiM5R/S06HreJZycwMRZsTs1YsBkxFphaNVamYtVYZWTVENalZH45gj3S0zpbO9HtidqJ7ra0E2kGrXdoJQlG6wateCxvlyZoebuGGJgRmggfJCAuqjwoUX9nJjER1NkyF1DCliIL6myZATHiMz80uv7ILRyLKcdyMz+GRtf5+MROq2Yd3snZuETB5Wx28qeBddiAabxBb9g+YymTKdCIApNZymeaGXt6+vb2Tp6qs7cLdfb2p+hEt7fPwiUl2lnL9/RGbN+zlo78/wVjDB6ZUmQsV7KRe3idr/iZTv7kOz7iJe5hI1cylhIjjGBKH4JVYGTk5xMMAAAAAElFTkSuQmCC"
#define successBase64 @"iVBORw0KGgoAAAANSUhEUgAAAFQAAABUCAQAAAC2YthKAAACkUlEQVR4Ae3aA5AeSxRH8fNs24pt27Zt27Zt27ZtOy+2bduZ+sf6cCs1vy4ues+yb9cOLpfL5XprfUBbLvI/ETDtPQZy697aiGHv0JVbD9YlDGvBLWe1x6xakjmJDzGqjGTO4VOMys9NJ3MpX2FUZq47mev4HqNScMXJ3MYvGBWPC07mPv7CqMicdTKPEgijQnLSyTxNKIwKwBEn8zyRMeoP9slxGQ+jfmKbk3mFVBj1LeuczOtkxagvWeJk3qQARn3KLDnVy2LUh0yQzNp25/ehktnS7vzeUzK78Q5GtZHMQbyHUfUkc6zd+b2CZM7kY4wqLPP7Ej7DqOwyv6/lK4xKxTUncws/YFR8uWbs5neMiirXjIMEwKgwnHYyjxESo4JwVK4ZkTDqH5nfLxAbo37T+Z2kGPUD62V+z4BRX7Fc5vc8duf3eXKql8Qjvqc948nu0fl9imRWx0OmPdiwksfm95GS2RRPkcOtokfm976S2cmT8/tU2bg8b6qD7Nbfk5nwMxs9dnFtIjuN5j087Gc2eSS1muwyjQ/xgl/YLB+kDK+jhOywgE/xkl/ZIn+gS/Oqcss1YyVfIbybWopXkV6uGRv4wftDxFZJLcnLSiJ/4rb7Zn7/nW2SWpyXEUv/TcB/CN+lFuNFIsr8fpRg+NDvbJfUojxPSJ3fCYeP/cEOSS2MUgE4IPN7dPzgT3ZKakEc4nd2yfyeEGUo9Qc5Iq6TBj/6i12Smh/1FWvkdTnws7/ZLTn5ZH5frL9uGPCPpN54kPoRM+VUr2TnZr5HUvPyAWMlswGG/Mte+bVZIpntMOY/J1VXb94Be6n7HsscznuYFIB9ph/zEQHZb/oxHxGAeZxlIF9hmMvlcrlcLpfrNuW/+kr37AsRAAAAAElFTkSuQmCC"
