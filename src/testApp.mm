#include "testApp.h"
#include "Settings.h"
//--------------------------------------------------------------
void testApp::setup(){
    // initialize the accelerometer
	
    float latitudeBands = 60;
    float longitudeBands = 60;
    float radius = 12;
    
    for (int latNumber = 0; latNumber <= latitudeBands; latNumber++) {
        float theta = latNumber * PI / latitudeBands;
        float sinTheta = sin(theta);
        float cosTheta = cos(theta);
        for (int longNumber = 0; longNumber <= longitudeBands; longNumber++) {
            float phi = longNumber * 2 * PI / longitudeBands;
            float sinPhi = sin(phi);
            float cosPhi = cos(phi);
            float x = cosPhi * sinTheta;
            float y = cosTheta;
            float z = sinPhi * sinTheta;
            float u = 1- (longNumber / longitudeBands);
            float v = latNumber / latitudeBands;
            sphereMesh.addVertex(ofVec3f(x,y,z)*radius);
            sphereMesh.addNormal(ofVec3f(x,y,z));
            sphereMesh.addTexCoord(ofVec2f(u,v));

            sphereMesh.addColor(ofFloatColor(0.2,0.2,1,0.1));
        }
    }
    for (int latNumber = 0; latNumber < latitudeBands; latNumber++) {
        for (int longNumber = 0; longNumber < longitudeBands; longNumber++) {
            int first = (latNumber * (longitudeBands + 1)) + longNumber;
            int second = first + longitudeBands + 1;
            sphereMesh.addIndex(first);
            sphereMesh.addIndex(second);
            sphereMesh.addIndex(first + 1);
            sphereMesh.addIndex(second);
            sphereMesh.addIndex(second + 1);
            sphereMesh.addIndex(first + 1);
        }
    }

    ofxAccelerometer.setup();
	ofRegisterTouchEvents(this);
	//If you want a landscape oreintation
    //    iPhoneSetOrientation(OFXIPHONE_ORIENTATION_LANDSCAPE_RIGHT);
    ofEnableAlphaBlending();
	ofEnableSmoothing();
	ofBackground(0);
    // open an outgoing connection to HOST:PORT
    
    // Get an integer and a string value
    string host = Settings::getString("Host");
    int port = Settings::getInt("Port");
    int inport = Settings::getInt("Incoming Port");
    
    
    
	sender.setup( host, port );
    receiver.setup( inport );
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
        float h = ofRandom(100,150);
        for (int i=0; i<LENGTH; i++)
        {
            int index = i+(j*LENGTH);
            strip[index].set(ofGetWidth()*0.5,ofGetHeight()*0.5,0);
            float brightness = sinf(PI*float((i*0.5)*1.f/LENGTH*0.5f))*125;
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
    
    setGUI1();
	setGUI2();
//    setGUI3();
//    setGUI4();
//    
    gui1->setDrawPadding(true);
    gui2->setDrawPadding(true);
//    gui3->setDrawPadding(true);
//    gui4->setDrawPadding(true);
    
    gui1->setDrawBack(false);
    gui2->setDrawBack(false);
//    gui3->setDrawBack(false);
//    gui4->setDrawBack(false);
    gui1->setVisible(true);
    gui2->setVisible(false);
//    gui3->setVisible(true);
//    gui4->setVisible(true);
}

//--------------------------------------------------------------
void testApp::update(){
    // check for waiting messages
    while(receiver.hasWaitingMessages()){
        // get the next message
        ofxOscMessage m;
        receiver.getNextMessage(&m);
        
        // check for mouse moved message
        if(m.getAddress() == "/mode"){
            int _mode = m.getArgAsInt32(0);
            switch(_mode)
            {
                case 0:
//                    mode = POINT;
                    gui1->setVisible(true);
                    gui2->setVisible(false);
                    break;
                case 1:
//                    mode = DISPLACEMENT;
                    gui1->setVisible(true);
                    gui2->setVisible(false);
                    break;
                case 2:
//                    mode = SLITSCAN;
                    gui1->setVisible(false);
                    gui2->setVisible(true);
                    break;
                case 3:
                    gui1->setVisible(true);
                    gui2->setVisible(false);
//                    mode = TRIANGLE;
                    break;
                default:
//                    mode = POINT;
                    break;
                    
            }

        }
    }
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
		
//		ofDrawAxis( 4 );
		
		ofNoFill();
		ofSetHexColor( 0x00A6FF );
        glPointSize(3);
//        sphereMesh.draw();
        sphereMesh.drawWireframe();
        sphereMesh.drawVertices();
//        ofSphere(0, 0, 0, 12);
//		ofBox( 0, 0, 12 );
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
    delete gui1;
	delete gui2;
//    delete gui3;
//    delete gui4;
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

void testApp::guiEvent(ofxUIEventArgs &e)
{
	string name = e.widget->getName();
	int kind = e.widget->getKind();
	cout << "got event from: " << name << endl;
//    if(kind == OFX_UI_WIDGET_TOGGLE)
    {
        ofxOscBundle bundle;
        if(name =="POINT")
        {
            ofxOscMessage msg;
            
            msg.setAddress("/mode");
            msg.addIntArg(0);
            bundle.addMessage(msg);
                        gui2->setVisible(false);
            
        }else if(name =="DISPLACEMENT")
        {
            ofxOscMessage msg;
            msg.setAddress("/mode");
            msg.addIntArg(1);
            bundle.addMessage(msg);
            gui2->setVisible(false);            
        }else if(name == "TRIANGLE")
        {
            gui2->setVisible(false);
            ofxOscMessage msg;
            msg.setAddress("/mode");
            msg.addIntArg(3);
            bundle.addMessage(msg);
        }else if(name == "SLITSCAN")
        {
            gui2->setVisible(true);
            ofxOscMessage msg;
            msg.setAddress("/mode");
            msg.addIntArg(2);
            bundle.addMessage(msg);
        }
        else
        {
            ofxOscMessage msg;
            msg.setAddress("/slitscan");
            msg.addStringArg(name);
            bundle.addMessage(msg);
//            "0: most recent");
//            gradientModeRadioOption.push_back("1: left-right");
//            gradientModeRadioOption.push_back("2: right-left");
//            gradientModeRadioOption.push_back("3: top-bottom");
//            gradientModeRadioOption.push_back("4: bottom-top"
        }
        sender.sendBundle(bundle);
    }

}
void testApp::setGUI1()
{
    float dim = 16;
	float xInit = OFX_UI_GLOBAL_WIDGET_SPACING;
    float length = ofGetWidth();
    float height = ofGetHeight()/4.0f;

	gui1 = new ofxUICanvas(0, ofGetHeight()-height, length+xInit, height);
gui1->addLabel("PANEL1");
    gui1->addLabelButton("DISPLACEMENT", false, length-xInit);
    gui1->addLabelButton("POINT", false, length-xInit);
    gui1->addLabelButton("TRIANGLE", false, length-xInit);
//    gui1->addLabelButton("SLITSCAN", false, length-xInit);
    ofAddListener(gui1->newGUIEvent,this,&testApp::guiEvent);
}
void testApp::setGUI2()
{
    float dim = 16;
	float xInit = OFX_UI_GLOBAL_WIDGET_SPACING;
    float length = ofGetWidth();
    float height = ofGetHeight()/4.0f;
    
	gui2 = new ofxUICanvas(0, ofGetHeight()-height, length+xInit, height);
    gui2->addLabel("PANEL2");
    vector<string>gradientModeRadioOption;
    gradientModeRadioOption.push_back("0: most recent");
    gradientModeRadioOption.push_back("1: left-right");
    gradientModeRadioOption.push_back("2: right-left");
    gradientModeRadioOption.push_back("3: top-bottom");
    gradientModeRadioOption.push_back("4: bottom-top");
    gui2->addLabelButton(gradientModeRadioOption[0], false, length-xInit);
    gui2->addLabelButton(gradientModeRadioOption[1], false, length-xInit);
    gui2->addLabelButton(gradientModeRadioOption[2], false, length-xInit);
    gui2->addLabelButton(gradientModeRadioOption[3], false, length-xInit);
    gui2->addLabelButton(gradientModeRadioOption[4], false, length-xInit);

    ofAddListener(gui2->newGUIEvent,this,&testApp::guiEvent);
    
}
//void testApp::setGUI3()
//{
//    float dim = 16;
//	float xInit = OFX_UI_GLOBAL_WIDGET_SPACING;
//    float length = ofGetWidth()/4.0f;
//    float height = ofGetHeight()/4.0f;
//    
//	gui3 = new ofxUICanvas(length*2+xInit, ofGetHeight()-height, length+xInit, height);
//    gui3->addLabel("PANEL3");
//    ofAddListener(gui3->newGUIEvent,this,&testApp::guiEvent);
//
//}
//void testApp::setGUI4()
//{
//    float dim = 16;
//	float xInit = OFX_UI_GLOBAL_WIDGET_SPACING;
//    float length = ofGetWidth()/4.0f;
//    float height = ofGetHeight()/4.0f;
//    
//	gui4 = new ofxUICanvas(length*3+xInit, ofGetHeight()-height, length+xInit, height);
//    gui4->addLabel("PANEL4");
//    ofAddListener(gui4->newGUIEvent,this,&testApp::guiEvent);
//
//}
