import ddf.minim.*;
import ddf.minim.analysis.*;
import ddf.minim.effects.*;
import ddf.minim.signals.*;
import ddf.minim.spi.*;
import ddf.minim.ugens.*;

import processing.sound.*;
Minim m;
import processing.net.*;
import java.util.ArrayList;
import java.util.HashSet;
AudioPlayer energySound;
UserManager userManager;
ArrayList<User> users;
Logger logger;

///####STUDENTS
ArrayList<Ripple> ripples = new ArrayList<Ripple>();
int maxRipples = 20; // Maximum number of ripples
int rippleInterval = 16; // Interval in frames to create new ripples
int maxAge = 100; // Number of frames after which ripples start fading
//SoundFile energySound; // Variable to hold the sound file
boolean soundPlaying = false; // Variable to track if the sound is currently playing

float scaleFactor = 1.8; // Scale factor to increase sizes by 20%
float rippleStartRadius = 75; // Start ripples 75px away from the user
float currentVolume = 0; // Track current volume for manual fade out

///####STUDENTS


String data = "";
int port = 12345;
String nothing = "Nothing";
Client myClient;
float[][] matrix = new float[4][4];
float[][] camMatrix = new float[4][4];

void setup() {
  fullScreen(P3D, 1);
  background(255);
  logger = new Logger("log.txt");
  logger.log("Program started");
  myClient = new Client(this, "127.0.0.1", port); // Use the correct IP and port
  loadMatrixFromFile("../../../resources/transformation_matrix.csv", matrix);
  loadMatrixFromFile("../../../resources/camera_transformation_matrix.csv", camMatrix);

  userManager = new UserManager();
  //userManager.initializeUsers("normal", 1); // Initialize 5 normal users
  //userManager.initializeUsers("mouse", 1);  // Initialize 1 mouse-controlled user
  applyMatrix(matrix[0][0], matrix[0][1], 0, matrix[0][2],
    matrix[1][0], matrix[1][1], 0, matrix[1][2],
    0, 0, 1, 0,
    matrix[2][0], matrix[2][1], 0, matrix[2][2]);
  m = new Minim(this);
  energySound = m.loadFile("energy.mp3", 1024);
}


void draw() {
  background(255);
  userManager.run();

  users = userManager.getUsers();

  applyMatrix(matrix[0][0], matrix[0][1], 0, matrix[0][2],
    matrix[1][0], matrix[1][1], 0, matrix[1][2],
    0, 0, 1, 0,
    matrix[2][0], matrix[2][1], 0, matrix[2][2]);
  // After this line you can draw static things on the movement area (or things not related to walkers positions).

  fill(44); // background color of projection area w/ movement
  rect(0, 0, width, height);

  //  applyMatrix(camMatrix[0][0], camMatrix[0][1], 0, camMatrix[0][2],
  //    camMatrix[1][0], camMatrix[1][1], 0, camMatrix[1][2],
  //    0, 0, 1, 0,
  //    camMatrix[2][0], camMatrix[2][1], 0, camMatrix[2][2]);
  //printArray(m.get(new float[]{}));
  // After this line you can draw dynamic things (coordinates of camera are transformed)


  ///####STUDENTS
  background(0); // Dark background
  for (User user : users) {
    createRipples(user.position.x, user.position.y, user.id);
    //user.show(); // Remove this to hide user dot.
  }

  // Update and display ripples
  for (Ripple ripple : ripples) {
    ripple.update();
    ripple.display();
  }

  // Check for ripple intersections and draw dots and lines at the intersection points
  float soundVolume = 0; // Initialize the volume for this frame
  int intersections = 0; // Count the number of intersections
  for (int i = 0; i < ripples.size(); i++) {
    for (int j = i + 1; j < ripples.size(); j++) {
      float intersectionVolume = drawIntersectionDotsAndLines(ripples.get(i), ripples.get(j));
      if (intersectionVolume > 0) {
        soundVolume += intersectionVolume;
        intersections++;
      }
    }
  }

  // Adjust the sound volume based on the distance
  if (intersections > 0) {
    soundVolume = constrain(soundVolume / intersections, 0, 1); // Average and constrain the volume
    if (!energySound.isPlaying()) {
      println("playing");
      energySound.play();
    }
    currentVolume = soundVolume;
    //energySound.amp(soundVolume); // Set the volume based on distance
    soundPlaying = true;
  } else if (soundPlaying) {
    // Fade out the sound manually
    //currentVolume = max(0, currentVolume - 0.05); // Quicker fade-out step
    //energySound.amp(currentVolume);

    energySound.pause( );
    //if (currentVolume == 0) {
    //energySound.stop();
    //soundPlaying = false;
    //}
  }


  // Remove ripples that are too old
  for (int i = ripples.size() - 1; i >= 0; i--) {
    if (ripples.get(i).isFinished()) {
      ripples.remove(i);
    }
  }


  ///####STUDENTS

  fill(144);
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



void handleClientData() {
  if (myClient.available() > 0) {
    data = myClient.readStringUntil('\n');
    if (data != null) {
      myClient.write("ACK\n");
    }
    if (data != null && !data.equals(nothing)) {
      userManager.processObjects(data);
    } else {
      //logger.log("no data");
    }
  } else {
    //logger.log("server not ready");
  }
}


void keyPressed() {
  if (key == '+' || key == '=') {
    userManager.addNormalUser();
  } else if (key == '-') {
    userManager.removeNormalUser();
  }
}

///####STUDENTS


void createRipples(float x, float y, int userId) {
  // Add new ripple periodically
  if (frameCount % rippleInterval == 0) {
    ripples.add(new Ripple(x, y, frameCount, userId));
  }
}

float drawIntersectionDotsAndLines(Ripple ripple1, Ripple ripple2) {
  float d = dist(ripple1.x, ripple1.y, ripple2.x, ripple2.y);
  if (d < (ripple1.diameter + ripple2.diameter) / 2 && d > abs(ripple1.diameter - ripple2.diameter) / 2) {
    float a = (sq(ripple1.diameter / 2) - sq(ripple2.diameter / 2) + sq(d)) / (2 * d);
    float h = sqrt(sq(ripple1.diameter / 2) - sq(a));
    float p2x = ripple1.x + a * (ripple2.x - ripple1.x) / d;
    float p2y = ripple1.y + a * (ripple2.y - ripple1.y) / d;
    float intersectionX1 = p2x + h * (ripple2.y - ripple1.y) / d;
    float intersectionY1 = p2y - h * (ripple2.x - ripple1.x) / d;
    float intersectionX2 = p2x - h * (ripple2.y - ripple1.y) / d;
    float intersectionY2 = p2y + h * (ripple2.x - ripple1.x) / d;

    fill(255); // White fill color for intersections
    noStroke();
    ellipse(intersectionX1, intersectionY1, 4 * scaleFactor, 4 * scaleFactor); // Increase size by 20%
    ellipse(intersectionX2, intersectionY2, 4 * scaleFactor, 4 * scaleFactor); // Increase size by 20%

    // Draw lines between users if their ripples intersect
    User user1 = null;
    User user2 = null;
    for (User user : users) {
      if (dist(user.position.x, user.position.y, ripple1.x, ripple1.y) < ripple1.diameter / 2) {
        user1 = user;
      }
      if (dist(user.position.x, user.position.y, ripple2.x, ripple2.y) < ripple2.diameter / 2) {
        user2 = user;
      }
    }

    if (user1 != null && user2 != null && user1 != user2) {
      stroke(255); // White stroke color for lines
      strokeWeight(1.6 * scaleFactor); // Increase size by 20%
      line(user1.position.x, user1.position.y, user2.position.x, user2.position.y);

      // Return the volume based on the distance between the users
      float maxDistance = dist(0, 0, width, height);
      return map(d, 0, maxDistance, 1, 0);
    }
  }
  return 0;
}

class Ripple {
  float x, y;
  int creationFrame;
  int age;
  float diameter;
  int userId;
  String userType;

  Ripple(float x, float y, int creationFrame, int userId) {
    this.x = x;
    this.y = y;
    this.creationFrame = creationFrame;
    this.age = 0;
    this.diameter = rippleStartRadius * 2; // Start diameter at 75px radius
    this.userId = userId;
    this.userType = userId == 0 ? "mouse" : "normal"; // Check if the user is mouse-controlled
  }

  void update() {
    this.age = frameCount - this.creationFrame;
    this.diameter = (rippleStartRadius + this.age * 1.4 * scaleFactor) * 2; // Adjust gaps and size by scaleFactor

    // Update position based on corresponding user position
    for (User user : users) {
      if (user.id == this.userId) {
        this.x = user.position.x;
        this.y = user.position.y;
      }
    }

    if (this.age > maxAge) {
      this.reset();
    }
  }

  void display() {
    float alpha = map(this.age, 0, maxAge, 255, 0);
    stroke(255, alpha); // White stroke color for ripples
    strokeWeight(1.6 * scaleFactor); // Adjust stroke weight based on scale factor
    noFill();
    ellipse(this.x, this.y, this.diameter, this.diameter);
  }

  boolean isFinished() {
    return this.age > maxAge;
  }

  void reset() {
    this.creationFrame = frameCount;
    this.diameter = rippleStartRadius * 2; // Reset diameter to start at 75px radius
  }
}

///####STUDENTS
