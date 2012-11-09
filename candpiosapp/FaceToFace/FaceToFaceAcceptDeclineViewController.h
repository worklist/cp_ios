//
//  FaceToFaceInviteController.h
//  candpiosapp
//
//  Created by Alexi (Love Machine) on 2012/02/14.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UserProfileViewController.h"

@interface FaceToFaceAcceptDeclineViewController : UIViewController <UITextFieldDelegate>

@property (strong, nonatomic) CPUser *user;
@property (strong, nonatomic) UserProfileViewController *userProfile;
@property (weak, nonatomic) IBOutlet UIView *actionBar;
@property (weak, nonatomic) IBOutlet UILabel *actionBarHeader;
@property (weak, nonatomic) IBOutlet UIButton *f2fAcceptButton;
@property (weak, nonatomic) IBOutlet UIButton *f2fDeclineButton;
@property (weak, nonatomic) IBOutlet UIView *viewUnderToolbar;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UINavigationBar *navigationBar;

- (IBAction)acceptContactRequest;
- (IBAction)declineContactRequest;

@end
