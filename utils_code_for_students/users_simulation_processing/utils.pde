import processing.net.*;
int cam_w=640;
int cam_h=480;

void loadMatrixFromFile(String filename, float[][] mat) {
  String[] rows = loadStrings(filename);
  for (int i = 0; i < rows.length; i++) {
    String[] cols = split(rows[i], ',');
    for (int j = 0; j < cols.length; j++) {
      mat[i][j] = float(cols[j]);
    }
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
