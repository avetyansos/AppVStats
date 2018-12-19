//
//  Uploader.h
//  AppVStats
//
//  Created by Sos Avetyan on 4/14/18.
//

#import <Foundation/Foundation.h>
#import "AWSS3.h"
#import "AWSCore.h"

typedef enum : NSUInteger {
    FileTypeJson,
    FileTypeVideo,
} FileType;

typedef void(^uploadCompletion)(BOOL isUploaded);

@interface Uploader : NSObject

- (AWSS3TransferManagerUploadRequest *)createUploadRequestWithSessionId:(NSString *)sessionId fileName:(NSString *)filename filePath:(NSString *)filepath fileType:(FileType)fileType;
- (void)uploadFileWithUploadRequest:(AWSS3TransferManagerUploadRequest *)uploadRequest completion:(uploadCompletion)completion;
- (void)sendRequestWithBody:(NSData *)body andCallback:(void (^)(NSDictionary *))callBack andFailCallBack:(void (^)(NSError *))failedCallBack;

@end
