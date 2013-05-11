#include "testApp.h"
#include "Settings.h"
//--------------------------------------------------------------
void testApp::setup(){
	// initialize the accelerometer
	ofxAccelerometer.setup();
	ofRegisterTouchEvents(this);
	//If you want a landscape oreintation
	//iPhoneSetOrientation(OFXIPHONE_ORIENTATION_LANDSCAPE_RIGHT);
    ofEnableAlphaBlending();
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
    
    for (int j=0; j<NUM_STRIP; j++)
    {
        pos[j].set(ofRandom(0, ofGetWidth()),ofRandom(0,ofGetHeight()),0);
        vec[j].set(0,0,0);
        acc[j].set(ofRandom(-1,1),ofRandom(-1,1),0);
        age[j] = 1;
        float h = ofRandom(100,200);
        for (int i=0; i<LENGTH; i++)
        {
            int index = i+(j*LENGTH);
            strip[index].set(ofGetWidth()*0.5,ofGetHeight()*0.5,0);
            float brightness = sinf(PI*float((i*0.5)*1.f/LENGTH*0.5f))*255;
            color[index].set(ofColor::fromHsb(h,255, 255,brightness));
        }
        
        for (int i=0; i<LOC_LENGTH; i++)
        {
            int index = i+(j*LOC_LENGTH);
            loc[index].set(0,0,0);
        }
        
        
    }
    total = NUM_STRIP*LENGTH;
    vbo.setVertexData(strip, total, GL_DYNAMIC_DRAW);
	vbo.setColorData(color, total, GL_DYNAMIC_DRAW);
    count = 0;
    
    for(int i = 0 ; i< 5 ; i++)
    {
        canFire[i] = false;
        point[i].set(0,0);
    }
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
    float t = (ofGetElapsedTimef()) * 0.9f;
    float div = 250.0;
    
    for (int j=0; j<NUM_STRIP; j++)
    {
        if(age[j]>0)
         {
             ofVec3f _vec(ofSignedNoise(t, pos[j].y/div, pos[j].z/div),
                          ofSignedNoise(pos[j].x/div, t, pos[j].z/div),
                          0);
             _vec *=  ofGetLastFrameTime()*50;
             vec[j]+=_vec;
             vec[j]+=acc[j];
             vec[j]*=0.9;
             ofVec3f Off;
             float radius = 10;
             for (int i=LOC_LENGTH-1; i>=1; i--)
             {
                 int index = i+(j*LOC_LENGTH);
                 loc[index].set(loc[index-1]);
             }
             for (int i=0; i<LOC_LENGTH; i++)
             {
                 int index = i+(j*LOC_LENGTH);
                 int index2 = (i*2)+(j*LENGTH);
                 
                 
                 radius = sinf(PI*float(i*1.f/LOC_LENGTH))*15;
                 {
                     ofVec3f perp0 = loc[index] - loc[index+1];
                     ofVec3f perp1 = perp0.getCrossed( ofVec3f( 0, 1, 0 ) ).getNormalized();
                     ofVec3f perp2 = perp0.getCrossed( perp1 ).getNormalized();
                     perp1 = perp0.getCrossed( perp2 ).getNormalized();
                     Off.x        = perp1.x * radius*age[j];
                     Off.y       = perp1.y * radius*age[j];
                     Off.z        = perp1.z * radius*age[j];
                     
                     strip[(index2)]=loc[index]-Off;
                     
                     strip[(index2+1)]=loc[index]+Off;
                 }
             }
             loc[j*LOC_LENGTH] = pos[j];
             pos[j]+=vec[j];
             age[j]-=0.02;
         }
         else
         {
             for (int i=0; i<LOC_LENGTH; i++)
             {
                 int index = i+(j*LOC_LENGTH);
                 loc[index].set(pos[j]);
                 int index2 = (i*2)+(j*LENGTH);
                 strip[(index2)]=loc[index];
                 
                 strip[(index2+1)]=loc[index];
             }
         }
        
        
    }
    for(int i = 0 ; i< NUM_TOUCH ; i++)
    {
        if(canFire[i])
        {
            fireStrip(point[i].x,point[i].y,pMouse[i].x,pMouse[i].y);
            canFire[i] = false;

        }
    }
}

//--------------------------------------------------------------
void testApp::draw(){
//    ofSetColor( ofColor::white );
	ofDrawBitmapString( "Double tap to align the cube", ofPoint( 10, 20 ) );
	
	camera.begin();
	
//	ofPushView();
    ofPushMatrix();
	{
		ofRotateX( ofRadToDeg( pitch ) );
		ofRotateY( -ofRadToDeg( roll ) );
		ofRotateZ( -ofRadToDeg( yaw ) );
		
		ofDrawAxis( 4 );
		
		ofNoFill();
		ofSetHexColor( 0x00A6FF );

		ofBox( 0, 0, 12 );
	}
	ofPopMatrix();
    
    
	
	camera.end();
    vbo.bind();
	vbo.updateVertexData(strip, total);
	vbo.updateColorData(color, total);
    
    
    for (int j=0; j<NUM_STRIP; j++)
        
    {
        int index = j * LENGTH;
        
        vbo.draw(GL_TRIANGLE_STRIP, index,LENGTH);
        
    }
    
    
	vbo.unbind();
}

//--------------------------------------------------------------
void testApp::exit(){
    
}

//--------------------------------------------------------------
void testApp::touchDown(ofTouchEventArgs & touch){
    
}
void testApp::fireStrip(float x, float y,float px , float py)
{
//    int ran = ofRandom(1,3);
//    for(int j = 0 ; j < ran ; j++)
    {
        count++;
        
        count%=NUM_STRIP;
        sin(ofRandomf()*TWO_PI)*50;
        pos[count].set(x+sin(ofRandomf()*TWO_PI)*ofRandom(-50,50), y+cos(ofRandomf()*TWO_PI)*ofRandom(-50,50));
        vec[count].set(x-px,y-py,0);
        vec[count]*=2;
        acc[count].set((x-pos[count].x)*0.01, (y-pos[count].y)*0.01);
        age[count] = 1;
        
        for (int i=0; i<LOC_LENGTH; i++)
        {
            int index = i+(count*LOC_LENGTH);
            loc[index].set(pos[count]);
            int index2 = (i*2)+(count*LENGTH);
            strip[(index2)]=loc[index];
            
            strip[(index2+1)]=loc[index];
            
            
        }

        
        
    }
}
//--------------------------------------------------------------
void testApp::touchMoved(ofTouchEventArgs & touch){
    if(touch.id<NUM_TOUCH)
    {
        point[touch.id].set(touch.x, touch.y);
        canFire[touch.id] = true;

    
    ofxOscMessage m;
    m.setAddress( "/mouse" );
    m.addFloatArg( touch.x/ofGetWidth()*1.0f );
    m.addFloatArg( touch.y/ofGetHeight()*1.0f );
    m.addFloatArg( touch.x-pMouse[touch.id].x );
    m.addFloatArg( touch.y-pMouse[touch.id].y );

    sender.sendMessage( m );
                    pMouse[touch.id] = point[touch.id];
    }
    
    

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
    ofLogWarning("gotMemoryWarning");
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