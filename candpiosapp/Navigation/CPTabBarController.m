//
//  CPTabBarController.m
//  candpiosapp
//
//  Created by Stephen Birarda on 4/2/12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "CPTabBarController.h"
#import "FeedViewController.h"
#import "CPTabBarControllerView.h"
#import "CPCheckinHandler.h"

@implementation CPTabBarController

// TODO: get rid of the currentVenueID here, let's keep that in NSUserDefaults (my bad)
@synthesize currentVenueID = _currentVenueID;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIImage *bgImage = [CPThinTabBar backgroundImage];
    
    CGFloat heightDiff = self.tabBar.frame.size.height - bgImage.size.height;
    
    // change the frame of the tab bar
    self.tabBar.frame = CGRectMake(self.tabBar.frame.origin.x, 
                                   self.tabBar.frame.origin.y + heightDiff, 
                                   self.tabBar.frame.size.width, 
                                   self.tabBar.frame.size.height - heightDiff);
    
    // be the tabBarController of the tab bar
    // so that it can send its buttons actions back to us
    // this is a weak pointer    
    self.thinBar.tabBarController = self;
    
    // make sure the CPTabBarController's views take up the extra space
    CGRect viewFrame = [[self.view.subviews objectAtIndex:0] frame];
    viewFrame.size.height += heightDiff;
    [[self.view.subviews objectAtIndex:0] setFrame:viewFrame];
    
    [self refreshTabBar];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(refreshTabBar)
                                                 name:@"LoginStateChanged"
                                               object:nil];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"LoginStateChanged" object:nil];
}

- (void)setSelectedIndex:(NSUInteger)selectedIndex
{
    // only try and change things if this isn't already our selected index
    if (selectedIndex != self.selectedIndex) {
        if (self.selectedIndex > 0 && 
            self.selectedIndex <= 4 && 
            selectedIndex == 0 && 
            ![CPUserDefaultsHandler currentUser]) {
            // don't change the selected index here
            // just show the login banner
            [self promptForLoginToSeeLogbook:CPAfterLoginActionShowLogbook];
        } else {
            // switch to the designated VC
            [super setSelectedIndex:selectedIndex];

            // move the green line to the right spot
            [self.thinBar moveGreenLineToSelectedIndex:selectedIndex];
        }
    }
}

- (CPThinTabBar *)thinBar
{
    return (CPThinTabBar *)self.tabBar;
}

- (IBAction)tabBarButtonPressed:(id)sender
{
    // switch to the tab the user just tapped
    int tabIndex = ((UIButton *)sender).tag;
    self.selectedIndex = tabIndex;
}

- (void)refreshTabBar
{
    if (![CPUserDefaultsHandler currentUser]) {
        UIStoryboard *signUpStoryboard = [UIStoryboard storyboardWithName:@"SignupStoryboard_iPhone" bundle:nil];
        UINavigationController *signupController = [signUpStoryboard instantiateInitialViewController];
        
        NSMutableArray *tabVCArray = [self.viewControllers mutableCopy];
        [tabVCArray replaceObjectAtIndex:3 withObject:signupController];
        self.viewControllers = tabVCArray;
        
        // tell the thinBar to update the button
        [self.thinBar refreshLastTab:NO];
    } else {
        UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"MainStoryboard_iPhone"
                                                                 bundle:nil];
        UINavigationController *contactsController = [mainStoryboard instantiateViewControllerWithIdentifier:@"contactsNavigationController"];

        NSMutableArray *tabVCArray = [self.viewControllers mutableCopy];
        [tabVCArray replaceObjectAtIndex:3 withObject:contactsController];
        self.viewControllers = tabVCArray;
        
        // tell the thinBar to update the button
        [self.thinBar refreshLastTab:YES];
    }  
}

- (void)questionButtonPressed:(id)sender
{  
    self.thinBar.actionButtonState = CPThinTabBarActionButtonStatePlus;

    if (![CPUserDefaultsHandler currentUser]) {
        [CPCheckinHandler sharedHandler].afterCheckinAction = CPAfterCheckinActionNewQuestion;
        [self promptForLoginToSeeLogbook:CPAfterLoginActionPostQuestion];
    } else if (![CPUserDefaultsHandler isUserCurrentlyCheckedIn]) {

        UIAlertView *checkinAlert =  [[UIAlertView alloc] initWithTitle:@"Please check in at venue to post a question."
                                                                message:nil
                                                               delegate:self
                                                      cancelButtonTitle:@"Cancel"
                                                      otherButtonTitles:@"Checkin", nil];
        [checkinAlert show];
    } else {
        [self showFeedViewController:CPPostTypeQuestion];
    }
}

- (IBAction)updateButtonPressed:(id)sender
{
    // hide the action menu
    self.thinBar.actionButtonState = CPThinTabBarActionButtonStatePlus;
    
    if (![CPUserDefaultsHandler currentUser]) {
        // if we don't have a current user then we need to just show the login banner
        [self promptForLoginToSeeLogbook:CPAfterLoginActionAddNewLog];
    } else if (![CPUserDefaultsHandler isUserCurrentlyCheckedIn]) {
        // if we have a user but they aren't checked in
        // they need to be checked in before they can log
        
        UIAlertView *checkinAlert =  [[UIAlertView alloc] initWithTitle:@"Choose one"
                                                                message:nil 
                                                               delegate:self 
                                                      cancelButtonTitle:@"Cancel"
                                                      otherButtonTitles:@"Checkin", @"Post to Feed", nil];
        [checkinAlert show];
        
    } else {
        [self showFeedViewController:CPPostTypeUpdate];
    }
}

- (void)showFeedViewController:(CPPostType)postType
{
    
    // the user is logged in and checked in
    // we need to bring them to the feed VC and display the feed for the venue they are checked into
    
    // grab the FeedViewController
    UINavigationController *feedNC = [self.viewControllers objectAtIndex:0];
    FeedViewController *feedVC = [feedNC.viewControllers objectAtIndex:0];
    feedVC.postType = postType;
    
    if ([CPCheckinHandler sharedHandler].afterCheckinAction == CPAfterCheckinActionNewPost) {
        // this is for a forced checkin
        // so the feedVC is already being show
        // just tell it we want a new post
        feedVC.newPostAfterLoad = YES;
    } else {
        // if the FeedViewController doesn't have our the current venue's feed as it's selectedVenueFeed
        // then alloc-init one and set it properly
        if ([CPUserDefaultsHandler currentVenue].venueID != feedVC.selectedVenueFeed.venue.venueID) {
            CPVenueFeed *currentVenueFeed = [[CPVenueFeed alloc] init];
            currentVenueFeed.venue = [CPUserDefaultsHandler currentVenue];
            
            feedVC.selectedVenueFeed = currentVenueFeed;
        } 
        
        // the user is already on the feed for the right venue
        // so tell the feedVC that we want to add a new post
        
        if (self.selectedIndex == 0) {
            // the feedVC is on screen so we want a new post right now
            [feedVC newPost:nil];
        } else {
            // the feedVC isn't on screen yet so tell we want a new post after it loads
            feedVC.newPostAfterLoad = YES;
            self.selectedIndex = 0;
        }
    }   
}

- (IBAction)checkinButtonPressed:(id)sender
{
    self.thinBar.actionButtonState = CPThinTabBarActionButtonStatePlus;
    
    [CPCheckinHandler sharedHandler].afterCheckinAction = CPAfterCheckinActionShowFeed;
    [[CPCheckinHandler sharedHandler] presentCheckinModalFromViewController:self];
}

- (void)promptForLoginToSeeLogbook:(CPAfterLoginAction)action
{
    // set the settingsMenuController CPAfterLoginAction so it knows where to go after login
    [CPAppDelegate settingsMenuController].afterLoginAction = action;
    
    // show the login banner
    [CPAppDelegate showLoginBanner];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == alertView.firstOtherButtonIndex) {        
        [CPCheckinHandler sharedHandler].afterCheckinAction = CPAfterCheckinActionNewPost;      
        [[CPCheckinHandler sharedHandler] presentCheckinModalFromViewController:self];
    } else if (buttonIndex != alertView.cancelButtonIndex) {
        // this is the "Post to Feed" button
        // tell the Feed TVC that it needs to show only postable feeds
        
        FeedViewController *feedVC = [[[self.viewControllers objectAtIndex:0] viewControllers] objectAtIndex:0];
        
        // tell the feedVC to switch to showing only postable feeds
        [feedVC showOnlyPostableFeeds];
        
        // make sure our selected index is 0
        self.selectedIndex = 0;
    }
}

@end
