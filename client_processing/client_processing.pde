// not ready.
// todo: make objects persistent?
// todo: kalman filter?
// add logs
import processing.net.*;
Logger logger;
String data = "";
int st=0;
int port=12345;
String nothing = "Nothing";
PMatrix m;
float[][] matrix = new float[4][4];
float[][] camMatrix = new float[4][4];
Client myClient;
int backGroundColor=44;


void loadMatrixFromFile(String filename, float[][] mat) {
  String[] rows = loadStrings(filename);
  for (int i = 0; i < rows.length; i++) {
    String[] cols = split(rows[i], ',');
    for (int j = 0; j < cols.length; j++) {
      mat[i][j] = float(cols[j]);
    }
  }
}

void drawObjects(String data) {
  logger.log("Data received: " + data);
  ArrayList<float[]> objectData = parseData(data);
  for (float[] obj : objectData) {

  fill(144);
    circle((int) obj[3], (int) obj[4], 200);  // Example of drawing a ring for each object
    fill(0);
    circle((int) obj[3], (int) obj[4], 150);  
    
  }
}

ArrayList<float[]> parseData(String data) {
  ArrayList<float[]> list = new ArrayList<float[]>();
  String[] items = split(data.substring(1, data.length() - 1), "],[");
  for (String item : items) {
    String[] elements = split(item, ",");
    float[] floats = new float[elements.length];
    for (int j = 0; j < elements.length; j++) {
      floats[j] = parseFloat(elements[j]);
    }
    list.add(floats);
  }
  return list;
}

void setup() {
logger = new Logger("log.txt");
logger.log("Program started");
  frameRate(30);
  fullScreen(P3D, 1);
  background(255);
  println(width);
  println(height);
  // Connect to the server's IP and the port
  myClient = new Client(this, "127.0.0.1", port); // Use the correct IP and port
  loadMatrixFromFile("../resources/transformation_matrix.csv", matrix);
  loadMatrixFromFile("../resources/camera_transformation_matrix.csv", camMatrix);
  fill(0);
  applyMatrix(matrix[0][0], matrix[0][1], 0, matrix[0][2],
    matrix[1][0], matrix[1][1], 0, matrix[1][2],
    0, 0, 1, 0,
    matrix[2][0], matrix[2][1], 0, matrix[2][2]);

}

void draw() {
  println(millis()-st);
  st=millis();

  background(255); // background color in edges

  //delay(1);
  applyMatrix(matrix[0][0], matrix[0][1], 0, matrix[0][2],
    matrix[1][0], matrix[1][1], 0, matrix[1][2],
    0, 0, 1, 0,
    matrix[2][0], matrix[2][1], 0, matrix[2][2]);

  fill(backGroundColor); // background color of projection area w/ movement
  rect(0, 0, width, height);
  applyMatrix(camMatrix[0][0], camMatrix[0][1], 0, camMatrix[0][2],
    camMatrix[1][0], camMatrix[1][1], 0, camMatrix[1][2],
    0, 0, 1, 0,
    camMatrix[2][0], camMatrix[2][1], 0, camMatrix[2][2]);
  //printArray(m.get(new float[]{}));
  fill(0);
  if (myClient.available() > 0) {
    data = myClient.readStringUntil('\n');
    if (data != null) {
      myClient.write("ACK\n");
    }

    if (data != null && !data.substring(0, 7).equals(nothing)) {
      drawObjects(data);
    } else {
      logger.log("no data");
    };
  } else {
    logger.log("server not ready");
  };
  //println(millis()-st);
}
