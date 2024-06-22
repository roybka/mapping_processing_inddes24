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
  loadMatrixFromFile("../../resources/transformation_matrix.csv", matrix);
  loadMatrixFromFile("../../resources/camera_transformation_matrix.csv", camMatrix);

  userManager = new UserManager();
  //userManager.initializeUsers("normal", 5); // Initialize 5 normal users
  //userManager.initializeUsers("mouse", 1);  // Initialize 1 mouse-controlled user
  applyMatrix(matrix[0][0], matrix[0][1], 0, matrix[0][2],
    matrix[1][0], matrix[1][1], 0, matrix[1][2],
    0, 0, 1, 0,
    matrix[2][0], matrix[2][1], 0, matrix[2][2]);
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



  applyMatrix(camMatrix[0][0], camMatrix[0][1], 0, camMatrix[0][2],
    camMatrix[1][0], camMatrix[1][1], 0, camMatrix[1][2],
    0, 0, 1, 0,
    camMatrix[2][0], camMatrix[2][1], 0, camMatrix[2][2]);
  //printArray(m.get(new float[]{}));
  // After this line you can draw dynamic things (coordinates of camera are transformed)


  for (User user : users) {

    user.show(); //Remove this to hide user dot.
    // ##### EXAMPLE CODE: divide the users to 2 random groups rect VS circle #####
    noStroke();

    int shapeSize = width/10;
    if (user.id % 2 == 0) { // if user id is even
      fill(255, 180, 180, 100);
      circle(user.position.x, user.position.y, shapeSize);
    } else { // if user id is odd
      rectMode(CENTER);
      fill(0, 180, 70, 100);
      rect(user.position.x, user.position.y, shapeSize, shapeSize);
      rectMode(CORNER);
    }
    // ##### END EXAMPLE #####
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

void keyPressed() {
  switch(key) {
  case '+':
  case '=': // Handle both keys due to keyboard layout differences
    userManager.addNormalUser();
    break;
  case '-':
    userManager.removeNormalUser();
    break;
  }
}
