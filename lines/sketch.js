// Array to store lines
let lines = [];
let maxLines = 137; // Maximum number of lines
let x1, y1, x2, y2;
let l = 80;
let xv1, yv1;
let stdx, stdy;
let dx1, dy1;

let mx, my;

function setup() {
    createCanvas(windowWidth, windowHeight); // fullScreen equivalent in p5.js
    console.log(width); // Printing width to the console
    xv1 = 150;
    yv1 = 150; // later will be location of person.
    stdx = 30;
    stdy = 30;
    strokeWeight(3);
}

function draw() {
    background(255, 248, 230);
    mx = mouseX;
    my = mouseY;

    // Randomly add a new line
    if (random(1) < 0.4) { // Adjust the probability as needed
        x1 = mx;
        y1 = my;
        dx1 = randomGaussian() * stdx;
        dy1 = randomGaussian() * stdy;
        lines.push(new Line(x1 + dx1, y1 + dy1, x1 + dx1 + random(-l, l), y1 + dy1 + random(-l, l)));
    }

    xv1 = xv1 + 0.2;
    yv1 = yv1 + 0.2;
    if (xv1 > 900) { xv1 = 50; }
    if (yv1 > 900) { yv1 = 50; }

    // Draw all lines
    lines.forEach(line => {
        line.display();
    });

    // Remove the oldest line if we exceed the maximum count
    if (lines.length > maxLines) {
        lines.shift(); // Removes the first element from an array
    }
}

// Line class
class Line {
    constructor(x1, y1, x2, y2) {
        this.x1 = x1;
        this.y1 = y1;
        this.x2 = x2;
        this.y2 = y2;
        this.s = (random(1) - 0.5) * 0.02;
        this.c = 0;
    }

    display() {
        stroke(0);
        this.c = this.c + 1;
        if (this.c > 32000) { this.c = 0; }
        push();
        translate((this.x1 + this.x2) / 2, (this.y1 + this.y2) / 2);
        rotate(this.c * this.s);
        line(this.x1 - (this.x1 + this.x2) / 2, this.y1 - (this.y1 + this.y2) / 2, this.x2 - (this.x1 + this.x2) / 2, this.y2 - (this.y1 + this.y2) / 2);
        pop();
    }
}

