//
//  QMHistoryVC.m
//  Q-municate
//
//  Created by Andrey Ivanov on 11.03.15.
//  Copyright (c) 2015 Quickblox. All rights reserved.
//

#import "QMHistoryVC.h"
#import "QMServicesManager.h"
#import "QMHistoryDataSource.h"
#import "QMGlobalSearchDataSource.h"
#import "QMNotificationView.h"
#import "QMProfileTitleView.h"
#import "QMAddContactCell.h"
#import "QMChatHistoryCell.h"
#import "QMSearchStatusCell.h"

#import "QMSearchController.h"
#import "QMTasks.h"
#import "QMChatVC.h"

const NSTimeInterval kQMKeyboardTapTimeInterval = 1.f;

typedef NS_ENUM(NSUInteger, QMSearchScopeButtonIndex) {
    
    QMSearchScopeButtonIndexLocal,
    QMSearchScopeButtonIndexGlobal
};

@interface QMHistoryVC ()

<QMContactListServiceDelegate,  QMAddContactProtocol, QMChatServiceDelegate, QMHistoryDataSourceHandler>
/**
 *  Datasources
 */
@property (strong, nonatomic) QMHistoryDataSource *historyDataSource;
@property (strong, nonatomic) QMGlobalSearchDataSource *globalSearchDatasource;
@property (strong, nonatomic) QMGlobalSearchDataSource *localSearchDatasource;
/**
 *  Notification view
 */
@property (strong, nonatomic) QMNotificationView *notificationView;

@property (weak, nonatomic) QBRequest *searchRequest;

@property (assign, nonatomic) BOOL globalSearchIsCancelled;

@end

@implementation QMHistoryVC

#pragma mark - lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self registerNibs];
    //Init datasources
    self.historyDataSource = [[QMHistoryDataSource alloc] init];
    self.historyDataSource.handler = self;
    self.tableView.dataSource = self.historyDataSource;
    self.tableView.backgroundView = [[UIView alloc] init];
    self.globalSearchDatasource = [[QMGlobalSearchDataSource alloc] init];
    //Configure search controller
    self.searchController.searchResultsTableView.rowHeight = 75;
    self.searchController.searchBar.tintColor = [UIColor colorWithRed:0.067 green:0.357 blue:0.643 alpha:1.000];
    self.searchController.searchBar.searchBarStyle = UISearchBarStyleMinimal;
    //Subscirbe to notification
    [QM.contactListService addDelegate:self];
    [QM.chatService addDelegate:self];
    //Set profile title view
    QMProfileTitleView *profileTitleView = [[QMProfileTitleView alloc] init];
    profileTitleView.title = QM.profile.userData.fullName;
    [profileTitleView setUserImageWithUrl:QM.profile.userData.avatarUrl];
    self.navigationItem.titleView = profileTitleView;
    //Fetch data from server
    [QMTasks taskLogin:^(BOOL successLogin) {
        [QMTasks taskFetchDialogsAndUsers:^(BOOL successFetch) {}];
    }];
}

- (void)stupNotificationView {
    
    self.notificationView = [QMNotificationView showInViewController:self];
    self.notificationView.tintColor = [UIColor colorWithWhite:0.800 alpha:0.380];
    [self.notificationView setVisible:YES animated:YES completion:^{}];
}

- (void)contactListServiceDidLoadCache {
    
    [self.tableView reloadData];
}

- (void)contactListService:(QMContactListService *)contactListService didAddUsers:(NSArray *)users {
    
    [self.tableView reloadData];
}

#pragma mark - QMChatServiceDelegate

- (void)chatServiceDidLoadDialogsFromCache {
    
    NSArray *dialogsFromCache = [QM.chatService.dialogsMemoryStorage unsortedDialogs];
    [self.historyDataSource.collection addObjectsFromArray:dialogsFromCache];
    [self.tableView reloadData];
}

- (void)chatService:(QMChatService *)chatService didAddChatDialog:(QBChatDialog *)chatDialog {
    
    [self.historyDataSource.collection insertObject:chatDialog atIndex:0];
    [self.tableView reloadData];
}

- (void)chatService:(QMChatService *)chatService didAddChatDialogs:(NSArray *)chatDialogs {
    
    [self.historyDataSource.collection removeAllObjects];
    [self.historyDataSource.collection addObjectsFromArray:chatDialogs];
    [self.tableView reloadData];
}

#pragma mark - Register nib's

- (void)registerNibs {
    
    [QMChatHistoryCell registerForReuseInTableView:self.tableView];
    [QMChatHistoryCell registerForReuseInTableView:self.searchController.searchResultsTableView];
    [QMAddContactCell registerForReuseInTableView:self.searchController.searchResultsTableView];
    [QMSearchStatusCell registerForReuseInTableView:self.searchController.searchResultsTableView];
}

#pragma mark - Search
#pragma mark Local

- (void)localSearch:(NSString *)searchText {
    
    self.globalSearchIsCancelled = YES;
    [self.globalSearchDatasource.collection removeAllObjects];
    self.globalSearchDatasource.searchText = nil;
    [self.searchController.searchResultsTableView reloadData];
}

#pragma mark Gloabal

- (void)globalSearch:(NSString *)searchText {
    
    self.globalSearchIsCancelled = NO;
    
    if (searchText.length == 0) {
        //Clear datasource
        [self.globalSearchDatasource.collection removeAllObjects];
        [self.searchController.searchResultsTableView reloadData];
    }
    else {
        //Keyboard typing timeout
        int64_t keyboadTapTimeInterval = (int64_t)(kQMKeyboardTapTimeInterval * NSEC_PER_SEC);
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, keyboadTapTimeInterval), dispatch_get_main_queue(), ^{
            
            if ([self.searchController.searchBar.text isEqualToString:searchText]) {
                
                if (self.globalSearchIsCancelled) {
                    
                    self.globalSearchIsCancelled = NO;
                    return;
                }
                
                [self beginSearchWithSearchText:searchText nextPage:NO];
                [self.searchController.searchResultsTableView reloadData];
            }
        });
    }
}

- (void)beginSearchWithSearchText:(NSString *)searchText nextPage:(BOOL)nextPage {
    
    if (!nextPage) {
        
        [self.globalSearchDatasource resetPage];
    }
    
    QBGeneralResponsePage *currentPage = [self.globalSearchDatasource nextPage];
    
    if (!currentPage) {
        return;
    }
    __weak __typeof(self)weakSelf = self;
    
    self.searchRequest =
    [QBRequest usersWithFullName:searchText
                            page:currentPage
                    successBlock:^(QBResponse *response,
                                   QBGeneralResponsePage *page,
                                   NSArray *users)
     {
         [weakSelf.globalSearchDatasource.collection addObjectsFromArray:users];
         [weakSelf.globalSearchDatasource setSearchText:searchText];
         [weakSelf.globalSearchDatasource updateCurrentPageWithResponcePage:page];
         [weakSelf.searchController.searchResultsTableView reloadData];
         weakSelf.searchRequest = nil;
         
     } errorBlock:^(QBResponse *response) {
         
         if (response.status == QBResponseStatusCodeCancelled) {
             
             NSLog(@"Global search is cancelled");
             
         } else if (response.status == QBResponseStatusCodeNotFound) {
             
             NSLog(@"Not found");
         }
     }];
}

- (void)beginSearch:(NSString *)searchString selectedScope:(NSInteger)selectedScope {
    
    switch (selectedScope) {
            
        case QMSearchScopeButtonIndexLocal: {
            
            [self localSearch:searchString];
        }
            break;
        case QMSearchScopeButtonIndexGlobal: {
            
            [self globalSearch:searchString];
        }
            break;
            
        default:break;
    }
}

#pragma mark - Prepare for Segue

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([segue.identifier isEqualToString: @"ChatViewController"]) {
        
        QMChatVC *chatVC = segue.destinationViewController;
        chatVC.chatDialog = sender;
    }
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    QBChatDialog *chatDialog = self.historyDataSource.collection[indexPath.row];
    
    [UIView animateWithDuration:0.2 animations:^{
        
        cell.contentView.transform = CGAffineTransformScale(cell.transform, 1, 1);
        
    } completion:^(BOOL finished) {
        
        [self performSegueWithIdentifier:@"ChatViewController" sender:chatDialog];
        
    }];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (tableView == self.searchController.searchResultsTableView) {
        
        if (indexPath.row == (int) self.globalSearchDatasource.collection.count && self.globalSearchDatasource.collection.count != 0 ) {
            
            [self beginSearchWithSearchText:self.searchController.searchBar.text nextPage:YES];
        }
    }
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    cell.contentView.transform = CGAffineTransformScale(cell.transform, 0.95, 0.95);
    
    return indexPath;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    return 75;
}

#pragma mark - Search bar

- (void)searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope  {
    
    if (self.searchRequest ) {
        //Cancel global search request
        [self.searchRequest cancel];
        self.searchRequest = nil;
    }
    
    [self beginSearch:searchBar.text selectedScope:selectedScope];
}

#pragma mark - QMSearchControllerDelegate
#pragma mark Present

- (void)willPresentSearchController:(QMSearchController *)searchController {
    
    self.globalSearchDatasource.addContactHandler = self;
    searchController.searchBar.searchBarStyle = UISearchBarStyleDefault;
    searchController.searchBar.barTintColor = [UIColor colorWithWhite:0.969 alpha:1.000];
    
    searchController.searchBar.scopeButtonTitles = @[@"Local", @"Global"];
}

- (void)didPresentSearchController:(QMSearchController *)searchController {
    
    self.tableView.dataSource = nil;
    [self.tableView reloadData];
}

#pragma mark Dissmiss

- (void)willDismissSearchController:(QMSearchController *)searchController {
    
    [self.searchController.searchBar setSearchBarStyle:UISearchBarStyleMinimal];
    self.searchController.searchBar.scopeButtonTitles = @[];
    
    self.globalSearchDatasource.addContactHandler = nil;
}

- (void)didDismissSearchController:(QMSearchController *)searchController {
    
    self.tableView.dataSource = self.historyDataSource;
    [self.tableView reloadData];
}

#pragma mark - QMSearchResultsUpdating

- (void)updateSearchResultsForSearchController:(QMSearchController *)searchController {
    
    if (searchController.searchBar.selectedScopeButtonIndex == QMSearchScopeButtonIndexGlobal) {
        
        self.searchController.searchResultsDataSource = self.globalSearchDatasource;
    }
    else {
        
        self.searchController.searchResultsDataSource = self.localSearchDatasource;
    }
    
    [self beginSearch:searchController.searchBar.text selectedScope:searchController.searchBar.selectedScopeButtonIndex];
}

#pragma mark - QMAddContactProtocol

- (void)didAddContact:(QBUUser *)contact {
    
    //Send contact request and create p2p chat
    [QM.contactListService addUserToContactListRequest:contact completion:^(BOOL success) {
        
        if (success) {
            
            [QM.chatService createPrivateChatDialogWithOpponent:contact completion:^(QBResponse *response, QBChatDialog *createdDialog) {
                
                //Send system message
                QBChatMessage *message = [QBChatMessage message];
                message.text = @"Contact request";
                
                [QM.chatService sendMessage:message
                                   toDialog:createdDialog
                                       type:QMMessageTypeNotificationAboutSendContactRequest
                                       save:YES
                                 completion:^(NSError *error)
                {
                    NSLog(@"Send contact request");
                }];
            }];
        }
    }];
}

- (BOOL)userExist:(QBUUser *)user {
    
    QBUUser *extstUser = [QM.contactListService.usersMemoryStorage userWithID:user.ID];
    return extstUser ? YES : NO;
}

#pragma mark - QMHistoryDataSourceHandler

- (QBUUser *)historyDataSource:(QMHistoryDataSource *)historyDataSource recipientWithIDs:(NSArray *)userIDs {
    
    NSArray *users = [QM.contactListService usersWithoutMeWithIDs:userIDs];
    NSAssert(users.count <= 1, @"");
    
    return users.firstObject;
}

@end