#ifndef PTIMAGEUTIL_H
#define PTIMAGEUTIL_H

#import "constants.h"

@class UIImage;

class PtImageUtil {
  static CGColorSpaceRef colorspace;
public:
  
  static UIImage* uint16toUIImage(uint16* buf, int imgw, int x0, int y0, int w, int h);
  static uint16* UIImagetoUint16(UIImage *img, int *imgw, int *imgh);
};

#endif //  PTIMAGEUTIL_H
