//
//  KCRunLoopProfile.h
//  KCRunLoopProfile
//
//  Created by karsa on 2018/7/2.
//  Copyright © 2018年 karsa. All rights reserved.
//

#import <UIKit/UIKit.h>

//! Project version number for KCRunLoopProfile.
FOUNDATION_EXPORT double KCRunLoopProfileVersionNumber;

//! Project version string for KCRunLoopProfile.
FOUNDATION_EXPORT const unsigned char KCRunLoopProfileVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <KCRunLoopProfile/PublicHeader.h>

@interface KCRunLoopProfile : NSObject
+ (void)profile;
+ (void)profileWithCheckDuration:(NSTimeInterval)duration;
+ (void)setStackTraceCallBackWhenSlow:(void(^)(NSArray<NSString *>* stackTrace))stackTraceCallBack;
@end
