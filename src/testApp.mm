#include "testApp.h"
#include "Settings.h"
//--------------------------------------------------------------
void testApp::setup(){
	// initialize the accelerometer
	ofxAccelerometer.setup();
	ofRegisterTouchEvents(this);
	//If you want a landscape oreintation
	//iPhoneSetOrientation(OFXIPHONE_ORIENTATION_LANDSCAPE_RIGHT);
	ofEnableSmoothing();
	ofBackground(0);
    // open an outgoing connection to HOST:PORT
    
    // Get an integer and a string value
    string host = Settings::getString("Host");
    int port = Settings::getInt("Port");
    
    
	sender.setup( host, port );
    // Initialize gyro
	enableGyro();
	
	// Camera setup
	camera.setPosition( ofVec3f(0, 0, -30.0f) );
	camera.lookAt( ofVec3f(0, 0, 0), ofVec3f(0, -1, 0) );
}

//--------------------------------------------------------------
void testApp::update(){
    //    if( ofGetFrameNum() % 120 == 0 ){
    ofxOscMessage m;
    m.setAddress( "/orbit" );
    m.addIntArg( ofRadToDeg( pitch ) );
    m.addIntArg( -ofRadToDeg( roll ) );
    m.addIntArg( -ofRadToDeg( yaw ) );
    sender.sendMessage( m );
    //	}
    getDeviceGLRotationMatrix();
}

//--------------------------------------------------------------
void testApp::draw(){
    ofSetColor( ofColor::white );
	ofDrawBitmapString( "Double tap to align the cube", ofPoint( 10, 20 ) );
	
	camera.begin();
	
	ofPushView();
	{
		ofRotateX( ofRadToDeg( pitch ) );
		ofRotateY( -ofRadToDeg( roll ) );
		ofRotateZ( -ofRadToDeg( yaw ) );
		
		ofDrawAxis( 4 );
		
		ofNoFill();
		ofSetHexColor( 0x00A6FF );
//        ofSphere(0, 0, 0, 6);
		ofBox( 0, 0, 12 );
	}
	ofPopMatrix();
	
	camera.end();
}

//--------------------------------------------------------------
void testApp::exit(){
    
}

//--------------------------------------------------------------
void testApp::touchDown(ofTouchEventArgs & touch){
    
}

//--------------------------------------------------------------
void testApp::touchMoved(ofTouchEventArgs & touch){
    
}

//--------------------------------------------------------------
void testApp::touchUp(ofTouchEventArgs & touch){
    
}

//--------------------------------------------------------------
void testApp::touchDoubleTap(ofTouchEventArgs & touch){
    CMDeviceMotion *deviceMotion = motionManager.deviceMotion;
	CMAttitude *attitude = deviceMotion.attitude;
	referenceAttitude	= [attitude retain];
}

//--------------------------------------------------------------
void testApp::touchCancelled(ofTouchEventArgs & touch){
    
}

//--------------------------------------------------------------
void testApp::lostFocus(){
    
}

//--------------------------------------------------------------
void testApp::gotFocus(){
    
}

//--------------------------------------------------------------
void testApp::gotMemoryWarning(){
    
}

//--------------------------------------------------------------
void testApp::deviceOrientationChanged(int newOrientation){
    
}

void testApp::enableGyro() {
	motionManager = [[CMMotionManager alloc] init];
	referenceAttitude = nil;
	
	CMDeviceMotion *deviceMotion = motionManager.deviceMotion;
	CMAttitude *attitude = deviceMotion.attitude;
	referenceAttitude = [attitude retain];
	[motionManager startDeviceMotionUpdates];
}


void testApp::getDeviceGLRotationMatrix() {
	CMDeviceMotion *deviceMotion = motionManager.deviceMotion;
	CMAttitude *attitude = deviceMotion.attitude;
	
	if ( referenceAttitude != nil ) {
		[attitude multiplyByInverseOfAttitude:referenceAttitude];
	}
	
	roll	= attitude.roll;
	pitch	= attitude.pitch;
	yaw	= attitude.yaw;
	
	
	CMRotationMatrix rot = attitude.rotationMatrix;
	rotMatrix[0] = rot.m11; rotMatrix[1] = rot.m21; rotMatrix[2] = rot.m31;rotMatrix[3] = 0;
	rotMatrix[4] = rot.m12; rotMatrix[5] = rot.m22; rotMatrix[6] = rot.m32;rotMatrix[7] = 0;
	rotMatrix[8] = rot.m13; rotMatrix[9] = rot.m23; rotMatrix[10] = rot.m33; rotMatrix[11] = 0;
	rotMatrix[12] = 0;rotMatrix[13] = 0;rotMatrix[14] = 0; rotMatrix[15] = 1;
	
}