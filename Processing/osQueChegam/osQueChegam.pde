import controlP5.*;

Canvas c;

ControlP5 myControlP5;

void setup() {
  size(1024, 768);
  background(222);
  smooth();

  myControlP5 = new ControlP5(this).setColorBackground(0xFF604644);

  c = new Canvas(loadXML("lightPos.xml"));

  textFont(createFont(PFont.list()[0], 32));
}

void draw() {
  background(#563e5f);
  c.update();
  c.draw();
}

void mouseReleased() {
  PVector mv = new PVector(mouseX, mouseY);
  c.mouseClicked(mv);
}

