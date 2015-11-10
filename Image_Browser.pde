/********************************************
 File: Image_Browser.pde
 By: Austin Ensley
 Date: 3/23/15
 
 Compile: processing for android
 
 Usage: open processing, plug-in android device, and run program in android mode
 
 System: processing
 
 Description:
 Part1 : Application is an image browser that displays 5 thumbnails at a time and when an image 
 is pressed, that image is displayed in full screen until the user presses the image again
 to return back to thumbnail view. By using the left and right arrows, the user is able to 
 load different images to the display.
 
 Part1.5 : When the left or right arrows are pressed in mode 0 images slide smoothly from previous
 thumbnails bar to current thumbnails bar. If in mode 1 the images slide smoothly from previous 
 image to current image.
 
 Part2.5 : Added sound to the image browser using soundpool. A short sound will play when an image 
 is clicked in both mode 0 and mode 1 as well as when a user clicks the left or right arrows in mode 1.
 A longer sound will play when the left and right arrows are clicked in mode 0. In mode 1 two buttons 
 (Save and Cancel) and a text-field were added. The idea was to save the text written in the text-field
 to the selected image. To save the collection of text tage a hashmap was created to save the content 
 associated with a selected image. By writing and reading the name of the hashmap to and from external 
 storage the selected images were saved along with their corresponding text tags. 
 
 Part3 : Replaced mouse click in mode 0 and mode 1 with double tap. Added flick to both mode 0 and mode 1. 
 Flick left works like clicking on the right arrow and flick right works like clicking on the left arrow. 
 Add zoom and pan to mode 1. If the zoom button is clicked in mode 1 the image browser goes into mode 2. 
 From there the user can zoom and pan the selected image. To exit mode 2 the user clicks on cancel.
 
 *********************************************/

import android.media.SoundPool; 
import android.content.res.AssetManager;
import android.media.AudioManager;
import apwidgets.*;
import java.io.*;
import android.view.MotionEvent;
import ketai.ui.*;

KetaiGesture gesture;

SoundPool soundPool;
AssetManager assetManager;

PImage img;
PImage leftArrow, rightArrow;
PImage previous;
String [] fileNames;
int mode;
int leftMost;
int selectedImage;

int velX;
boolean isMoving = false;
int offset;
int dir = 1;
boolean right_pressed = false;
int boundary = 0;

int sound1, sound2;
APWidgetContainer widgetContainer;
APEditText textField;
APButton save;
APButton cancel;
APButton zoom;
HashMap<String, String> cache = new HashMap<String, String>(); // create hashmap to hold content
String tag;

float Angle = 0;
float translateX = 0, translateY = 0;
float prevPinchX = -1, prevPinchY = -1;
int prevPinchFrame = -1;
float pinchWidth;
float pinchHeight;
int ModeOneW;
int ModeOneH;

void setup() {
  orientation(LANDSCAPE);
  velX = 0;
  frameRate(60);
  mode = 0;  //  select between mode 0 or mode 1
  leftMost = 0;   // set to the first image displayed on the screen 
  selectedImage = 0;   //  selects an image based on x and y coordinates 
  offset = 0;
  fileNames = new String[2];
  tag = "";
  textSize(75);
  gesture = new KetaiGesture(this);

  leftArrow = loadImage("leftArrow.png");
  rightArrow = loadImage("rightArrow.png");

  soundPool = new SoundPool(20, AudioManager.STREAM_MUSIC, 0); // max # of streams, stream type, source quality
  AssetManager am = getAssets();

  try {
    sound1 = soundPool.load(am.openFd("click.wav"), 0); // load audio file 
    sound2 = soundPool.load(am.openFd("horn.wav"), 0);
  } 
  catch (IOException e) {
    System.out.println("Error: sound not found");
    return;
  }

  widgetContainer = new APWidgetContainer(this); // create new container for widgets
  textField = new APEditText(20, 150, 400, 150);
  save = new APButton(width - 250, 10, "Save");
  cancel = new APButton(width - 250, 150, "Cancel");
  zoom = new APButton(width - 250, 290, "Zoom");
  widgetContainer.addWidget(textField); // place textField in container
  widgetContainer.addWidget(save); // place button in container
  widgetContainer.addWidget(cancel); // place button in container 
  widgetContainer.addWidget(zoom); // place button in container
  textField.setCloseImeOnDone(true);
  widgetContainer.hide();
  // displays selected image with its saved tags
  File data = new File(getFilesDir().getAbsolutePath() + "/android.content");
  if (data.exists() && !data.isDirectory()) {
    readFromExternalStorage();
  }

  // get list of folders and files in sketch data folder
  try {
    fileNames = am.list("Images");
  }
  catch (IOException e) {
    System.out.println("Error: folder Images not found");
    return;
  }
}// end setup()


void draw() {
  background(150, 0, 0);

  // display left and right arrows at the bottom corners
  image(leftArrow, 50, height - 200, 150, 150);
  image(rightArrow, width - 200, height - 200, 150, 150);

  if (mode == 0) {   // thumbnails displayed
    if (!isMoving) {
      for (int i = 0; i < 5; i++) {     // loop displays 5 images from array fileName
        if (leftMost + i >= fileNames.length) {
          img = loadImage("Images/" + fileNames [leftMost + i - fileNames.length]);
        } else {
          img = loadImage("Images/" + fileNames [leftMost + i]);
        }
        img.resize(0, height/4);
        image(img, (width*i/5), (height/2 - img.height/2));
      }// end for
    }// end if(!isMoving)

    if (isMoving) {
      for (int i = 0; i < 10; i++) {
        if (leftMost + i >= fileNames.length) {
          img = loadImage("Images/" + fileNames [leftMost + i - fileNames.length]);
        } else {
          img = loadImage("Images/" + fileNames [leftMost + i]);
        }
        img.resize(0, height/4);
        velX += offset;

        if ((velX >= width) || (velX <= -width)) {
          velX = 0;
          isMoving = false;
          boundary = 0;

          if (right_pressed) {

            if (leftMost >= fileNames.length - 5) {   // increments and keeps images in order and loops around
              leftMost = leftMost - fileNames.length + 5;
            } else 
              leftMost += 5; 

            right_pressed = false;
          } // end if(right_pressed)
        } else
          image(img, ((width*i)/5) + boundary + velX, (height/2 - img.height/2)); // equally displays 5 images
      }// end for
    }// if(isMoving)
  }// end if(mode == 0)

  if (mode == 1) {    // display selected image full-screen
    img = loadImage("Images/" + fileNames [selectedImage]);
    previous = loadImage("Images/" + fileNames [selectedImage - dir]);

    img.resize(0, height - 250);
    previous.resize(0, height - 250);

    if (isMoving) {
      image(img, width/2-img.width/2+ (width*dir) + velX, 50);
      image(previous, width/2-previous.width/2 + velX, 50);
      velX += offset;
      if ((velX >= width) || (velX <= -width)) {
        velX = 0;
        isMoving = false;
        img = previous;
      }
    } else {
      image(img, width/2-img.width/2, 50);
      ModeOneW = img.width;
      ModeOneH = img.height;
      text(tag, 0, 100);
    }
  } // end if (mode == 1)

  if (mode == 2) {
    background(150, 0, 0);
    pushMatrix();
    translate(width/2 + translateX, height/2 + translateY);
    rotate(Angle);
    image(img, 0, 0, pinchWidth, pinchHeight);
    popMatrix();
  }// end if (mode == 2)
}// end draw


void mousePressed() {
  if (mode == 0) {
    // left arrow location to be pressed in mode 0
    if (mouseX >= 0 && mouseX <= 250 && mouseY >= height - 250 && mouseY <= height) {
      leftMost -= 5;   // decrements and keeps images in reverse order
      if (leftMost <= -1) {
        leftMost = fileNames.length + leftMost;
      }  // end if (leftMost <= -1)
      soundPool.play(sound2, 1, 1, 0, 0, 1);
      offset = 15;
      isMoving = true;
      dir = -1;
      boundary = (width * dir);
    } // end if (leftMouseX && leftMouseY)


    // right arrow location to be pressed in mode 0
    if (mouseX >= width - 250 && mouseX <= width && mouseY >= height - 250 && mouseY <= height) {
      if (leftMost >= fileNames.length) {   // increments and keeps images in order and loops around
        //leftMost = leftMost - fileNames.length + 1;
      }  // end if (leftMost >= fileNames.length)
      else {       // proceeds to the next 5 images
        //  leftMost += 5;
        right_pressed = true;
      }
      soundPool.play(sound2, 1, 1, 0, 0, 1);
      offset = -15;
      isMoving = true;
      dir = 1;
      boundary = 0;
    } // end if (rightMouseX && rightMouseY)
  } // end if (mode == 0)


  // switch from mode 0 to mode 1 when an image is pressed
  else if (mode == 1) {
    // left arrow location to be pressed in mode 1
    if (mouseX >= 0 && mouseX <= 250 && mouseY >= height - 250 && mouseY <= height) {
      selectedImage--;   // decrements and keeps images in reverse order
      if (selectedImage <= -1) {
        selectedImage = fileNames.length - 1;
      }  // end if (leftMost <= -1)
      soundPool.play(sound1, 1, 1, 0, 0, 1);
      offset = 50;
      isMoving = true;
      dir = -1;
      // sets tag to the appropriate selected image
      if (cache.containsKey(fileNames[selectedImage])) {
        tag = cache.get(fileNames[selectedImage]);
      } else {
        tag = "";
      }
    } // end if (leftMouseX && leftMouseY)

    // right arrow location to be pressed in mode 1
    else if (mouseX >= width - 250 && mouseX <= width && mouseY >= height - 250 && mouseY <= height) {
      if (selectedImage >= fileNames.length -1) {   // increments and keeps images in order and loops around
        selectedImage = 0;
      }  // end if (selectedImage >= fileNames.length -1)
      else {       // proceeds to the next image
        selectedImage++;
      }
      soundPool.play(sound1, 1, 1, 0, 0, 1);
      offset = -50;
      isMoving = true;
      dir = 1;
      // sets tag to the appropriate selected image
      if (cache.containsKey(fileNames[selectedImage])) {
        tag = cache.get(fileNames[selectedImage]);
      } else {
        tag = "";
      }
    }// end if (rightMouseX && rightMouseY)
  }// end if (mode == 1)
}// end mousePressed() 



void onDoubleTap(float x, float y) {
  if (mode == 0) {
    for (int i = 0; i < 5; i++) {
      if (x >= width * i/5 && x <= width * (i+1)/5 && y >= height/3 && y <= height * 2/3) {
        selectedImage = leftMost + i;   // chooses the selected image based on x and y coordinates               
        mode = 1;
        soundPool.play(sound1, 1, 1, 0, 0, 1);
        widgetContainer.show();
        if (cache.containsKey(fileNames[selectedImage])) {
          tag = cache.get(fileNames[selectedImage]);
        } else {
          tag = "";
        }
        break;
      }
    } // end for (int i = 0; i < 5; i++)
  } else if (mode == 1) {
    if (x >= 250 && x <= width - 250 && y >= 250 && y <= height - 250) {
      leftMost = selectedImage;
      mode = 0;
      soundPool.play(sound1, 1, 1, 0, 0, 1);
      widgetContainer.hide();
    }
  }
}


void onFlick(float x, float y, float px, float py, float v) {
  if (mode == 0) {
    // flick to the right
    if (px < x) {
      leftMost -= 5;   // decrements and keeps images in reverse order
      if (leftMost <= -1) {
        leftMost = fileNames.length + leftMost;
      }  // end if (leftMost <= -1)
      soundPool.play(sound2, 1, 1, 0, 0, 1);
      offset = 15;
      isMoving = true;
      dir = -1;
      boundary = (width * dir);
    } // end if (px < x)

    // flick to the left
    if (px > x) {
      if (leftMost >= fileNames.length) {   // increments and keeps images in order and loops around
        leftMost = leftMost - fileNames.length + 1;
      }  // end if (leftMost >= fileNames.length)
      else {       // proceeds to the next 5 images
        //leftMost += 5;
        right_pressed = true;
      }
      soundPool.play(sound2, 1, 1, 0, 0, 1);
      offset = -15;
      isMoving = true;
      dir = 1;
      boundary = 0;
    }
  }// end if (mode == 0)

  else if (mode == 1) {
    //flick to the right
    if (px < x) {
      selectedImage--;   // decrements and keeps images in reverse order
      if (selectedImage <= -1) {
        selectedImage = fileNames.length - 1;
      }  // end if (leftMost <= -1)
      soundPool.play(sound1, 1, 1, 0, 0, 1);
      offset = 50;
      isMoving = true;
      dir = -1;
      // sets tag to the appropriate selected image
      if (cache.containsKey(fileNames[selectedImage])) {
        tag = cache.get(fileNames[selectedImage]);
      } else {
        tag = "";
      }
    }// end if (px < x)
    // flick to the left 
    if (px > x) {
      if (selectedImage >= fileNames.length - 1) {   // increments and keeps images in order and loops around
        selectedImage = 0;
      }  // end if (selectedImage >= fileNames.length -1)
      else {       // proceeds to the next image
        selectedImage++;
      }
      soundPool.play(sound1, 1, 1, 0, 0, 1);
      offset = -50;
      isMoving = true;
      dir = 1;
      // sets tag to the appropriate selected image
      if (cache.containsKey(fileNames[selectedImage])) {
        tag = cache.get(fileNames[selectedImage]);
      } else {
        tag = "";
      }
    }// end if (px > x)
  }// end else if (mode == 1)
}// end onFlick


void onPinch(float x, float y, float d) {
  if (mode == 2) {
    float w = pinchWidth;
    pinchWidth = constrain(pinchWidth + d, 10, 2000);
    if (prevPinchX >= 0 && prevPinchY >= 0 && (frameCount - prevPinchFrame < 10)) {
      translateX += (x - prevPinchX);
      translateY += (y - prevPinchY);
    }
    prevPinchX = x;
    prevPinchY = y;
    prevPinchFrame = frameCount;
    pinchHeight = (pinchHeight * (float)getAspectRatio(w, pinchWidth));
  }
}


float getAspectRatio(float origWidth, float newWidth) {
  return newWidth / origWidth;
}


void onRotate(float x, float y, float ang) {
  if (mode == 2) {
    Angle += ang;
  }
}


void onClickWidget(APWidget widget) {
  if (widget == save) {
    if (cache.containsKey(fileNames[selectedImage])) {
      String value = cache.get(fileNames[selectedImage]);
      cache.put(fileNames[selectedImage], value + ", " + textField.getText());
    } else {
      cache.put(fileNames[selectedImage], textField.getText());
    }
    tag = cache.get(fileNames[selectedImage]);
  }// end if(widget == save)

  if (widget == cancel) {
    if (mode == 1) {
      textField.setText("");
    }
    if (mode == 2) {
      mode = 1;
      Angle = 0;
      translateX = 0;
      translateY = 0;
      imageMode(CORNER);
    }
  }// end if(widget == cancel)

  if (widget == zoom) {
    mode = 2;
    pinchWidth = ModeOneW;
    pinchHeight = ModeOneH;
    imageMode(CENTER);
  }
}// end onClickWidget


void writeToExternalStorage() { 
  try
  {
    File directory = getFilesDir();
    FileOutputStream file = new FileOutputStream(directory.getAbsolutePath() + "/android.content");
    ObjectOutputStream object = new ObjectOutputStream(file);
    object.writeObject(cache);
    object.close();
    file.close();
  }
  catch(IOException e)
  {
    e.printStackTrace();
  }
}// end writeToExternalStorage


void readFromExternalStorage() {
  try
  {
    File directory = getFilesDir();
    FileInputStream file = new FileInputStream(directory.getAbsolutePath() + "/android.content");
    ObjectInputStream object = new ObjectInputStream(file);
    cache = (HashMap) object.readObject();
    object.close();
    file.close();
  }
  catch(IOException e)
  {
    e.printStackTrace();
    return;
  }
  catch(ClassNotFoundException c)
  {
    System.out.println("Class not found");
    c.printStackTrace();
    return;
  }
}// end readFromExternalStorage


@ Override
public void onStop() {
  if (!cache.isEmpty()) {
    writeToExternalStorage();
  }
  super.onStop();
}


public void onDestroy() {
  super.onDestroy(); // call onDestroy on super class
  if (soundPool != null) { // must be checked or else crash when return from landscape mode
    soundPool.release(); // release the player
  }
}


public boolean surfaceTouchEvent(MotionEvent event) {

  //call to keep mouseX, mouseY, etc updated
  super.surfaceTouchEvent(event);

  //forward event to class for processing
  return gesture.surfaceTouchEvent(event);
}

