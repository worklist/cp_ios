//
//  ProfileNotificationsViewController.m
//  candpiosapp
//
//  Created by Stojce Slavkovski on 05.5.12.
//  Copyright (c) 2012 Coffee and Power Inc. All rights reserved.
//

#import "ProfileNotificationsViewController.h"
#import "ActionSheetDatePicker.h"
#import "PushModalViewControllerFromLeftSegue.h"

#define kInVenueText @"in venue"
#define kInCityText @"in city"
#define kContactsText @"contacts"

#define kNotificationsViewPosition 295
#define kAnyoneChatViewPosition 75
#define kQuietTimeOffset 40

@interface ProfileNotificationsViewController () <UIActionSheetDelegate>

@property (strong, nonatomic) NSDate *quietTimeFromDate;
@property (strong, nonatomic) NSDate *quietTimeToDate;
@property (weak, nonatomic) IBOutlet UIButton *venueButton;
@property (weak, nonatomic) IBOutlet UISwitch *notificationsSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *checkedInOnlySwitch;
@property (weak, nonatomic) IBOutlet UISwitch *notifyOnEndorsementSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *notifyHeadlineChangesSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *quietTimeSwitch;
@property (weak, nonatomic) IBOutlet UIView *anyoneChatView;
@property (weak, nonatomic) IBOutlet UIButton *quietFromButton;
@property (weak, nonatomic) IBOutlet UIButton *quietToButton;
@property (weak, nonatomic) IBOutlet UISwitch *contactsOnlyChatSwitch;
@property (weak, nonatomic) IBOutlet UILabel *chatNotificationLabel;
@property (weak, nonatomic) IBOutlet UIView *dimView;
@property (weak, nonatomic) IBOutlet UIView *fromToSuperview;
@property (weak, nonatomic) IBOutlet UIView *notificationsView;

- (void)setVenue:(NSString *)setting;

@end

@implementation ProfileNotificationsViewController

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    [self venueButton].titleEdgeInsets = UIEdgeInsetsMake(0, 10, 0, 10);
    
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];    
    [self loadNotificationSettings];
}

-(void)viewDidDisappear:(BOOL)animated
{
    [self saveNotificationSettings];
    [super viewDidDisappear:animated];
}

#pragma mark - Api calls
- (void)loadNotificationSettings
{
    [SVProgressHUD show];
    [CPapi getNotificationSettingsWithCompletition:^(NSDictionary *json, NSError *err) {
        BOOL error = [[json objectForKey:@"error"] boolValue];
        if (error) {
            [self dismissModalViewControllerAnimated:YES];
            NSString *message = @"There was a problem getting your data!\nPlease logout and login again.";
            [SVProgressHUD dismissWithError:message
                                 afterDelay:kDefaultDismissDelay];
        } else {

            NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
            [dateFormat setDateFormat:@"HH:mm:ss"];
            [dateFormat setTimeZone:[NSTimeZone localTimeZone]];
            
            NSDictionary *dict = [json objectForKey:@"payload"];

            NSString *receiveNotifications = (NSString *)[dict objectForKey:@"receive_push_notifications"];
            [[self notificationsSwitch] setOn:[receiveNotifications isEqualToString:@"1"]];
            [self notificationSwitchChanged:self.notificationsSwitch];

            NSString *venue = (NSString *)[dict objectForKey:@"push_distance"];
            [self setVenue:venue];

            NSString *checkInOnly = (NSString *)[dict objectForKey:@"checked_in_only"];
            [[self checkedInOnlySwitch] setOn:[checkInOnly isEqualToString:@"1"]];

            NSString *notifyOnEndorsement = [dict objectForKey:@"push_contacts_endorsement"];
            [[self notifyOnEndorsementSwitch] setOn:[notifyOnEndorsement isEqualToString:@"1"]];

            NSString *notifyHealdineChanges = [dict objectForKey:@"push_headline_changes"];
            [[self notifyHeadlineChangesSwitch] setOn:[notifyHealdineChanges isEqualToString:@"1"]];

            NSString *quietTime = (NSString *)[dict objectForKey:@"quiet_time"];
            [[self quietTimeSwitch] setOn:[quietTime isEqualToString:@"1"]];
            [self setQuietTime:self.quietTimeSwitch.on];
            
            NSString *quietTimeFrom = (NSString *)[dict objectForKey:@"quiet_time_from"];
            if ([quietTimeFrom isKindOfClass:[NSNull class]]) {
                quietTimeFrom = @"20:00:00";
            }
            
            @try {
                self.quietTimeFromDate = [dateFormat dateFromString:quietTimeFrom];
            }
            @catch (NSException* ex) {
                self.quietTimeFromDate = [dateFormat dateFromString:@"7:00"];
            }
            
            [[self quietFromButton] setTitle:[self setTimeText:self.quietTimeFromDate]
                                    forState:UIControlStateNormal];

            
            NSString *quietTimeTo = (NSString *)[dict objectForKey:@"quiet_time_to"];
            if ([quietTimeTo isKindOfClass:[NSNull class]]) {
                quietTimeTo = @"07:00:00";
            }
            
            @try {
                self.quietTimeToDate = [dateFormat dateFromString:quietTimeTo];
            }
            @catch (NSException* ex) {
                self.quietTimeToDate = [dateFormat dateFromString:@"19:00"];
            }
            
            [[self quietToButton] setTitle:[self setTimeText:self.quietTimeToDate]
                                  forState:UIControlStateNormal];

            NSString *contactsOnlyChat = (NSString *)[dict objectForKey:@"contacts_only_chat"];
            [[self contactsOnlyChatSwitch] setOn:[contactsOnlyChat isEqualToString:@"0"]];

            [[self chatNotificationLabel] setHidden:self.contactsOnlyChatSwitch.on];

            [SVProgressHUD dismiss];
        }
    }];
}

- (void)saveNotificationSettings
{
    NSString *distance = @"city";
    
    if ([self.venueButton.currentTitle isEqualToString:kInVenueText]) {
        distance = @"venue";
    }
    
    else if ([self.venueButton.currentTitle isEqualToString:kContactsText]) {
        distance = @"contacts";
    }

    [CPapi setNotificationSettingsForDistance:distance
                         receiveNotifications:self.notificationsSwitch.on
                                 andCheckedId:self.checkedInOnlySwitch.on
                       receiveContactEndorsed:self.notifyOnEndorsementSwitch.on
                        contactHeadlineChange:self.notifyHeadlineChangesSwitch.on
                                    quietTime:self.quietTimeSwitch.on
                                quietTimeFrom:[self quietTimeFromDate]
                                  quietTimeTo:[self quietTimeToDate]
                      timezoneOffsetInSeconds:[[NSTimeZone defaultTimeZone] secondsFromGMT]
                         chatFromContactsOnly:!self.contactsOnlyChatSwitch.on];
}

#pragma mark - UI Events
-(IBAction)gearPressed:(id)sender
{
    [self dismissPushModalViewControllerFromLeftSegue];
}

- (IBAction)notificationSwitchChanged:(UISwitch *)sender
{
    [UIView animateWithDuration:0.3
                     animations:^{
                         self.dimView.alpha = sender.on ? 0 : 1;
                         self.dimView.userInteractionEnabled = !sender.on;
                     }];
}


- (IBAction)quietFromClicked:(UIButton *)sender
{
    [ActionSheetDatePicker showPickerWithTitle:@"Select Quiet Time From"
                                datePickerMode:UIDatePickerModeTime
                                  selectedDate:[self quietTimeFromDate]
                                        target:self
                                        action:@selector(timeWasSelected:element:)
                                        origin:sender];
}

- (IBAction)quietToClicked:(UIButton *)sender
{
    [ActionSheetDatePicker showPickerWithTitle:@"Select Quiet Time To"
                                datePickerMode:UIDatePickerModeTime
                                  selectedDate:[self quietTimeToDate]
                                        target:self
                                        action:@selector(timeWasSelected:element:)
                                        origin:sender];
}


- (void)timeWasSelected:(NSDate *)selectedTime element:(id)element
{
    UIButton *button = (UIButton *)element;
    [button setTitle:[self setTimeText:selectedTime] forState:UIControlStateNormal];
    if (button.tag == 1) {
        self.quietTimeFromDate = selectedTime;
    } else {
        self.quietTimeToDate = selectedTime;
    }
}

- (IBAction)quietTimeValueChanged:(UISwitch *)sender
{
    [self setQuietTime:sender.on];
}

- (IBAction)anyoneChatSwitchChanged:(id)sender 
{
    [[self chatNotificationLabel] setHidden:self.contactsOnlyChatSwitch.on];
}

- (IBAction)selectVenueCity:(UIButton *)sender 
{
    UIActionSheet *actionSheet = [[UIActionSheet alloc]
                                  initWithTitle:@"Show me new check-ins from:"
                                  delegate:self
                                  cancelButtonTitle:@"Cancel"
                                  destructiveButtonTitle:nil
                                  otherButtonTitles:@"City", @"Venue", @"Contacts", nil
                                  ];
    [actionSheet showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) {
        [self setVenue:@"city"];
    } else if (buttonIndex == 1) {
        [self setVenue:@"venue"];
    } else if (buttonIndex == 2) {
        [self setVenue:@"contacts"];
    }
    // Do nothing if "Cancel" was hit
}

- (void)setVenue:(NSString *)setting
{
    NSMutableString *title = [NSMutableString stringWithString:kInCityText];
    
    if ([setting isEqualToString:@"venue"]) {
        [title setString:kInVenueText];   
    }
    else if ([setting isEqualToString: @"contacts"]) {
        [title setString:kContactsText];   
    }
    
    [[self venueButton] setTitle: title
                        forState:UIControlStateNormal];
}

- (void)setQuietTime:(BOOL)quietTime
{
    [UIView animateWithDuration:0.3 animations:^ {
        CGRect anyoneChatFrame = self.anyoneChatView.frame;
        CGRect notificationsFrame = self.notificationsView.frame;

        if (quietTime) {
            anyoneChatFrame.origin.y = kNotificationsViewPosition;
            notificationsFrame.origin.y = kAnyoneChatViewPosition;
        } else {
            notificationsFrame.origin.y = kAnyoneChatViewPosition - kQuietTimeOffset;
            anyoneChatFrame.origin.y = kNotificationsViewPosition - kQuietTimeOffset;
        }
        self.anyoneChatView.frame = anyoneChatFrame;
        self.notificationsView.frame = notificationsFrame;
    }];
}

- (NSString *)setTimeText:(NSDate *)timeValue
{
    NSDateFormatter *timeFormatter = [[NSDateFormatter alloc]init];
    timeFormatter.dateFormat = @"HH:mm";
    timeFormatter.timeStyle = NSDateFormatterShortStyle;
    NSString *dateString = [timeFormatter stringFromDate: timeValue];
    
    return dateString;
}
- (void)viewDidUnload {
    [self setNotificationsView:nil];
    [super viewDidUnload];
}
@end
