public class ControlPanel {
  private PVector loc, dim;

  public ControlPanel(PVector loc_, PVector dim_, NuitControlListener listen_) {
    loc = new PVector();
    dim = new PVector();
    loc.set(loc_);
    dim.set(dim_);

    // 
    myControlP5.addButton("Add Frame", 1.0, (int)loc.x+10, (int)loc.y+10, (int)dim.x/5, (int)dim.x/10).addListener(listen_);
    myControlP5.addButton("Delete", 2.0, (int)loc.x+10, (int)loc.y+20+(int)dim.x/10, (int)dim.x/5, (int)dim.x/10).addListener(listen_);

    // text box
    myControlP5.addTextfield("seconds", (int)(loc.x+20+dim.x/5), (int)loc.y+10, (int)dim.x/5, (int)dim.x/10).setFocus(true).addListener(listen_);

    // buttons
    myControlP5.addButton("Play", 3.0, (int)loc.x+10, (int)loc.y+30+(int)dim.x/5, (int)dim.x/5, (int)dim.x/10).addListener(listen_);
    myControlP5.addButton("Pause",  4.0, (int)(loc.x+20+dim.x/5), (int)loc.y+30+(int)dim.x/5, (int)dim.x/5, (int)dim.x/10).addListener(listen_);
    myControlP5.addButton("Save", 5.0, (int)(loc.x+30+2*dim.x/5), (int)loc.y+30+(int)dim.x/5, (int)dim.x/5, (int)dim.x/10).addListener(listen_);
  }

  public void draw() {
    noStroke();
    fill(#281a32);
    rect(loc.x, loc.y, dim.x, dim.y);
  }
}

