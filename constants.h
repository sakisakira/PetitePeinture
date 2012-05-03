#ifndef CONSTANTS_H
#define CONSTANTS_H

#define PenWidthMaxPhone 50
#define PenWidthMaxPad 150
#define ZoomMax 10.0f
#define ZoomMin 0.25f
#define CloudWorkWidth 200
#define UndoStrokesMax 1024

typedef unsigned long long int uint64;
typedef unsigned long int uint32a;
typedef unsigned short int uint16;
typedef unsigned int uint;
typedef unsigned char uchar;

inline int max(int a, int b) {
  return (a >= b) ? a : b;
}

inline uint max(uint a, uint b) {
  return (a >= b) ? a : b;
}

inline float max(float a, float b) {
  return (a >= b) ? a : b;
}

inline int min(int a, int b) {
  return (a <= b) ? a : b;
}

inline float min(float a, float b) {
  return (a <= b) ? a : b;
}

inline uint min(uint a, uint b) {
  return (a <= b) ? a : b;
}

inline uint umin(uint a, uint b) {
  return (a <= b) ? a : b;
}

inline uint umax(uint a, uint b) {
  return (a <= b) ? b : a;
}

inline int abs(int a) {
  return a >= 0 ? a : -a;
}

enum {SolidBrush = 0, WaterBrush,
      CloudWeakBrush, CloudMidBrush, CloudWideBrush,
      EraserBrush,
      NumOfBrushes};

enum {MinComposition, MulComposition,
  SatComposition, ColComposition,
      NormalComposition, MaxComposition, MaskComposition,
      AlphaChannelComposition, ScreenComposition,
      DodgeComposition,
  NumOfComposition};

#endif		// CONSTANTS_H
