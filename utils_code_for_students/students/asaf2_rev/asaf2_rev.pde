import processing.net.*;
import processing.sound.*;
import ddf.minim.*;
import ddf.minim.analysis.*;
import ddf.minim.effects.*;
import ddf.minim.signals.*;
import ddf.minim.spi.*;
import ddf.minim.ugens.*;
Minim mi;


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
SoundFile m_sound;
//SoundFile[] sounds = new SoundFile[3];
AudioPlayer[] sounds = new AudioPlayer[3];
boolean[] soundPlayed = new boolean[3];
String chars = "mwc";
int charTypes = 3;
int action_imgs = 8;
int passive_imgs = 2;
PImage [] imgs;
PImage [] m_actionImgs = new PImage[8];
PImage [] m_passiveImgs = new PImage[2];
PImage [] w_actionImgs = new PImage[8];
PImage [] w_passiveImgs = new PImage[2];
PImage [] c_actionImgs = new PImage[8];
PImage [] c_passiveImgs = new PImage[2];
int nImgs = 2;
int imgIndex=0;
int aIndex = 0;
int pIndex = 0;
boolean draw_user; // or draw running shadow.
char c;
int startTime;
int perframes;
int curr;
PImage img; // The image to be attached to the mouse
float start_Time; // To track when the image should detach
boolean isDetached = false; // Flag to check if image is detached from mouse
float angle = 0; // Angle for rotation
float spiralSpeed = 0; // Speed of moving along the spiral
PVector lastMousePos = new PVector(); // Last mouse position before detachment
int chosenSpiralPattern; // Variable to store the chosen spiral pattern

// Define parameters for three different spiral patterns
float[] initialRadiusOptions = {7, 47, 70};
float[] spiralTightnessOptions = {1, 3, 5};


void setup() {
  fullScreen(P3D, 1);
  mi = new Minim(this);

  background(255);
  logger = new Logger("log.txt");
  logger.log("Program started");
  myClient = new Client(this, "127.0.0.1", port); // Use the correct IP and port
  loadMatrixFromFile("../../../resources/transformation_matrix.csv", matrix);
  loadMatrixFromFile("../../../resources/camera_transformation_matrix.csv", camMatrix);

  //sounds[0] = new SoundFile(this, "mixkit_voice_0.wav");
  //sounds[1] = new SoundFile(this, "mixkit_voice_1.wav");
  //sounds[2] = new SoundFile(this, "mixkit_voice_2.wav");

  sounds[0]   = mi.loadFile("mixkit_voice_0.wav", 1024);
  sounds[1]   = mi.loadFile("mixkit_voice_1.wav", 1024);
  sounds[2]   = mi.loadFile("mixkit_voice_2.wav", 1024);


  soundPlayed[0]=false;
  soundPlayed[1]=false;
  soundPlayed[2]=false;

  userManager = new UserManager();
  userManager.initializeUsers("mouse", 1);  // Initialize 1 mouse-controlled user

  for (int i = 0; i < charTypes; i++)
  {
    c = chars.charAt(i);
    for (int j = 0; j < passive_imgs; j++)
    {
      String filename = String.format("%c_walking_0%d.jpg", c, j);
      PImage frame = loadImage(filename);
      frame.resize(int(frame.width * 0.2), int(frame.height * 0.2)); // Resize the image to 20% of its original size
      if (c == 'm')
      {
        m_passiveImgs[j] = frame;
      } else if (c == 'w')
      {
        w_passiveImgs[j] = frame;
      } else
      {
        c_passiveImgs[j] = frame;
      }
    }

    for (int k = 0; k < action_imgs; k++)
    {
      String filename = String.format("%c_action_0%d.jpg", c, k);
      PImage img = loadImage(filename);
      img.resize(int(img.width * 0.2), int(img.height * 0.2)); // Resize the image to 20% of its original size
      if (c == 'm')
      {
        m_actionImgs[k] = img;
      } else if (c == 'w')
      {
        w_actionImgs[k] = img;
      } else
      {
        c_actionImgs[k] = img;
      }
    }
  }
  curr = (int)random(3);
  chosenSpiralPattern = (int) random(3);
  logger.log(String.valueOf(curr));
  c = chars.charAt(curr);
  startTime=millis();
  start_Time = millis();
  draw_user=true;
  //start_time=new int;
  //userManager.initializeUsers("normal", 5); // Initialize 5 normal users
  userManager.initializeUsers("mouse", 1);  // Initialize 1 mouse-controlled user
  applyMatrix(matrix[0][0], matrix[0][1], 0, matrix[0][2],
    matrix[1][0], matrix[1][1], 0, matrix[1][2],
    0, 0, 1, 0,
    matrix[2][0], matrix[2][1], 0, matrix[2][2]);
  perframes=50;
}

void draw() {
  background(0);
  if (millis() - startTime > 7000) {
    draw_user=false;
    perframes=25;
  }
  userManager.run();
  users = userManager.getUsers();
  applyMatrix(matrix[0][0], matrix[0][1], 0, matrix[0][2],
    matrix[1][0], matrix[1][1], 0, matrix[1][2],
    0, 0, 1, 0,
    matrix[2][0], matrix[2][1], 0, matrix[2][2]);
  // After this line you can draw static things on the movement area (or things not related to walkers positions).
  fill(255); // background color of projection area w/ movement
  rect(0, 0, width, height);

  for (User user : users)
  {
    user.show(); //Remove this to hide user dot.
    noStroke();

    if (draw_user==true)
    {
      pushMatrix();
      translate(user.position.x, user.position.y);
      rotate(radians(135));
      lastMousePos.set(user.position.x, user.position.y);
      if (c == 'm')
      {
        image(m_passiveImgs[pIndex], -m_passiveImgs[pIndex].width / 2, -m_passiveImgs[pIndex].height / 2);
      } else if (c == 'w')
      {
        image(w_passiveImgs[pIndex], -w_passiveImgs[pIndex].width / 2, -w_passiveImgs[pIndex].height / 2);
      } else
      {
        image(c_passiveImgs[pIndex], -c_passiveImgs[pIndex].width / 2, -c_passiveImgs[pIndex].height / 2);
      }
      popMatrix();
    } else
    {
      float elapsedTime = (millis() - start_Time) / 1000.0;
      spiralSpeed += elapsedTime * 0.1; // Increase speed over time
      angle += TWO_PI / 60; // Constant rotation speed
      float initialRadius = initialRadiusOptions[chosenSpiralPattern];
      float spiralTightness = spiralTightnessOptions[chosenSpiralPattern];
      float r = initialRadius + spiralSpeed + (spiralTightness * angle); // Radius for Archimedean spiral (r = a + bθ)
      float x = lastMousePos.x + r * cos(angle); // Calculate x position
      float y = lastMousePos.y + r * sin(angle); // Calculate y position

      pushMatrix();
      translate(x, y);
      rotate(radians(135));

      if (c == 'm')
      {
        image(m_actionImgs[aIndex], -m_actionImgs[aIndex].width / 2, -m_actionImgs[aIndex].height / 2);
      } else if (c == 'w')
      {
        image(w_actionImgs[aIndex], -w_actionImgs[aIndex].width / 2, -w_actionImgs[aIndex].height / 2);
      } else
      {
        image(c_actionImgs[aIndex], -c_actionImgs[aIndex].width / 2, -c_actionImgs[aIndex].height / 2);
      }

      popMatrix();

      //play sound
      if (!soundPlayed[curr] && !sounds[curr].isPlaying())
      {
        sounds[curr].play();
        soundPlayed[curr] = true; // Set the flag to true after playing the sound
      }
    }
  }

  if (frameCount % perframes == 0)
  {
    aIndex = (aIndex + 1) % action_imgs;
    pIndex = (pIndex + 1) % passive_imgs;
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
