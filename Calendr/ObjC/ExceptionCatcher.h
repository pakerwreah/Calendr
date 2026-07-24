//
//  ExceptionCatcher.h
//  Calendr
//
//  Created by Paker on 06/04/2025.
//

@import Foundation;

@interface ExceptionCatcher : NSObject

+ (nullable id)safeValueForKey:(NSString * _Nonnull)key in:(id _Nonnull)object keyExists:(BOOL * _Nonnull)keyExists;

@end
