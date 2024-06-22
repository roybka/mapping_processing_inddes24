import processing.net.*;
import java.util.ArrayList;
import java.util.HashSet;
UserManager userManager;
ArrayList<User> users;
Logger logger;

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
  setup2();
}

import ddf.minim.*;

Minim minim;
AudioPlayer player;

int padding = 150;
float frameScale = 0.07;
class Mover {
  PVector position;
  PVector velocity;
  float size;
  Animation animation; // Include Animation object

  Mover(Animation anim) {
    this.animation = anim; // Assign the animation
    position = new PVector(random(width), random(height));
    velocity = PVector.random2D();
    velocity.mult(random(4, 7));
    size = max(animation.getWidth(), animation.getHeight()); // Adjust size based on animation dimensions
  }

  void update() {
    position.add(velocity);

    // Screen wrapping
    if (position.x > width + padding) position.x = 0;
    if (position.x < -padding) position.x = width;
    if (position.y > height + padding) position.y = 0;
    if (position.y < -padding) position.y = height;
  }

  void display() {
    // Use the animation's display method

    float angle = atan2(velocity.y, velocity.x);
    animation.display(position.x, position.y, angle + PI);
  }

  void checkMouse(float mx, float my) {
    int radius = 300;
    PVector mouse = new PVector(mx, my);
    float d = PVector.dist(position, mouse);

    // Calculate avoidance force more smoothly
    if (d < radius) { // Increased sensitivity range
      PVector diff = PVector.sub(position, mouse);
      float forceMagnitude = map(d, 0, 200, 20, 0); // Stronger when closer
      diff.normalize();
      diff.mult(forceMagnitude);
      position.add(diff);
    }
  }
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

  fill(255); // background color of projection area w/ movement
  rect(0, 0, width, height);



  for (User user : users) {

    //user.show(); //Remove this to hide user dot.
    for (int i = 0; i < movers.length; i++) {
      movers[i].update();
      movers[i].checkMouse(user.position.x, user.position.y);
      movers[i].display();
    }
  }
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

Mover[] movers;
Animation[] animations; // Array to store animations for each mover

void setup2() {
  //size(800, 1600);
  minim = new Minim(this);

  // Load the sound file from the 'data' folder
  player = minim.loadFile("cockroachrun.mp3");

  // Play the sound file


  int numAnimations = 100;
  int numFrames = 8; // Number of frames per animation
  //frameRate(20);
  movers = new Mover[numAnimations];
  animations = new Animation[numAnimations];

  // Load animations
  for (int i = 0; i < numAnimations; i++) {
    animations[i] = new Animation("frame", numFrames, frameScale, frameScale);
  }

  // Initialize movers with animations
  for (int i = 0; i < movers.length; i++) {
    movers[i] = new Mover(animations[i]);
  }
  player.loop();
}


void stop() {
  // Close the player and Minim when the sketch stops
  player.close();
  minim.stop();

  super.stop();
}
