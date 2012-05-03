#ifndef SETTINGS_H
#define SETTINGS_H

//#import <Cocoa/Cocoa.h>
//#include <qstring.h>
//#include <qfile.h>
//#include <qstringlist.h>

#include "constants.h"

  ////「Preferences Utilities Reference」を読もう

class Settings {
  //  static NSString *conf_fn;
  static NSString *conf_string;
  //  static QFile conf_f;
  //  static QString last_fn;

public:
  //  static const QString SettingsFileName;

  static NSArray* items;
  static NSMutableArray* values;

  enum {i_lastfn = 0, i_palettefn,
    i_pressure_min, i_pressure_mid, i_pressure_max,
	i_pressure_east_min, i_pressure_east_max,
	i_pressure_west_min, i_pressure_west_max,
	i_pressure_south_min, i_pressure_south_max,
	i_pressure_north_min, i_pressure_north_max,
	i_pressure_smooth, i_palette_colors,
	i_sync_width, i_leftright, i_separate_pen,
	i_novice_mode, i_z_color_adjust,
    NumOfSetting_i};

  Settings();

  //  NSString* getLastFileName(void);
  //  void setLastFileName(const NSString*);
  NSString* getPaletteFileName(void);
  void setPaletteFileName(const NSString*);
  void getPaletteColors(std::vector<uint16>, std::vector<bool>);
  void setPaletteColors(const std::vector<uint16>,
                        const std::vector<bool>);
  unsigned long int getPressure(int);
  void setPressure(int, unsigned long int);
  int getPressureSmooth(void);
  void setPressureSmooth(int);
  bool getSyncWidth(void);
  void setSyncWidth(bool);
  bool getLeftRight(void);
  void setLeftRight(bool);
  bool getSeparatePen(void);
  void setSeparatePen(bool);
  bool getNoviceMode(void);
  void setNoviceMode(bool);
  bool getZColorAdjust(void);
  void setZColorAdjust(bool);

  //  void save(void) {save_conf();}
  
private:
  void prepare_items(void);
  //  QString config_path(void);
  //  void parse_items(void);
  //  void set_conf_string(void);
  //  void save_conf(void);
};

#if 0
#include <qdialog.h>

class QVBox;
class QCheckBox;

class SettingsDialog : public QDialog {

private:
  QVBox *main_box;
  QCheckBox *sync_width_check;
  QCheckBox *leftright_check;
  QCheckBox *separate_pen_check;
  QCheckBox *novice_mode_check;
  QCheckBox *z_color_adjust_check;

public:
  SettingsDialog(QWidget*);
  ~SettingsDialog(void);

  void setSyncWidth(bool);
  bool syncWidth(void);
  void setLeftRight(bool);
  bool leftRight(void);
  void setSeparatePen(bool);
  bool separatePen(void);
  void setNoviceMode(bool);
  bool noviceMode(void);
  void setZColorAdjust(bool);
  bool ZColorAdjust(void);
  
};

#endif

#endif		// SETTINGS_H
