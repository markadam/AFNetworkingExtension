//
//  ViewController.m
//  Animusic
//
//  Created by sban@netspectrum.com on 9/21/12.
//  Copyright (c) 2012 Netspectrum Inc. All rights reserved.
//

#import "ViewController.h"
#import "AFDownloadRequestOperation.h"
//#import "AFNetworkActivityIndicatorManager.h"

//#define DocumentsDirectory [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES) lastObject]
//#define MUSICFile [DocumentsDirectory stringByAppendingPathComponent:@"test.mov"]
//#define MUSICFile1 [DocumentsDirectory stringByAppendingPathComponent:@"test1.mp3"]
//#define MUSICFile2 [DocumentsDirectory stringByAppendingPathComponent:@"test2.zip"]

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

//- (IBAction)beginDownload:(id)sender;
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
   // [downloadURL addObject:@"http://download.wavetlan.com/SVV/Media/HTTP/BlackBerry.mov"];
    NSMutableDictionary *dict = [[NSMutableDictionary alloc]init];
    [dict setObject:@"http://www.msy.com.au/Parts/PARTS.pdf" forKey:@"URL"];
    [dict setObject:@"432423dsfdsf" forKey:@"ID"];
//    [downloadURL addObject:@"http://www.msy.com.au/Parts/PARTS.pdf"];
//    [downloadURL addObject:@"http://www.msy.com.au/Parts/MicrosoftFlyer.pdf"];
//    [downloadURL addObject:@"http://www.msy.com.au/Parts/Acertemp.pdf"];
//    [downloadURL addObject:@"http://www.msy.com.au/Parts/adelaide1.pdf"];
//    [downloadURL addObject:@"http://www.msy.com.au/Parts/adelaide2.pdf"];
//    [downloadURL addObject:@"http://www.msy.com.au/Parts/notebook.pdf"];
//    [downloadURL addObject:@"http://www.msy.com.au/Parts/notebook1.pdf"];
//    [downloadURL addObject:@"http://www.msy.com.au/Parts/notebook2.pdf"];
//    [downloadURL addObject:@"http://www.msy.com.au/Parts/ultimo1.pdf"];
    [downloadURL addObject:dict];
    dict = [[NSMutableDictionary alloc]init];
    [dict setObject:@"http://www.altraliterature.com/pdfs/PR_2012_Q3.pdf" forKey:@"URL"];
    [dict setObject:@"dsgdsfgdfg" forKey:@"ID"];
    [downloadURL addObject:dict];
    
//    dict = [[NSMutableDictionary alloc]init];
//    [dict setObject:@"http://www.msy.com.au/Parts/Acertemp.pdf" forKey:@"URL"];
//    [dict setObject:@"dsfv456465" forKey:@"ID"];
//    [downloadURL addObject:dict];
  //  [downloadURL addObject:@"http://192.168.4.43/208_hd_introducing_cloudkit.mov"];
//    [downloadURL addObject:@"http://192.168.4.43/224_hd_core_os_ios_application_architectural_patterns.mov"];
//    [downloadURL addObject:@"http://192.168.4.43/225_hd_whats_new_in_core_data.mov"];
//    [downloadURL addObject:@"http://192.168.4.43/226_hd_whats_new_in_table_and_collection_views.mov"];
   
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

- (IBAction)beginDownload:(id)sender
{
   //[[DownloadManager sharedInstance] startDownlodFiles:downloadURL withDelegate:self];
   [[DownloadManager sharedInstance]setProgressiveDownloadProgressBlock:downloadURL completion:^(float percentDone,NSString *current,NSString *total){
        self.progressView.progress = percentDone/100;
        self.progressLabel.text = [NSString stringWithFormat:@"%.0f%%",percentDone];
        self.currentSizeLabel.text = [NSString stringWithFormat:@"Completed %@ out of %@",current,total];
//        self.totalSizeLabel.text = total;
    }];
    [[DownloadManager sharedInstance] setCompletionBlockWithSuccess:^(NSMutableArray *locaPaths)
     {
         NSLog(@"%@",locaPaths);
     }];
    [[DownloadManager sharedInstance] setCompletionBlockWithError:^(NSMutableArray *locaPaths)
     {
         NSLog(@"%@",locaPaths);
     }];

}


- (IBAction)beginPlay:(id)sender
{
    MPMoviePlayerViewController *MPC = [[MPMoviePlayerViewController alloc] initWithContentURL:[NSURL fileURLWithPath:[downloadURL objectAtIndex:0]]];
    MPMoviePlayerController *moviePlayer = MPC.moviePlayer;
    MPC.moviePlayer.repeatMode = MPMovieRepeatModeNone;
    MPC.moviePlayer.movieSourceType = MPMovieSourceTypeFile;
    moviePlayer.controlStyle = MPMovieControlStyleFullscreen;
    
    [self presentMoviePlayerViewControllerAnimated:MPC];
}

#pragma mark DownloadManagerDelegate
-(void)downLoadDidComplete:(NSMutableArray *)localPaths
{
    
}
-(void)getDownloadProgress:(float)percentDone current:(NSString *)current total:(NSString *)total
{
    self.progressView.progress = percentDone/100;
    self.progressLabel.text = [NSString stringWithFormat:@"%.0f%%",percentDone];
}
@end
