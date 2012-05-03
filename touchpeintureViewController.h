//
//  touchpeintureViewController.h
//  touchpeinture
//
//  Created by sakira on 08/08/18.
//  Copyright 2008. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PtView;
@class PtPanelView;
@class PtTouchView;
@class PtLoupe;
@class PtLoupeCross;

@interface touchpeintureViewController : UIViewController {
  PtView *ptview;
  PtPanelView *baseview;
  PtPanelView *panel_view;
  PtPanelView *opt_panel_view;
  PtTouchView *touchview;
  PtLoupe *loupe;
  PtLoupeCross *cross;
}

@property(nonatomic, retain) PtView *ptview;
@property(nonatomic, retain) PtPanelView *baseview;
@property(nonatomic, retain) PtTouchView *touchview;
@property(nonatomic, retain) PtPanelView *panel_view;
@property(nonatomic, retain) PtPanelView *opt_panel_view;
@property(nonatomic, retain) PtLoupe *loupe;
@property(nonatomic, retain) PtLoupeCross *cross;

- (void)setLoupeFollowsFinger:(bool)f;
- (void)setShiftNozoom:(bool)f;

@end
