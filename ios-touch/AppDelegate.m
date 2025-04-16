- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [TouchPassthroughManager setupTouchPassthrough];
    return YES;
} 