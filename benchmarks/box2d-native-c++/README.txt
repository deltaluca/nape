pre-req:
	Box2D, GLEW, GLUT, gcc-4.5+

Technically, this is not directly comparable to other tests since c++ box2d uses single precisino floats, which whilst computations themselves are not significantely faster, would lead to better memory alignment and cache use possibly giving more performance than if it were using doubles.

There does not seem to be a way to compile Box2D with double precision floats that I can see.
