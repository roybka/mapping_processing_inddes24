// Define a class to represent draggable points
class DraggablePoint {
  float x, y;
  boolean dragging = false;
  
  DraggablePoint(float x, float y) {
    this.x = x;
    this.y = y;
  }
  
  void drawPoint() {
    stroke(255, 0, 0);
    strokeWeight(2);
    line(x - 10, y, x + 10, y);
    line(x, y - 10, x, y + 10);
  }
  
  void checkDragging() {
    if (mousePressed && dist(mouseX, mouseY, x, y) < 10) {
      dragging = true;
    }
    if (!mousePressed) {
      dragging = false;
    }
    if (dragging) {
      x = mouseX;
      y = mouseY;
    }
  }
}
void keyPressed() {
  if (key == 's' || key == 'S') {
    savePoints();
  }
}

void savePoints() {
  String[] coords = new String[points.length+2];
  for (int i = 0; i < points.length; i++) {
    coords[i] = points[i].x + "," + points[i].y;
    println("Point " + (i+1) + ": (" + points[i].x + ", " + points[i].y + ")");
  }
  coords[4] =  str(width);
  coords[5]= str(height);
  saveStrings("../resources/rectangle_corners.csv", coords);
  println("Coordinates saved to rectangle_corners.csv");
  exit(); 
}
// Initialize four corner points
DraggablePoint[] points = new DraggablePoint[4];

void setup() {
  //size(640, 480);
  fullScreen(P3D, 1);
  // Initialize points at the four corners of the canvas
  points[0] = new DraggablePoint(100, 100);
  points[1] = new DraggablePoint(width - 100, 100);
  points[2] = new DraggablePoint(width - 100, height - 100);
  points[3] = new DraggablePoint(100, height - 100);
}

void draw() {
  background(255);
  for (DraggablePoint point : points) {
    point.checkDragging();
    point.drawPoint();
  }
}
