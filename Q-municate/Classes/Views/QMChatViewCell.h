//
//  QMChatViewCell.h
//  Q-municate
//
//  Created by Igor Alefirenko on 01/04/2014.
//  Copyright (c) 2014 Quickblox. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface QMChatViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *avatarView;
@property (weak, nonatomic) IBOutlet UILabel *fullNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *messageTextLabel;
@property (weak, nonatomic) IBOutlet UILabel *dateTimeLabel;

- (void)configureCellWithMessage:(NSDictionary *)messageDictionary fromUser:(QBUUser *)user;
+ (CGFloat)cellHeightForMessage:(NSDictionary *)messageDictionary;

@end