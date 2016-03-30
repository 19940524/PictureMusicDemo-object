//
//  ListenMusicViewController.m
//  Object
//
//  Created by user on 16/3/16.
//  Copyright © 2016年 GuoBIn. All rights reserved.
//

#import "ListenMusicViewController.h"
#import "ParallaxCell.h"
#import <MJRefresh/MJRefresh.h>
#import <AFNetworking/AFNetworking.h>
#import <SDWebImage/UIImageView+WebCache.h>
#import "RecommandSongModel.h"
#import "MJExtension.h"
#import "ServerEventHandler.h"
#import "PlayMusicViewController.h"
#import "PlayMusicModel.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MPNowPlayingInfoCenter.h>
#import <MediaPlayer/MPMediaItem.h>
#import "Thread.h"

//#import <NSDictionary+Accessors/NSDictionary+Accessors.h>
//#define kDoubanUrl      @"http://douban.fm/j/mine/playlist?type=n&h=&channel=0&from=mainsite&r=4941e23d79"

@interface ListenMusicViewController ()  <PlayMusicViewControllerDelegate> {
    dispatch_source_t _timerSource;
    UIBackgroundTaskIdentifier  _bgTaskId;
    CGFloat timingUnit;
    BOOL isAllowPerform;
}

@property (strong, nonatomic) NSMutableArray *songArray;

@property (weak, nonatomic) IBOutlet UITableView *myTableView;
@property (strong, nonatomic) NSValue *targetRect;

@property (strong, nonatomic) PlayMusicModel *selectModel;
@property (strong, nonatomic) AVPlayer *myPlayer;

@property (copy, nonatomic) NSArray *keyList;
@property (copy, nonatomic) NSArray *lrcList;

@property (strong, nonatomic) PlayMusicViewController *playMusicVC;

@property (nonatomic) Thread *th;

@property (strong, nonatomic) SongModel *currPlayModel;

@property (strong, nonatomic) NSIndexPath *selectIndexPath;

@end

@implementation ListenMusicViewController
@synthesize songArray;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self initData];
}

- (void)initData {
    isAllowPerform = YES;
    songArray = [NSMutableArray array];
    
    //    NSString *url = @"http://tingapi.ting.baidu.com/v1/restserver/ting?from=webapp_music&method=baidu.ting.song.getRecommandSongList&format=json&callback=&song_id=13844864&num=10";
    NSString *url = @"http://tingapi.ting.baidu.com/v1/restserver/ting?from=webapp_music&method=baidu.ting.billboard.billList&type=21&size=30&offset=0";
    [self requestMusic:url];
    
    NSArray *types = @[@"1",@"2",@"11",@"12",@"16",@"21",@"22",@"23",@"24",@"25"];
    
    self.myTableView.mj_footer = [MJRefreshAutoNormalFooter footerWithRefreshingBlock:^{
        
        /*
         参数：	type = 1-新歌榜,2-热歌榜,11-摇滚榜,12-爵士,16-流行,21-欧美金曲榜,22-经典老歌榜,23-情歌对唱榜,24-影视金曲榜,25-网络歌曲榜
         */
        int type = [[types objectAtIndex:[self getScopeInsideRandomValue:0 to:10]] intValue];
        NSString *urlStr = [NSString stringWithFormat:@"http://tingapi.ting.baidu.com/v1/restserver/ting?from=webapp_music&method=baidu.ting.billboard.billList&type=%d&size=30&offset=0",type];
        [self requestMusic:urlStr];
        
        //        [self requestMusic:[NSString stringWithFormat:@"http://tingapi.ting.baidu.com/v1/restserver/ting?from=webapp_music&method=baidu.ting.song.getRecommandSongList&format=json&callback=&song_id=%d&num=30",7926593]];
        [self.myTableView.mj_footer endRefreshing];
    }];
    
    _th = [Thread sharedThred];
    // 设置音频会话，允许后台播放
    _bgTaskId = [self backgroundPlayerID:_bgTaskId];
    
    [SDWebImageManager.sharedManager.imageCache calculateSizeWithCompletionBlock:^(NSUInteger fileCount, NSUInteger totalSize) {
        //        NSLog(@"fileCount = %d    totalSize = %d",fileCount, totalSize);` 
        if (fileCount > 200) {
            [[[SDWebImageManager sharedManager] imageCache] clearDisk];
        }
    }];
}

- (UIBackgroundTaskIdentifier)backgroundPlayerID:(UIBackgroundTaskIdentifier)backTaskId
{
    // 1. 设置并激活音频会话类别
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setActive:YES error:nil];
    [session setCategory:AVAudioSessionCategoryPlayback error:nil];
    // 2. 允许应用程序接收远程控制
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    // 3. 设置后台任务ID
    UIBackgroundTaskIdentifier newTaskId = UIBackgroundTaskInvalid;
    newTaskId = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:nil];
    if (newTaskId != UIBackgroundTaskInvalid && backTaskId != UIBackgroundTaskInvalid) {
        [[UIApplication sharedApplication] endBackgroundTask:backTaskId];
    }
    return newTaskId;
}

// 获取一个随机整数，范围在[from,to），包括from，不包括to
- (int)getScopeInsideRandomValue:(int)from to:(int)to {
    return (int)(from + (arc4random() % (to - from)));
}

#pragma mark - 请求推荐音乐
- (void)requestMusic:(NSString *)url {
    [ServerEventHandler requestRecommendedMusic:url success:^(NSArray *dataArr) {
        [songArray addObjectsFromArray:dataArr];
        [self.myTableView reloadData];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.06f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self mobileVisibleCells];
        });
    } failure:^(NSError *error) {
        if (error) {
            NSLog(@"error = %@",error);
        }
    }];
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return songArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdeltifier = @"parallaxCell";
    
    ParallaxCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdeltifier forIndexPath:indexPath];
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    [self setupCell:cell withIndexPath:indexPath];
    return cell;
}

- (void)setupCell:(ParallaxCell *)cell withIndexPath:(NSIndexPath *)indexPath {
    RecommandSongModel *songModel = [self objectForRow:indexPath.row];
    cell.bottomView.layer.masksToBounds = YES;
    cell.bottomView.layer.cornerRadius = 3;
    
    NSURL *targetURL = [NSURL URLWithString:songModel.pic_big];
    
    if (![[cell.parallaxImage sd_imageURL] isEqual:targetURL]) {
        cell.parallaxImage.alpha = 0;
        SDWebImageManager *manager = [SDWebImageManager sharedManager];
        CGRect cellFrame = [self.myTableView rectForRowAtIndexPath:indexPath];
        BOOL shouldLoadImage = YES;
        if (self.targetRect && !CGRectIntersectsRect([self.targetRect CGRectValue], cellFrame)) {
            SDImageCache *cache = [manager imageCache];
            NSString *key = [manager cacheKeyForURL:targetURL];
            if (![cache imageFromMemoryCacheForKey:key]) {
                shouldLoadImage = NO;
            }
        }
        if (shouldLoadImage) {
            [cell.parallaxImage sd_setImageWithURL:targetURL placeholderImage:nil options:SDWebImageRefreshCached completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                if (!error && [imageURL isEqual:targetURL]) {
                    [UIView animateWithDuration:0.25 animations:^{
                        cell.parallaxImage.alpha = 1.0;
                    }];
                }
            }];
        }
    }
}

- (RecommandSongModel *)objectForRow:(NSInteger)row {
    if (row < songArray.count && row >= 0) {
        return songArray[row];
    } else if(row == songArray.count) {
        self.selectIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
        return songArray[0];
    } else {
        self.selectIndexPath = [NSIndexPath indexPathForRow:songArray.count - 1 inSection:0];
        return songArray[songArray.count - 1];
    }
    return nil;
}

#pragma mark - UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 160;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    ParallaxCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if (!cell.parallaxImage.image) {
        NSLog(@"image = nil");
        return;
    }
    
    self.selectIndexPath = indexPath;
    
    RecommandSongModel *model = [self objectForRow:indexPath.row];
    
    CGRect frame = [self getImageFramel:tableView cell:cell indexPath:indexPath];
    [self setSelectModel:model parallaxImage:cell.parallaxImage.image imageFrame:frame];
    
    if ([[[Thread sharedThred] thereIsMusicId] isEqualToString:model.song_id]) {
        self.playMusicVC = [self initplayMusicVCMusicReplace:NO];
        [self.navigationController pushViewController:self.playMusicVC animated:NO];
        return;
    }
    
    
    [self resetData];
    
    self.playMusicVC = [self initplayMusicVCMusicReplace:YES];
    
    __block typeof(self) weakSelf = self;
    self.playMusicVC.startPlay = ^{
        
        [ServerEventHandler requestSongLrc:model.song_id success:^(NSDictionary *dataDic) {
            NSDictionary *lrcDictionary = [weakSelf getLrc:[dataDic objectForKey:@"lrcContent"]];
            [weakSelf setLrcData:lrcDictionary];
            weakSelf.playMusicVC.lrcList = weakSelf.lrcList;
            weakSelf.playMusicVC.keyList = weakSelf.keyList;
            [weakSelf.playMusicVC.myTableView reloadData];
            
            [ServerEventHandler playSong:model.song_id callback:^(SongModel *songModel) {
                //                [weakSelf resetData];
                [weakSelf initPlayer:songModel picImage:cell.parallaxImage.image songId:model.song_id];
                [weakSelf.myPlayer play];
            }];
        } failure:^(NSError *error) {
            NSLog(@"error");
        }];
    };
    [self.navigationController pushViewController:self.playMusicVC animated:NO];
    
    
}

- (CGRect)getImageFramel:(UITableView *)tableView cell:(ParallaxCell *)cell indexPath:(NSIndexPath *)indexPath {
    CGRect rectInTabelView = [tableView rectForRowAtIndexPath:indexPath];
    CGRect rect = [tableView convertRect:rectInTabelView toView:[tableView superview]];
    rect.origin.y -= fabs(cell.parallaxImage.frame.origin.y);
    rect.size.height = cell.parallaxImage.frame.size.height;
    return rect;
}

- (void)setSelectModel:(RecommandSongModel *)model parallaxImage:(UIImage *)image imageFrame:(CGRect)frame {
    self.selectModel = [[PlayMusicModel alloc] init];
    self.selectModel.imageFrame = frame;
    self.selectModel.pic_bigImage = image;
    self.selectModel.songTitle = model.album_title;
    self.selectModel.song_id = model.song_id;
}

- (PlayMusicViewController *)initplayMusicVCMusicReplace:(BOOL)isReplace {
    UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]];
    PlayMusicViewController *playMusicVC = (PlayMusicViewController *)[storyBoard instantiateViewControllerWithIdentifier:@"PlayMusicViewController"];
    playMusicVC.delegate = self;
    playMusicVC.playMusicM = self.selectModel;
    playMusicVC.musicReplace = isReplace;
    playMusicVC.lrcList = self.lrcList;
    playMusicVC.keyList = self.keyList;
    _th.playMusicVC = playMusicVC;
    return playMusicVC;
}

#pragma mark - 重置播放器和定时器于数据
- (void)resetData {
    if (_timerSource) {
        dispatch_source_cancel(_timerSource);
    }
    if (self.myPlayer) {
        [self.myPlayer removeObserver:self forKeyPath:@"status"];
        self.myPlayer = nil;
    }
    _th.scrolToIndexPath = [NSIndexPath indexPathForRow:1 inSection:0];
}


#pragma mark - PlayMusicViewControllerDelegate
- (void)playOrStopMusicPlayBtn:(UIButton *)playBtn {
    if (!self.myPlayer) {
        return;
    }
    if (playBtn.selected) {
        playBtn.selected = NO;
    } else {
        playBtn.selected = YES;
    }
    BOOL play = playBtn.selected;
    if (play) {
        [self.myPlayer play];
        dispatch_resume(_timerSource);
    } else {
        [self.myPlayer pause];
        dispatch_suspend(_timerSource);
    }
}

#pragma mark -上下曲
- (void)inASongIsNext:(BOOL)next {
    if (isAllowPerform) {
        isAllowPerform = NO;
        [self resetData];
        
        NSInteger row = next ? self.selectIndexPath.row+1 : self.selectIndexPath.row-1;
        
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
        RecommandSongModel *recommandModel = [self objectForRow:indexPath.row];
        
        [ServerEventHandler requestSongLrc:recommandModel.song_id success:^(NSDictionary *dataDic) {
            
            NSDictionary *lrcDictionary = [self getLrc:[dataDic objectForKey:@"lrcContent"]];
            [self setLrcData:lrcDictionary];
            
            self.playMusicVC.songName.text = recommandModel.album_title;
            self.playMusicVC.keyList = self.keyList;
            self.playMusicVC.lrcList = self.lrcList;
            [self.playMusicVC.myTableView reloadData];
            [self.playMusicVC selectIndexPathChangeColor:[NSIndexPath indexPathForRow:1 inSection:0] animated:NO];
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                isAllowPerform = YES;
            });
            
        } failure:^(NSError *error) {
            NSLog(@"error = %@",error);
        }];
        
        [ServerEventHandler playSong:recommandModel.song_id callback:^(SongModel *songModel) {
            [self.playMusicVC.picImage sd_setImageWithURL:[NSURL URLWithString:recommandModel.pic_big] placeholderImage:nil options:SDWebImageHandleCookies completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                [self initPlayer:songModel picImage:image songId:recommandModel.song_id];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.8f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self.myPlayer play];
                });
            }];
            
        }];
        
        self.selectIndexPath = indexPath;
        
    }
}

- (void)initPlayer:(SongModel *)songModel picImage:(UIImage *)picImage songId:(NSString *)song_id {
    self.currPlayModel = songModel;
    self.currPlayModel.picImage = picImage;
    _th.thereIsMusicId = song_id;
    
    [self configNowPlayingInfoCenter];
    self.myPlayer = [[AVPlayer alloc] initWithURL:[NSURL URLWithString:songModel.link]];
    self.myPlayer.volume = 0.2f;
    [self.myPlayer addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
}

#pragma mark - 解析歌词
- (void)setLrcData:(NSDictionary *)lrcDictionary {
    NSArray *allKey = [lrcDictionary allKeys];
    
    NSMutableArray *lrcKey = [NSMutableArray array];
    for (NSString *str in allKey) {
        NSNumber *number = [NSNumber numberWithFloat:str.floatValue];
        [lrcKey addObject:number];
    }
    NSArray *compareArr = [lrcKey sortedArrayUsingSelector:@selector(compare:)];
    [lrcKey removeAllObjects];
    
    NSMutableArray *lrcArray = [NSMutableArray array];
    [lrcArray addObject:@""];
    [lrcKey addObject:@""];
    
    for (NSNumber *number in compareArr) {
        NSMutableString *str = [NSMutableString stringWithFormat:@"%@",number];
        
        if ([str rangeOfString:@"."].location == NSNotFound) {
            [str appendString:@".0"];
        }
        
        [lrcKey addObject:str];
        [lrcArray addObject:[lrcDictionary objectForKey:str]];
    }
    self.keyList = lrcKey;
    self.lrcList = lrcArray;
    _th.keyList = self.keyList;
    _th.lrcList = self.lrcList;
}

- (NSDictionary *)getLrc:(NSString *)contentString {
    
    NSArray *array = [contentString componentsSeparatedByString:@"\n"];
    NSMutableDictionary *lrcDictionary = [NSMutableDictionary dictionary];
    
    for (int i = 0; i < [array count]; i++) {
        
        NSString *lineString = [array objectAtIndex:i];
        NSArray *lineArray = [lineString componentsSeparatedByString:@"]"];
        
        if ([lineArray[0] length] > 8) {
            
            NSString *str1 = [lineString substringWithRange:NSMakeRange(3, 1)];
            NSString *str2 = [lineString substringWithRange:NSMakeRange(6, 1)];
            
            if ([str1 isEqualToString:@":"] && [str2 isEqualToString:@"."]) {
                
                for (int i = 0; i < lineArray.count - 1; i++) {
                    NSString *lrcString = [lineArray objectAtIndex:lineArray.count - 1];
                    //分割区间求歌词时间
                    NSString *time = [[lineArray objectAtIndex:i] substringWithRange:NSMakeRange(1, 7)];
                    NSString *timeString = [self timeToSecond:time];
                    //把时间 和 歌词 加入词典
                    [lrcDictionary setObject:lrcString forKey:timeString];
                }
            }
        }
    }
    
    return lrcDictionary;
}

- (NSString *)timeToSecond:(NSString *)str { // 12:12
    NSString *secondStr = [str substringWithRange:NSMakeRange(3, 2)];
    NSString *minutesStr = [str substringToIndex:2];
    NSString *msStr = [str substringWithRange:NSMakeRange(str.length - 1, 1)];
    
    int second = secondStr.intValue;
    int minutes = minutesStr.intValue;
    return [NSString stringWithFormat:@"%d.%@",minutes * 60 + second,msStr];
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    // Get visible cells on table view.
    [self mobileVisibleCells];
}

- (void)mobileVisibleCells {
    NSArray *visibleCells = [self.myTableView visibleCells];
    
    for (ParallaxCell *cell in visibleCells) {
        [cell cellOnTableView:self.myTableView didScrollOnView:self.view];
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    self.targetRect = nil;
    [self loadImageForVisibleCells];
}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset
{
    CGRect targetRect = CGRectMake(targetContentOffset->x, targetContentOffset->y, scrollView.frame.size.width, scrollView.frame.size.height);
    self.targetRect = [NSValue valueWithCGRect:targetRect];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    self.targetRect = nil;
    [self loadImageForVisibleCells];
}

- (void)loadImageForVisibleCells {
    NSArray *cells = [self.myTableView visibleCells];
    for (ParallaxCell *cell in cells) {
        NSIndexPath *indexPath = [self.myTableView indexPathForCell:cell];
        [self setupCell:cell withIndexPath:indexPath];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - KVO 监听播放器是否准备播放
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    if ([keyPath isEqual:@"status"]) {
        AVPlayerStatus tempAVStatus = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
        
        if (tempAVStatus == AVPlayerStatusReadyToPlay) {
            
            [UIView animateWithDuration:0.3f animations:^{
                self.myPlayer.volume = 1;
                [self configNowPlayingInfoCenter];
            }];
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                
                // 定时器
                dispatch_queue_t queue = dispatch_queue_create("timerQueue", DISPATCH_QUEUE_CONCURRENT);
                _timerSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
                double interval = 0.1f * NSEC_PER_SEC;
                dispatch_source_set_timer(_timerSource, dispatch_time(DISPATCH_TIME_NOW, 0), interval, 0);
                timingUnit = 0.1f;
                dispatch_source_set_event_handler(_timerSource, ^{
                    
                    Float64 dur = CMTimeGetSeconds([self.myPlayer currentTime]) / self.currPlayModel.duration.floatValue;
                    
                    [self changeBackProgress:[NSNumber numberWithFloat:dur]];
                    
                    if ((float)dur >= 1) {
                        //                        NSLog(@"dur = %.0f  ---> %f",dur,self.currPlayModel.duration.floatValue);
                        [self inASongIsNext:YES];
                        return;
                    }
                    NSString *key = [NSString stringWithFormat:@"%.1f",CMTimeGetSeconds([self.myPlayer currentTime])];
                    
                    if ([self.keyList containsObject:key]) {
                        
                        NSInteger row = [self.keyList indexOfObject:key];
                        //                        NSLog(@"row = %d",row);
                        if (row < self.keyList.count - 1) {
                            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:0];
                            _th.scrolToIndexPath = indexPath;
                            
                            NSNotification *notification = [NSNotification notificationWithName:@"scrolCell" object:nil userInfo:@{@"indexPath":indexPath}];
                            [[NSNotificationCenter defaultCenter] postNotification:notification];
                        }
                    }
                    
                    timingUnit += 0.1f;
                });
                dispatch_resume(_timerSource);
            });
            
            
        } else  if (tempAVStatus == AVPlayerStatusUnknown) {
            NSLog(@"AVPlayerStatusUnknown");
        } else if (tempAVStatus == AVPlayerStatusFailed) {
            NSLog(@"AVPlayerStatusFailed");
        }
        
    }
}

- (void)changeBackProgress:(NSNumber *)durationTime {
    
    dispatch_sync(dispatch_get_main_queue(), ^{
        [self changeProgress:durationTime];
    });
    
    
    
    NSNotification *updateProgressNot = [NSNotification notificationWithName:@"updateProgressNot" object:nil userInfo:@{@"value" : durationTime}];
    [[NSNotificationCenter defaultCenter] postNotification:updateProgressNot];
}

#pragma mark - 设置锁屏状态，显示的歌曲信息
-(void)configNowPlayingInfoCenter {
    
    if (NSClassFromString(@"MPNowPlayingInfoCenter")) {
        //            NSDictionary *info = [self.musicList objectAtIndex:_playIndex];
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
        //        NSLog(@"name = %@",self.currPlayModel.songName);
        //歌曲名称 MPMediaItemPropertyTitle
        [dict setObject:self.currPlayModel.songName forKey:MPMediaItemPropertyTitle];
        
        //演唱者
        [dict setObject:self.currPlayModel.artistName forKey:MPMediaItemPropertyArtist];
        
        //专辑名
        //        [dict setObject:self.currPlayModel. forKey:MPMediaItemPropertyAlbumTitle];
        
        //专辑缩略图
        MPMediaItemArtwork *artwork = [[MPMediaItemArtwork alloc] initWithImage:self.currPlayModel.picImage];
        [dict setObject:artwork forKey:MPMediaItemPropertyArtwork];
        
        //音乐剩余时长
        [dict setObject:[NSNumber numberWithDouble:self.currPlayModel.duration.floatValue] forKey:MPMediaItemPropertyPlaybackDuration];
        
        //音乐当前播放时间 在计时器中修改
        //[dict setObject:[NSNumber numberWithDouble:0.0] forKey:MPNowPlayingInfoPropertyElapsedPlaybackTime];
        
        //设置锁屏状态下屏幕显示播放音乐信息
        [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:dict];
    }
}

#pragma mark - 计时器修改进度
- (void)changeProgress:(NSNumber *)value {
    if(self.myPlayer){
        //当前播放时间
        NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:[[MPNowPlayingInfoCenter defaultCenter] nowPlayingInfo]];
        [dict setObject:value forKey:MPNowPlayingInfoPropertyElapsedPlaybackTime]; //音乐当前已经过时间
        [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:dict];
        
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
    [self resignFirstResponder];
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    UIDevice *device = [UIDevice currentDevice];
    
    BOOL backgroundSupported = NO;
    
    if ( [device respondsToSelector:@selector(isMultitaskingSupported)] ) {
        backgroundSupported = device.multitaskingSupported;
    }
    
    if ( backgroundSupported == YES ) {
        [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
        //注意这里，告诉系统已经准备好了
        [self becomeFirstResponder];
    }
    
    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    }
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}

@end
