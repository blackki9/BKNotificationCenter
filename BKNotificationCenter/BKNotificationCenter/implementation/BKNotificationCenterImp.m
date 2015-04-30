//
//  BKNotificationCenterImp.m
//  RemindToStudy
//
//  Created by black9 on 30/04/15.
//  Copyright (c) 2015 black9. All rights reserved.
//

#import "BKNotificationCenterImp.h"
@import AVFoundation;

NSString * const kNotificationAlertKey = @"kNotificationAlertKey";

@interface BKNotificationCenterImp ()

@property (nonatomic, strong)  AVAudioPlayer* notificationPlayer;
@property (nonatomic, strong) NSArray* currentButtonTitles;

@end


@implementation BKNotificationCenterImp

+ (instancetype)sharedCenter
{
    static dispatch_once_t onceToken;
    static id sharedInstance = nil;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    
    return sharedInstance;
}

- (void)initializeCenterWithApplication:(UIApplication*)application
{
    [self askUserToConfirmSendNotificationsWithApplication:application];
    [self cleanIfFirstLaunch];
    [self checkForOverdueNotifications];
    [self initSound];
}

- (void)askUserToConfirmSendNotificationsWithApplication:(UIApplication*)application
{
    if ([UIApplication instancesRespondToSelector:@selector(registerUserNotificationSettings:)]){
        [application registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert|UIUserNotificationTypeBadge|UIUserNotificationTypeSound categories:nil]];
    }
}

- (void)cleanIfFirstLaunch
{
    BOOL isFirstLaunch = ![[NSUserDefaults standardUserDefaults] boolForKey:@"isFirstLaunch"];
    if(isFirstLaunch)
    {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"isFirstLaunch"];
        [self cancelAllNotifications];
    }
    else
    {
        [self refreshNotifications];
    }
}

- (void)initSound
{
    NSError *error;
    NSURL *audioURL = [[NSBundle mainBundle ]URLForResource:@"notification_sound.caf" withExtension:nil];
    
    self.notificationPlayer = [[AVAudioPlayer alloc]initWithContentsOfURL:audioURL error:&error];
    
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    NSError *errorSession = nil;
    [audioSession setCategory:AVAudioSessionCategoryPlayback withOptions:AVAudioSessionCategoryOptionDuckOthers error:nil];
    [audioSession setActive:NO error:&errorSession];
    
    [self.notificationPlayer prepareToPlay];
    [self.notificationPlayer setVolume:1.0];
}

- (void)didReceiveLocalNotification:(UILocalNotification*)localNotification
{
    
}

#pragma mark - sound

- (void)playNotificationSound
{
    [self.notificationPlayer play];
}

#pragma mark - alert

- (void)showAlertIfSharedAppIsActiveForLocalNotification:(UILocalNotification*)localNotification
{
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive ) {
        
    }
}

- (void)showAlertForLocalNotification:(UILocalNotification*)localNotification
{
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:localNotification.alertTitle message:localNotification.alertBody delegate:self cancelButtonTitle:[self cancelButtonTitle] otherButtonTitles:nil];
    
    //TODO
    
    [alert show];
}

- (NSString*)cancelButtonTitle
{
    if(self.currentButtonTitles && self.currentButtonTitles.count) {
        return @"Cancel";
    }
    
    return @"OK";
}

- (UIAlertView*)setupAlertButtons:(UIAlertView*)alert
{
    if(self.currentButtonTitles) {
        for(NSString* buttonTitle in self.currentButtonTitles) {
            [alert addButtonWithTitle:buttonTitle];
        }
    }
    
    return alert;
}

#pragma mark - schedule

- (void)scheduleSingleNotificationOnDate:(NSDate*)fireDate message:(NSString*)message key:(NSString*)key
{
    [self scheduleSingleNotificationOnDate:fireDate message:message key:key userInfo:[NSDictionary dictionary]];
  }

- (void)scheduleSingleNotificationOnDate:(NSDate*)fireDate message:(NSString*)message key:(NSString*)key userInfo:(NSDictionary*)userInfo
{
    UILocalNotification* localNotification = [[UILocalNotification alloc] init];
    
    localNotification.fireDate = fireDate;
    localNotification.alertBody = message;
    localNotification.alertTitle = [self appName];
    localNotification.userInfo = [self userInfoForLocalNotificationWithInfo:userInfo key:key];
    
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
}

- (NSDictionary*)userInfoForLocalNotificationWithInfo:(NSDictionary*)info key:(NSString*)key
{
    NSMutableDictionary* result = [NSMutableDictionary dictionary];
    
    result[kNotificationAlertKey] = key;
    
    [result addEntriesFromDictionary:info];
    
    return result;
}

#pragma mark - cancel
- (void)cancelNotificationByKey:(NSString*)key
{
    UILocalNotification* localNotification = [self localNotificationWithKey:key];
    if(localNotification) {
        [[UIApplication sharedApplication] cancelLocalNotification:localNotification];
    }
}

- (UILocalNotification*)localNotificationWithKey:(NSString*)key
{
    for(UILocalNotification* localNotification in [[UIApplication sharedApplication] scheduledLocalNotifications]) {
        if([localNotification.userInfo[kNotificationAlertKey] isEqualToString:key]) {
            return localNotification;
        }
    }
    
    return nil;
}

- (void)cancelAllNotifications
{
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
}

#pragma mark - refresh

- (void)refreshNotifications
{
    
}

- (void)checkForOverdueNotifications
{
    //TODO check outdated notifications and clean it
}

#pragma mark - utils

- (NSString*)appName
{
    return [[[NSBundle mainBundle] localizedInfoDictionary]
            objectForKey:@"CFBundleDisplayName"];
}

@end
