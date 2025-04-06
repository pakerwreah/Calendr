//
//  ExceptionCatcher.m
//  Calendr
//
//  Created by Paker on 06/04/2025.
//


// ExceptionCatcher.m
#import "ExceptionCatcher.h"

@implementation ExceptionCatcher
+ (void)tryBlock:(void (^)(void))tryBlock catchBlock:(void (^)(NSException *exception))catchBlock {
    @try {
        tryBlock();
    } @catch (NSException *exception) {
        catchBlock(exception);
    }
}
@end
