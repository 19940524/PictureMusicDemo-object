//
//  ServerEventHandler.h
//  Object
//
//  Created by user on 16/3/16.
//  Copyright © 2016年 GuoBIn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SongModel.h"
typedef void(^SongInfoBlock)(SongModel *songModel);

@interface ServerEventHandler : NSObject

/**
 *  请求图片
 *
 *  @param referer URL
 *  @param success 请求成功后返回一个数组block
 *  @param failure 请求失败后放回一个NSError block
 */
+ (void)requestImage:(NSString *)referer success:(void (^) (NSArray *dataArr))success failure:(void (^)(NSError *error))failure;

/**
 *  请求推荐音乐
 *
 *  @param url     URL
 *  @param success 请求成功后返回一个数组block
 *  @param failure 请求失败后放回一个NSError block
 */
+ (void)requestRecommendedMusic:(NSString *)url success:(void (^) (NSArray *dataArr))success failure:(void (^)(NSError *error))failure;

/**
 *  播放网络音乐
 *
 *  @param ID    歌曲ID
 *  @param block 成功后返回一个 SongModel数据
 */
+ (void)playSong:(NSString *)ID callback:(SongInfoBlock)block;

/**
 *  请求歌词
 *
 *  @param song_id 歌曲ID
 *  @param success 请求成功后返回一个字典block
 *  @param failure 请求失败后放回一个NSError block
 */
+ (void)requestSongLrc:(NSString *)song_id success:(void (^) (NSDictionary *dataDic))success failure:(void (^)(NSError *error))failure;

@end
