//
//  ServerEventHandler.m
//  Object
//
//  Created by user on 16/3/16.
//  Copyright © 2016年 GuoBIn. All rights reserved.
//

#import "ServerEventHandler.h"
#import "RecommandSongModel.h"
#import <AFNetworking/AFNetworking.h>
#import "MJExtension.h"
#import <NSDictionary+Accessors/NSDictionary+Accessors.h>

@implementation ServerEventHandler

+ (void)requestImage:(NSString *)referer success:(void (^) (NSArray *dataArr))success failure:(void (^)(NSError *error))failure {
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer.acceptableContentTypes = [manager.responseSerializer.acceptableContentTypes setByAddingObject:@"text/html"];
    
    [manager GET:referer parameters:nil success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            NSArray *originalData = [responseObject arrayForKey:@"data"];
            NSMutableArray *data = [NSMutableArray array];
            for (NSDictionary *item in originalData) {
                if ([item isKindOfClass:[NSDictionary class]] && [[item stringForKey:@"hoverURL"] length] > 0) {
                    [data addObject:item];
                }
            }
            success(data);
        } else {
            NSAssert(NO, @"不是字典 无法赋值");
        }
        
    } failure:^(AFHTTPRequestOperation * _Nonnull operation, NSError * _Nonnull error) {
        failure(error);
    }];
}

+ (void)requestRecommendedMusic:(NSString *)url success:(void (^) (NSArray *dataArr))success failure:(void (^)(NSError *error))failure {
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.requestSerializer = [AFHTTPRequestSerializer serializer];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    manager.responseSerializer.acceptableContentTypes = [manager.responseSerializer.acceptableContentTypes setByAddingObject:@"text/html"];
    [manager GET:url parameters:nil success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
        
        if ([responseObject isKindOfClass:[NSData class]]) {
            NSDictionary *allData;
            
            allData = [self objectFromJSONString:responseObject];
            
            if (allData) {
                NSMutableArray *dataArray = [NSMutableArray array];
                
                NSArray *listArray = allData[@"song_list"];
                //                NSArray *listArray = allData[@"result"][@"list"];
                //                if (!listArray) {
                //                    success(@[]);
                //                    return;
                //                }
                //                NSAssert(listArray, @"无数据");
                
                //                NSDictionary *asdf = listArray[2];
                //                NSArray *keys = [asdf allKeys];
                //                for (NSString *obj in keys) {
                //                    NSLog(@"obj = %@",[asdf objectForKey:obj]);
                //                }
                
                for (NSDictionary *dic in listArray) {
                    
                    RecommandSongModel *songModel = [RecommandSongModel mj_objectWithKeyValues:dic];
                    [dataArray addObject:songModel];
                }
                [dataArray removeLastObject];
                
                success(dataArray);
            }
        }
    } failure:^(AFHTTPRequestOperation * _Nullable operation, NSError * _Nonnull error) {
        
        failure(error);
    }];
}

+ (void)playSong:(NSString *)ID callback:(SongInfoBlock)block {
    
    NSString *url = [NSString stringWithFormat:@"http://tingapi.ting.baidu.com/v1/restserver/ting?from=webapp_music&method=baidu.ting.song.play&songid=%@",ID];
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.requestSerializer = [AFHTTPRequestSerializer serializer];
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    manager.responseSerializer.acceptableContentTypes = [manager.responseSerializer.acceptableContentTypes setByAddingObject:@"text/html"];
    [manager GET:url parameters:nil success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
        //        NSLog(@"responseObject = %@",responseObject);
        if ([responseObject isKindOfClass:[NSData class]]) {
            //            NSMutableString *receisveStr = [NSMutableString stringWithString:[[NSString alloc]initWithData:responseObject encoding:NSUTF8StringEncoding]];
            NSDictionary *data = [self objectFromJSONString:responseObject];
            
            SongModel *songModel = [[SongModel alloc] init];
            NSDictionary *songinfo = [data valueForKey:@"songinfo"];
            NSDictionary *bitrate = [data valueForKey:@"bitrate"];
            
            songModel.link = bitrate[@"file_link"];
            songModel.duration = bitrate[@"file_duration"];
            songModel.imageUrl = songinfo[@"pic_radio"];
            songModel.songName = songinfo[@"album_title"];
            songModel.artistName = songinfo[@"author"];
            block(songModel);
        }
        
    } failure:^(AFHTTPRequestOperation * _Nullable operation, NSError * _Nonnull error) {
        NSLog(@"Request falied");
        if (error) {
            NSLog(@"error = %@",error);
        }
        block(nil);
    }];
}

+ (void)requestSongLrc:(NSString *)song_id success:(void (^) (NSDictionary *dataDic))success failure:(void (^)(NSError *error))failure {
    
    NSString *lryUrl = [NSString stringWithFormat:@"http://tingapi.ting.baidu.com/v1/restserver/ting?from=webapp_music&method=baidu.ting.song.lry&format=json&callback=&songid=%@",song_id];
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.responseSerializer.acceptableContentTypes = [manager.responseSerializer.acceptableContentTypes setByAddingObject:@"application/json"];
    
    [manager GET:lryUrl parameters:nil success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
        
        
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            
            NSDictionary *dic = responseObject;
            success(dic);
            //            [self getLrc:[dic objectForKey:@"lrcContent"]];
        } else {
            NSAssert(NO, @"不是字典 无法赋值");
        }
        
    } failure:^(AFHTTPRequestOperation * _Nonnull operation, NSError * _Nonnull error) {
        failure(error);
    }];
}

+ (NSDictionary *)objectFromJSONString:(id)json {
    NSError *error = nil;
    id jsonObject = [NSJSONSerialization JSONObjectWithData:json options:NSJSONReadingAllowFragments error:&error];
    if (error) {
        NSLog(@"解析失败 == %@",error);
        return nil;
    }
    
    if ([jsonObject isKindOfClass:[NSDictionary class]]) {
        return jsonObject;
    } else {
        NSAssert(NO, @"不是字典  无返回");
        return nil;
    }
    return nil;
}

@end
