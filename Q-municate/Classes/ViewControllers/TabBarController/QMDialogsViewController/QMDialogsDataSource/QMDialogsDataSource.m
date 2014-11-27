//
//  QMDialogsDataSource.m
//  Qmunicate
//
//  Created by Andrey Ivanov on 13.07.14.
//  Copyright (c) 2014 Quickblox. All rights reserved.
//

#import "QMDialogsDataSource.h"
#import "QMDialogCell.h"
#import "SVProgressHUD.h"
#import "QMServicesManager.h"

@interface QMDialogsDataSource()

<UITableViewDataSource, QMChatServiceDelegate>

@property (weak, nonatomic) UITableView *tableView;
@property (strong, nonatomic) NSArray *dialogs;
@property (assign, nonatomic) NSUInteger unreadDialogsCount;

@end

@implementation QMDialogsDataSource

- (void)dealloc {
    
    ILog(@"%@ - %@",  NSStringFromSelector(_cmd), self);
//    [[QMChatReceiver instance] unsubscribeForTarget:self];
}

- (instancetype)initWithTableView:(UITableView *)tableView {
    
    self = [super init];
    if (self) {
        
        self.tableView = tableView;
        self.tableView.dataSource = self;
        [QM.chatService addDelegate:self];
        
//        __weak __typeof(self)weakSelf = self;
//
//        [[QMChatReceiver instance] chatAfterDidReceiveMessageWithTarget:self block:^(QBChatMessage *message) {
//            
//            if (!message.cParamDialogID) {
//                return;
//            }
//            [weakSelf updateGUI];
//            [weakSelf retrieveUserIfNeededWithMessage:message];
//        }];
//        
//        [[QMChatReceiver instance] dialogsHisotryUpdatedWithTarget:self block:^{
//            [weakSelf updateGUI];
//        }];
//        
//        [[QMChatReceiver instance] usersHistoryUpdatedWithTarget:self block:^{
//            [weakSelf.tableView reloadData];
//        }];
    }
    
    return self;
}

#pragma mark - QMChatServiceDelegate

- (void)chatService:(QMChatService *)chatService didAddChatDialogs:(NSArray *)chatDialogs {
    
    self.dialogs = [QM.chatService.dialogsMemoryStorage dialogsSortByLastMessageDateWithAscending:NO];
    [self.tableView reloadData];
}

- (void)updateGUI {
    
    [self.tableView reloadData];
    [self fetchUnreadDialogsCount];
}

- (void)setUnreadDialogsCount:(NSUInteger)unreadDialogsCount {
    
    if (_unreadDialogsCount != unreadDialogsCount) {
        _unreadDialogsCount = unreadDialogsCount;
        
        [self.delegate didChangeUnreadDialogCount:_unreadDialogsCount];
    }
}

- (void)fetchUnreadDialogsCount {
    
    self.unreadDialogsCount = QM.chatService.dialogsMemoryStorage.unreadDialogs.count;
}

- (void)insertRowAtIndex:(NSUInteger)index {
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
    
    [self.tableView beginUpdates];
    [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationLeft];
    [self.tableView endUpdates];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    NSUInteger count = self.dialogs.count;
    return count > 0 ? count:1;
}

- (QBChatDialog *)dialogAtIndexPath:(NSIndexPath *)indexPath {
    
    NSArray *dialogs = self.dialogs;
    if (dialogs.count == 0) {
        return nil;
    }
    
    QBChatDialog *dialog = dialogs[indexPath.row];
    return dialog;
}

NSString *const kQMDialogCellID = @"QMDialogCell";
NSString *const kQMDontHaveAnyChatsCellID = @"QMDontHaveAnyChatsCell";

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    NSArray *dialogs = self.dialogs;
    
    if (dialogs.count == 0) {
        QMDialogCell *cell = [tableView dequeueReusableCellWithIdentifier:kQMDontHaveAnyChatsCellID];
        return cell;
    }
    
    QMDialogCell *cell = [tableView dequeueReusableCellWithIdentifier:kQMDialogCellID];
    QBChatDialog *dialog = dialogs[indexPath.row];
    cell.dialog = dialog;
    
    return cell;
}

#pragma mark - UITableViewDataSource Editing

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
#if DELETING_DIALOGS_ENABLED
    return YES;
#else
    return NO;
#endif
    
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        
        __weak typeof(self)weakSelf = self;
        
        [SVProgressHUD show];
        QBChatDialog *dialog = [self dialogAtIndexPath:indexPath];
        
//        [[QMApi instance] deleteChatDialog:dialog completion:^(BOOL success) {
//            
//            [SVProgressHUD dismiss];
//            (weakSelf.dialogs.count == 0) ?
//                [tableView reloadSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationFade] :
//                [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
//
//        }];
    }
}
@end
