//
//  ExceptionCatcher.h
//  Calendr
//
//  Created by Paker on 06/04/2025.
//


// ExceptionCatcher.h
#import <Foundation/Foundation.h>

@interface ExceptionCatcher : NSObject
+ (void)tryBlock:(void (^)(void))tryBlock catchBlock:(void (^)(NSException *exception))catchBlock;
@end
