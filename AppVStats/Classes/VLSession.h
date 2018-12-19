//
//  VLSession.h
//  AppVStats
//
//  Created by Sos Avetyan on 4/14/18.
//

#import <Foundation/Foundation.h>

@interface VLSession : NSObject

@property (nonatomic, readonly) NSTimeInterval sessionCreateTimestamp;
@property (nonatomic, copy, readonly) NSString *sessionId;
@property (nonatomic, copy, readonly) NSString *filesDirectory;
@property (nonatomic, strong) NSArray *events;
@property (nonatomic, strong) NSSet *currentTouches;
@property (nonatomic, readonly) NSTimeInterval duration;

+ (NSString *)sessionDirectoryWithSessionId:(NSString *)sessionId;
- (NSString *)sessionDirectory;

@end
