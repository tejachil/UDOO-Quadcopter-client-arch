/******************************************************************************************
* Test Sketch for Razor AHRS v1.4.2
* 9 Degree of Measurement Attitude and Heading Reference System
* for Sparkfun "9DOF Razor IMU" and "9DOF Sensor Stick"
*
* Released under GNU GPL (General Public License) v3.0
* Copyright (C) 2013 Peter Bartz [http://ptrbrtz.net]
* Copyright (C) 2011-2012 Quality & Usability Lab, Deutsche Telekom Laboratories, TU Berlin
* Written by Peter Bartz (peter-bartz@gmx.de)
*
* Infos, updates, bug reports, contributions and feedback:
*     https://github.com/ptrbrtz/razor-9dof-ahrs
******************************************************************************************/

/*
  NOTE: There seems to be a bug with the serial library in Processing versions 1.5
  and 1.5.1: "WARNING: RXTX Version mismatch ...".
  Processing 2.0.x seems to work just fine. Later versions may too.
  Alternatively, the older version 1.2.1 also works and is still available on the web.
*/

import processing.opengl.*;
//import processing.serial.*;
import hypermedia.net.*;

UDP udp;  // define the UDP object

final static int COPTER_GUI_SCALE_FACTOR = 30; // Scale factor for the box representation of the copter
final static String SERVER_HOST = "192.168.1.10";
final static int SERVER_PORT = 33333;
final static int CLIENT_AHRS_PORT = 33335;

float yaw = 0.0f;
float pitch = 0.0f;
float roll = 0.0f;
float yawOffset = 0.0f;

PFont font;
UDPSerial serial;

boolean synched = false;

class UDPSerial{
  public UDPSerial(){
  }
  
  public void write(String data){
    udp.send(data, SERVER_HOST, SERVER_PORT);
  }
}

void drawArrow(float headWidthFactor, float headLengthFactor) {
  float headWidth = headWidthFactor * 200.0f;
  float headLength = headLengthFactor * 200.0f;
  
  pushMatrix();
  
  // Draw base
  translate(0, 0, -100);
  box(100, 100, 200);
  
  // Draw pointer
  translate(-headWidth/2, -50, -100);
  beginShape(QUAD_STRIP);
    vertex(0, 0 ,0);
    vertex(0, 100, 0);
    vertex(headWidth, 0 ,0);
    vertex(headWidth, 100, 0);
    vertex(headWidth/2, 0, -headLength);
    vertex(headWidth/2, 100, -headLength);
    vertex(0, 0 ,0);
    vertex(0, 100, 0);
  endShape();
  beginShape(TRIANGLES);
    vertex(0, 0, 0);
    vertex(headWidth, 0, 0);
    vertex(headWidth/2, 0, -headLength);
    vertex(0, 100, 0);
    vertex(headWidth, 100, 0);
    vertex(headWidth/2, 100, -headLength);
  endShape();
  
  popMatrix();
}

void drawBoard() {
  pushMatrix();

  rotateY(-radians(yaw - yawOffset));
  rotateX(radians(roll));
  rotateZ(radians(pitch)); 

  rotateY(radians(180));
  
  rotateY(radians(45));
  fill(5, 5, 5);
  box(20*COPTER_GUI_SCALE_FACTOR, 0.5*COPTER_GUI_SCALE_FACTOR, 0.5*COPTER_GUI_SCALE_FACTOR);
  
  rotateY(radians(90));
  fill(5, 5, 5);
  box(20*COPTER_GUI_SCALE_FACTOR, 0.5*COPTER_GUI_SCALE_FACTOR, 0.5*COPTER_GUI_SCALE_FACTOR);
  
  rotateY(radians(45));
  // Board body
  fill(190, 190, 190, 50f);
  box(5*COPTER_GUI_SCALE_FACTOR, 1*COPTER_GUI_SCALE_FACTOR, 5*COPTER_GUI_SCALE_FACTOR);
  
  fill(16, 78, 140);
  translate(0, -1*COPTER_GUI_SCALE_FACTOR, 0);
  box(4.5*COPTER_GUI_SCALE_FACTOR, 1*COPTER_GUI_SCALE_FACTOR, 3.5*COPTER_GUI_SCALE_FACTOR);
  
  // Forward-arrow
  pushMatrix();
  translate(0, 1*COPTER_GUI_SCALE_FACTOR, -2.5*COPTER_GUI_SCALE_FACTOR);
  scale(0.5f, 0.2f, 0.25f);
  fill(0, 255, 0);
  drawArrow(1.0f, 1.0f);
  popMatrix();
    
  popMatrix();
}



// Global setup
void setup() {
  // Setup graphics
  size(640, 480, OPENGL);
  smooth();
  noStroke();
  frameRate(50);
  
  font = createFont("Ariel", 32);
  textFont(font);
  fill(50);
  
  udp = new UDP( this, CLIENT_AHRS_PORT);  // create datagram connection on port 33335   
  //udp.log( true );            // <-- print out the connection activity
  udp.listen( true );           // and wait for incoming message
  
  serial = new UDPSerial();
}


void receive( byte[] data ) {           // <-- default handler
    String dataStr = new String(data);
    //println(dataStr);
    yaw = Float.parseFloat(dataStr.substring(dataStr.indexOf('=')+1, dataStr.indexOf(',')));
    dataStr = dataStr.substring(dataStr.indexOf(',')+1);
    pitch = Float.parseFloat(dataStr.substring(0, dataStr.indexOf(',')));
    dataStr = dataStr.substring(dataStr.indexOf(',')+1);
    roll = Float.parseFloat(dataStr.substring(0));
}

void setupRazor() {
  println("Trying to setup and synch Razor...");
  
  // On Mac OSX and Linux (Windows too?) the board will do a reset when we connect, which is really bad.
  // See "Automatic (Software) Reset" on http://www.arduino.cc/en/Main/ArduinoBoardProMini
  // So we have to wait until the bootloader is finished and the Razor firmware can receive commands.
  // To prevent this, disconnect/cut/unplug the DTR line going to the board. This also has the advantage,
  // that the angles you receive are stable right from the beginning. 
  delay(2000);  // 3 seconds should be enough
  
  serial.write("#ot");  // Turn on text output
  serial.write("#o1");  // Turn on continuous streaming output
  serial.write("#oe0"); // Disable error message output
}

void draw() {
   // Reset scene
  background(65);
  lights();

  // Sync with Razor 
  if (!synched) {
    textAlign(CENTER);
    fill(255);
    text("Connecting to Razor...", width/2, height/2, -200);
    
    if (frameCount == 2)
      setupRazor();  // Set ouput params and request synch token
    else if (frameCount > 2)
      synched = true;
    return;
  }

  // Draw board
  pushMatrix();
  translate(width/2, height/2, -350);
  drawBoard();
  popMatrix();
  
  textFont(font, 12);
  fill(255);
  textAlign(LEFT);

  // Output info text
  text("'a' to align\n'0' to turn off continuous, \n'1' to turn on continuous\n'f' to request one frame", 5, 15);

  // Output angles
  pushMatrix();
  translate(10, height - 10);
  textAlign(LEFT);
  text("Yaw: " + ((int) yaw), 0, 0);
  text("Pitch: " + ((int) pitch), 150, 0);
  text("Roll: " + ((int) roll), 300, 0);
  popMatrix();
}

void keyPressed() {
  switch (key) {
    case '0':  // Turn Razor's continuous output stream off
      serial.write("#o0");
      break;
    case '1':  // Turn Razor's continuous output stream on
      serial.write("#o1");
      break;
    case 'f':  // Request one single yaw/pitch/roll frame from Razor (use when continuous streaming is off)
      serial.write("#f");
      break;
    case 'a':  // Align screen with Razor
      yawOffset = yaw;
  }
}



