#pragma once

#include "ofMain.h"
#include "ofxiPhone.h"
#include "ofxiPhoneExtras.h"
#include "ofxOsc.h"
#include "ofxUI.h"
#define HOST "10.0.1.9"
#define PORT 7170
#import <CoreMotion/CMMotionManager.h>
#define NUM_STRIP 1000
#define LOC_LENGTH 10
#define LENGTH LOC_LENGTH*2
#define NUM_TOUCH 10
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
    ofxOscReceiver receiver;
    
    
    void enableGyro();
	void getDeviceGLRotationMatrix();
	
	
	CMMotionManager *motionManager;
	CMAttitude *referenceAttitude;
	
	GLfloat rotMatrix[16];
	
	float roll, pitch, yaw;
	
	ofCamera camera;

    void fireStrip(float x, float y,float px, float py);


    	void guiEvent(ofxUIEventArgs &e);
    void setGUI1();
	void setGUI2();
//	void setGUI3();
//	void setGUI4();
    ofxUICanvas *gui1;
    ofxUICanvas *gui2;
//    ofxUICanvas *gui3;
//    ofxUICanvas *gui4;
    
    
    
    ofVbo vbo;
    ofVec3f pos[NUM_STRIP];
    ofVec3f acc[NUM_STRIP];
    ofVec3f vec[NUM_STRIP];
    float age[NUM_STRIP];
    ofVec3f strip[NUM_STRIP*LENGTH];
    ofVec3f loc[NUM_STRIP*LOC_LENGTH];
	ofFloatColor color[NUM_STRIP*LENGTH];
    int total;
    int count;
    ofVec3f point[NUM_TOUCH];
    bool canFire[NUM_TOUCH];
    ofVec3f pMouse[NUM_TOUCH];
    
    ofMesh sphereMesh;
    ofLight light;
    

    


};


