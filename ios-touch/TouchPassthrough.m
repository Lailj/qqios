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

@interface TouchPassthroughWindow : UIWindow
@end

@implementation TouchPassthroughWindow

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *hitView = [super hitTest:point withEvent:event];
    if ([self shouldPassthroughForView:hitView]) {
        [self simulateTouchAtPoint:point];
        return NO;
    }
    return [super pointInside:point withEvent:event];
}

- (BOOL)shouldPassthroughForView:(UIView *)view {
    return YES; // 根据需求修改判断条件
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
    
    // 使用更底层的方法模拟触摸
    [self sendTouchDownAtPoint:point toWindow:targetWindow];
    
    // 短暂延迟后发送触摸结束事件
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.05 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self sendTouchUpAtPoint:point toWindow:targetWindow];
    });
}

- (void)sendTouchDownAtPoint:(CGPoint)point toWindow:(UIWindow *)window {
    UIView *targetView = [window hitTest:point withEvent:nil];
    if (!targetView) return;
    
    // 创建触摸对象
    UITouch *touch = [[UITouch alloc] init];
    
    // 设置触摸的基本属性
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
    
    // 创建触摸集合
    NSSet *touches = [NSSet setWithObject:touch];
    
    // 发送触摸事件
    [targetView touchesBegan:touches withEvent:nil];
}

- (void)sendTouchUpAtPoint:(CGPoint)point toWindow:(UIWindow *)window {
    UIView *targetView = [window hitTest:point withEvent:nil];
    if (!targetView) return;
    
    // 创建触摸对象
    UITouch *touch = [[UITouch alloc] init];
    
    // 设置触摸的基本属性
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
    
    // 创建触摸集合
    NSSet *touches = [NSSet setWithObject:touch];
    
    // 发送触摸事件
    [targetView touchesEnded:touches withEvent:nil];
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


// 在 AppDelegate 中添加以下代码
// - (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
//     [TouchPassthroughManager setupTouchPassthrough];
//     return YES;
// }