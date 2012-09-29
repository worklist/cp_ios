//
//  UserVoice.h
//  UserVoice
//
//  Created by UserVoice on 10/19/09.
//  Copyright 2009 UserVoice Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UVStyleSheet.h"
#import "UVDelegate.h"
#import "UVConfig.h"

@interface UserVoice : NSObject {
}

// Modally present the UserVoice interface
+ (void)presentUserVoiceInterfaceForParentViewController:(UIViewController *)parentViewController andConfig:(UVConfig *)config;

// Modally present the UserVoice contact form
+ (void)presentUserVoiceContactUsFormForParentViewController:(UIViewController *)parentViewController andConfig:(UVConfig *)config;

// Modally present the UserVoice interface, but go directly to the forum screen
+ (void)presentUserVoiceForumForParentViewController:(UIViewController *)parentViewController andConfig:(UVConfig *)config;

// Set a <UVDelegate> to receive callbacks
+ (void)setDelegate:(id<UVDelegate>)delegate;

// Get the current <UVDelegate>
+ (id<UVDelegate>)delegate;

// Get the current version number of the iOS SDK
+ (NSString *)version;

/**
 * @deprecated Use [UserVoice presentUserVoiceModalInterfaceForParentViewController:andConfig:] instead.
 */
+ (void)presentUserVoiceModalViewControllerForParent:(UIViewController *)viewController andSite:(NSString *)site andKey:(NSString *)key andSecret:(NSString *)secret;
+ (void)presentUserVoiceModalViewControllerForParent:(UIViewController *)viewController andSite:(NSString *)site andKey:(NSString *)key andSecret:(NSString *)secret andSsoToken:(NSString *)token;
+ (void)presentUserVoiceModalViewControllerForParent:(UIViewController *)viewController andSite:(NSString *)site andKey:(NSString *)key andSecret:(NSString *)secret andEmail:(NSString *)email andDisplayName:(NSString *)displayName andGUID:(NSString *)guid;

@end
