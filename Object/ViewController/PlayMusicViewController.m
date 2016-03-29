//
//  PlayMusicViewController.m
//  Object
//
//  Created by user on 16/3/18.
//  Copyright © 2016年 GuoBIn. All rights reserved.
//

#import "PlayMusicViewController.h"
#import "ServerEventHandler.h"
#import "Masonry.h"
#import "Thread.h"
#import <SDWebImage/UIImageView+WebCache.h>

#define UIColorFromRGBA(r,g,b,a) [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:a]

//获取设备的物理高度
#define ScreenHeight [UIScreen mainScreen].bounds.size.height

//获取设备的物理宽度
#define ScreenWidth [UIScreen mainScreen].bounds.size.width

@interface PlayMusicViewController () {
    
    
    
    __weak IBOutlet UIImageView *backImageView;
    __weak IBOutlet UIProgressView *myProgressView;
    
    BOOL isAllowPerform;
}

@property (strong, nonatomic) IBOutletCollection(UIView) NSArray *views;

@property (strong, nonatomic) UITableViewCell *lastCell;

@end

@implementation PlayMusicViewController
@synthesize keyList,lrcList,lastCell,playOrStopButton;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.navigationController.navigationBar setHidden:YES];
    [self.tabBarController.tabBar setHidden:YES];
    isAllowPerform = YES;
    self.songName.text = self.playMusicM.songTitle; 
    
    [playOrStopButton setImage:[UIImage imageNamed:@"music_Play"] forState:UIControlStateNormal];
    
    [playOrStopButton setImage:[UIImage imageNamed:@"music_Pause"] forState:UIControlStateSelected];
    
    UIImageView *myImageView = [[UIImageView alloc] init];
    myImageView.image = self.playMusicM.pic_bigImage;
    myImageView.frame = self.playMusicM.imageFrame;
    [self.view addSubview:myImageView];
    self.picImage = myImageView;
    
    [myImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view).with.offset(self.playMusicM.imageFrame.origin.y);
        make.left.right.equalTo(self.view).with.offset(0);
        make.height.mas_equalTo(self.playMusicM.imageFrame.size.height);
    }];
    
    for (UIView *view in self.views) {
        if ([view isKindOfClass:[UIButton class]]) {
            view.layer.cornerRadius = view.frame.size.height / 2;
            view.layer.borderWidth = 1;
            view.layer.borderColor = [UIColor whiteColor].CGColor;
        }
    }
    
    
    if (self.musicReplace) {
        playOrStopButton.selected = YES;
    } else {
        playOrStopButton.selected = YES;
        [self.myTableView reloadData];
        [self selectIndexPathChangeColor:[[Thread sharedThred] scrolToIndexPath] animated:NO];
    }
}

- (void)updateProgressNot:(NSNotification *)obj {
    dispatch_async(dispatch_get_main_queue(), ^{
        float value = [obj.userInfo[@"value"] floatValue];
        myProgressView.progress = value;
        
    });
}

- (void)scrolCell:(NSNotification *)obj {
    
    NSIndexPath *indexPath = obj.userInfo[@"indexPath"];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self selectIndexPathChangeColor:indexPath animated:YES];
    });
}

- (void)selectIndexPathChangeColor:(NSIndexPath *)indexPath animated:(BOOL)animated {
    
    [self.myTableView selectRowAtIndexPath:indexPath animated:animated scrollPosition:UITableViewScrollPositionMiddle ];
    
    lastCell.textLabel.font = [UIFont systemFontOfSize:15];
    lastCell.textLabel.textColor = UIColorFromRGBA(122, 122, 122, 1);
    
    UITableViewCell *cell = [self.myTableView cellForRowAtIndexPath:indexPath];
    cell.textLabel.font = [UIFont systemFontOfSize:16];
    cell.textLabel.textColor = UIColorFromRGBA(78, 78, 78, 1);
    lastCell = cell;
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return lrcList.count - 1;
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
        cell.backgroundColor = [UIColor clearColor];
        cell.textLabel.numberOfLines = 2;
        if (indexPath.row == 1) {
            cell.textLabel.font = [UIFont systemFontOfSize:16];
            cell.textLabel.textColor = UIColorFromRGBA(88, 88, 88, 1);
            lastCell = cell;
        } else {
            cell.textLabel.font = [UIFont systemFontOfSize:15];
            cell.textLabel.textColor = UIColorFromRGBA(122, 122, 122, 1);
        }
    }
    
    cell.textLabel.text = lrcList[indexPath.row];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 40;
}

- (IBAction)playAction:(UIButton *)sender {
    
    [self playPause:sender];
}

- (void)playPause:(UIButton *)button {
    [self.delegate playOrStopMusicPlayBtn:button];
}

- (IBAction)nextAction:(UIButton *)sender {
    [myProgressView setProgress:0.0f];
    [self.delegate inASongIsNext:YES];
}

- (IBAction)previousAction:(UIButton *)sender {
    myProgressView.progress = 0;
    [self.delegate inASongIsNext:NO];
}

- (IBAction)dissVC:(UIButton *)sender {
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(scrolCell:) name:@"scrolCell" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateProgressNot:) name:@"updateProgressNot" object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController.navigationBar setHidden:NO];
    [self.tabBarController.tabBar setHidden:NO];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"scrolCell" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"updateProgressNot" object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.musicReplace) {
        if (self.startPlay) {
            self.startPlay();
        }
    }
    [UIView animateWithDuration:0.3f animations:^{
        [self.picImage mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.view).with.offset(70);
            make.left.equalTo(self.view).with.offset(50);
            make.right.equalTo(self.view).with.offset(-50);
            make.bottom.equalTo(self.myTableView.mas_top).with.offset(0);
        }];
        [self.view layoutIfNeeded];
        
        self.picImage.layer.masksToBounds = YES;
        self.picImage.layer.cornerRadius = 8;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.2f animations:^{
            for (UIView *view in self.views) {
                view.alpha = 1;
            }
        }];
    }];
    
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


@end
