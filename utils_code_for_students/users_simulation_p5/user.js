class UserManager {
  constructor() {
    this.users = [];
    this.usedIds = new Set();
  }

  initializeUsers(type, count) {
    for (let i = 0; i < count; i++) {
      let id = this.generateUniqueId();
      let col = this.generateRandomColor();
      let position = createVector(random(width), random(height));
      if (type === "normal") {
        this.users.push(new NormalUser(id, position, col));
      } else if (type === "mouse") {
        this.users.push(new MouseUser(id, col));
      }
    }
  }

  generateUniqueId() {
    let id;
    do {
      id = floor(random(1000));
    } while (this.usedIds.has(id));
    this.usedIds.add(id);
    return id;
  }

  addNormalUser() {
    let id = this.generateUniqueId();
    let col = this.generateRandomColor();
    let position = createVector(random(width), random(height));
    this.users.push(new NormalUser(id, position, col));
  }

  removeNormalUser() {
    for (let i = this.users.length - 1; i >= 0; i--) {
      let user = this.users[i];
      if (user instanceof NormalUser) {
        this.usedIds.delete(user.id);
        this.users.splice(i, 1);
        break;
      }
    }
  }

  generateRandomColor() {
    return color(random(255), random(255), random(255));
  }

  getUsers() {
    return this.users.map(user => user.copy());
  }

  run() {
    this.users.forEach(user => user.walk());
  }
}

class User {
  constructor(id, position, userColor) {
    this.id = id;
    this.position = position;
    this.userColor = userColor;
  }

  copy() {
    // Implemented in subclasses
  }

  walk() {
    // Can be overridden by subclasses
  }

  show() {
    fill(this.userColor);
    noStroke();
    ellipse(this.position.x, this.position.y, 10, 10);
  }
}

class NormalUser extends User {
  constructor(id, position, userColor) {
    super(id, position, userColor);
    this.xoff = random(1000);
    this.yoff = random(1000);
  }

  copy() {
    let copy = new NormalUser(this.id, this.position.copy(), this.userColor);
    copy.xoff = this.xoff;
    copy.yoff = this.yoff;
    return copy;
  }

  walk() {
    this.position.x = map(noise(this.xoff), 0, 1, 0, width);
    this.position.y = map(noise(this.yoff), 0, 1, 0, height);

    let radius = 5;
    this.position.x = constrain(this.position.x, radius, width - radius);
    this.position.y = constrain(this.position.y, radius, height - radius);

    this.xoff += 0.001; // Assuming NOISE_SCALE_MOVEMENT is 0.001
    this.yoff += 0.001;
  }
}

class MouseUser extends User {
  constructor(id, userColor) {
    super(id, createVector(mouseX, mouseY), userColor);
  }

  copy() {
    return new MouseUser(this.id, this.userColor);
  }

  walk() {
    this.position.x = mouseX;
    this.position.y = mouseY;
  }
}