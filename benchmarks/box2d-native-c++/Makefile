CC = c++
LD = c++
CFLAGS  = -I/usr/X11R6/include -I. -c -std=c++0x -O2
LDFLAGS = -L/usr/X11R6/lib -lglut -lGLU -lGL -lXi -lXmu -lXt -lXext -lSM -lICE -lBox2D -lGLEW

OBJS = main.o
DEPENDENCIES = $(shell echo $(OBJS) | sed 's/\.o/\.P/g')

all: main
	./main

main: $(OBJS)
	$(LD) $(OBJS) -o main $(LDFLAGS)

clean:
	rm -rf $(OBJS) $(DEPENDENCIES) main

%.o: %.cpp
	$(CC) $(CFLAGS) $< -MD -o $@
	@cp $*.d $*.P; \
		sed -e 's/#.*//' -e 's/^[^:]*: *//' -e 's/ *\\$$//' \
			-e '/^$$/ d' -e 's/$$/ :/' < $*.d >> $*.P; \
		rm -f $*.d

