//
//  VLSession.m
//  AppVStats
//
//  Created by Sos Avetyan on 4/14/18.
//

#import "VLSession.h"
#import "Videolytics.h"

@implementation VLSession

- (instancetype)init {
    
    self = [super init];
    if (self) {
        _sessionCreateTimestamp = [[NSDate date] timeIntervalSince1970];
        _sessionId = [[NSUUID UUID] UUIDString];
        _filesDirectory = [self createTempSessionDirectory];
    }
    
    return self;
}

- (NSString *)createTempSessionDirectory {
    
    NSString *mainDirectory = [Videolytics mainDirectory];
    NSString *dataPath = [mainDirectory stringByAppendingPathComponent:@"/tmp"];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if ([fileManager fileExistsAtPath:dataPath]) {
        [fileManager removeItemAtPath:dataPath error:nil];
    }
    if (![fileManager fileExistsAtPath:dataPath]) {
        NSError *error;
        if ([fileManager createDirectoryAtPath:dataPath withIntermediateDirectories:NO attributes:nil error:&error]) {
            return dataPath;
        }
        else {
            return nil;
        }
    }
    else {
        return dataPath;
    }
}

+ (NSString *)sessionDirectoryWithSessionId:(NSString *)sessionId {
    
    NSString *mainDirectory = [Videolytics sessionsDirectory];
    NSString *dataPath = [mainDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"/%@", sessionId]];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if (![fileManager fileExistsAtPath:dataPath]) {
        NSError *error;
        if ([fileManager createDirectoryAtPath:dataPath withIntermediateDirectories:NO attributes:nil error:&error]) {
            return dataPath;
        }
        else {
            return nil;
        }
    }
    else {
        return dataPath;
    }
}

- (NSString *)sessionDirectory {
    
    NSString *mainDirectory = [Videolytics sessionsDirectory];
    NSString *dataPath = [mainDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"/%@", self.sessionId]];
    return dataPath;
}

- (NSTimeInterval)duration {
    
    NSTimeInterval current = [[NSDate new] timeIntervalSince1970];
    NSUInteger duration = [[NSDate dateWithTimeIntervalSince1970:current] timeIntervalSinceDate:[NSDate dateWithTimeIntervalSince1970:self.sessionCreateTimestamp]]*1000;
    return duration;
}

- (NSArray *)events {
    
    if (!_events) {
        _events = [NSArray array];
    }
    
    return _events;
}

- (NSSet *)currentTouches {
    
    if (!_currentTouches) {
        _currentTouches = [NSSet set];
    }
    
    return _currentTouches;
}

@end
