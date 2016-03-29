//
//  RecommandSongModel.h
//  TableViewOptimize
//
//  Created by GuoBIn on 15/11/27.
//  Copyright © 2015年 XueGuoBin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RecommandSongModel : NSObject
/** 歌曲名称 */
@property (copy, nonatomic) NSString *album_title;
/** 歌曲封面 */
@property (copy, nonatomic) NSString *pic_big;
/** 歌曲id */
@property (copy, nonatomic) NSString *song_id;
/** 歌曲作者 */
@property (copy, nonatomic) NSString *author;
/** 作者id */
@property (copy, nonatomic) NSString *album_id;



@end
