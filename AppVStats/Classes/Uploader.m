//
//  Uploader.m
//  AppVStats
//
//  Created by Sos Avetyan on 4/14/18.
//

#import "Uploader.h"

#define awsAccessKey    @"AKIAJKYK5YYKONSHZFLQ"
#define awsSecretKey    @"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"
#define awsBucket       @"am.iunetworks.iun-hackathon"
#define videolyticsUrl  @"http://18.220.188.16/api/v1/analytics"

@interface Uploader()<NSURLSessionDelegate>

@end

@implementation Uploader

- (instancetype)init {
    
    self = [super init];
    if (self) {
        
        AWSStaticCredentialsProvider *credentialsProvider = [[AWSStaticCredentialsProvider alloc] initWithAccessKey:awsAccessKey secretKey:awsSecretKey];
        AWSServiceConfiguration *configuration = [[AWSServiceConfiguration alloc] initWithRegion:AWSRegionUSEast2 credentialsProvider:credentialsProvider];
        [AWSServiceManager defaultServiceManager].defaultServiceConfiguration = configuration;
    }
    
    return self;
}

- (AWSS3TransferManagerUploadRequest *)createUploadRequestWithSessionId:(NSString *)sessionId fileName:(NSString *)filename filePath:(NSString *)filepath fileType:(FileType)fileType {
    
    AWSS3TransferManagerUploadRequest *uploadRequest = [[AWSS3TransferManagerUploadRequest alloc] init];
    uploadRequest.body = [NSURL fileURLWithPath:filepath];
    uploadRequest.key = [NSString stringWithFormat:@"%@/%@", sessionId, filename];
//    uploadRequest.key = filename;
    uploadRequest.bucket = awsBucket;
    uploadRequest.ACL = AWSS3ObjectCannedACLPublicRead;
    switch (fileType) {
        case FileTypeJson:
            uploadRequest.contentType = @"application/json";
            break;
        case FileTypeVideo:
            uploadRequest.contentType = @"video/mp4";
            break;
    }
    
    uploadRequest.uploadProgress =  ^(int64_t bytesSent, int64_t totalBytesSent, int64_t totalBytesExpectedToSend){
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"%lld", bytesSent);
        });
    };
    
    return uploadRequest;
}

- (void)uploadFileWithUploadRequest:(AWSS3TransferManagerUploadRequest *)uploadRequest completion:(uploadCompletion)completion {
    
    AWSS3TransferManager *transferManager = [AWSS3TransferManager defaultS3TransferManager];
    [[transferManager upload:uploadRequest] continueWithBlock:^id _Nullable(AWSTask * _Nonnull task) {
        if (task.error) {
            if ([task.error.domain isEqualToString:AWSS3TransferManagerErrorDomain]) {
                switch (task.error.code) {
                    case AWSS3TransferManagerErrorCancelled:
                    case AWSS3TransferManagerErrorPaused:
                        break;
                        
                    default:
                        NSLog(@"Error: %@", task.error);
                        break;
                }
            } else {
                // Unknown error.
                NSLog(@"Error: %@", task.error);
            }
            
            completion(NO);
        }
        
        if (task.result) {
            AWSS3TransferManagerUploadOutput *uploadOutput = task.result;
            // The file uploaded successfully.
            completion(YES);
        }
        return nil;
    }];
}

- (void)sendRequestWithBody:(NSData *)body andCallback:(void (^)(NSDictionary *))callBack andFailCallBack:(void (^)(NSError *))failedCallBack {
    NSError *error;
    
    NSURL *urlFromString = [NSURL URLWithString:videolyticsUrl];
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:nil];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:urlFromString cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0];
    
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPMethod:@"POST"];

    [request setHTTPBody:body];
    
    NSURLSessionDataTask *postDataTask = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSDictionary *json = (NSDictionary *)response;
        callBack(json);
    }];
    
    [postDataTask resume];
}

@end
