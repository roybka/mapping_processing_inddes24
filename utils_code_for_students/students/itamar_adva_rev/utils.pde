import processing.net.*;
int cam_w=1280;
int cam_h=720;


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
float[] transform(float x, float y){
  float[] out=new float[2];
  float a=camMatrix[0][0]*x+camMatrix[0][1]*y+camMatrix[0][2]*1;
  float b=camMatrix[1][0]*x+camMatrix[1][1]*y+camMatrix[1][2]*1;
  float c=camMatrix[2][0]*x+camMatrix[2][1]*y+camMatrix[2][2]*1;

  out[0]=a/c;
  out[1]=b/c;
 return out;
}
