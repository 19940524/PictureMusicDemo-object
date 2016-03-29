//
//  Thread.h
//  Object
//
//  Created by user on 16/3/18.
//  Copyright © 2016年 GuoBIn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "PlayMusicViewController.h"

@interface Thread : NSObject

+ (id)sharedThred;

@property (strong, nonatomic) AVPlayer *savelayer;

@property (copy, nonatomic) NSString *thereIsMusicId;

@property (copy, nonatomic) NSIndexPath *scrolToIndexPath;
@property (copy, nonatomic) NSArray *keyList;
@property (copy, nonatomic) NSArray *lrcList;

@property (strong, nonatomic) PlayMusicViewController *playMusicVC;

@end
