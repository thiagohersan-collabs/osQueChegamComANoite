// A glorified linked list... 
public class TimeLine {
  private int id;

  // in seconds
  private int currPos;
  private int numFrames;
  private int totalDuration;
  private Frame currFrameLeft, currFrameRight, firstFrame;

  // physical, for click and draw methods
  private PVector loc, dim;

  public TimeLine(int i, PVector l, PVector d) {
    id = i;
    loc = new PVector();
    dim = new PVector();
    loc.set(l);
    dim.set(d);
    currPos = numFrames = 0;
    currFrameLeft = currFrameRight = firstFrame = null;
    totalDuration = 0;
  }

  // add to currPos
  public void addFrame(int duration, boolean frameState) {
    // this will always be the case
    totalDuration += duration;

    // right in the middle of a non-null Frame
    //   not gonna be first frame...
    //   split it !!
    if ((currFrameLeft == currFrameRight) && (currFrameLeft != null)) {
      // copy frame
      Frame newFrameRight = currFrameRight.copyFrame(numFrames);
      numFrames++;
      // deal with pointers
      if (currFrameRight.next != null) {
        currFrameRight.next.prev = newFrameRight;
      }
      currFrameLeft.next = newFrameRight;
      newFrameRight.prev = currFrameLeft;
      // should have p -> currLeftFrame -> newRightFrame -> n

      // adjust times. we're splitting at currPos
      //   soil some times
      int oldDurTime = currFrameLeft.getDurTime();
      currFrameLeft.setDuration(currPos - currFrameLeft.getStartTime());
      newFrameRight.setDuration(oldDurTime - currFrameLeft.getDurTime());
      // durations should be valid, now fix start times
      currFrameLeft.fixStartTimes();

      // update currPos
      currPos = newFrameRight.getStartTime();
      // update currFrames
      currFrameRight = newFrameRight;
    }

    // if we're here, then we're sure currLeft != currRight, or both are null
    // so we're either right between frames (at very beginning or very end) or creating the first frame

    // create new frame
    Frame mF = new Frame(currFrameLeft, currFrameRight, currPos, duration, frameState, numFrames);
    numFrames++;
    // update old ones
    if (currFrameLeft != null) {
      currFrameLeft.next = mF;
    }
    // if no leftFrame, we're at the beginning of the Timeline
    else {
      firstFrame = mF;
    }
    if (currFrameRight != null) {
      currFrameRight.prev = mF;
      currFrameRight.addToStartTime(duration);
    }
    // cursor moves to end of new frame
    currFrameLeft = mF;
    currPos += duration;
  }

  // only delete frame if cursor is in a frame or to the left of
  //   a 1-second frame
  public void deleteFrame() {
    // cursor at the very end, or no frames exist...    
    if (currFrameRight == null) {
      println("ERROR: not a valid frame to delete");
    }
    // cursor at an edge or very beginning
    else if ((currFrameLeft != currFrameRight) || (currFrameLeft == null)) {
      // see if frame to the right is a 1-second frame
      if (currFrameRight.getDurTime() == 1) {
        // breaking some invariant
        currFrameLeft = currFrameRight;
        deleteFrame();
      }
      else {
        println("ERROR: please select a single frame");
      }
    }
    // cursor in the middle of a frame
    else {
      // update totalDuration. if we get here we will remove
      int durToDel = currFrameLeft.getDurTime();
      totalDuration -= durToDel;

      // move pointers around
      if (currFrameLeft.prev != null) {
        currFrameLeft.prev.next = currFrameLeft.next;
      }
      // deleting first Frame!
      else {
        firstFrame = currFrameLeft.next;
      }
      if (currFrameLeft.next != null) {
        currFrameLeft.next.prev = currFrameLeft.prev;
      }

      // use currFrameLeft to get new currFrameLeft and Right
      currFrameRight = currFrameLeft.next;
      currFrameLeft = currFrameLeft.prev;
      // now the old Frame is completely disconnected, should GC
      numFrames--;

      // fix times 
      if (currFrameRight != null) {
        // shifting currFrameRight and everything else after it to the left by durToDel
        currFrameRight.addToStartTime(-durToDel);
        // move cursor to between L&R
        currPos = currFrameRight.getStartTime();
      }
      else if (currFrameLeft != null) {
        currPos = currFrameLeft.getStartTime() + currFrameLeft.getDurTime();
      }
      else {
        // currFrameLeft = currFrameRight = null
        currPos = 0;
      }
    }
  }

  public void editCurrentFrameState(boolean s) {
    // cursor at the very end, or no frames exist...
    if ((totalDuration <= 0) || (currFrameRight == null)) {
      // nothing. first frame on this lamp/timeline
      println("ERROR: not a valid frame to edit");
    }
    // cursor at an edge or very beginning
    else if ((currFrameLeft != currFrameRight) || (currFrameLeft == null)) {
      // see if frame to the right is a 1-second frame
      if (currFrameRight.getDurTime() == 1) {
        // breaking some invariant
        currFrameLeft = currFrameRight;
        editCurrentFrameState(s);
      }
      else {
        println("ERROR: please select a single frame");
      }
    }
    // cursor in the middle of a frame
    else {
      currFrameRight.setLightState(s);
    }
  }

  public boolean getCurrentFrameState() {
    if (currFrameRight != null) {
      return currFrameRight.getLightState();
    }
    return false;
  }

  // assume we can only move cursor when there is a frame
  //   and to where there is a frame
  //   ct_ in seconds
  public void moveCursor(int ct_) {
    // if asked to move to a place that doesn't exist
    //    go to end of timeline and add a filler frame
    if ((ct_ > totalDuration) || (totalDuration == 0)) {
      if (totalDuration != 0) {
        this.moveCursor(totalDuration);
      }
      this.addFrame(ct_-totalDuration, false);
    }

    // this is never null
    currFrameRight = firstFrame;
    // currFrameLeft points at previous frame
    currFrameLeft = currFrameRight.prev;
    // always do this
    currPos = ct_;

    while (currFrameRight != null) {
      // if at edge of leftFrame/rightFrame
      if (ct_ == currFrameRight.getStartTime()) {
        return;
      }
      // assume ct_ > currFrameRight.getStartTime()
      else if ((ct_ < (currFrameRight.getStartTime()+currFrameRight.getDurTime()))) {
        currFrameLeft = currFrameRight;
        return;
      }
      // cursor beyond currFrameRight, step currFrameRight
      else {
        currFrameLeft = currFrameRight;
        currFrameRight = currFrameRight.next;
      }
    }
    // if we get here, then currFrameLeft = last frame and currFrameRight = null;
  }

  // snap to frame: if, currPos within 10% of edge --> go to edge
  private void snapCursor() {
    // only snap when left == right, otherwise, already snapped...
    if (currFrameLeft == currFrameRight) {
      float distToStart = abs(currPos - currFrameLeft.getStartTime());
      float distToEnd   = abs(currPos - currFrameLeft.getEndTime());
      //////
      if (distToStart < (float(currFrameLeft.getDurTime())/10)) {
        moveCursor(currFrameLeft.getStartTime());
      }
      else if (distToEnd < (float(currFrameLeft.getDurTime())/10)) {
        moveCursor(currFrameLeft.getEndTime());
      }
    }
  }

  // mouseClicked to move cursor and always keep currPos and currFrameLeft/currFrameRight synched
  //       Easy. Use moveCursor, just have to make sure that:
  //             1. we only move cursor when there is a frame (+)
  //             2. we only move cursor to where there is a frame (~)
  //             3. snaps to 1 second "grid" (+)
  public boolean mouseClicked(PVector v) {
    // timeline was clicked and there's a frame already there
    if ((v.x>loc.x) && (v.x<(loc.x+dim.x)) && (v.y>loc.y) && (v.y<(loc.y+dim.y)) && (numFrames!=0)) {
      // time to pixel
      float scaleFactor = (totalDuration > (dim.x-20))?((dim.x-20)/totalDuration):((dim.x-20)/totalDuration);
      // check if there's a frame there
      if ((totalDuration*scaleFactor) > (v.x-loc.x-10)) {
        moveCursor((int)((v.x-loc.x-10)/scaleFactor));
        snapCursor();
      }
      // else move to end of timeline
      else {
        moveCursor(totalDuration);
      }
      // we were clicked !
      return true;
    }
    // not clicked
    return false;
  }


  // draw a scaled timeline, so it fits in the screen
  public void draw() {
    noStroke();
    fill(#281a32);
    rect(loc.x, loc.y, dim.x, dim.y);
    // time to pixels
    float scaleFactor = (totalDuration > (dim.x-20))?((dim.x-20)/totalDuration):((dim.x-20)/totalDuration);

    Frame frameI = firstFrame;
    strokeWeight(2);
    stroke(#563e5f);

    // draw frames 
    while (frameI != null) {
      if (frameI.getLightState()) {
        fill(255,200);
      }
      else {
        fill(0,200);
      }
      pushMatrix();
      translate(frameI.getStartTime()*scaleFactor+loc.x+10, loc.y+0.25*dim.y);
      rect(0, 0, frameI.getDurTime()*scaleFactor, 0.5*dim.y);
      popMatrix();
      // next!
      frameI = frameI.next;
    }

    // cursor
    strokeWeight(5);
    if (currFrameLeft == currFrameRight) {
      stroke(#993333, 100);
    }
    else {
      stroke(#993333);
    }
    pushMatrix();
    translate(loc.x+currPos*scaleFactor+10, 0);
    line(0, loc.y+0.25*dim.y, 0, loc.y+0.75*dim.y);
    popMatrix();
  }

  // for playign frames
  public int getPos() {
    return currPos;
  }
  public int getDuration() {
    return totalDuration;
  }
  public boolean getLightState() {
    if (currFrameRight != null) {
      return currFrameRight.getLightState();
    }
    return false;
  }

  public int getSize() {
    return numFrames;
  }
  public void printFrames() {
    if (firstFrame != null) {
      firstFrame.printFrames();
      println();
    }
  }

  // for generating transition codes
  // return a string of 0s and 1s
  public String getTransitionsString() {
    if (firstFrame != null) {
      return firstFrame.getTransitionsString();
    }
    return "";
  }
}

