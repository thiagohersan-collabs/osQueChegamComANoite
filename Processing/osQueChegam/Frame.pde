public class Frame {
  // these in seconds...
  private int startTime, durTime;
  // stuff
  private int id;
  private boolean lightState;
  // pointers
  public Frame next, prev;

  //
  private boolean DE_BUG = false;

  public Frame(Frame p_, Frame n_, int st_, int dt_, int id_) {
    prev = p_;
    next = n_;
    startTime = st_;
    durTime = dt_;
    id = id_;
    lightState = false;
  }
  public Frame(Frame p_, Frame n_, int st_, int dt_, boolean ls, int id_) {
    this(p_, n_, st_, dt_, id_);
    lightState = ls;
  }


  public int getStartTime() {
    return startTime;
  }
  public int getDurTime() {
    return durTime;
  }
  public int getEndTime() {
    return startTime+durTime;
  }

  public void setLightState(Frame f) {
    lightState = f.getLightState();
  }
  public void setLightState(boolean s) {
    lightState = s;
  }

  public boolean getLightState() {
    return lightState;
  }


  public Frame copyFrame(int newFrameId) {
    Frame nf = new Frame(prev, next, startTime, durTime, lightState, newFrameId);
    return nf;
  }

  public void addToStartTime(int dt_) {
    if (next != null) {
      next.addToStartTime(dt_);
    }
    startTime += dt_;
  }

  // this is called on a frame with valid start and duration times!!!
  public void fixStartTimes() {
    if (next != null) {
      next.setStartTime(startTime+durTime);
      // now next is valid
      next.fixStartTimes();
    }
  }

  private void setStartTime(int st_) {
    startTime = st_;
  }

  // this invalidates next frames start time!!!
  public void setDuration(int dt_) {
    durTime = dt_;
  }

  public void printFrames() {
    print(id+": "+startTime+" ("+durTime+") -> ");
    if (next != null) {
      next.printFrames();
    }
  }

  // return string representation of frame state
  public String getTransitionsString() {
    // create a string with one char per second of frame duration
    char[] tc = new char[durTime];
    Arrays.fill(tc, lightState?'1':'0');
    String myTransition = new String(tc);

    if (next != null) {
      myTransition = myTransition.concat(next.getTransitionsString());
    }
    return myTransition;
  }
}

