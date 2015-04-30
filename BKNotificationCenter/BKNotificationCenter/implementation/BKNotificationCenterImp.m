//
//  BKNotificationCenterImp.m
//  RemindToStudy
//
//  Created by black9 on 30/04/15.
//  Copyright (c) 2015 black9. All rights reserved.
//

#import "BKNotificationCenterImp.h"
#import "BKNotificationCanceler.h"
#import "BKNotificationRefresher.h"
#import "BKNotificationUtilities.h"
#import "BKNotificationScheduler.h"

@import AVFoundation;

NSString * const kFirstLaunchKey = @"kFirstLaunchKey";

@interface BKNotificationCenterImp ()

@property (nonatomic, strong) AVAudioPlayer* notificationPlayer;
@property (nonatomic, strong) NSArray* currentButtonTitles;

@property (nonatomic, strong) BKNotificationCanceler* canceler;
@property (nonatomic, strong) BKNotificationRefresher* refresher;
@property (nonatomic, strong) BKNotificationUtilities* utilities;
@property (nonatomic, strong) BKNotificationScheduler* scheduler;

@property (nonatomic,strong) CompletionAlertBlock finishBlock;
@property (nonatomic,strong) CompletionAfterOpenAppFromNotification afterOpenFinishBlock;

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

- (instancetype)init
{
    self = [super init];
    if (self) {
        _utilities = [[BKNotificationUtilities alloc] init];
        _canceler = [[BKNotificationCanceler alloc] initWithNotificationKey:[_utilities notificationIdKey]];
        _refresher = [[BKNotificationRefresher alloc] init];
        _scheduler = [[BKNotificationScheduler alloc] init];
    }
    
    return self;
}

- (void)initializeCenterWithApplication:(UIApplication*)application
{
    [self askUserToConfirmSendNotificationsWithApplication:application];
    [self cleanIfFirstLaunch];
    [self.refresher checkForOverdueNotifications];
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
    if([self isFirstLaunch])
    {
        [self setFirstLaunch];
        [self cancelAllNotifications];
    }
    else
    {
        [self.refresher refreshNotifications];
    }
}

- (BOOL)isFirstLaunch
{
    return ![[NSUserDefaults standardUserDefaults] boolForKey:kFirstLaunchKey];
}

- (void)setFirstLaunch
{
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kFirstLaunchKey];
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
    [self playNotificationSoundIfSharedAppIsActive];
    [self showAlertIfSharedAppIsActiveForLocalNotification:localNotification];
}

#pragma mark - sound

- (void)playNotificationSoundIfSharedAppIsActive
{
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive ) {
        [self.notificationPlayer play];
    }
}

#pragma mark - alert

- (void)showAlertIfSharedAppIsActiveForLocalNotification:(UILocalNotification*)localNotification
{
    if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive ) {
        [self showAlertForLocalNotification:localNotification];
    }
}

- (void)showAlertForLocalNotification:(UILocalNotification*)localNotification
{
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:localNotification.alertTitle message:localNotification.alertBody delegate:self cancelButtonTitle:[self cancelButtonTitle] otherButtonTitles:nil];
    
    alert = [self setupAlertButtons:alert];
    
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
    [self.scheduler scheduleSingleNotificationOnDate:fireDate message:message key:key userInfo:userInfo];
}

#pragma mark - cancel
- (void)cancelNotificationByKey:(NSString*)key
{
    [self.canceler cancelNotificationByKey:key];
}

- (void)cancelAllNotifications
{
    [self.canceler cancelAllNotifications];
}

#pragma mark - set blocks

- (void)setCompletitionHandler:(CompletionAlertBlock)finishBlock
{
    self.finishBlock = finishBlock;
}

- (void)setActionAfterOpenApp:(CompletionAfterOpenAppFromNotification)afterOpenFinishBlock
{
    self.afterOpenFinishBlock = afterOpenFinishBlock;
}

- (void)setButtonTitles:(NSArray*)titles
{
    self.currentButtonTitles = titles;
}

@end
