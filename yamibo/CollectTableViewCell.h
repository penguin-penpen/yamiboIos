//
//  CollectTableViewCell.h
//  yamibo
//
//  Created by 李思良 on 15/9/20.
//  Copyright © 2015年 lsl. All rights reserved.
//

#import <UIKit/UIKit.h>
@class ThreadFavoriteModel;
#define KCollectTableViewCell @"KCollectTableViewCell"

@interface CollectTableViewCell : UITableViewCell

- (void)loadData:(ThreadFavoriteModel *)data;

@end
