//
//  CPUserSessionHandler.m
//  candpiosapp
//
//  Created by Stephen Birarda on 8/9/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "CPUserSessionHandler.h"
#import "CPCheckinHandler.h"
#import "PushModalViewControllerFromLeftSegue.h"
#import "SSKeychain.h"
#import "CPConstants.h"
#import "LinkedInLoginController.h"

@implementation CPUserSessionHandler

static CPUserSessionHandler *sharedHandler;

+ (void)initialize
{
    if(!sharedHandler) {
        sharedHandler = [[self alloc] init];
    }
}

+ (void)performAfterLoginActions
{
    // make sure the CPAppDelegate's locationManager is lazily instantiated so it is ready to use
    [CPAppDelegate locationManager];
    
    // we have a current user so we are good to ask for push and sync the user
    
    // doesn't matter if this is called after UA has already taken off, the AppDelegate won't do it twice
    [CPAppDelegate setupUrbanAirship];
    [CPAppDelegate pushAliasUpdate];
    
    [CPUserSessionHandler syncCurrentUserWithWebAndCheckValidLogin];
}

+ (void)performAppVersionCheck
{
    // here we're going to check what the user's previously registered app version was
    // this allows us to force them to login again if required
    // or to tell them to update
    NSString *appVersion = [CPUserDefaultsHandler lastLoggedAppVersion];
    
    NSLog(@"The last logged app version for this user is %@.", appVersion);
    
    if (!appVersion || [appVersion doubleValue] < 1.3) {
        // we either don't have a logged version or it's less than our current baseline
        // kill the current user object
        NSLog(@"Forcing logout based on app version check.");
        [self logoutEverything];
    }
    
    NSString *currentVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    // set the kUDLastLoggedAppVersion to the current version if there has been a change
    if (!appVersion || [appVersion doubleValue] < [currentVersion doubleValue]) {
        NSLog(@"Storing app version %@ in NSUserDefaults.", currentVersion);
        [CPUserDefaultsHandler setLastLoggedAppVersion:currentVersion];
    }
}

+ (void)flushCookiesForURL:(NSString*)url
{
	// clear out the cookies
	NSArray *httpscookies3 = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:[NSURL URLWithString:url]];
	
	[httpscookies3 enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		NSHTTPCookie *cookie = (NSHTTPCookie*)obj;
		[[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookie];
	}];
}

+ (void)logoutEverything
{
    // clear C&P cookies
    [CPUserSessionHandler flushCookiesForURL:kCandPWebServiceSecureUrl];

    // clear linkedin secrets & cookies
    [CPUserSessionHandler flushCookiesForURL:kLinkedInAPIUrl];
    [LinkedInLoginController linkedInLogout];
	    
    // alert to state change
    if ([CPUserDefaultsHandler currentUser]) {
        [CPUserDefaultsHandler setCurrentUser:nil];
    }
    
    [[CPCheckinHandler sharedHandler] setCheckedOut];
    
    // zero out pending contact requests
    [CPUserDefaultsHandler setNumberOfContactRequests:0];
}

+ (void)storeUserLoginDataFromDictionary:(NSDictionary *)userInfo
{
    NSString  *nickname = [userInfo objectForKey:@"nickname"];
    
    CPUser *currUser = [[CPUser alloc] init];
    currUser.nickname = nickname;
    currUser.userID = @([[userInfo objectForKey:@"id"] intValue]);
    [currUser setJoinDateFromJSONString:[userInfo objectForKey:@"join_date"]];
    currUser.profileURLVisibility = [userInfo objectForKey:@"profileURL_visibility"];
    
    // Reset the Automatic Checkins default to YES
    [CPUserDefaultsHandler setAutomaticCheckins:YES];
    [CPUserDefaultsHandler setCurrentUser:currUser];
    
    // give number of contact requests for this user to CPUserDefaults
    // it will update the badge on the tab bar item
    [CPUserDefaultsHandler setNumberOfContactRequests:[[userInfo objectForKey:@"number_of_contact_requests"] integerValue]];
}

+ (void)dismissSignupModalFromPresentingViewController
{
    NSLog(@"Login / Signup process deemed complete. Dismissing signup modal.");
    if (sharedHandler.signUpPresentingViewController) {
        [sharedHandler.signUpPresentingViewController dismissViewControllerAnimated:YES completion:nil];
    } else {
        // nil out the variable since the modal is being dismissed
        sharedHandler.signUpPresentingViewController = nil;
    }
}

+ (void)showSignupModalFromViewController:(UIViewController *)viewController
                                 animated:(BOOL)animated
{
    [self logoutEverything];
    UIStoryboard *signupStoryboard = [UIStoryboard storyboardWithName:@"SignupStoryboard_iPhone" bundle:nil];
    UINavigationController *signupController = [signupStoryboard instantiateInitialViewController];
    
    [viewController presentModalViewController:signupController animated:animated];
    
    sharedHandler.signUpPresentingViewController = viewController;
}

+ (void)syncCurrentUserWithWebAndCheckValidLogin
{
    CPUser *currentUser = [CPUserDefaultsHandler currentUser];
    if (currentUser.userID) {
        CPUser *webSyncUser = [[CPUser alloc] init];
        webSyncUser.userID = currentUser.userID;

        [webSyncUser loadUserResumeOnQueue:nil completion:^(NSError *error) {
            if (!error) {
                // TODO: make this a better solution by checking for a problem with the PHP session cookie in CPApi
                // for now if the email comes back null this person isn't logged in so we're going to send them to do that.
                if (![webSyncUser.email isKindOfClass:[NSNull class]]) {
                    [CPUserDefaultsHandler setCurrentUser:webSyncUser];
                }
            }
        }];
    }
}

+ (void)showLoginBanner
{
    if ([CPAppDelegate tabBarController].selectedIndex == kNumberOfTabsRightOfButton) {
        return;
    }
    
    SettingsMenuController *settingsMenuController = [CPAppDelegate settingsMenuController];
    
    settingsMenuController.blockUIButton.frame = CGRectMake(0.0,
                                                            settingsMenuController.loginBanner.frame.size.height,
                                                            [CPAppDelegate window].frame.size.width,
                                                            [CPAppDelegate window].frame.size.height);
    
    [settingsMenuController.view bringSubviewToFront:settingsMenuController.blockUIButton];
    [settingsMenuController.view bringSubviewToFront:[CPAppDelegate settingsMenuController].loginBanner];
    
    [UIView animateWithDuration:0.3 animations:^ {
        settingsMenuController.loginBanner.frame = CGRectMake(0.0, 0.0,
                                                              settingsMenuController.loginBanner.frame.size.width,
                                                              settingsMenuController.loginBanner.frame.size.height);
    }];
}

+ (void)hideLoginBannerWithCompletion:(void (^)(void))completion
{
    SettingsMenuController *settingsMenuController = [CPAppDelegate settingsMenuController];
    settingsMenuController.blockUIButton.frame = CGRectMake(0.0, 0.0, 0.0, 0.0);
    [settingsMenuController.view sendSubviewToBack:[CPAppDelegate settingsMenuController].blockUIButton];
    
    [UIView animateWithDuration:0.3 animations:^ {
        settingsMenuController.loginBanner.frame = CGRectMake(0.0,
                                                              -settingsMenuController.loginBanner.frame.size.height,
                                                              settingsMenuController.loginBanner.frame.size.width,
                                                              settingsMenuController.loginBanner.frame.size.height);
        
        if (completion) {
            completion();
        }
    }];
}


@end
