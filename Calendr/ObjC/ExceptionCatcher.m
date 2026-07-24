//
//  ExceptionCatcher.m
//  Calendr
//
//  Created by Paker on 06/04/2025.
//

#import "ExceptionCatcher.h"

@implementation ExceptionCatcher

+ (nullable id)safeValueForKey:(NSString * _Nonnull)key in:(id _Nonnull)object keyExists:(BOOL * _Nonnull)keyExists {
    @try {
        id value = [object valueForKey:key];
        *keyExists = YES;
        return value;
    } @catch (NSException *exception) {
        *keyExists = NO;
        return nil;
    }
}

@end
