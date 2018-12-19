//
//  Videolytics.h
//  AppVStats
//
//  Created by Sos Avetyan on 4/14/18.
//

#import <Foundation/Foundation.h>

@class VLSession;

@interface Videolytics : NSObject

@property (nonatomic, strong) VLSession *session;

+ (NSString *)mainDirectory;
+ (NSString *)sessionsDirectory;
+ (id)sharedInstance;
- (void)startWithWindow:(UIWindow *)window andAppKey:(NSString *)appKey;
- (void)setUserIdentifier:(NSString *)userIdentifier;

@end
