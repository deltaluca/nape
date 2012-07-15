#summary Chxdoc information

= Introduction =

CHXDOC is a command line source code documentation system for the Haxe programming language. It is released under a BSD style license, and is available at
http://code.google.com/p/caffeine-hx/. Source is available using svn

svn checkout http://caffeine-hx.googlecode.com/svn/trunk/projects/chxdoc chxdoc

= Features =

  * Complete and clean documentation for releases or developer targets
  * Comment tags like @param, @return and @throws
  * Ability to generate docs for private vars, methods, typedefs, classes and enums
  * Templated html file generation

= Installation =

CHXDOC is now installed from haxelib. It must be compiled on your local system, so the program can locate the default template.

{{{
haxelib install chxdoc
haxelib run chxdoc install [optional path]
}}}

If the optional path parameter is omitted, chxdoc will be installed to the current directory.

CHXDOC uses a modified version of temploc, the template compiler system by Nicolas Cannasse. A compiled
copy is created when installing from haxelib.

For source code checkouts, there is a neko compiled chxtemploc.n in the ./utils/
subdirectory. Simply run 'nekotools boot utils/chxtemploc.n' to generate the binary,
which will be in the utils/ directory, named either "chxtemploc.exe" or "chxtemploc",
depending on your platform.

Install both the chxtemploc.exe and the chxdoc.exe file to somewhere on your executable
path. The templates directory can be placed anywhere.


= Usage =

You may want to start by running chxdoc with the --help switch, which will give you
the most up to date switches.

To generate documentation for a haxe project, an xml file for the project must be
created. To create one, simply add "-xml myproject.xml" to your haxe command
parameters. This will generate the file that chxdoc requires.

The most common usage of chxdoc would be something like:

{{{
chxdoc -o docs_dev --developer=true myproject.xml
chxdoc -o docs --templateDir=templates/release myproject.xml
}}}

Two versions of the documentation would be created, one with all the private data
documented (in docs_dev), and a public release of the documentation in docs.
All the images and css files from the template will be copied to both directories.

If you are documenting the haxe std library, you need to generate xml files using
the "all.hxml" file in the base directory of your installed standard lib. Once
the xml files are generated, you could generate flash9, neko and js targets
using a command similar to

{{{
chxdoc -o docs --tmpDir=_chxdoctmp --templateDir=../chxdoc/templates/default --installTemplate=true --developer=true flash9.xml,flash9,flash neko.xml,neko js.xml,js
}}}

= Options =

--developer=[true|false]
	This tag is a shortcut to setting the following switches:
	--showAuthorTags=bool;
	--showPrivateClasses=bool;
	--showPrivateTypedefs=bool;
	--showPrivateEnums=bool;
	--showPrivateMethods=bool;
	--showPrivateVars=bool;
	--showTodoTags=bool;
	--generateTodoFile=bool;
	Since arguments are parsed in order, you could selectively turn off showAuthorTags
	in a developer build with:
	--developer=true --showAuthorTags=false

= Using Tags =

Chxdoc adds support for @ tags in your source code comments. To use them, they
must be the first non-whitespace character on a line.

{{{
/**
 *	This function does very little.
 *	@param a An integer greater than 0
 *	@param s A string
 *	@return True if s is null
 *	@throws haxe.io.Eof When a <= 0
 **/
public function myFunc(a : Int, s : String) : Bool {
	if(a <= 0)
		throw new haxe.io.Eof();
	return (s == null);
}
}}}

The current available tags, all of which except for @deprecated can be used multiple times
{{{
@author
@deprecated
@param
@private
@requires
@return (or @returns)
@see
@throws
@todo
@type
}}}

@author text
	Adds an author field

@deprecated Description
	Prints a deprecation warning. This tag is not currently in the
	provided template, but is parsed.

@param name Description
	Adds a notation about a method argument.

@private
	Marks a field as private, even if the access is public. This is often used to
	hide methods that are internal use only, as Haxe has no 'protected' modifier.

@requires Description
	Adds a description for requirements, like a required neko ndll file

@return Description
	Adds literal description to html. @returns is also accepted.

@see Description
	Adds description as a source to view

@throws full_class_path Description
	Will link html documentation to the class path provided, so it
	must be a fully qualified class path. (haxe.io.Eof)

@todo Description
	For generating TODO files and html notes

@type Description
	For adding descriptions for types (<T>)

= Package and Type filtering =

Filtering classes and packages is done using the -f switch, which will prevent
paths matching the argument from having documentation generated.

A class, enum or typedef named my.pack.MyClass can be specifically filtered by using
-f my.pack.MyClass
To filter every class and subpackage in the package 'my.pack' use
-f my.pack
So, if you apply
-f my
All of my, including my.pack, and of course then my.pack.MyClass, will not show up in the
generated documentation.


= Planned =

embedded tags like {@link } for things like @see {@link haxe.io.Bytes}

----

If you have any questions, visit #haxe on Freenode (Madrok), or
by gmail (damonsbane).

Any suggestions or contributions welcome! A special thanks goes to
Franco Ponticelli for the 'default' template.
