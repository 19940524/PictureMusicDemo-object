//
//  Thread.m
//  Object
//
//  Created by user on 16/3/18.
//  Copyright © 2016年 GuoBIn. All rights reserved.
//

#import "Thread.h"

@implementation Thread

+ (id)sharedThred
{
    static dispatch_once_t pred;
    static Thread *thread = nil;
    dispatch_once(&pred, ^{
        thread = [[Thread alloc] init];
    });
    return thread;
}


@end
