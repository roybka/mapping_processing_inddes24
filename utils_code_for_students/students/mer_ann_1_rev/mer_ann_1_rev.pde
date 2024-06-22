import processing.net.*;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.HashMap;


import processing.sound.*;
IntDict colors;


float max_distance;
float rippleSpeed = 0.1;
UserManager userManager;
ArrayList<User> users;
Logger logger;
boolean two_meet = false; // Initialize two_meet to false
boolean isPlaying = false; // Track if a sound is currently playing
String data = "";
int st = 0;
int port = 12345;
String nothing = "Nothing";
PMatrix m;
int [] possible_colors_up = new int [5];
int [] possible_colors_down = new int [5];
int meeting_dist;
float[][] matrix = new float[4][4];
float[][] camMatrix = new float[4][4];
Client myClient;

HashMap <String, Integer> arePlaying;
SoundFile[] soundFiles = new SoundFile[5];
int playing_k;
int color_k;
void setup() {
  frameRate(30);
  fullScreen(P3D, 1);
  background(255);
  logger = new Logger("log.txt");
  logger.log("Program started");
  myClient = new Client(this, "127.0.0.1", port); // Use the correct IP and port
  loadMatrixFromFile("../../../resources/transformation_matrix.csv", matrix);
  loadMatrixFromFile("../../../resources/camera_transformation_matrix.csv", camMatrix);

  // Load sound files into the array
  soundFiles[0] = new SoundFile(this, "sound1.wav");
  soundFiles[1] = new SoundFile(this, "sound2.wav");
  soundFiles[2] = new SoundFile(this, "sound3.wav");
  soundFiles[3] = new SoundFile(this, "sound4.wav");
  soundFiles[4] = new SoundFile(this, "sound5.wav");
  possible_colors_up[0]=30;
  possible_colors_up[1]=60;
  possible_colors_up[2]=90;
  possible_colors_up[3]=180;
  possible_colors_up[4]=300;
  for (int j=0; j<5; j++) {
    possible_colors_down[j]=possible_colors_up[j]-80;
  }
  arePlaying = new HashMap<String, Integer>();
  playing_k=0;
  color_k=0;
  meeting_dist=200;
  userManager = new UserManager();
  // userManager.initializeUsers("normal", 5); // Initialize 5 normal users
  //userManager.initializeUsers("mouse", 1);  // Initialize 1 mouse-controlled user
  applyMatrix(matrix[0][0], matrix[0][1], 0, matrix[0][2],
    matrix[1][0], matrix[1][1], 0, matrix[1][2],
    0, 0, 1, 0,
    matrix[2][0], matrix[2][1], 0, matrix[2][2]);
  println(transform(180, 82));

  colors = new IntDict();
  max_distance = dist(20, 20, width / 5, height / 5);
  st = millis();
}

void draw() {
  //println(millis() - st);
  st = millis();
  background(255);
  userManager.run();

  users = userManager.getUsers();

  // Reset two_meet to false at the start of each frame
  two_meet = false;

  // Check if any two users are within 500 pixels of each other DISTANCE OF USERS
  for (int i = 0; i < users.size(); i++) {
    for (int j = i + 1; j < users.size(); j++) {

      User user1 = users.get(i);
      User user2 = users.get(j);

      String k = str(user1.id)+str(user2.id);

      float distance = dist(user1.position.x, user1.position.y, user2.position.x, user2.position.y);
      if (distance <= meeting_dist) {
        if (arePlaying.containsKey(k)) {
          if (!soundFiles[arePlaying.get(k)].isPlaying()) {
            soundFiles[arePlaying.get(k)].play();
          }
        } else {
          arePlaying.put(k, playing_k%5);

          playing_k+=1;
          soundFiles[arePlaying.get(k)].play();
        }
      } else
      {
        if (arePlaying.containsKey(k)) {

          soundFiles[arePlaying.get(k)].stop();
          arePlaying.remove(k);
        }
      }
    }
  }


  applyMatrix(matrix[0][0], matrix[0][1], 0, matrix[0][2],
    matrix[1][0], matrix[1][1], 0, matrix[1][2],
    0, 0, 1, 0,
    matrix[2][0], matrix[2][1], 0, matrix[2][2]);


  // After this line you can draw static things on the movement area (or things not related to walkers positions).

  fill(0); // background color of projection area w/ movement
  rect(0, 0, width, height);





  // ##### EXAMPLE CODE: divide the users to 2 random groups rect VS circle #####
  for (User user : users) { // Run on all users
    if (!colors.hasKey(str(user.id))) {
      colors.set(str(user.id), color_k%5); // this now stores the index for possible_colors_up,possible_colors_down
      color_k+=1;
    }

    for (int i = 0; i <= width; i += 15) {
      for (int j = 0; j <= height; j += 15) {
        float distance = dist(user.position.x, user.position.y, i, j);

        // Skip drawing if distance is greater than max_distance
        if (distance > max_distance) {
          continue;
        }

        float size = map(distance, 0, max_distance, 12, -5); // Adjusted size mapping
        float hue = map(distance, 0, max_distance, possible_colors_up[colors.get(str(user.id))], possible_colors_down[colors.get(str(user.id))]); // Scale down the hue gradient

        // Calculate ripple effect amplitude based on distance
        float amplitude = map(distance, 0, max_distance, 5, 0);
        float ripple = sin((frameCount * rippleSpeed) - (distance / 10.0)) * amplitude;

        size += ripple;

        // Ensure the size stays within desired bounds
        size = constrain(size, 0, 15);

        // Convert hue to RGB color
        colorMode(HSB, 360, 100, 100);
        fill(hue, 100, 100);
        ellipse(i, j, size, size);
      }
    }
  }
  // ##### END EXAMPLE #####

  //fill(144);
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
