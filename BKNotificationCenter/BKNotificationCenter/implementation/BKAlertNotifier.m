//
//  BKAlertNotifier.m
//  BKNotificationCenter
//
//  Created by black9 on 01/05/15.
//  Copyright (c) 2015 black9. All rights reserved.
//

#import "BKAlertNotifier.h"
@import UIKit;

@interface BKAlertNotifier ()

@property (nonatomic, strong) NSArray* currentButtonTitles;
@property (nonatomic,strong) CompletionAlertBlock finishBlock;
@property (nonatomic,strong) CompletionAfterOpenAppFromNotification afterOpenFinishBlock;
@end

@implementation BKAlertNotifier


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
