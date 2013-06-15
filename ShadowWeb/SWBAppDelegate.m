//
//  SWBAppDelegate.m
//  ShadowWeb
//
//  Created by clowwindy on 2/16/13.
//  Copyright (c) 2013 clowwindy. All rights reserved.
//

#import "SWBAppDelegate.h"
#import <AVFoundation/AVFoundation.h>

#import "GCDWebServer.h"
#import "SWBViewController.h"
#import "ProxySettingsTableViewController.h"

@implementation SWBAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

    [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{

    }];
    dispatch_queue_t proxy = dispatch_queue_create("proxy", NULL);
    dispatch_async(proxy, ^{
        [self runProxy];
    });

    NSData *pacData = [NSData dataWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"proxy" withExtension:@"pac"]];
    GCDWebServer *webServer = [[GCDWebServer alloc] init];
    [webServer addHandlerForMethod:@"GET" path:@"/proxy.pac" requestClass:[GCDWebServerRequest class] processBlock:^GCDWebServerResponse *(GCDWebServerRequest *request) {
             return [GCDWebServerDataResponse responseWithData:pacData contentType:@"application/x-ns-proxy-autoconfig"];

         }
    ];

    NSData *mobileconfig = [NSData dataWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"shadowsocks" withExtension:@"mobileconfig"]];
    [webServer addHandlerForMethod:@"GET" path:@"/apn" requestClass:[GCDWebServerRequest class] processBlock:^GCDWebServerResponse *(GCDWebServerRequest *request) {
             return [GCDWebServerDataResponse responseWithData:mobileconfig contentType:@"application/x-apple-aspen-config"];

         }
    ];


    dispatch_queue_t web = dispatch_queue_create("web", NULL);
    dispatch_async(web, ^{
        @try {
            [webServer runWithPort:8080];
        } @catch (NSException *e) {
            NSLog(@"webserver quit with error: %@", e);
        }
    });

    self.networkActivityIndicatorManager = [[SWBNetworkActivityIndicatorManager alloc] init];

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.viewController = [[SWBViewController alloc] init];
    self.window.rootViewController = self.viewController;
    [self.window makeKeyAndVisible];
    
    // Play music, so app can run in the backgound.
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setActive:YES error:nil];
    [session setCategory:AVAudioSessionCategoryPlayback error:nil];
    
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"Good.Time" withExtension:@"m4r"];
    
    static AVAudioPlayer *player;
    player = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
    [player prepareToPlay];
    [player setVolume:0];
    player.numberOfLoops = -1;
    [player play];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    [((SWBViewController *) self.window.rootViewController) saveData];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    [((SWBViewController *) self.window.rootViewController) saveData];
}

#pragma mark - Run proxy

- (void)runProxy {
    [ProxySettingsTableViewController reloadConfig];
    for (; ;) {
        if ([ProxySettingsTableViewController runProxy]) {
            sleep(1);
        } else {
            sleep(2);
        }
    }
}
@end