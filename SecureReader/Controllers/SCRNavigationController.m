//
//  SRNavigationController.m
//  SecureReader
//
//  Created by N-Pex on 2014-10-20.
//  Copyright (c) 2014 Guardian Project. All rights reserved.
//

#import "SCRNavigationController.h"
#import "SCRAppDelegate.h"
#import "SCRSelectLanguageViewController.h"
#import "SCRCreatePassphraseViewController.h"
#import "SCRLoginViewController.h"

@interface SCRNavigationController ()

@end

@implementation SCRNavigationController

- (void)viewDidLoad {
    [super viewDidLoad];
    if (![[SCRAppDelegate sharedAppDelegate] hasCreatedPassphrase])
        [self performSegueWithIdentifier:@"segueToWelcome" sender:self];
    else
        [self performSegueWithIdentifier:@"segueToMain" sender:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    if ([viewController class] != [SCRSelectLanguageViewController class] &&
        [viewController class] != [SCRCreatePassphraseViewController class] &&
        [viewController class] != [SCRLoginViewController class])
    {
        if (![[SCRAppDelegate sharedAppDelegate] isLoggedIn])
        {
            SCRLoginViewController *vcLogin = [self.storyboard instantiateViewControllerWithIdentifier:@"login"];
            vcLogin.modalPresentationStyle = UIModalPresentationFullScreen;
            [vcLogin setDestinationViewController:viewController animated:animated];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self presentViewController:vcLogin animated:YES completion:nil];
            });
            return;
        }
    }
    [super pushViewController:viewController animated:animated];
}

//- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender
//{
//        if ([[segue destinationViewController] class] != [SRSelectLanguageViewController class] &&
//            [[segue destinationViewController] class] != [SRLoginViewController class])
//        {
//                if (![[AppDelegate sharedAppDelegate] isLoggedIn])
//                {
//                    UIViewController *viewController = [self.storyboard instantiateViewControllerWithIdentifier:@"login"];
//                    //viewController.delegate = self;
//                    viewController.modalPresentationStyle = UIModalPresentationFullScreen;
//                    [self presentViewController:viewController animated:YES completion:NULL];
//                    return NO;
//                }
//        }
//    return [super shouldPerformSegueWithIdentifier:<#identifier#> sender:<#sender#>];
//}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
//    if ([[segue destinationViewController] class] != [SRSelectLanguageViewController class] &&
//        [[segue destinationViewController] class] != [SRLoginViewController class])
//    {
//            if (![[AppDelegate sharedAppDelegate] isLoggedIn])
//            {
//                UIViewController *viewController = [self.storyboard instantiateViewControllerWithIdentifier:@"login"];
//                //viewController.delegate = self;
//                viewController.modalPresentationStyle = UIModalPresentationFullScreen;
//                [self presentViewController:viewController animated:YES completion:NULL];
//                segue
//            }
//    }
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}


@end