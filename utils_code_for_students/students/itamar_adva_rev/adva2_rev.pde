import processing.net.*;
import java.util.ArrayList;
import java.util.HashSet;

PImage img;
PImage presentedImg;

PImage [] pixelatedImgs= new PImage[4];
float [] radii = new float[4];
int imgWidth = 600;
int imgHeight = 600;
int maxPixelationFactor = 40; // maximum level of pixelation
int targetRevealRadius = 200; // adjust this value for desired reveal size
int revealRadius = 50;

UserManager userManager;
ArrayList<User> users;
Logger logger;

String data = "";
int port = 12345;
String nothing = "Nothing";
Client myClient;
float[][] matrix = new float[4][4];
float[][] camMatrix = new float[4][4];

void settings() {
  fullScreen(P3D, 1);
}

void setup() {
  img = loadImage("Hieronymus.jpg");
  //img.resize(height, height);
  imgWidth = width;
  imgHeight = height;
  //pixelatedImgs = new [4] PImage();
  radii[0]=60;
  radii[1]=120;
  radii[2]=180;
  radii[3]=240;
  for (int k =0; k<4; k++) {
    //pixelatedImgs[k] = new PImage(width,height);
    pixelatedImgs[k]= createImage(width, height, RGB);
    pixelateImage(pixelatedImgs[k], int(radii[k]/4));
  }
  presentedImg= createImage(width, height, RGB);
  presentedImg = pixelatedImgs[3].copy();
  noCursor();

  background(255);
  logger = new Logger("log.txt");
  logger.log("Program started");
  myClient = new Client(this, "127.0.0.1", port);
  userManager = new UserManager();
  //userManager.initializeUsers("mouse", 1);  // Initialize 1 mouse-controlled user

  // Load transformation matrices
  loadMatrixFromFile("../../../resources/transformation_matrix.csv", matrix);
  loadMatrixFromFile("../../../resources/camera_transformation_matrix.csv", camMatrix);
}

void draw() {
  println(millis());
  //presentedImg=pixelatedImgs[3].copy();
  //PImage presentedImg = createImage(width, height, RGB);
  background(255);
  int xOffset = (width - imgWidth) / 2;
  int yOffset = (height - imgHeight) / 2;


  userManager.run();
  users = userManager.getUsers();
  applyMatrix(matrix[0][0], matrix[0][1], 0, matrix[0][2],
    matrix[1][0], matrix[1][1], 0, matrix[1][2],
    0, 0, 1, 0,
    matrix[2][0], matrix[2][1], 0, matrix[2][2]);
  for (User user : users) {
    updateRevealRadius(user.position.x, user.position.y );
    for (int i = 0; i < img.pixels.length; i++) {
      float x = i % width;
      float y = floor(i / width);
      float d = dist(x, y, user.position.x, user.position.y);
      float dx = abs(x-user.position.x);
      float dy = abs(y-user.position.y);
      if ((dx < radii[0])&(dy<radii[0])) {
        presentedImg.pixels[i] = img.pixels[i];
      } else if ((dx < radii[1])&(dy<radii[1])) {
        presentedImg.pixels[i] = pixelatedImgs[1].pixels[i];
      } else if ((dx < radii[2])&(dy<radii[2])) {
        presentedImg.pixels[i] = pixelatedImgs[2].pixels[i];
      } else {
        presentedImg.pixels[i] = pixelatedImgs[3].pixels[i];
      }
    }

    //popMatrix();
    //displayUserShapes(user);
  }
  presentedImg.updatePixels();
  //updatePixels();
  image(presentedImg, 0, 0);
  handleClientData();
}

void pixelateImage(PImage p, int pixelationFac) {
  //img.loadPixels();
  p.loadPixels();
  for (int y = 0; y < imgHeight; y += pixelationFac) {
    for (int x = 0; x < imgWidth; x += pixelationFac) {
      int c = img.pixels[y * imgWidth + x];
      int endX = Math.min(x + pixelationFac, imgWidth);
      int endY = Math.min(y + pixelationFac, imgHeight);
      for (int dy = y; dy < endY; dy++) {
        for (int dx = x; dx < endX; dx++) {
          p.pixels[dy * imgWidth + dx] = c;
        }
      }
    }
  }
  p.updatePixels();
}

void updateRevealRadius(float userX, float userY) {
  // Update logic based on user's activity or proximity
  // Placeholder: updating based on the presence of any user activity
  revealRadius =300;// (int) lerp(revealRadius, targetRevealRadius, 0.5); // Simple lerp update
  //println(revealRadius);
}
void revealImage(float userX, float userY, int revealRadius) {
  int levels = 4;
  float levelSize = revealRadius / (float)levels;
  int[] levelFactors = new int[levels];

  // Pre-compute level factors
  for (int i = 0; i < levels; i++) {
    levelFactors[i] = (int) map(i + 1, 1, levels, 1, maxPixelationFactor);
  }

  for (int level = levels - 1; level >= 0; level--) {
    int levelFactor = levelFactors[level];
    float currentSize = levelSize * (level + 1);
    int minX = (int)(userX - currentSize);
    int maxX = (int)(userX + currentSize);
    int minY = (int)(userY - currentSize);
    int maxY = (int)(userY + currentSize);

    for (int x = minX; x < maxX; x += levelFactor) {
      for (int y = minY; y < maxY; y += levelFactor) {
        if (x >= 0 && y >= 0 && x < imgWidth && y < imgHeight) {
          int c = img.pixels[y * imgWidth + x];
          fill(c);
          noStroke();
          rect(x, y, levelFactor, levelFactor);
        }
      }
    }
  }
}

void displayUserShapes(User user) {
  int shapeSize = width / 10;
  if (user.id % 2 == 0) {
    fill(255, 180, 180, 100);
    circle(user.position.x, user.position.y, shapeSize);
  } else {
    rectMode(CENTER);
    fill(0, 180, 70, 100);
    rect(user.position.x, user.position.y, shapeSize, shapeSize);
    rectMode(CORNER);
  }
}


void handleClientData() {
  if (myClient.available() > 0) {
    data = myClient.readStringUntil('\n');
    if (data != null) {
      myClient.write("ACK\n");
    }

    if (data != null && !data.substring(0, 7).equals(nothing)) {
      userManager.processObjects(data); // TODO: this needs to be called anyway even when there's no data?
    } else {
      //logger.log("no data");
    };
  } else {
    //logger.log("server not ready");
  };
}
