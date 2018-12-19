//
//  Crash.m
//  AppVStats
//
//  Created by Sos Avetyan on 4/14/18.
//

#import "Crash.h"

@implementation Crash

- (instancetype)init {
    
    self = [super init];
    if (self) {
        NSSetUncaughtExceptionHandler(&onUncaughtException);
    }
    return self;
}

void onUncaughtException(NSException* exception) {
    NSLog(@"%@", exception);
}

@end
