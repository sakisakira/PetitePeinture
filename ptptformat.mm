/**
 **	ptptformat.cpp
 **	PtptFormat
 **	by Saki Sakira <sakira@sun.dhis.portside.net>
 **	from 2003 August 5
 **     porting to iOS from 2010 September 16
 */

//#include <stdio.h>
//#include <qfile.h>
//#include <qbuffer.h>
//#include <qfileinfo.h>
//#include <qdir.h>
//#include <qpe/resource.h>

#include "ptptformat.h"

//const QString PtptFormat::FileIconPath = "image_ptpt.png";
//QImage PtptFormat::small_icon;
//int PtptFormat::small_icon_width;
//int PtptFormat::small_icon_height;
//int PtptFormat::thumbnail_width;
//int PtptFormat::thumbnail_height;
//QString PtptFormat::dot_icon;

PtptFormat::PtptFormat(uint n) {
  //  init_small_icon();
	this->data = [[NSMutableData alloc] init];

  setNumOfLayers(n, true);
}



PtptFormat::~PtptFormat(void) {
//	[this->data release];
#if 0
  for (uint k = 0; k < num_of_layers; k ++)
    if (layers[k])
      delete layers[k];
#endif
}


#if 0
void PtptFormat::init_small_icon(void) {
  QImage img;

  if (img.load(Resource::findPixmap(FileIconPath))) {
    small_icon_width = img.width() * small_icon_height
      / img.height();
    small_icon.create(small_icon_width, small_icon_height, 32);

    int x, y, x2, y2, xx, yy;
    uint32a r, g, b;
    QRgb rgb = qRgb(0, 0, 0);
    uint32a ratio, ratio2;
    ratio = img.height() / small_icon_height;
    ratio2 = ratio * ratio;
    if (ratio2 == 0) ratio2 = 1;
    for (y = 0; y < small_icon_height; y ++) {
      y2 = y * img.height() / small_icon_height;
      for (x = 0; x < small_icon_width; x ++) {
        x2 = x * img.height() / small_icon_width;
        r = g = b = 0;
        for (yy = 0; yy < (int)ratio; yy ++)
          for (xx = 0; xx < (int)ratio; xx ++) {
            if (img.valid(x2 + xx, y2 + yy))
              rgb = img.pixel(x2 + xx, y2 + yy);
            r += qRed(rgb);
            g += qGreen(rgb);
            b += qBlue(rgb);
          }
        small_icon.setPixel(x, y,
                            qRgb(r / ratio2,
                                 g / ratio2,
                                 b / ratio2));
      }
    }
  } else
    qFatal("cannot load image %s", FileIconPath.latin1());
}
#endif

void PtptFormat::setNumOfLayers(uint n, bool reset) {
  num_of_layers = n;
  layer_infos.resize(n);
  
  cur = 0;
  
  if (reset) {
    if (this->data) [this->data release];
    this->data = [[NSMutableData alloc]
	     initWithLength:0x20 + 0x10 * n];
  }
}

void PtptFormat::addLayer(UIImage *img) {
  if (cur >= num_of_layers) return;
  
  NSData *png = UIImagePNGRepresentation(img);
  uint start_o, size;
  
  start_o = [data length];
  size = [png length];

  [data appendData:png];
  
  layer_infos[cur].offset = start_o;
  layer_infos[cur].length = size;

  cur ++;
}

void PtptFormat::setCompositionMethod(uint k, uint m) {
  if (k < num_of_layers)
    layer_infos[k].comp_method = m;
}

void PtptFormat::setAlpha(uint k, uint alpha) {
  if (k < num_of_layers)
    layer_infos[k].alpha = alpha;
}

void PtptFormat::setPaperColor(uint k, const PtColor &col) {
  if (k < num_of_layers)
    layer_infos[k].paper_col = col;
}

#if 0
void PtptFormat::setTNHeight(int height) {
  if (height == TNHeightSmall) {
    thumbnail_height = TNHeightSmall;
    small_icon_height = 15;
    dot_icon = QString(".icons");
  } else if (height == TNHeightLarge) {
    thumbnail_height = TNHeightLarge;
    small_icon_height = 30;
    dot_icon = QString(".icons144");
  } else {
    thumbnail_height = small_icon_height = 0;
    dot_icon = QString("");
  }
}

void PtptFormat::setThumbnail(const QImage &img) {
//  const uint ptpt_ptn[] = {
//    0xeeee, 0xa4a4, 0xe4e4, 0x8484};
  int height = thumbnail_height;
  int width = height * img.width() / img.height();

  if (width < small_icon_width) width = small_icon_width;
  thumbnail.create(width, height, 32);

  int x, y, x2, y2, xx, yy;
  uint32a r, g, b;
  QRgb rgb = qRgb(0, 0, 0);
  uint32a ratio, ratio2;
  ratio = img.height() / height;
  ratio2 = ratio * ratio;
  if (ratio2 == 0) ratio2 = 1;
  for (y = 0; y < height; y ++) {
    y2 = y * img.height() / height;
    for (x = 0; x < width; x ++) {
      x2 = x * img.width() / width;
      r = g = b = 0;
      for (yy = 0; yy < (int)ratio; yy ++)
        for (xx = 0; xx < (int)ratio; xx ++) {
          if (img.valid(x2 + xx, y2 + yy))
            rgb = img.pixel(x2 + xx, y2 + yy);
          r += qRed(rgb);
          g += qGreen(rgb);
          b += qBlue(rgb);
        }
      thumbnail.setPixel(x, y, 
                       qRgb(r / ratio2, g / ratio2, b /ratio2));
    }
  }

  int x_offset = width - small_icon_width;
  int y_offset = height - small_icon_height;
  for (y = 0; y < small_icon_height; y ++)
    for (x = 0; x < small_icon_width; x ++)
      thumbnail.setPixel(x + x_offset, y + y_offset,
                       small_icon.pixel(x, y));
  
#if 0
  for (y = 0; y < 4; y ++)
    for (x = 0; x < 16; x ++)
      thumbnail.setPixel(width - 16 + x, height - 4 + y,
                       (ptpt_ptn[y] & (0x8000 >> x)) ?
                       qRgb(0, 0, 0) : qRgb(255, 255,255));
#endif
}


bool PtptFormat::saveThumbnail(const QString &fp) {
  QFileInfo info(fp);
  QString dir, fn;

  dir = info.dirPath() + "/" + dot_icon + "/";
  fn = info.baseName() + "_" + info.extension() + ".jpg";

  QDir d(dir);
  if (!d.exists())
    d.mkdir(dir);

  return thumbnail.save(dir + fn, "JPEG");
}
#endif

void PtptFormat::setThumbnail(UIImage* img) {
	NSData *jpg = UIImageJPEGRepresentation(img, 0.9);
	uint start_o, size;
	
	start_o = [data length];
	size = [jpg length];
	
	[data appendData:jpg];
	
	thumbnail_info.offset = start_o;
	thumbnail_info.length = size;
}

UIImage* PtptFormat::getThumbnail(void) {
	UIImage *img;
	NSData *img_data =
	[NSData dataWithBytes:(char*)[data bytes] + thumbnail_info.offset 
								 length:thumbnail_info.length];
	img = [UIImage imageWithData:img_data];
	
	return img;
}

bool PtptFormat::save(NSString *fn) {
  prepare_data();

  return [data writeToFile:fn atomically:YES];
}

void PtptFormat::prepare_data(void) {
  // file header
  
	uchar *dbuf = (uchar*)[this->data bytes];
	
  dbuf[0] = dbuf[2] = 'P';
  dbuf[1] = dbuf[3] = 't';
  dbuf[4] = 0;
  dbuf[5] = '1'; dbuf[6] = '.'; dbuf[7] = '0';

  // infomation header

  dbuf[0x10] = num_of_layers;
	
	// thumbnail info
	for (uint j = 0; j < 4; j ++) {
		dbuf[0x14 + j] = (thumbnail_info.offset >> (24 - 8*j)) & 0xff;
		dbuf[0x18 + j] = (thumbnail_info.length >> (24 - 8*j)) & 0xff;
	}
	
  // layers info
  for (uint k = 0; k < num_of_layers; k ++) {
    for (uint j = 0; j < 4; j ++) {
      dbuf[0x20 + k * 0x10 + j]
        = (layer_infos[k].offset >> (24 - 8*j)) & 0xff;
      dbuf[0x24 + k * 0x10 + j]
        = (layer_infos[k].length >> (24 - 8*j)) & 0xff;
    }

    dbuf[0x28 + k * 0x10] = layer_infos[k].comp_method;
    dbuf[0x29 + k * 0x10] = layer_infos[k].alpha;
    dbuf[0x2a + k * 0x10] = layer_infos[k].paper_col.red;
    dbuf[0x2b + k * 0x10] = layer_infos[k].paper_col.green;
    dbuf[0x2c + k * 0x10] = layer_infos[k].paper_col.blue;
  }
}

bool PtptFormat::isPtpt(NSString *fn) {
  bool r;
  NSData *dat =
  [[NSData alloc] initWithContentsOfMappedFile:fn];
  if (dat) {
    char buf[9];
    buf[8] = NULL;
    [dat getBytes:(void*)buf length:8];

    if ([[NSString stringWithCString:buf 
		  encoding:[NSString defaultCStringEncoding]]
	  isEqualToString:@"PtPt"] &&
	buf[5] >= '0' && buf[5] <= '9' &&
	buf[6] == '.' &&
	buf[7] >= '0' && buf[7] <= '9')
      r = true;
    else
      r = false;
  } else {
    r = false;
  }
  [dat release];

  return r;
}

bool PtptFormat::isPtpt(void) {
  char buf[9];
  buf[8] = NULL;
    [this->data getBytes:(void*)buf length:8];

    if ([[NSString stringWithCString:buf 
		  encoding:[NSString defaultCStringEncoding]]
	  isEqualToString:@"PtPt"] &&
	buf[5] >= '0' && buf[5] <= '9' &&
	buf[6] == '.' &&
	buf[7] >= '0' && buf[7] <= '9')
    return true;
  else
    return false;
}

void PtptFormat::parse_data(void) {
  if (!isPtpt()) return;

  // infomation header

  uchar r, g, b;
  uchar *dat_buf = (uchar*)[data bytes];
  
  setNumOfLayers(dat_buf[0x10]);

  uint32a offset, length;
  for (uint k = 0; k < num_of_layers; k ++) {
    offset = length = 0;
    for (uint j = 0; j < 4; j ++) {
      offset = (offset << 8) +
        (uchar)dat_buf[0x20 + k * 0x10 + j];
      length = (length << 8) +
        (uchar)dat_buf[0x24 + k * 0x10 + j];
    }
    layer_infos[k].offset = offset;
    layer_infos[k].length = length;

    layer_infos[k].comp_method = dat_buf[0x28 + k * 0x10];
    layer_infos[k].alpha = dat_buf[0x29 + k * 0x10];

    r = (uchar)dat_buf[0x2a + k * 0x10];
    g = (uchar)dat_buf[0x2b + k * 0x10];
    b = (uchar)dat_buf[0x2c + k * 0x10];
    layer_infos[k].paper_col.setRgb(r, g, b);
  }
	
	offset = length = 0;
	for (uint j = 0; j < 4; j ++) {
		offset = (offset << 8) + (uchar)dat_buf[0x14 + j];
		length = (length << 8) + (uchar)dat_buf[0x18 + j];
	}
	thumbnail_info.offset = offset;
	thumbnail_info.length = length;
}

uint PtptFormat::numOfLayers(void) {
  return num_of_layers;
}

UIImage* PtptFormat::layer(uint k) {
	UIImage *img;

	NSData *img_dat =
//	[NSData dataWithBytesNoCopy:(char*)[data bytes] + layer_infos[k].offset
	[NSData dataWithBytes:(char*)[data bytes] + layer_infos[k].offset
											 length:layer_infos[k].length];
	img = [UIImage imageWithData:img_dat];

  return img;
}

uint PtptFormat::compositionMethod(uint k) {
  return layer_infos[k].comp_method;
}

uint PtptFormat::alpha(uint k) {
  return layer_infos[k].alpha;
}

PtColor PtptFormat::paperColor(uint k) {
  return layer_infos[k].paper_col;
}

bool PtptFormat::load(NSString *fn) {
	if (this->data) [this->data release];
	this->data = [[NSData dataWithContentsOfFile:fn] retain];
	
  parse_data();

  return true;
}
