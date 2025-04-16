#import <UIKit/UIKit.h>
#import <objc/runtime.h>

@interface GSEvent : NSObject
- (void)_setEvent:(NSInteger)event;
- (void)_setWindow:(UIWindow *)window;
- (void)_setLocationInWindow:(CGPoint)location;
@end

@interface UIEvent (Private)
- (void)_setGSEvent:(GSEvent *)event;
@end

@interface TouchIndicatorView : UIView
- (void)showAtPoint:(CGPoint)point;
@end

@interface TouchPassthroughWindow : UIWindow
@property (nonatomic, strong) UIButton *touchButton;
// 预设的目标坐标
@property (nonatomic, assign) CGPoint targetPoint;
@property (nonatomic, strong) TouchIndicatorView *indicatorView;
@property (nonatomic, strong) UILabel *coordinateLabel; // 添加坐标显示标签
@end

@implementation TouchPassthroughWindow

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        // 设置默认的目标坐标，这里的坐标值需要根据实际需求修改
        _targetPoint = CGPointMake(200, 300); // 示例坐标
        [self setupTouchButton];
        [self setupIndicator];
        [self setupCoordinateLabel];
        
        // 在目标位置显示一个永久性的标记
        [self showPermanentMarker];
    }
    return self;
}

- (void)setupTouchButton {
    // 创建一个半透明的按钮
    self.touchButton = [UIButton buttonWithType:UIButtonTypeCustom];
    // 设置按钮位置和大小，可以根据需求调整
    self.touchButton.frame = CGRectMake(20, 40, 120, 44);
    [self.touchButton setTitle:@"触发点击" forState:UIControlStateNormal];
    [self.touchButton setBackgroundColor:[UIColor colorWithWhite:0.0 alpha:0.5]];
    self.touchButton.layer.cornerRadius = 8;
    [self.touchButton addTarget:self 
                       action:@selector(touchButtonTapped:) 
             forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.touchButton];
}

- (void)setupIndicator {
    self.indicatorView = [[TouchIndicatorView alloc] init];
    [self addSubview:self.indicatorView];
}

- (void)setupCoordinateLabel {
    self.coordinateLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 90, 200, 30)];
    self.coordinateLabel.textColor = [UIColor whiteColor];
    self.coordinateLabel.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.5];
    self.coordinateLabel.layer.cornerRadius = 5;
    self.coordinateLabel.clipsToBounds = YES;
    self.coordinateLabel.text = [NSString stringWithFormat:@"目标坐标: (%.0f, %.0f)", 
                                self.targetPoint.x, self.targetPoint.y];
    [self addSubview:self.coordinateLabel];
}

- (void)showPermanentMarker {
    // 创建一个永久性的标记视图
    UIView *markerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
    markerView.center = self.targetPoint;
    markerView.backgroundColor = [UIColor clearColor];
    markerView.layer.borderColor = [UIColor greenColor].CGColor;
    markerView.layer.borderWidth = 2;
    markerView.layer.cornerRadius = 10;
    markerView.userInteractionEnabled = NO;
    
    // 添加十字线
    CAShapeLayer *crossLayer = [CAShapeLayer layer];
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(10, 0)];
    [path addLineToPoint:CGPointMake(10, 20)];
    [path moveToPoint:CGPointMake(0, 10)];
    [path addLineToPoint:CGPointMake(20, 10)];
    crossLayer.path = path.CGPath;
    crossLayer.strokeColor = [UIColor greenColor].CGColor;
    crossLayer.lineWidth = 1;
    [markerView.layer addSublayer:crossLayer];
    
    [self addSubview:markerView];
}

- (void)touchButtonTapped:(UIButton *)button {
    // 显示点击效果
    [self.indicatorView showAtPoint:self.targetPoint];
    
    // 模拟点击
    [self simulateTouchAtPoint:self.targetPoint];
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    // 如果点击到按钮，直接处理按钮事件
    if ([self.touchButton pointInside:[self convertPoint:point toView:self.touchButton] withEvent:event]) {
        return YES;
    }
    
    // 其他区域的点击穿透处理
    UIView *hitView = [super hitTest:point withEvent:event];
    if ([self shouldPassthroughForView:hitView]) {
        [self simulateTouchAtPoint:point];
        return NO;
    }
    return [super pointInside:point withEvent:event];
}

- (void)simulateTouchAtPoint:(CGPoint)point {
    // 获取目标窗口
    UIWindow *targetWindow = nil;
    NSArray *windows = [[UIApplication sharedApplication] windows];
    for (UIWindow *window in windows) {
        if (window != self && window.windowLevel < self.windowLevel) {
            targetWindow = window;
            break;
        }
    }
    
    if (!targetWindow) return;
    
    // 发送按下事件
    [self sendTouchDownAtPoint:point toWindow:targetWindow];
    
    // 短暂延迟后发送抬起事件
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.05 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self sendTouchUpAtPoint:point toWindow:targetWindow];
    });
}

- (void)sendTouchDownAtPoint:(CGPoint)point toWindow:(UIWindow *)window {
    UIView *targetView = [window hitTest:point withEvent:nil];
    if (!targetView) return;
    
    UITouch *touch = [[UITouch alloc] init];
    
    if ([touch respondsToSelector:@selector(setView:)]) {
        [touch setView:targetView];
    }
    if ([touch respondsToSelector:@selector(setWindow:)]) {
        [touch setWindow:window];
    }
    if ([touch respondsToSelector:@selector(setPhase:)]) {
        [touch setPhase:UITouchPhaseBegan];
    }
    if ([touch respondsToSelector:@selector(_setLocationInWindow:resetPrevious:)]) {
        [touch _setLocationInWindow:point resetPrevious:YES];
    }
    
    NSSet *touches = [NSSet setWithObject:touch];
    [targetView touchesBegan:touches withEvent:nil];
}

- (void)sendTouchUpAtPoint:(CGPoint)point toWindow:(UIWindow *)window {
    UIView *targetView = [window hitTest:point withEvent:nil];
    if (!targetView) return;
    
    UITouch *touch = [[UITouch alloc] init];
    
    if ([touch respondsToSelector:@selector(setView:)]) {
        [touch setView:targetView];
    }
    if ([touch respondsToSelector:@selector(setWindow:)]) {
        [touch setWindow:window];
    }
    if ([touch respondsToSelector:@selector(setPhase:)]) {
        [touch setPhase:UITouchPhaseEnded];
    }
    if ([touch respondsToSelector:@selector(_setLocationInWindow:resetPrevious:)]) {
        [touch _setLocationInWindow:point resetPrevious:YES];
    }
    
    NSSet *touches = [NSSet setWithObject:touch];
    [targetView touchesEnded:touches withEvent:nil];
}

- (BOOL)shouldPassthroughForView:(UIView *)view {
    // 根据需求判断是否需要穿透
    return YES;
}

@end

@interface TouchPassthroughManager : NSObject
+ (void)setupTouchPassthrough;
@end

@implementation TouchPassthroughManager

+ (void)setupTouchPassthrough {
    CGRect frame = [UIScreen mainScreen].bounds;
    TouchPassthroughWindow *window = [[TouchPassthroughWindow alloc] initWithFrame:frame];
    
    UIWindow *originalWindow = [UIApplication sharedApplication].keyWindow;
    window.rootViewController = originalWindow.rootViewController;
    
    window.windowLevel = UIWindowLevelNormal + 1;
    window.backgroundColor = [UIColor clearColor];
    window.opaque = NO;
    
    [window makeKeyAndVisible];
}

@end 