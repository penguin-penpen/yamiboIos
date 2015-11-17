//
//  MessageDetailTableViewCell.h
//  yamibo
//
//  Created by shuang yang on 10/15/15.
//  Copyright © 2015 lsl. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PrivateMessageDetailModel;
@class PublicMessageDetailModel;

#define KMessageDetailTableViewCell_In  @"KMessageDetailTableViewCell_In"
#define KMessageDetailTableViewCell_Out  @"KMessageDetailTableViewCell_Out"

@interface MessageDetailTableViewCell : UITableViewCell

- (void)loadPrivateData:(PrivateMessageDetailModel *)data;
- (void)loadPublicData:(PublicMessageDetailModel *)data;
- (void)cellBgColor:(BOOL)longPressed;

@end
