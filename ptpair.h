#ifndef PTPAIR_H
#define PTPAIR_H

class PtPair {
 public:
  int x, y;
	
  PtPair(void);
  PtPair(int, int);
  PtPair(const PtPair&);

  PtPair operator+(const PtPair&) const;
  PtPair operator-(const PtPair&) const;
};

class PtRect {
 public:
  int x, y, w, h;
		
  PtRect(void);
  PtRect(int, int, int, int);
  PtRect(const PtRect&);
		
  bool isValid(void);
  void setRect(int, int, int, int);
  
  int left(void) const {return x;}
  int right(void) const {return x + w - 1;}
  int top(void) const {return y;}
  int bottom(void) const {return y + h - 1;}

  PtPair topLeft(void) const {return PtPair(left(), top());}
  PtPair topRight(void) const {return PtPair(right(), top());}
  PtPair bottomLeft(void) const {return PtPair(left(), bottom());}
  PtPair bottomRight(void) const {return PtPair(right(), bottom());}
	void enlarge(int);

  bool contains(int, int);
  void moveBy(int, int);

  PtRect operator&(const PtRect&) const;
  PtRect operator*(const float) const;
};

#endif // PTPAIR
