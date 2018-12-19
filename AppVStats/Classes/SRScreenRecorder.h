
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <TargetConditionals.h>

@interface SRScreenRecorder : NSObject

@property (retain, nonatomic, readonly) UIWindow *window; // A window to be recorded.
@property (assign, nonatomic) NSInteger frameInterval;
@property (assign, nonatomic) NSUInteger autosaveDuration; // in second, default value is 600 (10 minutes).
@property (assign, nonatomic) BOOL recordTouchPointer;
@property (copy, nonatomic) NSString *directory;

- (instancetype)initWithWindow:(UIWindow *)window;

- (void)startRecording;
- (void)stopRecording;
- (BOOL)isRecording;

@end
