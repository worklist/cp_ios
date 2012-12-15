//
//  SignupController.m
//  candpiosapp
//
//  Created by David Mojdehi on 1/11/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "SignupController.h"
#import "Flurry.h"
#import "UIViewController+isModal.h"

@interface SignupController()

@property (weak, nonatomic) IBOutlet UIImageView *backgroundImageView;
@property (weak, nonatomic) IBOutlet UIButton *linkedinLoginButton;
@property (weak, nonatomic) IBOutlet UIButton *dismissButton;

@end

@implementation SignupController

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [Flurry logEvent:@"signupScreen"];
    
    // if this is being presented inside the app from the UITabBarController
    // then don't show the later button
    if (!self.isModal) {
        [self.dismissButton removeFromSuperview];
        
        // if the user is currently on the 4th tab
        // then bring them to the map once they login
        [CPAppDelegate settingsMenuController].afterLoginAction = CPAfterLoginActionShowMap;
    }
    
    if ([CPUtils isDeviceWithFourInchDisplay]) {
        self.backgroundImageView.image = [UIImage imageNamed:@"Default-568h"];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationItem setHidesBackButton:YES animated:NO];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    self.title = @"Log In";
    // Set the back button that will appear in pushed views
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Back" 
                                                                             style:UIBarButtonItemStyleDone 
                                                                            target:nil 
                                                                            action:nil];
    // prepare for the icons to fade in
    self.linkedinLoginButton.alpha = 0.0;
    self.dismissButton.alpha = 0.0;
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // fade in the icons to direct user attention at them
    [UIView animateWithDuration:0.3 animations:^{
        self.linkedinLoginButton.alpha = 1.0;
        self.dismissButton.alpha = 1.0;
    }];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self.navigationController setNavigationBarHidden:NO animated:animated];
}

- (IBAction)loginWithLinkedInTapped:(id)sender 
{
	// Handle LinkedIn login
	// The LinkedIn login object will handle the sequence that follows
    [self performSegueWithIdentifier:@"ShowLinkedInLoginController" sender:sender];
    [Flurry logEvent:@"startedLinkedInLogin"];
}

- (IBAction) dismissClick:(id)sender
{
    // make sure the selected index is 1 so it goes to the map
    [CPAppDelegate tabBarController].selectedIndex = 0;
    [self dismissModalViewControllerAnimated:YES];
    [Flurry logEvent:@"skippedSignup"];
}

@end
