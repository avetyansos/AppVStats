//
//  Report.m
//  AppVStats
//
//  Created by Sos Avetyan on 4/14/18.
//

#import "Report.h"

@interface Report()

@end

@implementation Report

- (NSDictionary *)reportWithSessionId:(NSString *)sessionId startTime:(double)startTime duration:(NSUInteger)duration userIdentifier:(NSString *)userIdentifier crash:(NSDictionary *)crash {
    
    NSDictionary *report = @{
                             @"sessionId": sessionId,
                             @"startTime": @(startTime),
                             @"duration": @(duration),
                             @"userIdentifier": userIdentifier ? userIdentifier : [NSNull null],
                             @"deviceInfo": [self deviceInfo],
                             @"crash": crash ? crash : @[]
                             };
    
    return report;
}

- (NSDictionary *)deviceInfo {
    
    NSDictionary *deviceInfo = @{
                                 @"deviceId": [[[UIDevice currentDevice] identifierForVendor] UUIDString],
                                 @"deviceModel": [[UIDevice currentDevice] name],
                                 @"platform": @"ios",
                                 @"osVersion": [[UIDevice currentDevice] systemVersion]
                                 };
    
    return deviceInfo;
}

@end
