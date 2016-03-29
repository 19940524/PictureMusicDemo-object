//
//  PlayMusicModel.h
//  Object
//
//  Created by user on 16/3/18.
//  Copyright © 2016年 GuoBIn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface PlayMusicModel : NSObject

@property (copy, nonatomic) UIImage *pic_bigImage;
@property (assign, nonatomic) CGRect imageFrame;
@property (copy, nonatomic) NSString *songTitle;
@property (copy, nonatomic) NSString *song_id;

@end
