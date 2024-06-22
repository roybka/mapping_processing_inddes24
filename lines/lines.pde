ArrayList<Line> lines; // List to store lines
int maxLines = 137;    // Maximum number of lines
float x1,y1,x2,y2;
int l=80;
float xv1;
float yv1;
float stdx;
float stdy;
float dx1;
float dy1;

int mx;
int my;

void setup() {
    fullScreen();
  println(width);
  xv1=150;
  yv1=150; // later will be location of person. 
  stdx=30;
  stdy=30;
  //size(900, 900);
  lines = new ArrayList<Line>();
  //lines.add(new Line(390,390, 400,400));
  strokeWeight(3);
}

void draw() {
  background(255, 248, 230);
  mx = mouseX;
  my = mouseY;
  // Randomly add a new line
  if (random(1) < 0.4) { // Adjust the probability as needed
    x1=mx;
    y1=my;
    dx1=randomGaussian()*stdx;
    dy1=randomGaussian()*stdy;
    lines.add(new Line(x1+dx1,y1+dy1, x1+dx1+random(-l,l),y1+dy1+random(-l,l)));
    
  }
  xv1=xv1+0.2;
  yv1=yv1+0.2;
  if (xv1>900){xv1=50;}
  if (yv1>900){yv1=50;}
  // Draw all lines
  //if (lines.size()>(maxLines-1)){
  for (Line line : lines) {
    line.display();
  }
//}

  // Remove the oldest line if we exceed the maximum count
  if (lines.size() > maxLines) {
    lines.remove(0);
  }
}

// Line class
class Line {
  float x1, y1; // Position
  float x2,y2; // Length of the line
  int c;
  float s;
  Line(float x1, float y1, float x2,float y2) {
    this.x1 = x1;
    this.y1 = y1;
    this.x2 = x2;
    this.y2 = y2;
    this.s=(random(1)-0.5)*0.02;
  }

  void display() {
    stroke(0);
    c=c+1;
    if (c>32000){c=0;}
    pushMatrix();
    translate((x1+x2)/2,(y1+y2)/2);
    rotate(c*s);
    line(x1-(x1+x2)/2, y1-(y1+y2)/2, x2-(x1+x2)/2 , y2-(y1+y2)/2);
    popMatrix();

  }
}
