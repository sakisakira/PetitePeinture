//
//  ptpanelview.h
//  touchpeinture
//
//  Created by Saki Sakira on 09/01/31.
//  Copyright 2009. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "constants.h"

@interface PtPanelView : UIView {
@public
  uint16* buf;
  UIImage *img;

  NSString *info_string;
}

@property(assign, readwrite) uint16* buf;
@property(assign, readwrite) UIImage* img;

@end
