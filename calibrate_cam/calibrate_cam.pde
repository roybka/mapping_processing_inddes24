/* 
This code uses the projector corrected image (floor) to present a rectangle, and shows the camera view in a smaller window.
You then tell it where are the screen corners relative to camera view. this is then  saved. 
 
 */

import processing.video.*;
int mi;
int cam_w=640;
int cam_h=480;
int cam_screen_offset_x=300;
int cam_screen_offset_y=300;
float[][] matrix = new float[4][4];
Capture video;

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
void savePoints() {
  String[] coords = new String[points.length+6];
  for (int i = 0; i < points.length; i++) {
    coords[i] = points[i].x + "," + points[i].y;
    println("Point " + (i+1) + ": (" + points[i].x + ", " + points[i].y + ")");
  }
  coords[4] =  str(width);
  coords[5]= str(height);
  coords[6] =  str(cam_w);
  coords[7]= str(cam_h);
  coords[8] =  str(cam_screen_offset_x);
  coords[9]= str(cam_screen_offset_y);
  saveStrings("../resources/camera_rectangle_corners.csv", coords);
  println("Coordinates saved to camera_rectangle_corners.csv");
  exit();
}
// Function to load the matrix from a CSV file
void loadMatrixFromFile(String filename) {
  String[] rows = loadStrings(filename);
  for (int i = 0; i < rows.length; i++) {
    String[] cols = split(rows[i], ',');
    for (int j = 0; j < cols.length; j++) {
      matrix[i][j] = float(cols[j]);
    }
  }
}

void keyPressed() {
  if (key == 's' || key == 'S') {
    savePoints();
  }
}

DraggablePoint[] points = new DraggablePoint[4];
//DraggablePoint pt;
void setup() {
  fullScreen(P3D, 1);

  // Initialize points at the four corners of the canvas
  points[0] = new DraggablePoint(100, 100);
  points[1] = new DraggablePoint(width - 100, 100);
  points[2] = new DraggablePoint(width - 100, height - 100);
  points[3] = new DraggablePoint(100, height - 100);
  //pt= new DraggablePoint(1820, 980);
  loadMatrixFromFile("../resources/transformation_matrix.csv");
  background(0);

  video = new Capture(this, cam_w, cam_h);
  video.start();
  println(width);
  println(height);
  background(255);
}

void draw() {
  background(255);
  video.read();
  image(video, cam_screen_offset_x, cam_screen_offset_y, cam_w, cam_h);

  for (DraggablePoint point : points) {
    point.checkDragging();
    point.drawPoint();
  }
  applyMatrix(matrix[0][0], matrix[0][1], 0, matrix[0][2],
    matrix[1][0], matrix[1][1], 0, matrix[1][2],
    0, 0, 1, 0,
    matrix[2][0], matrix[2][1], 0, matrix[2][2]);
  // Example drawing code

  fill(120, 120, 120, 100);
  rect(0, 0, width, height);
}
