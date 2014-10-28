//
//  ViewController.m
//  Animusic
//
//  Created by sban@netspectrum.com on 9/21/12.
//  Copyright (c) 2012 Netspectrum Inc. All rights reserved.
//

#import "ViewController.h"
#import "AFDownloadRequestOperation.h"
#import "AFNetworkActivityIndicatorManager.h"

#define DocumentsDirectory [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES) lastObject]
#define MUSICFile [DocumentsDirectory stringByAppendingPathComponent:@"test.mov"]
#define MUSICFile1 [DocumentsDirectory stringByAppendingPathComponent:@"test1.mp3"]
#define MUSICFile2 [DocumentsDirectory stringByAppendingPathComponent:@"test2.zip"]

@interface ViewController ()
{
     NSOperationQueue *operationQueue;
    NSMutableArray *downloadURL;
}
@property (nonatomic,strong) IBOutlet UILabel *progressLabel;
@property (nonatomic,strong) IBOutlet UIProgressView *progressView;
@property (nonatomic,strong) IBOutlet UIButton *downloadBtn;
@property (nonatomic,strong) IBOutlet UIButton *playBtn;
@property (nonatomic,strong) IBOutlet UILabel *currentSizeLabel;
@property (nonatomic,strong) IBOutlet UILabel *totalSizeLabel;

- (IBAction)beginDownload:(id)sender;
- (IBAction)beginPlay:(id)sender;
@end

@implementation ViewController
@synthesize progressLabel,progressView,downloadBtn,playBtn;
@synthesize currentSizeLabel,totalSizeLabel;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    self.currentSizeLabel.text = @"CUR : 0 M";
    self.totalSizeLabel.text = @"TOTAL : 0 M";
    self.view.layer.cornerRadius = 5;

    self.view.backgroundColor = [UIColor colorWithRed:217/255. green:218/255. blue:219/255. alpha:1];
    operationQueue = [NSOperationQueue new];
    [operationQueue setMaxConcurrentOperationCount:5];
    
    downloadURL  = [NSMutableArray array];
    [downloadURL addObject:@"http://192.168.4.43/213_hd_introducing_homekit.mov"];
   [downloadURL addObject:@"http://192.168.4.43/Season2Ep2.mp3"];
    [downloadURL addObject:@"http://192.168.4.43/208_hd_introducing_cloudkit.mov"];
    [downloadURL addObject:@"http://192.168.4.43/224_hd_core_os_ios_application_architectural_patterns.mov"];
    [downloadURL addObject:@"http://192.168.4.43/225_hd_whats_new_in_core_data.mov"];
    [downloadURL addObject:@"http://192.168.4.43/226_hd_whats_new_in_table_and_collection_views.mov"];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (IBAction)beginDownload:(id)sender{
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    dispatch_group_t group = dispatch_group_create();
    NSDate *startDate = [NSDate date];
    NSDateFormatter *dateformate = [[NSDateFormatter alloc]init];
    [dateformate setDateFormat:@"mm.ss.sss"];
    NSLog(@"Start Date ==%@==",[dateformate stringFromDate: startDate]);
    NSMutableArray *downloadProgress = [NSMutableArray array];
   
    NSInteger count = downloadURL.count;
    for (int k=0;k<count;k++)
    {
        NSString *urlStr;
        NSString *path;
        NSString *fileName;
        NSString *documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES) lastObject];
        
        urlStr = [downloadURL objectAtIndex:k];
        NSArray *array = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentPath error:nil];
        
        fileName = [NSString stringWithFormat:@"%@.%@", [AFDownloadRequestOperation md5StringForString:urlStr],[[urlStr lastPathComponent] pathExtension]];
        NSLog(@"%@",array);
        NSPredicate * predicate = [NSPredicate predicateWithFormat:@"SELF == %@", fileName];
        NSArray * filteredArray = [array filteredArrayUsingPredicate:predicate];
        dispatch_group_enter(group);
        path = [NSString stringWithFormat:@"%@/%@",documentPath, fileName];
        [downloadProgress insertObject:[NSString stringWithFormat:@"0.0"] atIndex:k];

        if (filteredArray.count == 0)
        {

            
            NSURL *url = [NSURL URLWithString:urlStr];
            NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:3600];
            
            
            AFDownloadRequestOperation *operation = [[AFDownloadRequestOperation alloc] initWithRequest:request targetPath:path shouldResume:YES];
            //        operation.outputStream = [NSOutputStream outputStreamToFileAtPath:path append:YES];
            //        [operation setTargetPath:path];
            [operation setDownloadFileIndex:[NSString stringWithFormat:@"%i",k]];
            
            [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
                NSLog(@"Successfully downloaded file to %@", path);
                [downloadURL replaceObjectAtIndex:k withObject:path];
                dispatch_group_leave(group);
                
            } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                NSLog(@"Error: %@ ==%i", error,k);
                dispatch_group_leave(group);
            }];
            [operation setProgressiveDownloadProgressBlock:^(NSInteger bytesRead, long long totalBytesRead, long long totalBytesExpected, long long totalBytesReadForFile, long long totalBytesExpectedToReadForFile) {
                float percentDone = totalBytesReadForFile/(float)totalBytesExpectedToReadForFile;
                [downloadProgress replaceObjectAtIndex:[operation.downloadFileIndex intValue] withObject:[NSString stringWithFormat:@"%.0f",percentDone*100]];
                NSNumber * sum = [downloadProgress valueForKeyPath:@"@sum.self"];
                percentDone = ([sum floatValue]) / count;
                self.progressView.progress = percentDone/100;
                self.progressLabel.text = [NSString stringWithFormat:@"%.0f%%",percentDone];
                self.currentSizeLabel.text = [NSString stringWithFormat:@"CUR : %lli M",totalBytesReadForFile*count/1024/1024];
                self.totalSizeLabel.text = [NSString stringWithFormat:@"TOTAL : %lli M",totalBytesExpectedToReadForFile*count/1024/1024];
                
                //  NSLog(@"--%i----%f",k,percentDone);
                //            NSLog(@"Operation%i: bytesRead: %d", k, bytesRead);
                //            NSLog(@"Operation%i: totalBytesRead: %lld", k, totalBytesRead);
                //            NSLog(@"Operation%i: totalBytesExpected: %lld", k, totalBytesExpected);
                //            NSLog(@"Operation%i: totalBytesReadForFile: %lld", k, totalBytesReadForFile);
                //            NSLog(@"Operation%i: totalBytesExpectedToReadForFile: %lld", k ,totalBytesExpectedToReadForFile);
                NSLog(@"Download Progress %@",downloadProgress);
                
            }];
            
            [operationQueue addOperation:operation];
        }else{
            [downloadURL replaceObjectAtIndex:k withObject:path];
            [downloadProgress replaceObjectAtIndex:k withObject:[NSString stringWithFormat:@"100"]];
            NSNumber * sum = [downloadProgress valueForKeyPath:@"@sum.self"];
           float percentDone = ([sum floatValue]) / count;
            self.progressView.progress = percentDone/100;
            self.progressLabel.text = [NSString stringWithFormat:@"%.0f%%",percentDone];
            dispatch_group_leave(group);
        }
    }
    // Here we wait for all the requests to finish
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        // run code when all files are downloaded
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        NSLog(@"End Date ==%@==*==%.2f==",[dateformate stringFromDate:[NSDate date]],[[NSDate date] timeIntervalSinceDate:startDate]/60);
        
        NSLog(@"Download URL %@",downloadURL);
    });
    
}

- (IBAction)beginPlay:(id)sender{
//    AudioPlayer *player = [AudioPlayer sharePlayer];
//    [player playWithDataSourceType:DataSourceTypeLocal withURLString:MUSICFile];
    MPMoviePlayerViewController *MPC = [[MPMoviePlayerViewController alloc] initWithContentURL:[NSURL fileURLWithPath:[downloadURL objectAtIndex:0]]];
    MPMoviePlayerController *moviePlayer = MPC.moviePlayer;
    MPC.moviePlayer.repeatMode = MPMovieRepeatModeNone;
    MPC.moviePlayer.movieSourceType = MPMovieSourceTypeFile;
    moviePlayer.controlStyle = MPMovieControlStyleFullscreen;
    
    [self presentMoviePlayerViewControllerAnimated:MPC];

    
}
@end
