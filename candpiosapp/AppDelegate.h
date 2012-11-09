//
//  AppDelegate.h
//  candpiosapp
//
//  Created by David Mojdehi on 12/30/11.
//  Copyright (c) 2011 Coffee and Power Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Settings.h"
#import "UAirship.h"
#import "UAPush.h"
#import "SettingsMenuController.h"
#import "CPTabBarController.h"
#import <CoreLocation/CoreLocation.h>
#import "Flurry.h"

@class AFHTTPClient;
@class CPUser;

@interface AppDelegate : UIResponder <UIApplicationDelegate, UIAlertViewDelegate, CLLocationManagerDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic, readonly) Settings *settings;
@property (strong, nonatomic, readonly) CLLocationManager *locationManager;
@property (strong, nonatomic, readonly) CLLocation *currentOrDefaultLocation;
@property (strong, nonatomic) SettingsMenuController *settingsMenuController;
@property (strong, nonatomic) CPTabBarController *tabBarController;
           
- (void)pushAliasUpdate;
- (void)saveSettings;
- (void)loadVenueView:(NSString *)venueName;
- (void)toggleSettingsMenu;
- (void)setupUrbanAirship;
- (NSCache *)appCache;


void uncaughtExceptionHandler(NSException *exception);
void SignalHandler(int sig);

@end

