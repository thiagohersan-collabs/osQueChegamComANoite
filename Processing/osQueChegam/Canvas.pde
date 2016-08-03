//   TODO: time scale display

static final int CANVAS_STATE_STOP = 0;
static final int CANVAS_STATE_PLAY = 1;

public class Canvas {
  private ImageMap iM;
  private ArrayList<TimeLine> theLamps;
  private ControlPanel cP;

  // 
  private int currentLamp;
  private int currentTimePos;

  /// for playing!!
  private int currState;
  private int currPlayingPos;
  private long lastUpdate;

  // for saving
  private final String THE_HEADER_FILE = "header.txt";
  private final String THE_FOOTER_FILE = "footer.txt";

  /////////////////
  // my very own control listener
  private  NuitControlListener myListener = new NuitControlListener() {
    public void controlEvent(ControlEvent theEvent) {
      if (theEvent.controller().name().toLowerCase().matches(".*add.*")) {
        // get number from textbox or scrollnumberbox
        int nsec = 0;
        Textfield tf = myControlP5.get(Textfield.class, "seconds");
        if (tf != null) {
          try {
            nsec = Integer.parseInt(tf.getText());
          }
          catch(NumberFormatException e) {
            nsec = 0;
          }
        }
        nsec = abs(nsec);
        println("ADD: "+nsec);
        // add to timeline here
        // only add if new frame duration > 0
        if (nsec > 0) {
          // new lights are always off
          theLamps.get(currentLamp).addFrame(nsec, false);
          currentTimePos = theLamps.get(currentLamp).getPos();
        }
      }
      else if (theEvent.controller().name().toLowerCase().matches(".*delete.*")) {
        println("DELETED");
        // delete frame here
        theLamps.get(currentLamp).deleteFrame();
        currentTimePos = theLamps.get(currentLamp).getPos();
      }
      else if (theEvent.controller().name().toLowerCase().matches(".*play.*")) {
        println("PLAYING");
        if (theLamps.get(currentLamp).getDuration() > 0) {
          // start from current position.
          //   current image should be correct
          lastUpdate = millis();
          currState = CANVAS_STATE_PLAY;
        }
      }
      else if (theEvent.controller().name().toLowerCase().matches(".*pause.*")) {
        println("PAUSING");
        lastUpdate = millis();
        currState = CANVAS_STATE_STOP;
      }      
      else if (theEvent.controller().name().toLowerCase().matches(".*save.*")) {
        println("SAVE");
        saveOutputArduinoFile();
      }
    }
  };

  Canvas(XML xmle) {
    iM = new ImageMap("mapa_lago.png", xmle, new PVector(10, 10), new PVector(1000*0.6, 1000*0.6));
    cP = new ControlPanel(new PVector(1000*0.6+20, 10), new PVector(width-1000*0.6-30, 1000*0.6), myListener);

    // add lamp objects to array
    theLamps = new ArrayList<TimeLine>();
    // creating lamps from xml
    for (int i=0; i<xmle.getChildCount(); i++) {
      theLamps.add(new TimeLine(i, new PVector(10, 1000*0.6+20), new PVector(width-20, height-1000*0.6-30)));
    }

    currentLamp = 1;
    iM.selectLight(currentLamp);

    currentTimePos = 0;

    // start state machine
    currState = CANVAS_STATE_STOP;
    lastUpdate = millis();
  }

  private void setImageFromLamps() {
    for (int i=0; i<theLamps.size(); i++) {
      theLamps.get(i).moveCursor(currentTimePos);
      // set image from the timeline state
      iM.setState(i, theLamps.get(i).getCurrentFrameState());
    }
  }

  public void update() {
    if ((currState == CANVAS_STATE_PLAY) && ((millis()-lastUpdate) >= 1000)) {
      TimeLine ctl = theLamps.get(currentLamp);
      if (ctl.getPos() < ctl.getDuration()) {
        // move all cursors by one
        currentTimePos += 1;
      }
      else {
        currState = CANVAS_STATE_STOP;
      }
      lastUpdate = millis();
    }
    // update cursors and image
    this.setImageFromLamps();
  }

  public void draw() {
    iM.draw();
    theLamps.get(currentLamp).draw();
    cP.draw();

    fill(0);
    text("Lamp: "+currentLamp, 20, 1000*0.6);
  }

  public void mouseClicked(PVector v) {
    // see if we clicked on the lamp that is already selected
    //   if so, change the state of the light at the current frame position
    int whichLampClicked = iM.mouseClicked(v);
    if (whichLampClicked == currentLamp) {
      // change light state on image
      // this flips button when cursor is in-between frames
      iM.flipState(whichLampClicked);  
      // change light state on timeline
      theLamps.get(currentLamp).editCurrentFrameState(iM.getLightStateFromButton(currentLamp));

      // keep image and timeline sync'ed
      // this is necessary because sometimes we flip a 
      //   button on the image before we know if that flip
      //   is valid on the timeline
      if (iM.getLightStateFromButton(currentLamp) != theLamps.get(currentLamp).getCurrentFrameState()) {
        // trust the timeline
        iM.setState(currentLamp, theLamps.get(currentLamp).getCurrentFrameState());
      }
    }
    // if not, switch lamps
    else if (whichLampClicked != -1) {
      // select the one that was clicked
      iM.selectLight(whichLampClicked);
      currentLamp = whichLampClicked;
    }

    // check if timeline was clicked    
    if (theLamps.get(currentLamp).mouseClicked(v)) {
      currentTimePos = theLamps.get(currentLamp).getPos();
      // set image from timeline
      this.setImageFromLamps();
    }
  }

  /////////// for writing output file

  // convert a char value to a string of its hex representation
  private String charToHexString(char c) {
    StringBuffer h = new StringBuffer();
    h.append("0x");
    if (c < 0x10) {
      h.append('0');
    }
    h.append(Integer.toHexString(c));

    return h.toString();
  }

  // pack string of 0s and 1s into an array of chars
  private char[] getArrayFromString(String s) {
    int sizeOfArray;
    if (s.length()%8 == 0) {
      sizeOfArray = s.length()/8;
    }
    else {
      sizeOfArray = (s.length()/8)+1;
    }

    char[] theArray = new char[sizeOfArray];

    char tmp = 0x0;
    // go through every bit of the string
    for (int i=0; i<s.length(); i++) {
      // once we've gone through 8 values (packed a byte)
      //    write result into array
      if ((i%8 == 0) && (i>0)) {
        theArray[(i/8)-1] = tmp;
        tmp = 0x0;
      }
      // read the next char from string
      char bit = (char)((s.charAt(i) == '0')?0x0:0x1);
      // pack it into byte
      tmp |= (bit<<(i%8))&0xFF;
    }
    // deal with stragglers
    theArray[s.length()/8] = tmp;

    return theArray;
  }

  // write the file
  private void saveOutputArduinoFile() {
    try {
      // create some "nice" strings for writing output file name
      String mMonth = (month()<10)?("0"+month()):(""+month());
      String mDay = (day()<10)?("0"+day()):(""+day());
      String mHour = (hour()<10)?("0"+hour()):(""+hour());
      String mMinute = (minute()<10)?("0"+minute()):(""+minute());
      String mSecond = (second()<10)?("0"+second()):(""+second());

      // open output file
      PrintWriter out = new PrintWriter(dataPath("osQueChegamTransmitArduino_"+year()+mMonth+mDay+"_"+mHour+mMinute+mSecond+".ino"));
      // open header, write header, close header
      BufferedReader reader = new BufferedReader(new FileReader(dataPath(THE_HEADER_FILE)));
      String tmpBuf = null;
      while ( (tmpBuf = reader.readLine ()) != null) {
        out.println(tmpBuf);
      }
      reader.close();

      // get all the packed arrays
      char[][] theArrs = new char[theLamps.size()][];
      int maxD = 0;
      for (int i=0; i<theLamps.size(); i++) {
        theArrs[i] = getArrayFromString(theLamps.get(i).getTransitionsString());
        if (theArrs[i].length > maxD) {
          maxD = theArrs[i].length;
        }
      }

      // some other stuff that has to go to the file
      out.println("#define NUM_LIGHTS "+(theLamps.size()-1));
      out.println("#define NUM_TRANSITIONS ("+maxD+"*8)+1");
      out.println("// leave 0 empty. there's no lamp with id 0");
      out.println("unsigned char theTrans[NUM_LIGHTS+1][NUM_TRANSITIONS/8] = {");
      out.print("{0x00}");

      ////////// write other arrays
      for (int i=1; i<theLamps.size(); i++) {
        out.println(",");
        out.print("{");
        for (int j=0; j<theArrs[i].length; j++) {
          // print the char as hex
          out.print(charToHexString(theArrs[i][j]));
          if (j != theArrs[i].length-1) {
            out.print(", ");
          }
        }
        out.print("}");
      }  
      out.println("};");

      // open footer, write footer, close footer
      reader = new BufferedReader(new FileReader(dataPath(THE_FOOTER_FILE)));
      tmpBuf = null;
      while ( (tmpBuf = reader.readLine ()) != null) {
        out.println(tmpBuf);
      }
      reader.close();

      // close output file
      out.close();
    }
    catch(Exception e) {
    }
  }
  //
}

