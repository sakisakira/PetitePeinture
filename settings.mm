/*
 **	settings.cpp
 **	by Saki Sakira <sakira@sun.dhis.portside.net>
 **	from 2003 July 20
 */

#include <stdio.h>
//#include <qdir.h>
//#include <qfile.h>
//#include <qregexp.h>
//#import <Cocoa/Cocoa.h>

#include "colorpalette.h"
#include "settings.h"

#if 0
const QString Settings::SettingsFileName("Settings/petitpeintu.conf");

QString Settings::conf_fn, Settings::conf_string, Settings::last_fn;
QFile Settings::conf_f;
QStringList Settings::items, Settings::values;
#endif
NSString *Settings::conf_string;
NSArray *Settings::items;
NSMutableArray *Settings::values;

Settings::Settings() {
  prepare_items();

#if 0
  conf_fn = config_path();
  QFile conf_f(conf_fn);
  
  if (conf_f.exists()) {
    int size = conf_f.size();
    char str[size + 1];
    
    str[size] = 0;
    conf_f.open(IO_ReadOnly);
    conf_f.flush();
    size = conf_f.readBlock(str, size);
    conf_f.close();

    conf_string = QString(str);
    conf_string.truncate(size);
  } else {
    conf_string = QString("[global]\n");
  }
  #endif

  conf_string = @"[global]\n";

  //  parse_items();
}

void Settings::prepare_items(void) {
  items = [NSArray arrayWithObjects:@"LastFileName", @"PaletteFileName",
           @"PressureMin", @"PressureMid", @"PressureMax",
           @"PressureEastMin", @"PressureEastMax",
           @"PressureWestMin", @"PressureWestMax",
           @"PressureSouthMin", @"PressureSouthMax",
           @"PressureNorthMin", @"PressureNorthMax",
           @"PressureSmooth", @"PaletteColors",
           @"SyncPenWidth", @"UseLeftRightFor",
           @"SeparatePen", @"NoviceMode", @"ZColorAdjust", nil];

  values = [NSMutableArray arrayWithCapacity:NumOfSetting_i];
  for (int i = 0; i < NumOfSetting_i; i ++)
    [values addObject:@""];
}

#if 0
NSString* Settings::config_path(void) {
  QString path = QDir::homeDirPath();

  if (path.right(1) != "/")
    path += "/";

  return path + SettingsFileName;
}
#endif

#if 0
void Settings::parse_items(void) {
  int start_pos, len;

  for (int i = 0; i < NumOfSetting_i; i ++) {
    QRegExp exp(QString("[\\r\\n]")
                + items[i] + "[ \\t]*=[ \\t]*");
    start_pos = exp.match(conf_string, 0, &len);
    if (start_pos >= 0) {
      start_pos += len;
      exp.setPattern("[^\\r\\n]*");
      exp.match(conf_string, start_pos, &len);

      values[i] = conf_string.mid(start_pos, len);
    } else {
      values[i] = "";
    }
  }
}
#endif

#if 0
NSString* Settings::getLastFileName(void) {
  if ([values[i_lastfn] length] == 0)
    return QDir::homeDirPath() + "/.";
  else
    return values[i_lastfn];
}

void Settings::setLastFileName(const QString fn) {
  values[i_lastfn] = fn;

  save_conf();
}
#endif

NSString* Settings::getPaletteFileName(void) {
  return @"hoge";
#if 0
  if (values[i_palettefn].length() == 0)
    return @"/...hoge";
  else
    return values[i_palettefn];
#endif
}

void Settings::setPaletteFileName(const NSString *fn) {
#if 0
  values[i_palettefn] = fn;

  save_conf();
#endif
}

void Settings::getPaletteColors(std::vector<uint16> cols,
                                std::vector<bool> chgs) {
  cols.resize(ColorPalette::length);
  chgs.assign(ColorPalette::length, false);

  for (uint i = 0; i < ColorPalette::length; i ++)
    cols[i] = ColorPalette::init_colors[i];

  if ([[values objectAtIndex:i_palette_colors] length] == 0) return;
  
#if 0
  QStringList strs 
    = QStringList::split(" ", values[i_palette_colors]);
  uint l = umin(strs.count(), ColorPalette::length);
  uint32a c;

  for (uint i = 0; i < l; i ++) {
    c = strs[i].toULong(0, 16);
    cols[i] = c & 0xffff;
    if (c > 0xffff)
      chgs[i] = false;
    else
      chgs[i] = true;
  }
#endif
}

void Settings::setPaletteColors(const std::vector<uint16> cols,
                                const std::vector<bool> chgs) {
#if 0
  QStringList strs;
  uint32a n;

  for (uint i = 0; i < cols.size(); i ++) {
    n = cols[i];
    if (!chgs[i]) n |= 0x10000;
    strs << QString::number(n, 16);
  }
  
  values[i_palette_colors] = strs.join(" ");
#endif
}

unsigned long int Settings::getPressure(int i) {
  return 0;
#if 0
  if (values[i].length() == 0)
    return 0;
  else
    return values[i].toULong();
#endif
}

void Settings::setPressure(int i, unsigned long int pressure) {
  //  values[i] = QString::number(pressure);
}

int Settings::getPressureSmooth(void) {
  return 4;
#if 0
  if (values[i_pressure_smooth].length() == 0)
    return 4;
  else
    return values[i_pressure_smooth].toInt();
#endif
}

void Settings::setPressureSmooth(int s) {
  //  values[i_pressure_smooth] = QString::number(s);
}

bool Settings::getSyncWidth(void) {
  return false;
  //  return (values[i_sync_width] == "true");
}

void Settings::setSyncWidth(bool f) {
#if 0
  if (f)
    values[i_sync_width] = "true";
  else
    values[i_sync_width] = "false";
#endif
}

bool Settings::getLeftRight(void) {
  return false;
  //  return (values[i_leftright] == "true");
}

void Settings::setLeftRight(bool f) {
#if 0
  if (f)
    values[i_leftright] = "true";
  else
    values[i_leftright] = "false";
#endif
}

bool Settings::getSeparatePen(void) {
  return false;
  //  return (values[i_separate_pen] == "true");
}

void Settings::setSeparatePen(bool f) {
#if 0
  if (f)
    values[i_separate_pen] = "true";
  else
    values[i_separate_pen] = "false";
#endif
}

bool Settings::getNoviceMode(void) {
  return false;
  //  return (values[i_novice_mode] != "false");
}

void Settings::setNoviceMode(bool f) {
#if 0
  if (f)
    values[i_novice_mode] = "true";
  else
    values[i_novice_mode] = "false";
#endif
}

bool Settings::getZColorAdjust(void) {
  return false;
  //  return (values[i_z_color_adjust] != "false");
}

void Settings::setZColorAdjust(bool f) {
#if 0
  if (f)
    values[i_z_color_adjust] = "true";
  else
    values[i_z_color_adjust] = "false";
#endif
}

#if 0
void Settings::set_conf_string(void) {
  int start_pos, len;

  for (int i = 0; i < NumOfSetting_i; i ++) {
    QRegExp exp(QString("[\\r\\n]") +
                items[i] + "[ \\t]*=[ \\t]*");
    start_pos = exp.match(conf_string, 0, &len);
    if (start_pos >= 0) {
      start_pos += len;
      exp.setPattern("[^\\r\\n]*");
      exp.match(conf_string, start_pos, &len);
  
      conf_string.replace(start_pos, len, values[i]);
    } else {
      if (conf_string.right(1) != "\n")
        conf_string += "\n";

      conf_string += items[i]
        + " = " + values[i] + "\n";
    }
  }
}

void Settings::save_conf(void) {
  set_conf_string();
  
  QFile conf_f(conf_fn);

  conf_f.open(IO_WriteOnly);
  conf_f.writeBlock(conf_string.data(), conf_string.length());
  conf_f.close();
}
#endif

////////////////////////////////////////////////////////////
// SettingsDialog

#if 0
#include <qvbox.h>
#include <qcheckbox.h>

SettingsDialog::SettingsDialog(QWidget *parent) :
QDialog(parent, "SettingsDialog", true) {
  setCaption("Settings");

  main_box = new QVBox(this);
  main_box->setMinimumSize(200, 200);
  sync_width_check = 
    new QCheckBox("Sync. Pen Width", main_box);
  separate_pen_check =
    new QCheckBox("Pen for each Layer", main_box);
  leftright_check =
    new QCheckBox("Left-Right for Density", main_box);
  novice_mode_check =
    new QCheckBox("Novice Mode", main_box);
  z_color_adjust_check =
    new QCheckBox("ZColorAdjust", main_box);
}

SettingsDialog::~SettingsDialog(void) {
  delete z_color_adjust_check;
  delete novice_mode_check;
  delete separate_pen_check;
  delete leftright_check;
  delete sync_width_check;
  delete main_box;
}

void SettingsDialog::setSyncWidth(bool f) {
  sync_width_check->setChecked(f);
}

bool SettingsDialog::syncWidth(void) {
  return sync_width_check->isChecked();
}

void SettingsDialog::setLeftRight(bool f) {
  leftright_check->setChecked(f);
}

bool SettingsDialog::leftRight(void) {
  return leftright_check->isChecked();
}

void SettingsDialog::setSeparatePen(bool f) {
  separate_pen_check->setChecked(f);
}

bool SettingsDialog::separatePen(void) {
  return separate_pen_check->isChecked();
}

void SettingsDialog::setNoviceMode(bool f) {
  novice_mode_check->setChecked(f);
}

bool SettingsDialog::noviceMode(void) {
  return novice_mode_check->isChecked();
}

void SettingsDialog::setZColorAdjust(bool f) {
  z_color_adjust_check->setChecked(f);
}

bool SettingsDialog::ZColorAdjust(void) {
  return z_color_adjust_check->isChecked();
}

#endif // SettingsDialog
