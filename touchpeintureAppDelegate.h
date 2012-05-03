//
//  touchpeintureAppDelegate.h
//  touchpeinture
//
//  Created by sakira on 08/08/18.
//  Copyright 2008. All rights reserved.
//

#import <UIKit/UIKit.h>

@class touchpeintureViewController;

@interface touchpeintureAppDelegate : NSObject <UIApplicationDelegate> {
	IBOutlet UIWindow *window;
	IBOutlet touchpeintureViewController *viewController;
}

@property (nonatomic, retain) UIWindow *window;
@property (nonatomic, retain) touchpeintureViewController *viewController;

@end

