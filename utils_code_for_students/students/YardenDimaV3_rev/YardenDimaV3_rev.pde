import processing.net.*;
import java.util.ArrayList;
import java.util.HashSet;

UserManager userManager;
ArrayList<User> users;
Logger logger;

String data = "";
int st = 0;
int port = 12345;
int score = 0;
String nothing = "Nothing";
PMatrix m;
float[][] matrix = new float[4][4];
float[][] camMatrix = new float[4][4];
Client myClient;

int rez = 20;  // Resolution scale factor
PVector food;
int w;
int h;
PFont retroFont;

Snake snake;

void setup() {
  fullScreen(P3D, 1);
  background(255);
  //frameRate(1); // Set the frame rate to X frames per second
  retroFont = createFont("PixelifySans-Regular.ttf", 32); // Load the retro font with size 32
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

void draw() {
  background(255);
  userManager.run();

  users = userManager.getUsers();

  applyMatrix(matrix[0][0], matrix[0][1], 0, matrix[0][2],
    matrix[1][0], matrix[1][1], 0, matrix[1][2],
    0, 0, 1, 0,
    matrix[2][0], matrix[2][1], 0, matrix[2][2]);
  fill(169, 244, 0);
  rect(0, 0, width, height);

  // Draw users and snake
  for (User user : users) {
    user.show();
    snake.update(user.position.x, user.position.y);
  }

  if (snake.eat(food)) {
    foodLocation();
  }
  snake.show();

  // Draw the food as a cross with a missing center
  noStroke();
  fill(22, 29, 0);
  drawCross(food.x * rez, food.y * rez);  // Adjusted to draw food at the correct scale

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
    }
  } else {
    logger.log("server not ready");
  }

  // Draw score board
  fill(0);
  textFont(retroFont); // Set the font for the game over message
  textSize(70);
  textAlign(LEFT, TOP);
  text("Score: " + score, 10, 10);

  // Check for collision with own tail
  if (snake.checkCollision()) {
    gameOver();
  }
}

void setup2() {
  w = floor(width / rez);  // Corrected screen width in grid units
  h = floor(height / rez); // Corrected screen height in grid units
  frameRate(30);
  snake = new Snake();
  foodLocation();
}

void foodLocation() {
  int x = floor(random(w));  // Ensure food is within grid width
  int y = floor(random(h));  // Ensure food is within grid height
  food = new PVector(x, y);
  println("Food location: " + food.x + ", " + food.y);  // Debug: Print food coordinates
}

void drawCross(float x, float y) {
  //// Adjusted to ensure proper drawing of the cross
  rect(x - 0.5 * rez, y, 0.5 * rez, 0.5 * rez); // Left
  rect(x + 0.5 * rez, y, 0.5 * rez, 0.5 * rez); // Right
  rect(x, y - 0.5 * rez, 0.5 * rez, 0.5 * rez); // Top
  rect(x, y + 0.5 * rez, 0.5 * rez, 0.5 * rez); // Bottom
}

// Snake class with adjusted coordinates
class Snake {
  ArrayList<PVector> body;
  int xdir;
  int ydir;
  int len;

  Snake() {
    body = new ArrayList<PVector>();
    body.add(new PVector(floor(w / 2), floor(h / 2)));
    xdir = 0;
    ydir = 0;
    len = 1;
  }

  void setDir(int x, int y) {
    xdir = x;
    ydir = y;
  }

  void updateDirection(float x, float y) {
    PVector head = body.get(body.size() - 1);
    float dx = x / rez - head.x;
    float dy = y / rez - head.y;
    if (abs(dx) > abs(dy)) {
      if (dx > 0) {
        setDir(1, 0);
      } else {
        setDir(-1, 0);
      }
    } else {
      if (dy > 0) {
        setDir(0, 1);
      } else {
        setDir(0, -1);
      }
    }
  }

  void update(float x, float y) {
    updateDirection(x, y);
    PVector head = body.get(body.size() - 1).copy();
    head.x += xdir;
    head.y += ydir;

    head.x = (head.x + w) % w;
    head.y = (head.y + h) % h;

    body.add(head);

    if (body.size() > len) {
      body.remove(0);
    }
  }

  void show() {
    fill(22, 29, 0);
    for (PVector v : body) {
      noStroke();
      rect(v.x * rez, v.y * rez, rez, rez);  // Adjusted to draw snake at the correct scale
    }
  }

  boolean eat(PVector pos) {
    PVector head = body.get(body.size() - 1);
    if (head.x == pos.x && head.y == pos.y) {
      len++;
      score++;  // Increment score when snake eats food
      return true;
    }
    return false;
  }

  boolean checkCollision() {
    if (score < 10) {
      return false;  // No collision detection until score is 10 or higher
    }

    PVector head = body.get(body.size() - 1);
    for (int i = 0; i < body.size() - 1; i++) {
      PVector segment = body.get(i);
      if (head.x == segment.x && head.y == segment.y) {
        println("Collision detected at: " + segment);
        return true;  // Collision detected
      }
    }
    return false;  // No collision
  }
}

void gameOver() {
  // Display game over message
  fill(255, 0, 0); // Red color for game over message
  textFont(retroFont); // Set the font for the game over message
  textSize(100);
  textAlign(CENTER, CENTER + 10);
  text("Game Over", width/2, height/2 - 20);
  textSize(50);
  text("Score: " + score, width/2, height/2 + 20);

  noLoop(); // Stop the draw loop to freeze the game
}
