//
//  SongModel.h
//  TableViewOptimize
//
//  Created by GuoBIn on 15/11/24.
//  Copyright © 2015年 XueGuoBin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface SongModel : NSObject

@property (copy, nonatomic) NSString *songName;
@property (copy, nonatomic) NSString *artistName;
@property (copy, nonatomic) NSString *songID;

@property (copy, nonatomic) NSString *link;
@property (copy, nonatomic) NSString *imageUrl;
@property (copy, nonatomic) NSString *duration;

@property (copy, nonatomic) UIImage *picImage;
@end
