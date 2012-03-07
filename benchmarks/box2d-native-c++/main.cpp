#include <iostream>
#include <GL/glew.h>
#include <GL/glxew.h>
#include <GL/glut.h>
#include <Box2D/Dynamics/b2World.h>
#include <Box2D/Dynamics/b2Fixture.h>
#include <Box2D/Dynamics/b2Body.h>
#include <Box2D/Common/b2Math.h>
#include <Box2D/Collision/Shapes/b2PolygonShape.h>
#include <ctime>
#include <vector>
#include <algorithm>

using namespace std;

double getTimer() {
	return double(clock())/double(CLOCKS_PER_SEC)*1000.0;
}

const float scale = 30.f;
const float boxw = 6.f;
const float boxh = 12.f;
const int height = 40;

typedef b2Body* Body;

vector<Body> bodies;
b2World world(b2Vec2(0.f,400.f/scale));

void init() {
	b2BodyDef borderDef;
	Body border = Body(world.CreateBody(&borderDef));

	b2PolygonShape borders[4];
	borders[0].SetAsBox(50.f/scale/2,500.f/scale/2,b2Vec2(-25.f/scale,250.f/scale),0);
	borders[1].SetAsBox(50.f/scale/2,500.f/scale/2,b2Vec2(525.f/scale,250.f/scale),0);
	borders[1].SetAsBox(500.f/scale/2,50.f/scale/2,b2Vec2(250.f/scale,-25.f/scale),0);
	borders[1].SetAsBox(500.f/scale/2,50.f/scale/2,b2Vec2(250.f/scale,525.f/scale),0);
	for(int i = 0; i<4; i++) border->CreateFixture(&borders[i],0.0f);

	for(int y = 1; y<=height; y++) {
		for(int x = 0; x<y; x++) {
			b2BodyDef blockdef;
			blockdef.type = b2_dynamicBody;
			blockdef.position.Set(
				(250.f-boxw*float(y-1)*0.5f+float(x)*boxw)/scale,
				(500.f-boxh*0.5f-boxh*float(height-y)*0.98f)/scale
			);
			b2Body* block = world.CreateBody(&blockdef);
			bodies.push_back(block);
			b2PolygonShape box;
			box.SetAsBox(boxw/scale/2.1,boxh/scale/2.1);
			b2FixtureDef fixture;
			fixture.shape = &box;
			fixture.density = 1.0f;
			fixture.friction = 0.3f;
			block->CreateFixture(&fixture);
		}
	}
}

bool render = true;
void display() {
	glClear(GL_COLOR_BUFFER_BIT);

	if(render) {
		glMatrixMode(GL_PROJECTION);
		glLoadIdentity();
		glOrtho(0,500,0,500,1,2);
		glMatrixMode(GL_MODELVIEW);
		glLoadIdentity();
		glTranslatef(0,500,-1.5);
		glScalef(1,-1,1);

		glPolygonMode(GL_FRONT_AND_BACK, GL_LINE);
		glBegin(GL_QUADS);
		int i = 0;
		for_each(bodies.begin(),bodies.end(),[&](Body b){
			int rgb = int(0xffffff*exp(-float((i++)%500)/1500));
			glColor3f(
				float(rgb>>16)/255.f,
				float((rgb>>8)&0xff)/255.f,
				float(rgb&0xff)/255.f
			);

			b2Vec2 vert;
			vert = b->GetWorldPoint(b2Vec2(boxw/2/scale,boxh/2/scale));	
			glVertex2f(vert.x*scale,vert.y*scale);
			vert = b->GetWorldPoint(b2Vec2(-boxw/2/scale,boxh/2/scale));	
			glVertex2f(vert.x*scale,vert.y*scale);
			vert = b->GetWorldPoint(b2Vec2(-boxw/2/scale,-boxh/2/scale));	
			glVertex2f(vert.x*scale,vert.y*scale);
			vert = b->GetWorldPoint(b2Vec2(boxw/2/scale,-boxh/2/scale));	
			glVertex2f(vert.x*scale,vert.y*scale);
		});
		glEnd();
	}

	glutSwapBuffers();
}

double pt;
int i = 0;
void mainloop() {
	double ct = getTimer();
	if((++i)%10==0) {
		std::cout << (10000.0/(ct-pt)) << "fps" << std::endl;
		pt = ct;
	}
		
	float dt = 1.f/200.f + float(i)*1e-5*30.f;
	if(dt>1.f/40.f) dt = 1.f/40.f;

	world.Step(dt,8,8);
	display();
}

void keyboard(unsigned char key, int x, int y) {
	if(key==' ') render = !render;
}

int main(int argc, char** argv) {
	glutInit(&argc, argv);
	glutInitDisplayMode(GLUT_DOUBLE | GLUT_RGB);
	
	glutInitWindowSize(500,500);
	glutInitWindowPosition(0,0);
	glutCreateWindow(argv[0]);

	GLenum err = glewInit();
	if(GLEW_OK != err) {
		fprintf(stderr, "Error: %s\n", glewGetErrorString(err));
		return 0;
	}

	if(!GLEW_VERSION_1_5) {
		fprintf(stderr, "Error: OpenGL 1.5 not supported??");
		return 0;
	}

	if(!GLX_SGI_swap_control) {
		std::cout << "swap control extension not supported!!\n";
		return 0;
	}
	glXSwapIntervalSGI(0);

	glShadeModel(GL_FLAT);
	glClearColor(0.3,0.3,0.3,0.0);

	init();

	pt = getTimer();
	glutDisplayFunc(display);
	glutIdleFunc(mainloop);
	glutKeyboardFunc(keyboard);
	glutMainLoop();

	return 0;
}
