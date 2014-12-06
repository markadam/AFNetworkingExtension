//
//  DownloadManager.m
//  DownloadManger
//
//  Created by Anil Upadhyay on 10/29/14.
//  Copyright (c) 2014 Netspectrum Inc. All rights reserved.
//

#import "DownloadManager.h"
#import "AFDownloadRequestOperation.h"
#define CachesDirectory     [NSSearchPathForDirectoriesInDomains(NSCachesDirectory,NSUserDomainMask,YES) lastObject]

#define ID @"ID"
#define FileURL @"URL"
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
        [[NSNotificationCenter defaultCenter] addObserver:sharedInstance selector:@selector(applicatonInBackground) name:UIApplicationWillResignActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:sharedInstance selector:@selector(applicatonInForground) name:UIApplicationDidBecomeActiveNotification object:nil];

    });
    return sharedInstance;
}
-(void)applicatonInBackground
{
    [self pause];
}
-(void)applicatonInForground    
{
    [self resume];
}
-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
-(void)startDownlodFiles:(NSMutableArray *)downloadsURLs withDelegate:(id)delegateObject
{
    _delegate =  delegateObject;
    operationQueue = [NSOperationQueue new];
    operationQueue.MaxConcurrentOperationCount = NSOperationQueueDefaultMaxConcurrentOperationCount;
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
        NSArray *array = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[NSString stringWithFormat:@"%@/AllPDFS",CachesDirectory] error:nil];
        
        fileName = [NSString stringWithFormat:@"%@.%@", [AFDownloadRequestOperation md5StringForString:urlStr],[[urlStr lastPathComponent] pathExtension]];
        NSPredicate * predicate = [NSPredicate predicateWithFormat:@"SELF == %@", fileName];
        NSArray * filteredArray = [array filteredArrayUsingPredicate:predicate];
        dispatch_group_enter(group);
        path = [NSString stringWithFormat:@"%@/AllPDFS/%@",CachesDirectory, fileName];
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
                [_downloadURLs replaceObjectAtIndex:k withObject:[NSDictionary dictionaryWithObjectsAndKeys:path,FileURL,nil]];
                dispatch_group_leave(group);
                
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                dispatch_group_leave(group);
                [_downloadURLs replaceObjectAtIndex:k withObject:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%@",operation.request.URL.absoluteString],FileURL,error,@"error" ,nil]];
            }];
            [operation setProgressiveDownloadProgressBlock:^(AFDownloadRequestOperation *operation, NSInteger bytesRead, long long totalBytesRead, long long totalBytesExpected, long long totalBytesReadForFile, long long totalBytesExpectedToReadForFile)
             {
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
            [_downloadURLs replaceObjectAtIndex:k withObject:[NSDictionary dictionaryWithObjectsAndKeys:path,FileURL,nil]];
            [downloadProgress replaceObjectAtIndex:k withObject:[NSString stringWithFormat:@"100"]];
          //  NSNumber * sum = [downloadProgress valueForKeyPath:@"@sum.self"];
//            float percentDone = ([sum floatValue]) / count;
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
    }else{
        [_downloadURLs removeAllObjects];
    }
    [_downloadURLs addObjectsFromArray:downloadURLs];
   __block NSMutableArray *sucessedDownload;
    __block NSMutableArray *failedDownload;

    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    dispatch_group_t group = dispatch_group_create();
    NSMutableArray *downloadProgress = [NSMutableArray array];
    
    NSInteger count = _downloadURLs.count;
    for (int k=0;k<count;k++)
    {
        NSString *urlStr;
        NSString *path;
        NSString *fileName;
        
        urlStr =  [[_downloadURLs objectAtIndex:k]objectForKey:FileURL];
        if (![[NSFileManager defaultManager]fileExistsAtPath:[NSString stringWithFormat:@"%@/AllPDFS",CachesDirectory]])
        {
            [[NSFileManager defaultManager] createDirectoryAtPath:[NSString stringWithFormat:@"%@/AllPDFS",CachesDirectory] withIntermediateDirectories:YES attributes:nil error:nil];
        }
        NSArray *array = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[NSString stringWithFormat:@"%@/AllPDFS",CachesDirectory] error:nil];
        fileName = [NSString stringWithFormat:@"%@.pdf", [AFDownloadRequestOperation md5StringForString:urlStr]];

      //  fileName = [NSString stringWithFormat:@"%@.%@", [AFDownloadRequestOperation md5StringForString:urlStr],[[urlStr lastPathComponent] pathExtension]];
        NSPredicate * predicate = [NSPredicate predicateWithFormat:@"SELF == %@", fileName];
        NSArray * filteredArray = [array filteredArrayUsingPredicate:predicate];
        dispatch_group_enter(group);
        path = [NSString stringWithFormat:@"%@/AllPDFS/%@",CachesDirectory, fileName];
        
        
        [downloadProgress insertObject:[NSString stringWithFormat:@"0.0"] atIndex:k];
        if (filteredArray.count == 0)
        {
            NSURL *url = [NSURL URLWithString:urlStr];
            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:3600];
            AFDownloadRequestOperation *operation = [[AFDownloadRequestOperation alloc] initWithRequest:request targetPath:path shouldResume:YES];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-retain-cycles"
            [operation setDownloadFileIndex:[NSString stringWithFormat:@"%i",k]];
            [operation setUniqueKey:[[_downloadURLs objectAtIndex:k]objectForKey:ID]];
            [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
                if (!sucessedDownload)
                {
                    sucessedDownload = [[NSMutableArray alloc]init];
                }
//                [_downloadURLs replaceObjectAtIndex:k withObject:[NSDictionary dictionaryWithObjectsAndKeys:operation.uniqueKey,ID,path,FileURL,nil]];
                [sucessedDownload addObject:[NSDictionary dictionaryWithObjectsAndKeys:operation.uniqueKey,ID,path,FileURL,nil]];
                dispatch_group_leave(group);
                
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                
               // [_downloadURLs replaceObjectAtIndex:k withObject:[NSDictionary dictionaryWithObjectsAndKeys:operation.uniqueKey,ID,[NSString stringWithFormat:@"%@",operation.request.URL.absoluteString],FileURL,error,@"error" ,nil]];
                if (!failedDownload)
                {
                    failedDownload = [[NSMutableArray alloc]init];
                }
                [failedDownload addObject:[NSDictionary dictionaryWithObjectsAndKeys:operation.uniqueKey,ID,[NSString stringWithFormat:@"%@",operation.request.URL.absoluteString],FileURL,error,@"error" ,nil]];
                dispatch_group_leave(group);
            }];
            [operation setProgressiveDownloadProgressBlock:^(AFDownloadRequestOperation *operation, NSInteger bytesRead, long long totalBytesRead, long long totalBytesExpected, long long totalBytesReadForFile, long long totalBytesExpectedToReadForFile)
            {
                float percentDone = totalBytesReadForFile/(float)totalBytesExpectedToReadForFile;
                [downloadProgress replaceObjectAtIndex:[operation.downloadFileIndex intValue] withObject:[NSString stringWithFormat:@"%.0f",percentDone*100]];
                
                NSNumber * sum = [downloadProgress valueForKeyPath:@"@sum.self"];
                percentDone = ([sum floatValue]) / count;
                
                _getProgressiveDownloadProgressBlock = block;
                
                // Call completion handler.
                _getProgressiveDownloadProgressBlock(percentDone,[NSString stringWithFormat:@"%lu",sucessedDownload.count+failedDownload.count],[NSString stringWithFormat:@"%lu",_downloadURLs.count]);
                // Clean up.
                _getProgressiveDownloadProgressBlock = nil;
            }];
            [operationQueue addOperation:operation];
        }else{
            if (!sucessedDownload)
            {
                sucessedDownload = [[NSMutableArray alloc]init];
            }
            //                [_downloadURLs replaceObjectAtIndex:k withObject:[NSDictionary dictionaryWithObjectsAndKeys:operation.uniqueKey,ID,path,FileURL,nil]];
            [sucessedDownload addObject:[NSDictionary dictionaryWithObjectsAndKeys:[[_downloadURLs objectAtIndex:k]objectForKey:ID],ID,path,FileURL,nil]];
            [downloadProgress replaceObjectAtIndex:k withObject:[NSString stringWithFormat:@"100"]];
          //  NSNumber * sum = [downloadProgress valueForKeyPath:@"@sum.self"];
//            float percentDone = ([sum floatValue]) / count;
            dispatch_group_leave(group);
        }
    }
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        // run code when all files are downloaded
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        if(sucessedDownload)
        _downloadCompletionBlockWithSuccess(sucessedDownload);
        
        _downloadCompletionBlockWithSuccess = nil;
        if(failedDownload)
        {
            _downloadFailedBlockWithSuccess(failedDownload);
            _downloadFailedBlockWithSuccess = nil;
        }
        
    });
}
- (void) setCompletionBlockWithSuccess:(void(^)(NSMutableArray *))block
{
    _downloadCompletionBlockWithSuccess = block;
}
- (void) setCompletionBlockWithError:(void(^)(NSMutableArray *))block
{
    _downloadFailedBlockWithSuccess = block;
}

-(void)pause
{
    [operationQueue setSuspended:YES];
}
-(void)resume
{
    [operationQueue setSuspended:NO];
}
-(void)cancelAllOperations
{
    [operationQueue cancelAllOperations];
}

@end
