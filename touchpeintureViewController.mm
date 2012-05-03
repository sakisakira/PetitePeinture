//
//  touchpeintureAppDelegate.m
//  touchpeinture
//
//  Created by sakira on 08/08/18.
//  Copyright 2008. All rights reserved.
//

#import "touchpeintureViewController.h"
#import "ptview.h"
#import "ptpanelview.h"
#import "pttouchview.h"
#import "ptloupe.h"
#import "canvascontroller.h"
#import "singletonjunction.h"

@implementation touchpeintureViewController

@synthesize touchview, panel_view, opt_panel_view, baseview, ptview;
@synthesize loupe, cross;

- (void)loadView {
  [super loadView];
  ALog(@"PtView initializing");
	self.view.frame = [[UIScreen mainScreen] applicationFrame];
  baseview = [[PtPanelView alloc]
							initWithFrame:[[UIScreen mainScreen] applicationFrame]];
  ptview = [[PtView alloc] 
						initWithFrame:[[UIScreen mainScreen] 
													 applicationFrame]];
  panel_view = [[PtPanelView alloc]
								initWithFrame:CGRectMake(-10, 0, 10, 10)];
  opt_panel_view = [[PtPanelView alloc]
										initWithFrame:CGRectMake(-10, 0, 10, 10)];
  touchview = [[PtTouchView alloc] 
							 initWithFrame:[[UIScreen mainScreen] applicationFrame]];
  loupe = [[PtLoupe alloc]
					 initWithFrame:CGRectMake(-20, 0, 20, 20)];
  [touchview setup:ptview withCanvas:ptview->canvas];
  ptview.touchview = touchview;
  [loupe setup:ptview];
  ptview->canvas->setPtLoupe(loupe);
  cross = loupe.cross;

  SingletonJunction::panelview = self.panel_view;
  SingletonJunction::optpanelview = self.opt_panel_view;

  ALog(@"PtView initialized");
}

- (void)viewDidLoad {
  [super viewDidLoad];
  [ptview setupCanvas];
  [touchview setupTables];
}

- (void)dealloc {
  if (ptview) [ptview release];
  if (touchview) [touchview release];
  if (loupe) [loupe release];
  if (panel_view) [panel_view release];
  if (opt_panel_view) [opt_panel_view release];
  if (baseview) [baseview release];
  [super dealloc];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
  if (UI_USER_INTERFACE_IDIOM() == 
      UIUserInterfaceIdiomPad) {
    // iPad
    return (interfaceOrientation == UIInterfaceOrientationPortrait ||
            interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown);
  } else {
    // iPhone
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
  }
}


- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
	// Release anything that's not essential, such as cached data
}

- (void)setLoupeFollowsFinger:(bool)f {
  loupe.follow_finger = f;
}

- (void)setShiftNozoom:(bool)f {
  ptview.shift_nozoom = f;
}

@end
