//
//  ExceptionCatcher.h
//  Calendr
//
//  Created by Paker on 06/04/2025.
//

#import <Foundation/Foundation.h>

@interface ExceptionCatcher : NSObject

+ (void)tryBlock:(void (^_Nonnull)(void))tryBlock
      catchBlock:(void (^_Nonnull)(NSException * _Nullable exception))catchBlock;

@end
