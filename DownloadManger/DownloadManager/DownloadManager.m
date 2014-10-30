//
//  DownloadManager.m
//  DownloadManger
//
//  Created by Anil Upadhyay on 10/29/14.
//  Copyright (c) 2014 Netspectrum Inc. All rights reserved.
//

#import "DownloadManager.h"
#import "AFDownloadRequestOperation.h"

#define DocumentsDirectory  [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES) lastObject]
#define CachesDirectory     [NSSearchPathForDirectoriesInDomains(NSCachesDirectory,NSUserDomainMask,YES) lastObject]
#define CachesDirectory     [NSSearchPathForDirectoriesInDomains(NSCachesDirectory,NSUserDomainMask,YES) lastObject]
#define TempDirectory        NSTemporaryDirectory()

@interface DownloadManager ()
{
    NSOperationQueue *operationQueue;
}
@end


static DownloadManager *sharedInstance =  nil;

@implementation DownloadManager
@synthesize downloadURLs = _downloadURLs;

+(DownloadManager *)sharedInstance
{
    static dispatch_once_t disptchOnce;
    dispatch_once(&disptchOnce, ^{
        sharedInstance = [[self alloc]init];
        
    });
    return sharedInstance;
}

-(void)startDownlodFiles:(NSMutableArray *)downloadsURLs withDelegate:(id)delegateObject
{
    _delegate =  delegateObject;
    operationQueue = [NSOperationQueue new];
    [operationQueue setMaxConcurrentOperationCount:5];
    if (_downloadURLs == nil)
    {
        _downloadURLs = [[NSMutableArray alloc]init];
    }
    [_downloadURLs addObjectsFromArray:downloadsURLs];
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    dispatch_group_t group = dispatch_group_create();
    NSMutableArray *downloadProgress = [NSMutableArray array];
    
    NSInteger count = _downloadURLs.count;
    for (int k=0;k<count;k++)
    {
        NSString *urlStr;
        NSString *path;
        NSString *fileName;
        
        urlStr = [_downloadURLs objectAtIndex:k];
        NSArray *array = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:DocumentsDirectory error:nil];
        
        fileName = [NSString stringWithFormat:@"%@.%@", [AFDownloadRequestOperation md5StringForString:urlStr],[[urlStr lastPathComponent] pathExtension]];
        NSPredicate * predicate = [NSPredicate predicateWithFormat:@"SELF == %@", fileName];
        NSArray * filteredArray = [array filteredArrayUsingPredicate:predicate];
        dispatch_group_enter(group);
        path = [NSString stringWithFormat:@"%@/%@",DocumentsDirectory, fileName];
        [downloadProgress insertObject:[NSString stringWithFormat:@"0.0"] atIndex:k];
        if (filteredArray.count == 0)
        {
            NSURL *url = [NSURL URLWithString:urlStr];
            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:3600];
            AFDownloadRequestOperation *operation = [[AFDownloadRequestOperation alloc] initWithRequest:request targetPath:path shouldResume:YES];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-retain-cycles"
            [operation setDownloadFileIndex:[NSString stringWithFormat:@"%i",k]];
            
            [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
                [_downloadURLs replaceObjectAtIndex:k withObject:[NSDictionary dictionaryWithObjectsAndKeys:path,@"url",nil]];
                dispatch_group_leave(group);
                
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                dispatch_group_leave(group);
                [_downloadURLs replaceObjectAtIndex:k withObject:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%@",operation.request.URL.absoluteString],@"url",error,@"error" ,nil]];
            }];
            [operation setProgressiveDownloadProgressBlock:^(NSInteger bytesRead, long long totalBytesRead, long long totalBytesExpected, long long totalBytesReadForFile, long long totalBytesExpectedToReadForFile) {
                float percentDone = totalBytesReadForFile/(float)totalBytesExpectedToReadForFile;
                
                [downloadProgress replaceObjectAtIndex:[operation.downloadFileIndex intValue] withObject:[NSString stringWithFormat:@"%.0f",percentDone*100]];

                NSNumber * sum = [downloadProgress valueForKeyPath:@"@sum.self"];
                percentDone = ([sum floatValue]) / count;
                if ([_delegate respondsToSelector:@selector(setProgressiveDownloadProgress:current:total:)])
                {
                    [_delegate setProgressiveDownloadProgress:percentDone current:[NSString stringWithFormat:@"CUR : %lli M",(totalBytesReadForFile*count)/1024/1024] total:[NSString stringWithFormat:@"TOTAL : %lli M",(totalBytesExpectedToReadForFile*count)/1024/1024]];
                }
            }];
            
            [operationQueue addOperation:operation];
        }else{
            [_downloadURLs replaceObjectAtIndex:k withObject:[NSDictionary dictionaryWithObjectsAndKeys:path,@"url",nil]];
            [downloadProgress replaceObjectAtIndex:k withObject:[NSString stringWithFormat:@"100"]];
            NSNumber * sum = [downloadProgress valueForKeyPath:@"@sum.self"];
            float percentDone = ([sum floatValue]) / count;
            dispatch_group_leave(group);
        }
    }
    // Here we wait for all the requests to finish
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        // run code when all files are downloaded
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        if ([_delegate respondsToSelector:@selector(setCompletionWithSuccess:)])
        {
            [_delegate setCompletionWithSuccess:_downloadURLs];
            operationQueue = nil;
            _downloadURLs = nil;
        }
    });

}
- (void) setProgressiveDownloadProgressBlock:(NSMutableArray *)downloadURLs completion:(void(^)(float,NSString*,NSString*))block
{
    operationQueue = [NSOperationQueue new];
    [operationQueue setMaxConcurrentOperationCount:5];
    if (_downloadURLs == nil)
    {
        _downloadURLs = [[NSMutableArray alloc]init];
    }
    [_downloadURLs addObjectsFromArray:downloadURLs];
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    dispatch_group_t group = dispatch_group_create();
    NSMutableArray *downloadProgress = [NSMutableArray array];
    
    NSInteger count = _downloadURLs.count;
    for (int k=0;k<count;k++)
    {
        NSString *urlStr;
        NSString *path;
        NSString *fileName;
        
        urlStr = [_downloadURLs objectAtIndex:k];
        NSArray *array = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:DocumentsDirectory error:nil];
        
        fileName = [NSString stringWithFormat:@"%@.%@", [AFDownloadRequestOperation md5StringForString:urlStr],[[urlStr lastPathComponent] pathExtension]];
        NSPredicate * predicate = [NSPredicate predicateWithFormat:@"SELF == %@", fileName];
        NSArray * filteredArray = [array filteredArrayUsingPredicate:predicate];
        dispatch_group_enter(group);
        path = [NSString stringWithFormat:@"%@/%@",DocumentsDirectory, fileName];
        [downloadProgress insertObject:[NSString stringWithFormat:@"0.0"] atIndex:k];
        if (filteredArray.count == 0)
        {
            NSURL *url = [NSURL URLWithString:urlStr];
            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:3600];
            AFDownloadRequestOperation *operation = [[AFDownloadRequestOperation alloc] initWithRequest:request targetPath:path shouldResume:YES];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-retain-cycles"
            [operation setDownloadFileIndex:[NSString stringWithFormat:@"%i",k]];
            
            [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
                
                [_downloadURLs replaceObjectAtIndex:k withObject:[NSDictionary dictionaryWithObjectsAndKeys:path,@"url",nil]];
                dispatch_group_leave(group);
                
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
               
                [_downloadURLs replaceObjectAtIndex:k withObject:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%@",operation.request.URL.absoluteString],@"url",error,@"error" ,nil]];
                dispatch_group_leave(group);
            }];
            [operation setProgressiveDownloadProgressBlock:^(NSInteger bytesRead, long long totalBytesRead, long long totalBytesExpected, long long totalBytesReadForFile, long long totalBytesExpectedToReadForFile) {
                float percentDone = totalBytesReadForFile/(float)totalBytesExpectedToReadForFile;
                
                [downloadProgress replaceObjectAtIndex:[operation.downloadFileIndex intValue] withObject:[NSString stringWithFormat:@"%.0f",percentDone*100]];
                
                NSNumber * sum = [downloadProgress valueForKeyPath:@"@sum.self"];
                percentDone = ([sum floatValue]) / count;
                
                _getProgressiveDownloadProgressBlock = block;
                
                // Call completion handler.
                _getProgressiveDownloadProgressBlock(percentDone,[NSString stringWithFormat:@"CUR : %lli M",(totalBytesReadForFile*count)/1024/1024],[NSString stringWithFormat:@"TOTAL : %lli M",(totalBytesExpectedToReadForFile*count)/1024/1024]);
               
                // Clean up.
                _getProgressiveDownloadProgressBlock = nil;
            }];
            [operationQueue addOperation:operation];
        }else{
            [_downloadURLs replaceObjectAtIndex:k withObject:[NSDictionary dictionaryWithObjectsAndKeys:path,@"url",nil]];
            [downloadProgress replaceObjectAtIndex:k withObject:[NSString stringWithFormat:@"100"]];
            NSNumber * sum = [downloadProgress valueForKeyPath:@"@sum.self"];
            float percentDone = ([sum floatValue]) / count;
            dispatch_group_leave(group);
        }
    }
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        // run code when all files are downloaded
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        _downloadCompletionBlockWithSuccess(_downloadURLs);
        _downloadCompletionBlockWithSuccess = nil;
    });
}
- (void) setCompletionBlockWithSuccess:(void(^)(NSMutableArray *))block
{
    _downloadCompletionBlockWithSuccess = block;
}

@end
