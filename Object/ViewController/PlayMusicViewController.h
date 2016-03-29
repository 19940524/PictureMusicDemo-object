//
//  PlayMusicViewController.h
//  Object
//
//  Created by user on 16/3/18.
//  Copyright © 2016年 GuoBIn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PlayMusicModel.h"
#import "RecommandSongModel.h"
#import <AVFoundation/AVFoundation.h>

@protocol PlayMusicViewControllerDelegate <NSObject>

/**
 *  播放暂停
 *
 *  @param playBtn 播放安妮
 */
- (void)playOrStopMusicPlayBtn:(UIButton *)playBtn;

/**
 *  上下曲
 *
 *  @param isNext 是否下一曲
 */
- (void)inASongIsNext:(BOOL)isNext;

@end

typedef void(^startPlayBlock)();

@interface PlayMusicViewController : UIViewController

@property (weak, nonatomic) IBOutlet UILabel *songName;
@property (weak, nonatomic) IBOutlet UITableView *myTableView;
@property (weak, nonatomic) IBOutlet UIButton *playOrStopButton;
@property (strong, nonatomic) UIImageView *picImage;

@property (strong, nonatomic) PlayMusicModel *playMusicM;

@property (copy, nonatomic) NSArray *keyList;
@property (copy, nonatomic) NSArray *lrcList;

@property (assign, nonatomic) CGFloat saveTime;

@property (assign, nonatomic) BOOL musicReplace;

@property (copy, nonatomic) startPlayBlock startPlay;

@property (weak, nonatomic) id<PlayMusicViewControllerDelegate> delegate;

- (void)playPause:(UIButton *)button;
- (void)selectIndexPathChangeColor:(NSIndexPath *)indexPath animated:(BOOL)animated;

@end
