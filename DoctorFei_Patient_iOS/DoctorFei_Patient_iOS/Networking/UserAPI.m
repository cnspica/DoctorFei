//
//  UserAPI.m
//  DoctorFei_iOS
//
//  Created by GuJunjia on 14/12/6.
//
//

#import "UserAPI.h"
#define kMethodUserInfomation @"get.user.infomation"
#define kMethodFeedBack @"set.feed.back"
#define kMethodSearchUser @"get.search.user"
#define kMethodGetDoctorInfomation @"get.doctor.information"
#define kMethodGetMemberInfomation @"get.member.information"
#define kMethodCheckFriend @"get.user.checkfriend"
#define kMethodCheckFriendIsRegister @"get.friend.check"
#define kMethodCheckNewList @"get.friend.newlist"

@implementation UserAPI

+ (void)getUserInfomationWithParameters: (id)parameters success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure {
    [[self sharedManager]defaultGetWithMethod:kMethodUserInfomation WithParameters:parameters success:success failure:failure];
}

+ (void)setFeedBackWithParameters: (id)parameters success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure {
    [[self sharedManager]defaultGetWithMethod:kMethodFeedBack WithParameters:parameters success:success failure:failure];
}
+ (void)searchUserWithParameters: (id)parameters success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure {
    [[self sharedManager]defaultGetWithMethod:kMethodSearchUser WithParameters:parameters success:success failure:failure];
}
+ (void)getDoctorInfomationWithParameters: (id)parameters success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure {
    [[self sharedManager]defaultGetWithMethod:kMethodGetDoctorInfomation WithParameters:parameters success:success failure:failure];
}
+ (void)getMemberInfomationWithParameters: (id)parameters success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure {
    [[self sharedManager]defaultGetWithMethod:kMethodGetMemberInfomation WithParameters:parameters success:success failure:failure];
}
+ (void)checkFriendWithParameters: (id)parameters success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure {
    [[self sharedManager]defaultGetWithMethod:kMethodCheckFriend WithParameters:parameters success:success failure:failure];
}
+ (void)checkFriendIsRegisterWithParameters: (id)parameters success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure {
    [[self sharedManager] defaultPostWithMethod:kMethodCheckFriendIsRegister WithParameters:nil WithBodyParameters:parameters success:success failure:failure];
}

+ (void)getFriendNewListWithParameters: (id)parameters success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure {
    [[self sharedManager]defaultGetWithMethod:kMethodCheckNewList WithParameters:parameters success:success failure:failure];
}
@end
