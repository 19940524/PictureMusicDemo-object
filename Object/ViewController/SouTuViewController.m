//
//  SouTuViewController.m
//  Object
//
//  Created by user on 16/3/16.
//  Copyright © 2016年 GuoBIn. All rights reserved.
//

#import "LCYImageCell.h"
#import "SouTuViewController.h"
#import <MJRefresh/MJRefresh.h>
#import <AFNetworking/AFNetworking.h>
#import <SDWebImage/UIImageView+WebCache.h>
#import <NSDictionary+Accessors/NSDictionary+Accessors.h>
#import "ServerEventHandler.h"

@interface SouTuViewController () {
    NSArray *_keyword;
    NSString *_refererString;
    NSString *_searchName;
}

@property (weak, nonatomic) IBOutlet UITableView *myTableView;
@property (strong, nonatomic) NSValue *targetRect;
@property (strong, nonatomic) NSMutableArray *allData;      // 所有的请求数据

@end

@implementation SouTuViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _keyword = @[@"lion",@"tiger",@"monkey",@"cat",@"dog",@"horse",@"leopard",@"boar",@"cow",@"bear"];
    
    self.allData = [NSMutableArray array];
    
    [self getRandomImage];
    self.myTableView.mj_footer = [MJRefreshAutoNormalFooter footerWithRefreshingBlock:^{
        [self getRandomImage];
    }];
    
    [SDWebImageManager.sharedManager.imageCache
     calculateSizeWithCompletionBlock:^(NSUInteger fileCount, NSUInteger totalSize) {
         NSLog(@"fileCount = %d    totalSize = %d",fileCount, totalSize);
         if (fileCount > 200) {
             [[[SDWebImageManager sharedManager] imageCache] clearDisk];
         }
     }];
}

- (NSString *)getRandomReferer {
    int index = [self getScopeInsideRandomValue:0 to:10];
    NSString *name = [_keyword objectAtIndex:index];
    return [self refererString:name];
}

- (NSString *)refererString:(NSString *)name {
    NSString *url = [NSString stringWithFormat:@"http://image.baidu.com/search/acjson?tn=resultjson_com&ipn=rj&ie=utf-8&oe=utf-8&word=%@&queryWord=%@",name,name];
    return [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

- (void)getWebImage {
    _refererString = [self refererString:_searchName];
    [self requestImage:_refererString];
}

- (void)getRandomImage {
    _refererString = [self getRandomReferer];
    [self requestImage:_refererString];
    
}

- (void)requestImage:(NSString *)referer {
    
    [ServerEventHandler requestImage:referer success:^(NSArray *dataArr) {
        [self.allData addObjectsFromArray:dataArr];
        [self.myTableView reloadData];
        [self.myTableView.mj_footer endRefreshing];
    } failure:^(NSError *error) {
        if (error) {
            NSLog(@"error = %@",error);
        }
    }];
}

- (int)getScopeInsideRandomValue:(int)from to:(int)to {
    return (int)(from + (arc4random() % (to - from)));
}

#pragma mark - UITableViewDataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.allData.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"ImageCell";
    LCYImageCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier forIndexPath:indexPath];
    [self setupCell:cell withIndexPath:indexPath];
    return cell;
}

- (void)setupCell:(LCYImageCell *)cell withIndexPath:(NSIndexPath *)indexPath {
    SDWebImageDownloader *downloader = [[SDWebImageManager sharedManager] imageDownloader];
    [downloader setValue:_refererString forHTTPHeaderField:@"Referer"];
    
    NSDictionary *obj = [self objectForRow:indexPath.row];
    NSURL *targetURL = [NSURL URLWithString:[obj stringForKey:@"hoverURL"]];
    
    if (![[cell.photoView sd_imageURL] isEqual:targetURL]) {
        cell.photoView.alpha = 0.0f;
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
            [cell.photoView sd_setImageWithURL:targetURL placeholderImage:nil options:SDWebImageRefreshCached completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                if (!error && [imageURL isEqual:targetURL]) {
                    // fade in animation
                    [UIView animateWithDuration:0.25 animations:^{
                        cell.photoView.alpha = 1.0;
                    }];
                }
            }];
        }
    }
}

- (NSDictionary *)objectForRow:(NSInteger)row
{
    if (row < self.allData.count) {
        return self.allData[row];
    }
    return nil;
}

#pragma mark - UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *obj = [self objectForRow:indexPath.row];
    NSInteger width = [obj integerForKey:@"width"];
    NSInteger height = [obj integerForKey:@"height"];
    if (obj && width > 0 && height > 0) {
        return tableView.frame.size.width / (float)width * (float)height;
    }
    return 180.0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)loadImageForVisibleCells
{
    NSArray *cells = [self.myTableView visibleCells];
    for (LCYImageCell *cell in cells) {
        NSIndexPath *indexPath = [self.myTableView indexPathForCell:cell];
        [self setupCell:cell withIndexPath:indexPath];
    }
}

#pragma mark - UIScrollViewDelegate
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

- (IBAction)searchAction:(id)sender {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"输入搜索关键字" message:@"百度图片" preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
    }];
    UIAlertAction *search = [UIAlertAction actionWithTitle:@"搜索" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self.allData removeAllObjects];
        [self getWebImage];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
        [self.myTableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionNone animated:YES];
    }];
    [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.textAlignment = NSTextAlignmentCenter;
        textField.placeholder = @"关键字";
        [textField resignFirstResponder];
        [textField addTarget:self action:@selector(textFieldAction:) forControlEvents:UIControlEventEditingChanged];
    }];
    [alert addAction:cancel];
    [alert addAction:search];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)textFieldAction:(UITextField *)textField {
    _searchName = textField.text;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
