//
//  ExceptionCatcher.m
//  Calendr
//
//  Created by Paker on 06/04/2025.
//

#import "ExceptionCatcher.h"

@implementation ExceptionCatcher

+ (void)tryBlock:(void (^_Nonnull)(void))tryBlock
      catchBlock:(void (^_Nonnull)(NSException * _Nullable exception))catchBlock
{
    @try {
        tryBlock();
    } @catch (NSException *exception) {
        catchBlock(exception);
    }
}

@end
