//
//  DownloadManager.h
//  DownloadManger
//
//  Created by Anil Upadhyay on 10/29/14.
//  Copyright (c) 2014 Netspectrum Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol DowloadManagerDelegate <NSObject>

@required
-(void)setCompletionWithSuccess:(NSMutableArray *)localPaths;
@optional
-(void)setProgressiveDownloadProgress:(float)percentDone current:(NSString *)current total:(NSString *)total;
@end

@interface DownloadManager : NSObject
{
    NSMutableArray *_downloadURLs;
    void (^_getProgressiveDownloadProgressBlock)(float percentDone,NSString * current,NSString *total);
    void (^_downloadCompletionBlockWithSuccess)(NSMutableArray * localPaths);
    void (^_downloadFailedBlockWithSuccess)(NSMutableArray * localPaths);
}
@property (nonatomic, strong) NSMutableArray *downloadURLs;
@property (nonatomic, assign)  id <DowloadManagerDelegate> delegate;
# pragma mark - Shared Instance
+(DownloadManager *) sharedInstance;

-(void)startDownlodFiles:(NSMutableArray *)downloadsURLs withDelegate:(id)delegateObject;

# pragma mark - Block Methods
- (void) setProgressiveDownloadProgressBlock:(NSMutableArray *)downloadURLs completion:(void(^)(float,NSString*,NSString*))block;
- (void) setCompletionBlockWithSuccess:(void(^)(NSMutableArray *))block;
- (void) setCompletionBlockWithError:(void(^)(NSMutableArray *))block;
-(void)pause;
-(void)resume;
-(void)cancelAllOperations;
@end
