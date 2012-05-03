//
//  ptpanelview.mm
//  touchpeinture
//
//  Created by SAkira on 09/01/31.
//  Copyright 2009 SAkira. All rights reserved.
//

#import "ptpanelview.h"
#import "singletonjunction.h"
#import "ptimageutil.h"

@implementation PtPanelView

@synthesize buf, img;

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
      info_string = nil;
      buf = NULL;
      img = NULL;
    }
    return self;
}

- (void)dealloc {
  if (info_string) [info_string release];
    [super dealloc];
}

- (void)drawRect:(CGRect)rect {

  if (!buf && !img) {
    [[UIColor grayColor] set];
    UIRectFill(rect);
    return;
  }

  uint w, h;
  CGSize s;

  s = [self bounds].size;
  w = s.width;
  h = s.height;
  
  if (! w * h) return;
  
  if (img) {
    [[UIColor whiteColor] set];
    UIRectFill(rect);
//    [img drawAtPoint:CGPointMake(0, 0)];
    [img drawInRect:self.bounds];
    [img release];
    img = nil;
  } else {
    UIImage *image = PtImageUtil::uint16toUIImage(buf, w,
						  0, 0, 
						  w, h);
//    [image drawAtPoint:CGPointMake(0, 0)];
    [image drawInRect:self.bounds];
  }

  if (info_string) {
    UIFont *tfont = [UIFont boldSystemFontOfSize:12];
    CGRect rect = [self bounds];
    rect.origin.y = rect.size.height / 5;

    [[UIColor whiteColor] set];
    [info_string drawInRect:rect
		 withFont:tfont
		 lineBreakMode:UILineBreakModeMiddleTruncation
		 alignment:UITextAlignmentCenter];

    rect.origin.x += 1;
    rect.origin.y += 1;
    [[UIColor blackColor] set];
    [info_string drawInRect:rect
		 withFont:tfont
		 lineBreakMode:UILineBreakModeMiddleTruncation
		 alignment:UITextAlignmentCenter];
  }
}



@end
