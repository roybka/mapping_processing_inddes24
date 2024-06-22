
// creates the lines demo, for two projectors, and fills black near each person so that no shadow is seen. 


SecondWindow secondWindow; // Declare the second window

ArrayList<Line> lines; // List to store lines
int maxLines = 437;    // Maximum number of lines
float x1,y1,x2,y2;
int l=80;
float xv1;
float yv1;
float stdx;
float stdy;
float dx1;
float dy1;
boolean iterating=false;
int mx;
int my;
int st;
int rad=200;
int skew=5;


void setup() {
    //fullScreen();
  println(width);
    //fullScreen(P2D, 1); // Use '2' for the second monitor
  xv1=150;
  yv1=150; // later will be location of person. 
  stdx=30;
  stdy=30;
  size(800, 800);
    surface.setLocation(100, 100);
  lines = new ArrayList<Line>();
  //lines.add(new Line(390,390, 400,400));
  strokeWeight(3);
  
    secondWindow = new SecondWindow();
  String[] args = {"Second Window"};
  PApplet.runSketch(args, secondWindow);
}

void draw() {
  st=millis();
  background(255, 248, 230);
  mx = mouseX;
  my = mouseY;
  // Randomly add a new line
  if (random(1) < 0.4) { // Adjust the probability as needed
    x1=mx;
    y1=my;
    dx1=randomGaussian()*stdx;
    dy1=randomGaussian()*stdy;
    if (iterating==false){
    lines.add(new Line(x1+dx1,y1+dy1, x1+dx1+random(-l,l),y1+dy1+random(-l,l)));
    }
  }
  if (random(1) < 0.01) {
  println(lines.size());
}
  xv1=xv1+0.2;
  yv1=yv1+0.2;
  if (xv1>900){xv1=50;}
  if (yv1>900){yv1=50;}
  // Draw all lines
  //if (lines.size()>(maxLines-1)){
  for (Line line : lines) {
    iterating=true;
    line.display(this);
  }
  iterating=false;
//}

  // Remove the oldest line if we exceed the maximum count
  if ((lines.size() > maxLines) & (iterating==false)) {
    lines.remove(0);
  }
    
  println(millis()-st);
  paintBlackToLeft(this,mx,my);
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

  void display(PApplet applet) {
    applet.stroke(0);
    c=c+1;
    if (c>32000){c=0;}
    applet.pushMatrix();
    applet.translate((x1+x2)/2,(y1+y2)/2);
    applet.rotate(c*s);
    applet.line(x1-(x1+x2)/2, y1-(y1+y2)/2, x2-(x1+x2)/2 , y2-(y1+y2)/2);
    applet.popMatrix();

  }
}
float euclideanDistance(float x1, float y1, float x2, float y2) {
  float dx = x2 - x1;  // Difference in x-coordinates
  float dy = y2 - y1;  // Difference in y-coordinates
  return sqrt(dx * dx + skew*dy * dy);  // Square root of the sum of the squares of differences
}

void paintBlackToLeft(PApplet applet,int xThreshold,int yThreshold) {
  applet.loadPixels(); // Load the pixels into the pixels array
  
  for (int y = 0; y < applet.height; y++) {
    for (int x = 0; x < xThreshold; x++) {
      if ( euclideanDistance(x,y,xThreshold,yThreshold)<rad){
      int index = x + y * applet.width; // Calculate the index in the pixels array
      applet.pixels[index] = color(0); // Set the pixel color to black
    }}
  }
  
  applet.updatePixels(); // Apply the changes to the canvas
}

void paintBlackToRight(PApplet applet,int xThreshold,int yThreshold) {
  applet.loadPixels(); // Load the pixels into the pixels array
  
  for (int y = 0; y < applet.height; y++) {
    for (int x = xThreshold; x < applet.width; x++) {
      if ( euclideanDistance(x,y,xThreshold,yThreshold)<rad){
      int index = x + y * applet.width; // Calculate the index in the pixels array
      applet.pixels[index] = color(0); // Set the pixel color to black
    }}
  }
  
  applet.updatePixels(); // Apply the changes to the canvas
}


public class SecondWindow extends PApplet {
  public void settings() {
    size(800, 800);
  }

  public void setup() {
      //fullScreen(P2D, 2); // Use '2' for the second monitor
    background(255);
      strokeWeight(3);
      surface.setLocation(900, 100);

  }

  public void draw() {
    background(255, 248, 230);
        //ellipse(width / 2, height / 2, 50, 50);
    // Second window content
  for (Line line : lines) {
    iterating=true;
    line.display(this);
  }
  iterating=false;
  paintBlackToRight(this,mx,my);
}
}
