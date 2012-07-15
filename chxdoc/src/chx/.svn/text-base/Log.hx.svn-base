/*
 * Copyright (c) 2008-2009, The Caffeine-hx project contributors
 * Original author : Russell Weir
 * Contributors:
 * All rights reserved.
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *   - Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 *   - Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE CAFFEINE-HX PROJECT CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE CAFFEINE-HX PROJECT CONTRIBUTORS
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
 * THE POSSIBILITY OF SUCH DAMAGE.
 */

package chx;

/**
	A replacement for haxe.Log.trace which formats objects in a fashion which is easier to read.
**/
class Log {
	static var useFirebug : Bool = false;
	static var haxeLogTrace : Dynamic = haxe.Log.trace;

	#if flash
	static var defTextFont		: String = "_sans"; // "Times New Roman"
	static var defTextFontSize	: Float = 8;
	#end

	public static function clear() : Void {
		haxe.Log.clear();
		#if flash
		setDefaultFont();
		setDefaultFontSize();
		#end
	}

	/**
		Sets the trace color. Currently has no effect except in flash
	**/
	public static dynamic function setColor( rgb : Int ) {
		#if flash
		haxe.Log.setColor(rgb);
		#end
	}

	/**
		Set the trace font to the font name supplied, or if null
		uses the current default. Only works in flash.
	**/
	public static function setDefaultFont(?font : String) {
		#if flash
			if(font == null)
				font = defTextFont;
			var tf = untyped getTraceField();
			var format = tf.getTextFormat();
			format.font = font;
			tf.defaultTextFormat = format;
			defTextFont = font;
		#end
	}

	/**
		Sets the font size for traces. Only works in flash.
	**/
	public static function setDefaultFontSize(? pts : Float) {
		#if flash
			if(Math.isNaN(pts))
				pts = defTextFontSize;
			var tf = untyped getTraceField();
			var format = tf.getTextFormat();
			format.size = pts;
			defTextFontSize = pts;
		#end
	}

	#if flash
	/**
		Returns the flash textfield currently being used for traces. Invalidated
		by a call to {@link #clear() clear()}.
	**/
	public static function getTraceField() {
		return untyped flash.Boot.getTrace();
	}
	#end

	/**
		To initialize chx.Log as the default tracer. In js and flash, the optional
		[useFirebug] will redirect formatted traces through Firebug, if it is detected.
	**/
	public static function redirectTraces(?useFirebug : Bool = false) {
		#if (flash || flash9 || js)
			Log.useFirebug = false;
			if(useFirebug)
				if(haxe.Firebug.detect())
					Log.useFirebug = true;
		#end
		#if flash
			setDefaultFont();
			setDefaultFontSize();
			setColor(0x222222);
		#end
		haxe.Log.trace = trace;
	}

	public static function trace(v : Dynamic, ?inf : haxe.PosInfos ) {
		var s = prettyFormat(v, "");
		#if (flash || js)
			if(Log.useFirebug) {
				haxe.Firebug.trace(s, inf);
				return;
			}
		#end
		haxeLogTrace(s, inf);
	}

	/**
		@todo Enums and classes
	**/
	public static function prettyFormat(v : Dynamic, ?indent : String =  "") : String {
		var buf = new StringBuf();
		switch( Type.typeof(v) ) {
		case TClass(c):
			if(c == String)
				buf.add("'" + v + "'");
			else
				switch( c ) {
				case cast Array:
					#if flash9
					var v : Array<Dynamic> = v;
					#end
					var l = #if (neko || flash9 || php) v.length #else v[untyped "length"] #end;
					var first = true;
					if(l > 0)
						buf.add(iterFmtLinear("[","]",indent, v.iterator()));
					else
						buf.add("[]");
				case cast List:
					if(v.length > 0)
						buf.add(iterFmtLinear("{","}",indent, v.iterator()));
					else
						buf.add("{}");
				case cast Hash:
					buf.add(
						iterFmtAssoc("{", "}", " => ", indent, v.keys(), v.get)
					);
				case cast IntHash:
					buf.add(
						iterFmtAssoc("{", "}", " => ", indent, v.keys(), v.get)
					);
				default:
					buf.add(Std.string(v));
				}
		case TObject:
			buf.add(
				iterFmtAssoc("{", "}", " : ", indent, Reflect.fields(v).iterator(), callback(Reflect.field, v))
			);
		case TEnum(e):
			buf.add(Std.string(v));
		default:
// trace("default: " + Type.typeof(v));
			buf.add(Std.string(v));
		}
		return buf.toString();
	}



	/**
		Will format arrays and lists.
	**/
	static function iterFmtLinear<T>(open:String, close:String, indent : String, iter : Iterator<T>) {
		var buf = new StringBuf();
		buf.add(open);
		buf.add("\n");
		var ni = indent + "  ";
		var first = true;
		while(iter.hasNext()) {
			var i = iter.next();
			if(!first)
				buf.add(",\n");
			buf.add(ni);
			buf.add(prettyFormat(i, indent + "  "));
			first = false;
		}
		buf.add("\n");
		buf.add(indent);
		buf.add(close);
		return buf.toString();
	}

	/**
		@param separator The string to place between keys and values.
		@param valueRetriever A method to return the value for a given key.
	**/
	static function iterFmtAssoc<T>(open:String, close:String, separator:String, indent : String, keysIter : Iterator<T>, valueRetriever : T->Dynamic) {
		var buf = new StringBuf();
		if(!keysIter.hasNext()) {
			buf.add(open);
			buf.add(close);
			return buf.toString();
		}
		buf.add(open);
		buf.add("\n");

		var ni= indent + "  ";
		var first = true;

		while(keysIter.hasNext()) {
			var key = keysIter.next();
			var value = valueRetriever(key);
			if(!first)
				buf.add(",\n");
			buf.add(ni);

			buf.add(key);
			buf.add(separator);

			buf.add(prettyFormat(value, ni));
			first = false;
		}
		buf.add("\n");
		buf.add(indent);
		buf.add(close);
		return buf.toString();
	}
}