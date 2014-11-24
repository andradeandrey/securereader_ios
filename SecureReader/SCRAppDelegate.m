//
//  AppDelegate.m
//  SecureReader
//
//  Created by N-Pex on 2014-10-20.
//  Copyright (c) 2014 Guardian Project. All rights reserved.
//

#import "SCRAppDelegate.h"
#import "SCRApplication.h"
#import "SCRSettings.h"
#import "NSBundle+Language.h"
#import "SCRApplication.h"
#import "SCRLoginViewController.h"
#import "SCRSelectLanguageViewController.h"
#import "SCRCreatePassphraseViewController.h"
#import "SCRNavigationController.h"
#import "SCRTheme.h"

@implementation SCRAppDelegate
{
    BOOL mLoggedIn;
}

+ (SCRAppDelegate*) sharedAppDelegate
{
    return (SCRAppDelegate*)[[UIApplication sharedApplication] delegate];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [NSBundle setLanguage:[SCRSettings getUiLanguage]];
    [SCRTheme initialize];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidTimeout:) name:kApplicationDidTimeoutNotification object:nil];
    
    return YES;
}

-(void)applicationDidTimeout:(NSNotification *) notif
{
    NSLog (@"time exceeded!!");
    SCRNavigationController *navController = (SCRNavigationController *)self.window.rootViewController;
    UIViewController *vcCurrent = [navController visibleViewController];
    if ([vcCurrent class] != [SCRSelectLanguageViewController class] &&
        [vcCurrent class] != [SCRCreatePassphraseViewController class] &&
        [vcCurrent class] != [SCRLoginViewController class])
    {
        SCRLoginViewController *vcLogin = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"login"];
        vcLogin.modalPresentationStyle = UIModalPresentationFullScreen;
        dispatch_async(dispatch_get_main_queue(), ^{
            [(SCRNavigationController *)self.window.rootViewController presentViewController:vcLogin animated:YES completion:nil];
        });
    }
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    [[SCRApplication sharedApplication] lockApplicationDelayed];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    self.window.hidden = YES;
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    self.window.hidden = NO;
    [(SCRApplication *)[UIApplication sharedApplication] startLockTimer];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (BOOL)hasCreatedPassphrase
{
    //return NO;
    return [SCRSettings getPassphrase] != nil && [SCRSettings getPassphrase].length > 0;
}

- (BOOL)isLoggedIn
{
    return mLoggedIn;
}

- (BOOL)loginWithPassphrase:(NSString *)passphrase
{
    if ([passphrase isEqualToString:[SCRSettings getPassphrase]])
    {
        mLoggedIn = YES;
    }
    return mLoggedIn;
}

@end