//
//  Report.h
//  AppVStats
//
//  Created by Sos Avetyan on 4/14/18.
//

#import <Foundation/Foundation.h>

@interface Report : NSObject

- (NSDictionary *)reportWithSessionId:(NSString *)sessionId startTime:(double)startTime duration:(NSUInteger)duration userIdentifier:(NSString *)userIdentifier crash:(NSDictionary *)crash;

@end
