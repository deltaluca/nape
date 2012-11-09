#!/bin/sh

VER=$(echo $1)
DIR=chxdoc_$(echo $VER | sed 's/\./_/g')
VERSION=$(echo $VER | sed 's/\./_/g')

function prompt_continue {
	echo $1
	echo -n "Continue? [y/n] "
	read cont

	if [ !"$cont" = "y" ]; then
		exit 0
	fi;
}

if [ ! -n "$VER" ]; then
	echo "Add a release number (eg. 0.5) to the command line"
	exit 1
fi;



if [ -e chxdoc_release ]; then
	prompt_continue "This will remove an existing chxdoc_release directory";
	rm -Rf chxdoc_release
fi;


prompt_continue "Building release for $DIR"

make linux
make windows

mkdir -p chxdoc_release/Windows/$DIR
mkdir -p chxdoc_release/Linux/$DIR

cp -r src chxdoc_release/
rm chxdoc_release/src/chxdoc/Settings.hx
rm -r chxdoc_release/src/templates/ianxm

#readme
sed 's/\n/\r\n/g' src/README > chxdoc_release/Windows/$DIR/README.txt
cp src/README chxdoc_release/Linux/$DIR/

#temploc
mv chxtemploc.exe bin/Windows/
mv chxtemploc bin/Linux/
cp bin/Windows/chxtemploc.exe chxdoc_release/Windows/$DIR/
cp bin/Linux/chxtemploc chxdoc_release/Linux/$DIR/

#chxdoc
mv chxdoc.exe bin/Windows/
mv chxdoc bin/Linux/
cp bin/Windows/chxdoc.exe chxdoc_release/Windows/$DIR/
cp bin/Linux/chxdoc chxdoc_release/Linux/$DIR/


#templates
cp -R src/templates chxdoc_release/Windows/$DIR/
cp -R src/templates chxdoc_release/Linux/$DIR/

cd chxdoc_release

#remove 'devel' template in chxdoc_release
rm -Rf Linux/$DIR/templates/devel
rm -Rf Windows/$DIR/templates/devel

#remove .svn directories in chxdoc_release
find . -name ".svn" -exec rm -Rf {} \; 2>/dev/null

#remove tmp files in chxdoc_release
find . -name "*~" -exec rm {} \;

#make the haxelib version
cd src/Tools
haxe build.hxml
cd ../
zip -r ../chxdoc_lib-${VERSION} *
cd ..
haxelib test chxdoc_lib-${VERSION}.zip

cd Linux
tar -czf ${DIR}_linux.tgz $DIR
mv ${DIR}_linux.tgz ../

cd ../Windows
zip -rq $DIR $DIR
mv ${DIR}.zip ../${DIR}_win.zip

cd ../../

pwd
rm chxdoc.n
rm chxtemploc.n

echo "Complete. Files are in chxdoc_release."
echo ""
echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo "Make sure to test the haxelib version now with"
echo "haxelib run chxdoc install ~/bin"

