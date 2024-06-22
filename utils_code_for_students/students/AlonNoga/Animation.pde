class Animation {
  PImage[] images;
  int imageCount;
  int frame;
  float scaleX;
  float scaleY;
  
  Animation(String imagePrefix, int count, float scaleX, float scaleY) {
    imageCount = count;
    images = new PImage[imageCount];

    for (int i = 0; i < imageCount; i++) {
      // Use nf() to number format 'i' into four digits
      String filename = imagePrefix + nf(i, 1) + ".gif";
      images[i] = loadImage(filename);
      images[i].resize(int(images[i].width * scaleX), int(images[i].height * scaleY));
    }
  }
  
  void display(float xpos, float ypos, float angle) {
        pushMatrix();  // Save the current state of the coordinate system
        translate(xpos, ypos);  // Move to the object's position
        rotate(angle);  // Rotate the image by the angle
        image(images[frame], -images[frame].width / 2, -images[frame].height / 2);  // Draw the image centered
        popMatrix();  // Restore the original coordinate system state
        frame = (frame + 1) % imageCount;  // Update frame for animation
    }
  
  int getWidth() {
    return images[0].width;
  }
  
  int getHeight() {
    return images[0].height;
  }
}
