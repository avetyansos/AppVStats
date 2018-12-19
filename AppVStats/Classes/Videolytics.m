//
//  Videolytics.m
//  AppVStats
//
//  Created by Sos Avetyan on 4/14/18.
//

#import "Videolytics.h"
#import "SRScreenRecorder.h"
#import "Crash.h"
#import "UIViewController+Events.h"
#import "VLSession.h"
#import "Uploader.h"
#import "Report.h"

#define videoFileName   @"video.mp4"
#define eventsFileName  @"events.json"
#define reportFileName  @"report.json"

@interface Videolytics()

@property (nonatomic, strong) SRScreenRecorder *screenRecorder;
@property (nonatomic, strong) Uploader *uploader;
@property (nonatomic, copy) NSString *userIdentifier;

@property (nonatomic, copy) NSString *sessionsDirectory;

@end


@implementation Videolytics

+ (NSString *)mainDirectory {
    
    static NSString *directory = nil;
    if (directory == nil) {
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *dataPath = [documentsDirectory stringByAppendingPathComponent:@"/Videolytics"];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        
        if (![fileManager fileExistsAtPath:dataPath]) {
            NSError *error;
            if (![fileManager createDirectoryAtPath:dataPath withIntermediateDirectories:NO attributes:nil error:&error]) {
                dataPath = nil;
            }
        }
        directory = dataPath;
    }
    return directory;
}

+ (NSString *)sessionsDirectory {
    
    static NSString *directory = nil;
    if (directory == nil) {
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *dataPath = [documentsDirectory stringByAppendingPathComponent:@"/Videolytics/Sessions"];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        
        if (![fileManager fileExistsAtPath:dataPath]) {
            NSError *error;
            if (![fileManager createDirectoryAtPath:dataPath withIntermediateDirectories:YES attributes:nil error:&error]) {
                dataPath = nil;
            }
        }
        directory = dataPath;
    }
    return directory;
}

+ (id)sharedInstance {
    
    static Videolytics *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    
    return sharedInstance;
}

- (void)startWithWindow:(UIWindow *)window andAppKey:(NSString *)appKey {
    self.uploader = [[Uploader alloc] init];
    [self setupNotifications];
    [self setupRecorderWithWindow:window];
    [self startSession];
    EventsInstall();
}

- (void)setUserIdentifier:(NSString *)userIdentifier {
    _userIdentifier = userIdentifier;
}

- (void)setupRecorderWithWindow:(UIWindow *)window {
    
    self.screenRecorder = [[SRScreenRecorder alloc] initWithWindow:window];
    self.screenRecorder.frameInterval = 6;
    self.screenRecorder.recordTouchPointer = YES;
}

- (void)setupNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)applicationDidEnterBackground:(NSNotification *)notification {
    [self stopSession];
}

- (void)applicationWillEnterForeground:(NSNotification *)notification {
    [self startSession];
}

- (void)startSession {
    
    [self uploadPreviousSession];
    self.session = [[VLSession alloc] init];
    self.screenRecorder.directory = self.session.filesDirectory;
    [self.screenRecorder startRecording];
}

- (void)stopSession {
    
    if ([self.screenRecorder isRecording]) {
        
        [self.screenRecorder stopRecording];

        [self saveData:self.session.events toFile:eventsFileName];
        
        Report *report = [[Report alloc] init];
        NSDictionary *reportDict = [report reportWithSessionId:self.session.sessionId startTime:(NSUInteger)(self.session.sessionCreateTimestamp*1000) duration:self.session.duration userIdentifier:self.userIdentifier crash:nil];
        [self saveData:reportDict toFile:reportFileName];

        [self moveToSessions];

        self.session = nil;
    }
}

- (void)moveToSessions {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    [fileManager moveItemAtPath:self.session.filesDirectory toPath:[self.session sessionDirectory] error:&error];
    if (error) {
        NSLog(@"Error: %@", error.localizedDescription);
    }
}

- (void)uploadPreviousSession {

    NSString *sessionId = [self nextSessionId];
    if (sessionId) {

        if ([self checkFilesForSessionId:sessionId]) {
            
            NSString *filePath = [[VLSession sessionDirectoryWithSessionId:sessionId] stringByAppendingPathComponent:[NSString stringWithFormat:@"/%@", videoFileName]];
            AWSS3TransferManagerUploadRequest *request = [self.uploader createUploadRequestWithSessionId:sessionId fileName:videoFileName filePath:filePath fileType:FileTypeVideo];
            [self.uploader uploadFileWithUploadRequest:request completion:^(BOOL isUploaded) {
                if (isUploaded) {
                    NSString *filePath = [[VLSession sessionDirectoryWithSessionId:sessionId] stringByAppendingPathComponent:[NSString stringWithFormat:@"/%@", eventsFileName]];
                    AWSS3TransferManagerUploadRequest *request = [self.uploader createUploadRequestWithSessionId:sessionId fileName:eventsFileName filePath:filePath fileType:FileTypeJson];
                    [self.uploader uploadFileWithUploadRequest:request completion:^(BOOL isUploaded) {
                        if (isUploaded) {
                            NSString *filePath = [[VLSession sessionDirectoryWithSessionId:sessionId] stringByAppendingPathComponent:[NSString stringWithFormat:@"/%@", reportFileName]];
                            NSData *reportData = [self reportJsonFromFile:filePath];
                            [self.uploader sendRequestWithBody:reportData andCallback:^(NSDictionary *dict) {
                                NSLog(@"success");
                                NSFileManager *fm = [NSFileManager defaultManager];
                                NSString *directory = [VLSession sessionDirectoryWithSessionId:sessionId];
                                NSError *error = nil;
                                [fm removeItemAtPath:directory error:&error];
                                if (!error) {
                                    [self uploadPreviousSession];
                                }
                            } andFailCallBack:^(NSError *error) {
                                NSLog(@"failure");
                            }];
                        }
                    }];
                }
            }];
        }
        else {
            NSFileManager *fm = [NSFileManager defaultManager];
            NSString *directory = [VLSession sessionDirectoryWithSessionId:sessionId];
            NSError *error = nil;
            [fm removeItemAtPath:directory error:&error];
            if (!error) {
                [self uploadPreviousSession];
            }
        }
    }
}

- (BOOL)checkFilesForSessionId:(NSString *)sessionId {
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *videoFilePath = [[VLSession sessionDirectoryWithSessionId:sessionId] stringByAppendingPathComponent:[NSString stringWithFormat:@"/%@", videoFileName]];
    NSString *eventsFilePath = [[VLSession sessionDirectoryWithSessionId:sessionId] stringByAppendingPathComponent:[NSString stringWithFormat:@"/%@", eventsFileName]];
    NSString *reportFilePath = [[VLSession sessionDirectoryWithSessionId:sessionId] stringByAppendingPathComponent:[NSString stringWithFormat:@"/%@", reportFileName]];
    return ([fileManager fileExistsAtPath:videoFilePath] && [fileManager fileExistsAtPath:eventsFilePath] && [fileManager fileExistsAtPath:reportFilePath]);
}

- (NSString *)nextSessionId {
    
    NSArray *sessions = [self sessionDirectories];
    NSString *sessionId;
    
    if (sessions.count > 0) {
        sessionId = sessions.firstObject;
    }
    
    return sessionId;
}

- (void)saveData:(id)data toFile:(NSString *)fileName {
    
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:data options:NSJSONWritingPrettyPrinted error:&error];

    NSString *filePath = [NSString stringWithFormat:@"%@/%@", self.session.filesDirectory, fileName];
    [jsonData writeToFile:filePath atomically:YES];
}

- (NSData *)reportJsonFromFile:(NSString *)filePath {
    
    NSData *data = [NSData dataWithContentsOfFile:filePath];
    return data;
}


- (NSArray *)sessionDirectories {
    
    NSMutableArray *directories = [NSMutableArray array];

    NSString *entry;
    BOOL isDirectory;
    NSString *mainDirectory = [Videolytics sessionsDirectory];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager changeCurrentDirectoryPath:mainDirectory];
    NSDirectoryEnumerator *enumerator = [fileManager enumeratorAtPath:mainDirectory];
    while ((entry = [enumerator nextObject]) != nil) {
        if ([fileManager fileExistsAtPath:entry isDirectory:&isDirectory] && isDirectory) {
            [directories addObject:entry];
        }
    }
    
    return directories;
}

@end
