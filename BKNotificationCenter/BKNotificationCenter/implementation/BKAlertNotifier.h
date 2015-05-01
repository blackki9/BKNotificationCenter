//
//  BKAlertNotifier.h
//  BKNotificationCenter
//
//  Created by black9 on 01/05/15.
//  Copyright (c) 2015 black9. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Blocks.h"
@class UILocalNotification;

@interface BKAlertNotifier : NSObject

- (void)showAlertIfSharedAppIsActiveForLocalNotification:(UILocalNotification*)localNotification;

- (void)setCompletitionHandler:(CompletionAlertBlock)finishBlock;
- (void)setActionAfterOpenApp:(CompletionAfterOpenAppFromNotification)afterOpenFinishBlock;
- (void)setButtonTitles:(NSArray*)titles;

@end
