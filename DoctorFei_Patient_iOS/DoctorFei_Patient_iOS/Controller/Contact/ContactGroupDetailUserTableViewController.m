//
//  ContactGroupDetailUserTableViewController.m
//  DoctorFei_iOS
//
//  Created by GuJunjia on 15/3/24.
//
//

#import "ContactGroupDetailUserTableViewController.h"
#import "ContactGroupUserCollectionViewCell.h"
#import "Chat.h"
#import "Friends.h"
#import <UIImageView+WebCache.h>
#import "ChatAPI.h"
#import "MBProgressHUD.h"
#import "GroupChat.h"
#import "GroupChatFriend.h"
#import "ContactGroupDetailInfoTableViewController.h"
#import "ContactMainViewController.h"
#import "JSONKit.h"
#import "ContactGroupListTableViewController.h"
#import "ContactDoctorFriendDetailTableViewController.h"
#import "ContactPeronsalFriendDetailTableViewController.h"
#import "ContactGroupNewGeneralViewController.h"
static NSString *ContactGroupUserCellIdentifier = @"ContactGroupUserCellIdentifier";
@interface ContactGroupDetailUserTableViewController ()
<UICollectionViewDelegate, UICollectionViewDataSource>
- (IBAction)backButtonClicked:(id)sender;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UIButton *quitButton;
- (IBAction)quitButtonClicked:(id)sender;
@property (weak, nonatomic) IBOutlet UISwitch *visiableSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *noDisturbSwitch;
- (IBAction)visiableSwitchValueChanged:(id)sender;
- (IBAction)disturbSwitchValueChanged:(id)sender;

@end

@implementation ContactGroupDetailUserTableViewController
{
    NSArray *userArray, *userDataArray;
    BOOL isCanDeleteUser;
    NSNumber *userGroupId;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    //    [self.tableView setTableFooterView:[UIView new]];
    
    [self.collectionView addObserver:self forKeyPath:@"contentSize" options:NSKeyValueObservingOptionOld context:NULL];
    
    CGRect headRect = self.tableView.tableHeaderView.frame;
    headRect.size.height = 200.0f;
    [self.tableView.tableHeaderView setFrame:headRect];
    //    [self reloadCollectionViewData];
    CGRect footerRect = self.tableView.tableFooterView.frame;
    footerRect.size.height = 60.0f;
    [self.tableView.tableFooterView setFrame:footerRect];
    isCanDeleteUser = NO;
    [self updateQuitButtonTitle];
    [self fetchChatUser];
    //    [_visiableSwitch setOn:_currentGroupChat.visible.boolValue];
    //    [_noDisturbSwitch setOn:_currentGroupChat.allowDisturb.boolValue];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    _nameLabel.text = _currentGroupChat.name;
    [self fetchGroupInfo];
    
    
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)updateQuitButtonTitle {
    if (isCanDeleteUser) {
        [self.quitButton setTitle:@"解散该群" forState:UIControlStateNormal];
    }else{
        [self.quitButton setTitle:@"退出该群" forState:UIControlStateNormal];
    }
    [self.tableView reloadData];
}

- (void)reloadCollectionViewData{
    //    userArray = _currentChat.user.allObjects;
    userArray = _currentGroupChat.member.allObjects;
    [self.collectionView reloadData];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    CGRect headRect = self.tableView.tableHeaderView.frame;
    headRect.size.height = self.collectionView.contentSize.height + 20;
    UIView *headerView = self.tableView.tableHeaderView;
    [headerView setFrame:headRect];
    [self.tableView setTableHeaderView:headerView];
}
- (void)dealloc {
    [self.collectionView removeObserver:self forKeyPath:@"contentSize"];
}

- (void)fetchGroupInfo {
    NSNumber *userId = [[NSUserDefaults standardUserDefaults]objectForKey:@"UserId"];
    NSDictionary *param = @{@"groupid": _currentGroupChat.groupId,
                            @"userid": userId,
                            @"usertype": [[NSUserDefaults standardUserDefaults] objectForKey:@"UserType"]};
    [ChatAPI getGroupInfoWithParameters:param success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"%@",responseObject);
        NSDictionary *dict = [responseObject firstObject];
        if (dict) {
            GroupChat *groupChat = [GroupChat MR_findFirstByAttribute:@"groupId" withValue:@([dict[@"groupid"] intValue])];
            if (groupChat == nil) {
                groupChat = [GroupChat MR_createEntity];
                groupChat.groupId = @([dict[@"groupid"] intValue]);
            }
            groupChat.name = dict[@"name"];
            groupChat.flag = @([dict[@"flag"] intValue]);
            groupChat.address = [dict[@"address"] isKindOfClass:[NSString class]] ? dict[@"address"] : nil;
            groupChat.taxis = @([dict[@"taxis"] intValue]);
            groupChat.latitude = @([dict[@"lat"]doubleValue]);
            groupChat.longtitude = @([dict[@"long"]doubleValue]);
            groupChat.visible = @([dict[@"visible"] intValue]);
            groupChat.icon = dict[@"icon"];
            groupChat.note = [dict[@"note"] isKindOfClass:[NSString class]] ? dict[@"note"]: nil;
            groupChat.total = @([dict[@"total"]intValue]);
            groupChat.allowDisturb = @([dict[@"allowdisturb"] intValue]);
            [[NSManagedObjectContext MR_defaultContext]MR_saveToPersistentStoreAndWait];
            [self.noDisturbSwitch setOn:groupChat.allowDisturb.boolValue];
            [self.visiableSwitch setOn:groupChat.visible.boolValue];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"%@",error.localizedDescription);
    }];
}

- (void)fetchChatUser{
    NSDictionary *param = @{@"groupid": _currentGroupChat.groupId};
    [ChatAPI getChatUserWithParameters:param success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"%@",responseObject);
        NSNumber *userId = [[NSUserDefaults standardUserDefaults]objectForKey:@"UserId"];
        userDataArray = (NSArray *)responseObject;
        [_currentGroupChat removeMember:_currentGroupChat.member];
        for (NSDictionary *dict in responseObject) {
            if ([dict[@"userid"] intValue] == [userId intValue] && [dict[@"usertype"] intValue] == [[[NSUserDefaults standardUserDefaults]objectForKey:@"UserType"] intValue]) {
                isCanDeleteUser = ([dict[@"role"] intValue] == 2);
                userGroupId = @([dict[@"id"] intValue]);
                [self updateQuitButtonTitle];
                continue;
            }
            Friends *friend = [Friends MR_findFirstWithPredicate:[NSPredicate predicateWithFormat:@"userId == %@ && userType == %@", @([dict[@"userid"] intValue]), @([dict[@"usertype"] intValue])]];
            if (friend == nil) {
                friend = [Friends MR_createEntity];
                friend.userId = @([dict[@"userid"] intValue]);
                friend.userType = @([dict[@"usertype"] intValue]);
            }
            else{
                [_currentGroupChat.chat addUserObject:friend];
            }
            GroupChatFriend *groupChatFriend = [GroupChatFriend MR_findFirstByAttribute:@"id" withValue:@([dict[@"id"] intValue])];
            if (groupChatFriend == nil) {
                groupChatFriend = [GroupChatFriend MR_createEntity];
                groupChatFriend.id = @([dict[@"id"] intValue]);
            }
            groupChatFriend.name = dict[@"name"];
            groupChatFriend.createTime = [NSDate dateWithTimeIntervalSince1970:[dict[@"ctime"]intValue]];
            groupChatFriend.role = @([dict[@"role"] intValue]);
            groupChatFriend.friend = friend;
            [_currentGroupChat addMemberObject:groupChatFriend];
            //            [_currentChat addUserObject:friend];
        }
        [[NSManagedObjectContext MR_defaultContext]MR_saveToPersistentStoreAndWait];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self reloadCollectionViewData];
        });
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"%@",error.localizedDescription);
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.mode = MBProgressHUDModeText;
        hud.labelText = error.localizedDescription;
        [hud hide:YES afterDelay:1.5f];
    }];
}

- (void)deleteUserWithGroupChatFriend:(GroupChatFriend *)friend {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view.window animated:YES];
    NSDictionary *param = @{@"id": friend.id,
                            @"groupid" : _currentGroupChat.groupId,
                            @"userid": [[NSUserDefaults standardUserDefaults]objectForKey:@"UserId"],
                            @"usertype": [[NSUserDefaults standardUserDefaults] objectForKey:@"UserType"],
                            @"etype": @1
                            };
    [ChatAPI delChatUserWithParameters:param success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"%@",responseObject);
        if ([[responseObject firstObject][@"state"]intValue] == 1) {
            [_currentGroupChat removeMemberObject:friend];
            [_currentGroupChat.chat removeUserObject:friend.friend];
            [[NSManagedObjectContext MR_defaultContext]MR_saveToPersistentStoreAndWait];
            [self fetchChatUser];
        }
        hud.mode = MBProgressHUDModeText;
        hud.labelText = [responseObject firstObject][@"msg"];
        [hud hide:YES afterDelay:1.0f];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"%@",error.localizedDescription);
        hud.mode = MBProgressHUDModeText;
        hud.labelText = error.localizedDescription;
        [hud hide:YES afterDelay:1.5f];
    }];
}

- (void)addUserWithUserArray:(NSArray *)array {
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    NSMutableArray *joinArray = [NSMutableArray array];
    NSSet *users = _currentGroupChat.chat.user;
    for (Friends *friend in array) {
        if (![users containsObject:friend]) {
            [joinArray addObject:@{@"id": friend.userId, @"type": friend.userType}];
        }
    }
    NSDictionary *param = @{
                            @"groupid": _currentGroupChat.groupId,
                            @"userid": [[NSUserDefaults standardUserDefaults]objectForKey:@"UserId"],
                            @"usertype": [[NSUserDefaults standardUserDefaults] objectForKey:@"UserType"],
                            @"joinuserids": [joinArray JSONString]
                            };
    NSLog(@"%@",param);
    [ChatAPI setChatUserWithParameters:param success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"%@",responseObject);
        if ([[responseObject firstObject][@"state"]intValue] == 1) {
            [self fetchChatUser];
        }
        //        hud.mode = MBProgressHUDModeText;
        //        hud.labelText = [responseObject firstObject][@"msg"];
        //        [hud hide:YES afterDelay:1.0f];
        [hud hide:YES];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"%@",error.localizedDescription);
        hud.mode = MBProgressHUDModeText;
        hud.labelText = error.localizedDescription;
        [hud hide:YES afterDelay:1.5f];
    }];
}

- (void)changeDeleteButtonState {
    for (int i = 0; i < userArray.count ; i ++) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:i + 1 inSection:0];
        ContactGroupUserCollectionViewCell *cell = (ContactGroupUserCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
        [cell.deleteButton setHidden:!cell.deleteButton.isHidden];
    }
}
- (void)deleteUserButtonClicked:(UIButton *)sender {
    NSInteger tag = sender.tag;
    GroupChatFriend *deleteFriend = userArray[tag];
    //    Friends *deleteFriend = userArray[tag];
    [self deleteUserWithGroupChatFriend:deleteFriend];
}
#pragma mark - Actions
- (IBAction)backButtonClicked:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}
- (IBAction)quitButtonClicked:(id)sender {
    if (isCanDeleteUser) {
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view.window animated:YES];
        NSDictionary *param = @{
                                @"groupid": _currentGroupChat.groupId,
                                @"userid": [[NSUserDefaults standardUserDefaults]objectForKey:@"UserId"],
                                @"usertype": [[NSUserDefaults standardUserDefaults] objectForKey:@"UserType"]
                                };
        [ChatAPI delChatGroupWithParameters:param success:^(AFHTTPRequestOperation *operation, id responseObject) {
            hud.mode = MBProgressHUDModeText;
            hud.labelText = [responseObject firstObject][@"msg"];
            [hud hide:YES afterDelay:1.0f];
            if ([[responseObject firstObject][@"state"]intValue] == 1) {
                [_currentGroupChat MR_deleteEntity];
                [[NSManagedObjectContext MR_defaultContext]MR_saveToPersistentStoreAndWait];
                NSMutableArray *allViewControllers = [NSMutableArray arrayWithArray:[self.navigationController viewControllers]];
                for (UIViewController *aViewController in allViewControllers) {
                    if ([aViewController isKindOfClass:[ContactGroupListTableViewController class]]) {
                        [self.navigationController popToViewController:aViewController animated:NO];
                    }
                }
            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"%@",error.localizedDescription);
            hud.mode = MBProgressHUDModeText;
            hud.labelText = error.localizedDescription;
            [hud hide:YES afterDelay:1.5f];
            
        }];
        
    }else{
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view.window animated:YES];
        NSDictionary *param = @{@"id": userGroupId,
                                @"groupid" : _currentGroupChat.groupId,
                                @"userid": [[NSUserDefaults standardUserDefaults]objectForKey:@"UserId"],
                                @"usertype": [[NSUserDefaults standardUserDefaults] objectForKey:@"UserType"],
                                @"etype": @0
                                };
        [ChatAPI delChatUserWithParameters:param success:^(AFHTTPRequestOperation *operation, id responseObject) {
            NSLog(@"%@",responseObject);
            if ([[responseObject firstObject][@"state"]intValue] == 1) {
                [_currentGroupChat MR_deleteEntity];
                [[NSManagedObjectContext MR_defaultContext]MR_saveToPersistentStoreAndWait];
                NSMutableArray *allViewControllers = [NSMutableArray arrayWithArray:[self.navigationController viewControllers]];
                for (UIViewController *aViewController in allViewControllers) {
                    if ([aViewController isKindOfClass:[ContactGroupListTableViewController class]]) {
                        [self.navigationController popToViewController:aViewController animated:NO];
                    }
                }
            }
            hud.mode = MBProgressHUDModeText;
            hud.labelText = [responseObject firstObject][@"msg"];
            [hud hide:YES afterDelay:1.0f];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            NSLog(@"%@",error.localizedDescription);
            hud.mode = MBProgressHUDModeText;
            hud.labelText = error.localizedDescription;
            [hud hide:YES afterDelay:1.5f];
        }];
        
    }
    
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (!isCanDeleteUser && (indexPath.row == 0 || indexPath.row == 2)) {
        return 0;
    }
    return [super tableView:tableView heightForRowAtIndexPath:indexPath];
}


#pragma mark - UICollectionView Datasource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return userArray.count + (isCanDeleteUser ? 3 : 1);
}
- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    ContactGroupUserCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:ContactGroupUserCellIdentifier forIndexPath:indexPath];
    if (indexPath.item > 0 && indexPath.item < userArray.count + 1) {
        //        Friends *friend = userArray[indexPath.item - 1];
        GroupChatFriend *friend = userArray[indexPath.item - 1];
        [cell.nameLabel setText:friend.name];
        [cell.imageView sd_setImageWithURL:[NSURL URLWithString:friend.friend.icon]    placeholderImage:[UIImage imageNamed:@"details_uers_example_pic"]];
    }else if (indexPath.item == 0) {
        NSString *name = [[NSUserDefaults standardUserDefaults]objectForKey:@"UserRealName"];
        NSString *icon = [[NSUserDefaults standardUserDefaults] objectForKey:@"UserIcon"];
        [cell.nameLabel setText:name];
        [cell.imageView sd_setImageWithURL:[NSURL URLWithString:icon] placeholderImage:[UIImage imageNamed:@"details_uers_example_pic"]];
    }else if (indexPath.item == userArray.count + 1){
        [cell.nameLabel setText:@""];
        [cell.imageView setImage:[UIImage imageNamed:@"add_user_btn"]];
    }else if (indexPath.item == userArray.count + 2){
        [cell.nameLabel setText:@""];
        [cell.imageView setImage:[UIImage imageNamed:@"minus-user_btn"]];
    }
    [cell.deleteButton setHidden:YES];
    [cell.deleteButton setTag:indexPath.item - 1];
    [cell.deleteButton addTarget:self action:@selector(deleteUserButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    return cell;
}

#pragma mark - UICollectionView Delegate
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.item == 0) {
        return;
    }else if (indexPath.item == userArray.count + 1){
        [self performSegueWithIdentifier:@"ContactGroupDetailAddMemberSegueIdentifier" sender:nil];
    }else if (indexPath.item == userArray.count + 2){
        [self changeDeleteButtonState];
    }else{
        GroupChatFriend *groupFriend = userArray[indexPath.item - 1];
        Friends *friend = groupFriend.friend;
        if (friend.userType.intValue == 2) {
            [self performSegueWithIdentifier:@"ContactGroupUserDetailDoctorSegueIdentifier" sender:friend];
        }else{
            [self performSegueWithIdentifier:@"ContactGroupUserDetailMemberSegueIdentifier" sender:friend];
        }
    }
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    if ([segue.identifier isEqualToString:@"ContactGroupDetailInfoSegueIdentifier"]) {
        ContactGroupDetailInfoTableViewController *vc = [segue destinationViewController];
        [vc setGroupChat:_currentGroupChat];
    }else if ([segue.identifier isEqualToString:@"ContactGroupDetailAddMemberSegueIdentifier"]) {
        UINavigationController *nav = [segue destinationViewController];
        ContactMainViewController *contact = nav.viewControllers.firstObject;
        contact.contactMode = ContactMainViewControllerModeCreateGroup;
        //        NSMutableArray *array = [NSMutableArray array];
        //        for (GroupChatFriend *groupFriend in _currentGroupChat.member) {
        //            [array addObject:groupFriend.friend];
        //        }
        //        contact.selectedArray = array;
        contact.selectedArray = [_currentGroupChat.chat.user.allObjects mutableCopy];
        contact.didSelectFriend = ^(NSArray *friends){
            //            NSLog(@"%@",friends);
            [self addUserWithUserArray:friends];
        };
        
    }else if ([segue.identifier isEqualToString:@"ContactGroupUserDetailDoctorSegueIdentifier"]) {
        ContactDoctorFriendDetailTableViewController *vc = [segue destinationViewController];
        [vc setCurrentFriend:sender];
    }else if ([segue.identifier isEqualToString:@"ContactGroupUserDetailMemberSegueIdentifier"]) {
        ContactPeronsalFriendDetailTableViewController *vc = [segue destinationViewController];
        [vc setCurrentFriend:sender];
    }else if ([segue.identifier isEqualToString:@"ContactGroupInfoDetailSegueIdentifier"]) {
        ContactGroupNewGeneralViewController *vc = [segue destinationViewController];
        [vc setCurrentGroup:_currentGroupChat];
    }
    
}


- (IBAction)visiableSwitchValueChanged:(id)sender {
    NSDictionary *param = @{@"groupid": _currentGroupChat.groupId,
                            @"visible": self.visiableSwitch.isOn ? @1 : @0};
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view.window animated:YES];
    hud.labelText = @"设置中...";
    [ChatAPI updateChatGroupWithParameters:param success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"%@",responseObject);
        hud.mode = MBProgressHUDModeText;
        if ([[responseObject firstObject][@"state"]intValue] == 1) {
            hud.labelText = self.visiableSwitch.isOn ? @"附近的人将能够搜索到该群": @"附近的人将不能搜索到该群";
        }else{
            hud.labelText = @"设置失败";
        }
        [hud hide:YES afterDelay:1.0f];
        [self fetchGroupInfo];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"%@",error.localizedDescription);
        hud.mode = MBProgressHUDModeText;
        hud.labelText = error.localizedDescription;
        [hud hide:YES afterDelay:1.5f];
    }];
}

- (IBAction)disturbSwitchValueChanged:(id)sender {
    NSDictionary *param = @{@"groupid": _currentGroupChat.groupId,
                            @"allowdisturb": self.noDisturbSwitch.isOn ? @1 : @0};
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view.window animated:YES];
    hud.labelText = @"设置中...";
    [ChatAPI updateChatGroupWithParameters:param success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"%@",responseObject);
        hud.mode = MBProgressHUDModeText;
        if ([[responseObject firstObject][@"state"]intValue] == 1) {
            //            hud.labelText = [responseObject firstObject][@"msg"];
            hud.labelText = self.visiableSwitch.isOn ? @"您将不会收到该群消息提醒": @"您将收到该群消息提醒";
        }else{
            hud.labelText = @"设置失败";
        }
        [hud hide:YES afterDelay:1.0f];
        [self fetchGroupInfo];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"%@",error.localizedDescription);
        hud.mode = MBProgressHUDModeText;
        hud.labelText = error.localizedDescription;
        [hud hide:YES afterDelay:1.5f];
    }];
    
}
@end
