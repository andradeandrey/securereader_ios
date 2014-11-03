//
//  SRLoginViewController.h
//  SecureReader
//
//  Created by N-Pex on 2014-10-17.
//  Copyright (c) 2014 Guardian Project. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SRLoginViewController : UIViewController

- (IBAction)loginButtonClicked:(id)sender;

- (void) setDestinationViewController:(UIViewController *)viewController animated:(BOOL)animated;

@end
