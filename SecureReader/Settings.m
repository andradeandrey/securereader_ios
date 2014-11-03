//
//  Settings.m
//  SecureReader
//
//  Created by N-Pex on 2014-10-17.
//  Copyright (c) 2014 Guardian Project. All rights reserved.
//

#import "Settings.h"

@implementation Settings

+ (NSString *)getUiLanguage
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *ret = [userDefaults stringForKey:@"uiLanguage"];
    if (ret == nil)
        ret = @"en";
    return ret;
}

+ (void)setUiLanguage:(NSString *)languageCode
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setValue:languageCode forKey:@"uiLanguage"];
    [userDefaults synchronize];
}

+ (NSString *)getPassphrase
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *ret = [userDefaults stringForKey:@"passphrase"];
    return ret;
}

+ (void) setPassphrase:(NSString *)passphrase
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setValue:passphrase forKey:@"passphrase"];
    [userDefaults synchronize];
}



@end
