
class UserManager {
  ArrayList<User> users = new ArrayList<User>();
  HashSet<Integer> usedIds = new HashSet<Integer>();

  UserManager() {
    // Constructor stays clean
  }

  void initializeUsers(String type, int count) {
    for (int i = 0; i < count; i++) {
      int id = generateUniqueId();
      color col = generateRandomColor(); // Safe to call here if within setup()
      PVector position = new PVector(random(width), random(height));
      if (type.equals("normal")) {
        users.add(new NormalUser(id, position, col));
      } else if (type.equals("mouse")) {
        users.add(new MouseUser(id, col));
      }
    }
  }

  int generateUniqueId() {
    int id;
    do {
      id = floor(random(1000));
    } while (usedIds.contains(id));
    usedIds.add(id);
    return id;
  }

  void addNormalUser() {
    int id = generateUniqueId();
    color col = generateRandomColor();
    PVector position = new PVector(random(cam_w), random(cam_h));
    users.add(new NormalUser(id, position, col));
  }

  void removeNormalUser() {
    // This method removes the first normal user found and frees their ID
    for (int i = users.size() - 1; i >= 0; i--) {
      User user = users.get(i);
      if (user instanceof NormalUser) {
        usedIds.remove(user.id);  // Remove the ID from the used set, freeing it up for reuse
        users.remove(i);  // Remove the user from the list
        break; // Stop after removing one user to ensure only one user is removed per key press
      }
    }
  }
  void addRealUser(int id, int x, int y) {
    println("adding new user");
    color col = generateRandomColor();
    PVector position = new PVector(x, y);
    users.add(new RealUser(id, position, col, millis()));
    usedIds.add(id);
  }

  void removeRealUser(int id) {
    println("removing  "+str(id));
    // This method removes the first normal user found and frees their ID
    for (int i = users.size() - 1; i >= 0; i--) {
      User user = users.get(i);
      if (user.id==id) {
        usedIds.remove(id);  // Remove the ID from the used set, freeing it up for reuse
        users.remove(i);  // Remove the user from the list
      }
    }
  }


  void processObjects(String data) {
    logger.log("Data received: " + data);
    ArrayList<float[]> objectData = parseData(data);
    for (float[] obj : objectData) {
      //circle((int) obj[3], (int) obj[4], 100);  // Example of drawing a ring for each object
      //fill(44);
      //circle((int) obj[3], (int) obj[4], 80);
      //fill(144);
      int id=int(obj[0]);
      int cls=int(obj[1]);
      float conf=obj[2];
      int x=int(obj[3]);
      int y=int(obj[4]);


      if (usedIds.contains(id)) { //this user already exist, lets update it

        for (int i = users.size() - 1; i >= 0; i--) {
          User user = users.get(i);
          if (user.id==id) {
            user.walk(x, y);
          }
        }
      } else { //new user
        addRealUser(id, x, y);
      }
    }
    for (int i = users.size() - 1; i >= 0; i--) {
      User user = users.get(i);
      if ((millis()-user.lastSeen)>3000) {
        removeRealUser(user.id);
      }
    }
  }

  color generateRandomColor() {
    return color(random(255), random(255), random(255));
  }

  ArrayList<User> getUsers() {
    ArrayList<User> copy = new ArrayList<User>();
    for (User user : users) {
      copy.add(user.copy()); // Use the copy method
    }
    return copy;
  }


  void run() {
    for (User user : users) {

      if ((user instanceof RealUser)==false) {
        user.walk(0, 0);
      }
      //user.show(); // REMOVE THIS FOR ALWAYS DRAWING USERS ON SCREEN
    }
  }
}


float NOISE_SCALE_MOVEMENT = 0.001;
abstract class User {
  int id;
  PVector position;
  color userColor; // Changed variable name from 'color' to 'userColor'
  int lastSeen;
  User(int id, PVector position, color userColor) { // Adjust constructor
    this.id = id;
    this.position = position;
    this.userColor = userColor;
  }

  abstract User copy();

  void walk(int x, int y) {
    // This method can be overridden by subclasses
  }

  void show() {
    fill(userColor); // Adjust usage to new variable name
    noStroke();
    ellipse(position.x, position.y, 10, 10);
  }
}

// Subclass for normal random walking users
class NormalUser extends User {
  float xoff, yoff;

  NormalUser(int id, PVector position, color userColor) { // Adjust constructor
    super(id, position, userColor);
    xoff = random(cam_w);
    yoff = random(cam_h);
  }

  @Override
    User copy() {
    NormalUser copy = new NormalUser(this.id, this.position.copy(), this.userColor);
    copy.xoff = this.xoff;
    copy.yoff = this.yoff;
    return copy;
  }

  void walk(int x, int y) {
    println("walking");
    println(position.x);
    position.x = map(noise(xoff), 0, 1, 0, cam_w);
    position.y = map(noise(yoff), 0, 1, 0, cam_h);
    println(position.x);
    // Add boundary constraints to ensure the user does not leave the canvas
    float radius = 5; // Assuming the drawn ellipse has a radius of 5
    position.x = constrain(position.x, radius, cam_w - radius);
    position.y = constrain(position.y, radius, cam_h - radius);
    println(position.x);
    xoff += NOISE_SCALE_MOVEMENT;
    yoff += NOISE_SCALE_MOVEMENT;
  }
}

// Subclass for user controlled by mouse position
class MouseUser extends User {
  MouseUser(int id, color userColor) { // Adjust constructor
    super(id, new PVector(mouseX, mouseY), userColor);
  }

  @Override
    User copy() {
    return new MouseUser(this.id, this.userColor);
  }

  void walk(int x, int y) {
    position.x = mouseX;
    position.y = mouseY;
  }
}


// Subclass for normal random walking users
class RealUser extends User {
  float xoff, yoff;
  RealUser(int id, PVector position, color userColor, int lastSeen) { // Adjust constructor
    super(id, position, userColor);
    xoff = random(1000);
    yoff = random(1000);
    this.lastSeen=lastSeen;
  }

  @Override
    User copy() {
    RealUser copy = new RealUser(this.id, this.position.copy(), this.userColor, this.lastSeen);
    copy.xoff = this.xoff;
    copy.yoff = this.yoff;
    return copy;
  }


  void walk(int x, int y) {
    println(lastSeen);
    println("walking");

    lastSeen=millis();
    position.x = x;
    position.y = y;

    // Add boundary constraints to ensure the user does not leave the canvas
    //float radius = 5; // Assuming the drawn ellipse has a radius of 5
    //position.x = constrain(position.x, radius, width - radius);
    //position.y = constrain(position.y, radius, height - radius);

    //xoff += NOISE_SCALE_MOVEMENT;
    //yoff += NOISE_SCALE_MOVEMENT;
  }
}
