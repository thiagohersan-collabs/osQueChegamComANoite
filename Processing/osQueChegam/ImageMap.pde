public class ImageMap {
  private final float BSIZE = 10;
  private PImage myImage;
  PVector loc, dim;
  private ArrayList<LightButton> theButtons;
  private int selectedLamp;
  //
  private boolean DE_BUG = false;

  public ImageMap(String fname, XML mXML, PVector l, PVector d) {
    loc = new PVector();
    loc.set(l);
    dim = new PVector();
    dim.set(d);

    myImage = loadImage(fname);
    theButtons = new ArrayList<LightButton>();

    mXML.trim();

    for (int i=0; i<mXML.getChildCount(); i++) {
      XML light = mXML.getChild(i);
      theButtons.add(new LightButton(PVector.add(new PVector(light.getFloat("x"), light.getFloat("y")), loc), BSIZE));
    }

    selectedLamp = 1;
  }

  public void draw() {
    image(myImage, loc.x, loc.y, dim.x, dim.y);
    // draw light buttons
    for (int i=0; i<theButtons.size(); i++) {
      theButtons.get(i).draw();
    }
  }

  // in absolute pixels
  public int mouseClicked(PVector v) {
    if (DE_BUG) {
      PVector tv = PVector.sub(v, loc);
      println("<light x=\""+tv.x+"\" y=\""+tv.y+"\"></light>");
    }

    if ((v.x>loc.x) && (v.x<(loc.x+myImage.width)) && (v.y>loc.y) &&(v.y<(loc.y+myImage.height))) {
      for (int i=0; i<theButtons.size(); i++) {
        if (theButtons.get(i).mouseClicked(v)) {
          return i;
        }
      }
    }
    return -1;
  }

  public void flipState(int i) {
    theButtons.get(i).flipState();
  }
  public void setState(int i, boolean b) {
    theButtons.get(i).setState(b);
  }

  public boolean getLightStateFromButton(int i) {
    return theButtons.get(i).getState();
  }

  public void selectLight(int l) {
    theButtons.get(selectedLamp).deselectMe();
    selectedLamp = (l);
    theButtons.get(selectedLamp).selectMe();
  }
}

