//
//  MessageDetailTableView.m
//  yamibo
//
//  Created by shuang yang on 10/15/15.
//  Copyright © 2015 lsl. All rights reserved.
//

#import "MessageDetailTableView.h"
#import "MessageDetailTableViewCell.h"
#import "CommunicationrManager.h"

@interface MessageDetailTableView()<UITableViewDelegate, UITableViewDataSource>

@property (strong, nonatomic) NSMutableArray *dataArray;
@property (strong, atomic) NSMutableDictionary *pmidIndexDic;
@property (strong, atomic) NSMutableDictionary *pmidHeightDic;
@property (strong, atomic) NSMutableDictionary *pmidFlagDic; // Recored the pmid that has images
@property (strong, atomic) NSMutableArray *pmidArray;
@property (strong, atomic) NSMutableArray *cellFlagArray;

@property (assign, nonatomic) MessageViewType viewType;
@property (assign, nonatomic) NSInteger detailId;
@property (assign, nonatomic) int msgCount;
@property (assign, nonatomic) int perPage;
@property (strong, nonatomic) UIView *editingMenuView;              //click cell to open the option panel
@property (strong, nonatomic) MessageDetailTableViewCell *longPressedCell;
@end

@implementation MessageDetailTableView
- (instancetype)init
{
    return [self initWithViewType:MessagePrivate andDetailId:0];
}
- (instancetype)initWithViewType:(MessageViewType)type andDetailId:(NSInteger)detailId{
    if (self = [super init]) {
        self.backgroundColor = [UIColor clearColor];
        self.separatorStyle = UITableViewCellSeparatorStyleNone;
        self.dataSource = self;
        self.delegate = self;
        _viewType = type;
        _detailId = detailId;
        _dataArray = [NSMutableArray array];
        _pmidIndexDic = [NSMutableDictionary dictionary];
        _pmidHeightDic = [NSMutableDictionary dictionary];
        _pmidFlagDic = [NSMutableDictionary dictionary];
        _pmidArray = [NSMutableArray array];
        _cellFlagArray = [NSMutableArray array];
        
        [self registerClass:[MessageDetailTableViewCell class] forCellReuseIdentifier:KMessageDetailTableViewCell_In];
        [self registerClass:[MessageDetailTableViewCell class] forCellReuseIdentifier:KMessageDetailTableViewCell_Out];
        self.estimatedRowHeight = 100;

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resizeCell:) name:@"resizeCell" object:nil];
    }
    return self;
}
- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
- (void)refreshData {
    [self beginLoadNewData];
}

- (void)loadNewData {
    if (_viewType == MessagePrivate) {
        [CommunicationrManager getPrivateMessageDetailList:1 toId:_detailId completion:^(PrivateMessageDetailListModel *model, NSString *message) {
            [self stopLoadNewData];
            if (message != nil) {
                [Utility showTitle:message];
                
            } else {
                _dataArray = [NSMutableArray arrayWithArray:model.msgList];
                int i = 0;
                for (PrivateMessageDetailModel *data in _dataArray) {
                    [_pmidIndexDic setObject:@((int)_dataArray.count-i-1) forKey:@([data.pmId intValue])];
                    [_cellFlagArray addObject:@0];
                    [_pmidArray insertObject:@([data.pmId intValue]) atIndex:0];
                    ++i;
                }

                _msgCount = [model.count intValue];
                _perPage = [model.perPage intValue];
                //FIXME: 所有类似tableview都需注意_msgCount == _perPage的情况
                if (model.msgList.count < _perPage || _msgCount == _perPage) {
                    [self hiddenHeader:YES];
                } else {
                    [self hiddenHeader:NO];
                }
                [self reloadData];
            }
        }];
    } else if (_viewType == MessagePublic) {
        [CommunicationrManager getPublicMessageDetailList:_detailId completion:^(PublicMessageDetailListModel *model, NSString *message) {
            [self stopLoadNewData];
            if (message != nil) {
                [Utility showTitle:message];
            } else {
                _dataArray = [NSMutableArray arrayWithArray:model.msgList];
                [self hiddenHeader:YES];
                [self reloadData];
            }
        }];
    }
    [self hiddenFooter:YES];
}
- (void)loadMoreData {
    if (_viewType == MessagePrivate) {
        [CommunicationrManager getPrivateMessageDetailList:(int)_dataArray.count / _perPage + 1 toId:_detailId completion:^(PrivateMessageDetailListModel *model, NSString *message) {
            [self stopLoadMoreData];
            if (message != nil) {
                [Utility showTitle:message];
            } else {
                [_dataArray addObjectsFromArray:model.msgList];
                for (PrivateMessageDetailModel *data in model.msgList) {
                   [_pmidArray insertObject:@([data.pmId intValue]) atIndex:0];
                }

                int i = 0;
                _cellFlagArray = [NSMutableArray array];
                for (PrivateMessageDetailModel *data in _dataArray) {
                    [_cellFlagArray addObject:@0];
                    [_pmidIndexDic setObject:@((int)_dataArray.count-i-1) forKey:@([data.pmId intValue])];
                    ++i;
                }
            }
            if (model.msgList.count < _perPage) {
                [self hiddenHeader:YES];
            } else {
                [self hiddenHeader:NO];
            }
            [self reloadData];
        }];
    }
}
#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _dataArray.count;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    long x = indexPath.row;
    NSNumber *pmid = [_pmidArray objectAtIndex:indexPath.row];
    NSNumber *height = [_pmidHeightDic objectForKey:pmid];
    if (height == nil) {
        return 81;
    }
    return [height floatValue];
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    int x = indexPath.row;

    PrivateMessageDetailModel *data = _dataArray[_dataArray.count - indexPath.row - 1];
    MessageDetailTableViewCell *cell;
    if (_viewType == MessagePublic || data.toId == [[NSUserDefaults standardUserDefaults] stringForKey:@"userId"]) {
        cell = [tableView dequeueReusableCellWithIdentifier:KMessageDetailTableViewCell_In forIndexPath:indexPath];
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:KMessageDetailTableViewCell_Out forIndexPath:indexPath];
    }
    if (![[_pmidArray objectAtIndex:indexPath.row] isEqual:@(cell.pmid)]) {
        [self configureCell:cell atIndexPath:indexPath];
        if ([_pmidHeightDic objectForKey:@(cell.pmid)] == nil) {
            CGFloat height = cell.height;
            [_pmidHeightDic setObject:[NSNumber numberWithFloat:height] forKey:@(cell.pmid)];
        }
    }

    return cell;
}
- (void)configureCell:(MessageDetailTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath{
    long x = indexPath.row;
    
    if (_viewType == MessagePrivate) {
        [cell loadPrivateData:_dataArray[_dataArray.count - indexPath.row - 1]];
    } else if (_viewType == MessagePublic) {
        [cell loadPublicData:_dataArray[_dataArray.count - indexPath.row - 1]];
    }
    cell.contentLabel.tag = cell.pmid;
    UILongPressGestureRecognizer *msgLPGR = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(mMsgLongPress:)];
    [msgLPGR setNumberOfTouchesRequired:1];
    [msgLPGR setAllowableMovement:100];
    [msgLPGR setMinimumPressDuration:0.5];
    //[cell addGestureRecognizer:msgLPGR];
}
- (void)resizeCell:(NSNotification*)notification {
    
    NSDictionary *dic = notification.userInfo;
    CGFloat height = [dic[@"height"] floatValue] + 30;
    NSNumber *pmid = dic[@"pmid"];
    if ([_pmidFlagDic objectForKey:pmid] == nil) {
        [_pmidHeightDic setObject:[NSNumber numberWithFloat:height] forKey:pmid];
        [_pmidFlagDic setObject:@1 forKey:pmid];
        long index = [[_pmidIndexDic objectForKey:pmid] intValue];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
        [self reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    }
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}


#pragma mark popup option view
-(void)mMsgLongPress:(UILongPressGestureRecognizer *)recognizer{
    
    CGPoint touchP = [recognizer locationInView:self];
    NSIndexPath *indexPath = [self indexPathForRowAtPoint:touchP];
    _longPressedCell = [self cellForRowAtIndexPath:indexPath];
    
    if (indexPath != nil) {
        [_longPressedCell cellBgColor:YES];

        if (recognizer.state == UIGestureRecognizerStateBegan) {
            if (!_editingMenuView) {
                [self initEditingMenuView];
            } else {
                [_editingMenuView setHidden:NO];
                _editingMenuView.alpha = 0;
            }
            
            [_editingMenuView mas_remakeConstraints:^(MASConstraintMaker *make) {
                make.center.mas_equalTo(_longPressedCell);
                make.width.mas_equalTo(80);
                make.height.mas_equalTo(40);
            }];
            
            [UIView animateWithDuration:0.3 animations:^{
                _editingMenuView.alpha = 1;
            } completion:nil];
        }
    }
}
-(void)initEditingMenuView {
    _editingMenuView = [[UIView alloc] init];
    _editingMenuView.alpha = 0;
    [self addSubview:_editingMenuView];
    
    UIButton *deleteBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    deleteBtn.backgroundColor = KCOLOR_RED_FC481F;
    [deleteBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [deleteBtn setTitle:@"删除" forState:UIControlStateNormal];

    [deleteBtn addTarget:self action:@selector(deleteBtnPressed) forControlEvents:UIControlEventTouchDown];
    [deleteBtn addTarget:self action:@selector(deleteBtnDepressed) forControlEvents:UIControlEventTouchUpInside];

    [_editingMenuView addSubview:deleteBtn];
    
    [deleteBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(_editingMenuView);
    }];
}
- (void)deleteRow:(NSIndexPath *)indexPath {
    [Utility showHUDWithTitle:@"正在删除"];
    __unsafe_unretained MessageDetailTableView *weakSelf = self;
    [CommunicationrManager delMessage:[_dataArray[indexPath.row] pmId] orConversation:@"0" ofType:_viewType completion:^(NSString *message) {
        [Utility hiddenProgressHUD];
        if (message != nil) {
            [Utility showTitle:message];
        } else {
            [_dataArray removeObjectAtIndex:indexPath.row];
            [weakSelf deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
    }];
    [Utility hiddenProgressHUD];

}
-(void)deleteBtnPressed {
}
-(void)deleteBtnDepressed {
    [_editingMenuView setHidden:YES];
    NSIndexPath *indexPath = [self indexPathForCell:_longPressedCell];
    [self deleteRow:indexPath];
}
-(id)hitTest:(CGPoint)point withEvent:(UIEvent *)event {

    id hitView = [super hitTest:point withEvent:event];
    CGRect rect = _editingMenuView.frame;
    if (!CGRectContainsPoint(rect, point)) {
        [_longPressedCell cellBgColor:NO];
        [_editingMenuView setHidden:YES];
    }
    return hitView;
}

#pragma mark inheritance

- (BOOL)showHeaderRefresh
{
    return YES;
}
- (BOOL)showFooterRefresh
{
    return YES;
}

@end
