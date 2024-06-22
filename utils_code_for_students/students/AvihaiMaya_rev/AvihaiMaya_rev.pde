import processing.sound.*;

import ddf.minim.*;
import ddf.minim.analysis.*;
import ddf.minim.effects.*;
import ddf.minim.signals.*;
import ddf.minim.spi.*;
import ddf.minim.ugens.*;

Minim mi;

import java.util.ArrayList;
import processing.net.*;
import java.util.ArrayList;
import java.util.HashSet;
UserManager userManager;
ArrayList<User> users;
Logger logger;

ArrayList<Particle> particles = new ArrayList<Particle>();
int res = 20;
PImage img;
PImage particleImg;
//SoundFile moveSound;
AudioPlayer moveSound;

String data = "";
int st=0;
int port=12345;
String nothing = "Nothing";
PMatrix m;
float[][] matrix = new float[4][4];
float[][] camMatrix = new float[4][4];
Client myClient;

void setup() {
  fullScreen(P3D, 1);
  background(255);
  //blendMode(BLEND);

  logger = new Logger("log.txt");
  logger.log("Program started");
  myClient = new Client(this, "127.0.0.1", port); // Use the correct IP and port
  loadMatrixFromFile("../../../resources/transformation_matrix.csv", matrix);
  loadMatrixFromFile("../../../resources/camera_transformation_matrix.csv", camMatrix);

  userManager = new UserManager();
  //userManager.initializeUsers("normal", 5); // Initialize 5 normal users
  //userManager.initializeUsers("mouse", 1);  // Initialize 1 mouse-controlled user
  applyMatrix(matrix[0][0], matrix[0][1], 0, matrix[0][2],
    matrix[1][0], matrix[1][1], 0, matrix[1][2],
    0, 0, 1, 0,
    matrix[2][0], matrix[2][1], 0, matrix[2][2]);
  mi = new Minim(this);
  img = loadImage("pic/hope2.png");
  particleImg = loadImage("pic/maple.png");
  particleImg = makeTransparent(particleImg);

  //moveSound = new SoundFile(this, "sounds/1.mp3");
  moveSound = mi.loadFile("sounds/1.mp3", 1024);
  //moveSound.amp(0); // Set initial volume to 0
  moveSound.setGain(0);
  placeParticles();
  for (Particle particle : particles) {
    //particle.update(user.position.x, user.position.y);
    particle.draw();
  }
  noStroke();
  image(img, 0, 0, width, height); // Draw the background image
}
////#################3STUDENTS


void draw() {
  background(255);
  userManager.run();

  users = userManager.getUsers();

  applyMatrix(matrix[0][0], matrix[0][1], 0, matrix[0][2],
    matrix[1][0], matrix[1][1], 0, matrix[1][2],
    0, 0, 1, 0,
    matrix[2][0], matrix[2][1], 0, matrix[2][2]);
  // After this line you can draw static things on the movement area (or things not related to walkers positions).

  fill(255); // background color of projection area w/ movement
  rect(0, 0, width, height);

  image(img, 0, 0, width, height); // Draw the background image

  if ((users.size())==0) {
    for (Particle particle : particles) {
      //particle.update(user.position.x, user.position.y);
      particle.draw();
    }
  }


  ////#################3STUDENTS

  float totalMovement = 10;

  for (User user : users) {

    user.show(); //Remove this to hide user dot.
    for (Particle particle : particles) {
      particle.update(user.position.x, user.position.y);
      particle.draw();
      totalMovement += particle.movementDistance();
    }
  }

  float volume = map(totalMovement, 0, 1000, 0, 1); // Adjust the mapping range as needed
  volume = constrain(volume, 0, 1); // Ensure volume is within 0 to 1
  //moveSound.amp(volume);
  moveSound.setGain(volume );

  if (totalMovement > 0) {
    if (!moveSound.isPlaying()) {
      println("Playing sound");
      moveSound.loop(); // Start the sound in loop mode
    }
  } else {
    if (moveSound.isPlaying()) {
      println("Stopping sound");
      //moveSound.stop(); // Stop the sound
      moveSound.pause( );
    }
  }



  ////#################3STUDENTS


  fill(144);
  if (myClient.available() > 0) {
    data = myClient.readStringUntil('\n');
    if (data != null) {
      myClient.write("ACK\n");
    }

    if (data != null && !data.substring(0, 7).equals(nothing)) {
      userManager.processObjects(data); // TODO: this needs to be called anyway even when there's no data?
    } else {
      logger.log("no data");
    };
  } else {
    logger.log("server not ready");
  };
}



void placeParticles() {

  img.loadPixels();
  for (int i = 0; i < width; i += res) {
    for (int j = 0; j < height; j += res) {
      int x = int((i / (float)width) * img.width);
      int y = int((j / (float)height) * img.height);
      int c = img.get(x, y);
      if (red(c) + green(c) + blue(c) != 255 * 3) {
        particles.add(new Particle(i, j, c));
      }
    }
  }
  img.updatePixels();
}



PImage makeTransparent(PImage img) {
  PImage result = createImage(img.width, img.height, ARGB);
  img.loadPixels();
  result.loadPixels();

  for (int y = 0; y < img.height; y++) {
    for (int x = 0; x < img.width; x++) {
      int index = x + y * img.width;
      color c = img.pixels[index];

      if (red(c) > 180 && green(c) > 180 && blue(c) > 180) {
        result.set(x, y, color(255, 255, 255, 0));
      } else {
        result.set(x, y, c);
      }
    }
  }

  result.updatePixels();
  return result;
}

class Particle {
  float x, y, homeX, homeY, size, angle;
  color c;
  float prevX, prevY, movedDistance;

  Particle(float x, float y, color c) {
    this.x = x;
    this.y = y;
    this.c = c;
    this.homeX = x;
    this.homeY = y;
    this.size = random(25, 100); // Random size between 10 and 50
    this.angle = random(TWO_PI); // Random angle between 0 and 2*PI
    this.prevX = x;
    this.prevY = y;
    this.movedDistance = 0;
  }

  void update(float x, float y) {
    // mouse
    float mouseD = dist(this.x, this.y, x, y);
    float mouseA = atan2(this.y - mouseY, this.x - mouseX);
    // home
    float homeD = dist(this.x, this.y, this.homeX, this.homeY);
    float homeA = atan2(this.homeY - this.y, this.homeX - this.x);
    // forces
    float mouseF = constrain(map(mouseD, 0, 120, 10, 0), 0, 10);
    float homeF = map(homeD, 0, 100, 0, 10);
    float vx = cos(mouseA) * mouseF;
    vx += cos(homeA) * homeF;
    float vy = sin(mouseA) * mouseF;
    vy += sin(homeA) * homeF;

    this.prevX = this.x;
    this.prevY = this.y;

    this.x += vx;
    this.y += vy;

    // Calculate movement distance
    this.movedDistance = dist(this.prevX, this.prevY, this.x, this.y);
  }

  float movementDistance() {
    return this.movedDistance;
  }

  void draw() {
    pushMatrix();
    translate(this.x, this.y);
    rotate(this.angle);
    image(particleImg, -this.size / 2, -this.size / 2, this.size, this.size); // Draw the particle image with random size and angle

    popMatrix();
  }
}
