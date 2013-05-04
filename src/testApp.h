#pragma once

#include "ofMain.h"
#include "ofxiPhone.h"
#include "ofxiPhoneExtras.h"
#include "ofxOsc.h"

#define HOST "10.0.1.9"
#define PORT 7170
#import <CoreMotion/CMMotionManager.h>
class testApp : public ofxiPhoneApp{
	
public:
    void setup();
    void update();
    void draw();
    void exit();
	
    void touchDown(ofTouchEventArgs & touch);
    void touchMoved(ofTouchEventArgs & touch);
    void touchUp(ofTouchEventArgs & touch);
    void touchDoubleTap(ofTouchEventArgs & touch);
    void touchCancelled(ofTouchEventArgs & touch);
    
    void lostFocus();
    void gotFocus();
    void gotMemoryWarning();
    void deviceOrientationChanged(int newOrientation);
    ofxOscSender sender;
    
    
    void enableGyro();
	void getDeviceGLRotationMatrix();
	
	
	CMMotionManager *motionManager;
	CMAttitude *referenceAttitude;
	
	GLfloat rotMatrix[16];
	
	float roll, pitch, yaw;
	
	ofCamera camera;
};


