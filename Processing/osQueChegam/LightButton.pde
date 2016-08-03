public class LightButton {
  private boolean isOn;
  private PVector loc;
  private float myRadius;
  private boolean isSelected;

  public LightButton(PVector p_, float r_) {
    loc = new PVector();
    loc.set(p_);
    myRadius = r_;
    isOn = false;
    isSelected = false;
  }

  // in absolute pixels
  public boolean mouseClicked(PVector click) {
    if (loc.dist(click) < myRadius) {
      return true;
    }
    return false;
  }

  public void draw() {
    noStroke();
    if (isSelected) {
      fill(#FF0000, 100);
    }
    else {
      fill(0, 0);
    }

    ellipse(loc.x, loc.y, myRadius*2+10, myRadius*2+10);

    stroke(0);
    strokeWeight(2);
    fill(isOn?255:0);
    ellipse(loc.x, loc.y, myRadius*2, myRadius*2);
  }

  public boolean getState() {
    return isOn;
  }

  public void setState(boolean s) {
    isOn = s;
  }
  public void flipState() {
    isOn = !isOn;
  }


  public void selectMe() {
    isSelected = true;
  }

  public void deselectMe() {
    isSelected = false;
  }
}

