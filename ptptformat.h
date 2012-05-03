#ifndef PTPTFORMAT_H
#define PTPTFORMAT_H

//#include <qarray.h>
//#include <qimage.h>
//#include <qstring.h>
#include <vector>

#include "ptcolor.h"
#include "constants.h"

class PtptFormat {

  //  static const QString FileIconPath;
  
  typedef struct {
    uint32a offset;
    uint32a length;
    uint comp_method;
    uint alpha;
    PtColor paper_col;
  } layer_info;
	
	typedef struct {
		uint32a offset, length;
	} ThumbnailInfo;

  uint num_of_layers, cur;
  std::vector<layer_info> layer_infos;
	ThumbnailInfo thumbnail_info;
//  QArray<QImage*> layers;
  NSMutableData *data;
  //  QString filename;
  //  QImage thumbnail;
  //  static QImage small_icon;
  //  static int small_icon_width, small_icon_height;
  //  static int thumbnail_height, thumbnail_width;
  //  static QString dot_icon;

  //  void init_small_icon();
  void prepare_data(void);
  void parse_data(void);

public:
  PtptFormat(uint = 0);
  ~PtptFormat(void);
  
//  static const int TNHeightSmall = 45;
//  static const int TNHeightLarge = 90;

//  static QString dotIcon(void) {return dot_icon;};
  void setNumOfLayers(uint n, bool = false);
  void addLayer(UIImage *);
  void setCompositionMethod(uint k, uint m);
  void setAlpha(uint k, uint alpha);
  void setPaperColor(uint k, const PtColor&);
  //  static void setTNHeight(int);
  //  void setThumbnail(const QImage &);
	void setThumbnail(UIImage*);
	UIImage* getThumbnail(void);
  //  bool saveThumbnail(const QString &);
  bool save(NSString *);

  static bool isPtpt(NSString *);
  bool isPtpt(void);
  
  uint numOfLayers(void);
  UIImage* layer(uint k);
  uint compositionMethod(uint k);
  uint alpha(uint k);
  PtColor paperColor(uint k);
  bool load(NSString *);

};

#endif //	PTPTFORMAT_H
