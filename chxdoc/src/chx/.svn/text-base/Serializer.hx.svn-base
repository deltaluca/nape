/*
 * Copyright (c) 2005, The haXe Project Contributors
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
 * THIS SOFTWARE IS PROVIDED BY THE HAXE PROJECT CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE HAXE PROJECT CONTRIBUTORS BE LIABLE FOR
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 */
package chx;

//import chx.io.Output;
import haxe.io.Output;

/**
	This is a haxe compatible serializer optimized for serializing objects with lots
	of circular references. To do this, a special field "__serializeHash" should exist
	on the objects and classes, which is either a function Void->String or just a String.
	The String returned should be unique to the class or object instance, not to the
	class or object. If the field "__serializeHash" does not exist, it will be created.

	Also, this version of haxe serialization does not throw errors on Function fields,
	they are detected and ignored.

	The preSerialize* dynamic methods are available to be set to handlers
	that may modify the objects before being serialized. There can be multiple
	calls per object if there are circular references, so code accordingly.

	Developed for ChxDoc, which was taking 5:36 to serialize configuration data under
	haxe.Serializer, reduced to 0:58 using this technique.

	@todo Move to chx.io
**/
class Serializer {

	/**
		If the values you are serializing can contain
		circular references or objects repetitions, you should
		set USE_CACHE to true to prevent infinite loops.
	**/
	public static var USE_CACHE = false;

	/**
		Use constructor indexes for enums instead of names.
		This is less reliable but more compact.
	**/
	public static var USE_ENUM_INDEX = false;

	static var BASE64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789%:";

	var buf : Output;
	var cache : Array<Dynamic>;
	var shash : Hash<Int>;
	var scount : Int;
	public var useCache : Bool;
	public var useEnumIndex : Bool;


	/** Can be used to modify objects before they are serialized **/
	public var preSerializeObject	: Dynamic -> Void;
	/** Can be used to modify classes before they are serialized **/
	public var preSerializeClass	: Dynamic -> Void;
	/** Can be used to modify enums before they are serialized **/
	public var preSerializeEnum		: Dynamic -> Void;

	var keyCache : Hash<Array<{obj: Dynamic, idx : Int }>>;

	/**
		Create a new Serializer with output going to stream [out]
		@param out Output stream
	**/
	public function new(out : Output) {
		buf = out;
		cache = new Array();
		useEnumIndex = USE_ENUM_INDEX;
		shash = new Hash();
		scount = 0;

		keyCache = new Hash();
		useCache = true;
	}

	/* prefixes :
		a : array
		b : hash
		c : class
		d : Float
		e : reserved (float exp)
		f : false
		g : object end
		h : array/list/hash end
		i : Int
		j : enum (by index)
		k : NaN
		l : list
		m : -Inf
		n : null
		o : object
		p : +Inf
		q : inthash
		r : reference
		s : bytes (base64)
		t : true
		u : array nulls
		v : date
		w : enum
		x : exception
		y : urlencoded string
		z : zero
	*/

	function serializeString( s : String ) {
		var x = shash.get(s);
		if( x != null ) {
			buf.writeString("R");
			buf.writeString(Std.string(x));
			return;
		}
		shash.set(s,scount++);
		#if old_serialize
			// no more support for -D old_serialize due to 'j' reuse
			#if error #end
		#end
		buf.writeString("y");
		s = StringTools.urlEncode(s);
		buf.writeString(Std.string(s.length));
		buf.writeString(":");
		buf.writeString(s);
	}

	function serializeRef(v) {
		var key : String = null;
		var isClass = false;
		var isObject = false;

		switch(Type.typeof(v)) {
		case TEnum(e):
			if(preSerializeEnum != null)
				preSerializeEnum(v);
		case TClass(c):
			isClass = true;
			if(preSerializeClass != null)
				preSerializeClass(v);
		case TObject:
			isObject = true;
			if(preSerializeObject != null)
				preSerializeObject(v);
		default:
			throw "Unexpected type.";
		}

		try {
			if(isClass || isObject) {
				if(!Reflect.hasField(v, "__serializeHash"))
					throw "bad key";
				try {
					// Don't use Reflect.callMethod, which fails in neko
					// when f() is a callback
					key = untyped v.__serializeHash();
				} catch(e : Dynamic) {
					key = cast Reflect.field(v, "__serializeHash");
					if(key == null)
						throw "bad key";
				}
			}
			else
				key = "__ENUM__" + Type.enumConstructor(cast v);
		} catch(e : Dynamic) {
			key = "";
			var fields = Reflect.fields(v);
			for(i in fields) {
				key += i;
				var val = Reflect.field(v, i);
				switch(Type.typeof(val)) {
				case TInt:
					key += Std.string(val);
				case TBool:
					key += Std.string(val);
				case TClass(c):
					if( c == String )
						key += Std.string(val.length);
				default:
				}
			}
			Reflect.setField(v, "__serializeHash", key);
		}

		if(keyCache.exists(key)) {
			#if js
			var vt = untyped __js__("typeof")(v);
			#end
			var types = keyCache.get(key);
			for(i in types) {
				#if js
				var ci = i.obj;
				if( untyped __js__("typeof")(ci) == vt && ci == v ) {
				#else
				if(i.obj == v) {
				#end
					buf.writeString("r");
					buf.writeString(Std.string(i.idx));
					return true;
				}
			}
			types.push({ obj : v, idx : cache.length });
		} else {
			keyCache.set(key, [{ obj : v, idx : cache.length}]);
		}
		cache.push(v);
		return false;
	}

	#if flash9
	// only the instance variables

	function serializeClassFields(v,c) {
		var xml : flash.xml.XML = untyped __global__["flash.utils.describeType"](c);
		var vars = xml.factory[0].child("variable");
		for( i in 0...vars.length() ) {
			var f = vars[i].attribute("name").toString();
			if(f == "__serializeHash")
				continue;
			switch(Type.typeof(Reflect.field(v, f))) {
			case TFunction: // ignore
			default:
				if( !v.hasOwnProperty(f) )
					continue;
				serializeString(f);
				serialize(Reflect.field(v,f));
			}
		}
		buf.writeString("g");
	}
	#end

	function serializeFields(v) {
		for( f in Reflect.fields(v) ) {
			if(f == "__serializeHash")
				continue;
			switch(Type.typeof(Reflect.field(v, f))) {
			case TFunction: // ignore
			default:
			serializeString(f);
			serialize(Reflect.field(v,f));
			}
		}
		buf.writeString("g");
	}

	public function serialize( v : Dynamic ) {
		switch( Type.typeof(v) ) {
		case TNull:
			buf.writeString("n");
		case TInt:
			if( v == 0 ) {
				buf.writeString("z");
				return;
			}
			buf.writeString("i");
			buf.writeString(Std.string(v));
		case TFloat:
			if( Math.isNaN(v) )
				buf.writeString("k");
			else if( !Math.isFinite(v) )
				buf.writeString(if( v < 0 ) "m" else "p");
			else {
				buf.writeString("d");
				buf.writeString(Std.string(v));
			}
		case TBool:
			buf.writeString(if( v ) "t" else "f");
		case TClass(c):
			if( c == String ) {
				serializeString(v);
				return;
			}
			if( useCache && serializeRef(v) )
				return;
			switch( c ) {
			case cast Array:
				var ucount = 0;
				buf.writeString("a");
				#if flash9
				var v : Array<Dynamic> = v;
				#end
				var l = #if (neko || flash9 || php) v.length #else v[untyped "length"] #end;
				for( i in 0...l ) {
					if( v[i] == null )
						ucount++;
					else {
						if( ucount > 0 ) {
							if( ucount == 1 )
								buf.writeString("n");
							else {
								buf.writeString("u");
								buf.writeString(Std.string(ucount));
							}
							ucount = 0;
						}
						serialize(v[i]);
					}
				}
				if( ucount > 0 ) {
					if( ucount == 1 )
						buf.writeString("n");
					else {
						buf.writeString("u");
						buf.writeString(Std.string(ucount));
					}
				}
				buf.writeString("h");
			case cast List:
				buf.writeString("l");
				var v : List<Dynamic> = v;
				for( i in v )
					serialize(i);
				buf.writeString("h");
			case cast Date:
				var d : Date = v;
				buf.writeString("v");
				buf.writeString(d.toString());
			case cast Hash:
				buf.writeString("b");
				var v : Hash<Dynamic> = v;
				for( k in v.keys() ) {
					serializeString(k);
					serialize(v.get(k));
				}
				buf.writeString("h");
			case cast IntHash:
				buf.writeString("q");
				var v : IntHash<Dynamic> = v;
				for( k in v.keys() ) {
					buf.writeString(":");
					buf.writeString(Std.string(k));
					serialize(v.get(k));
				}
				buf.writeString("h");
			case cast haxe.io.Bytes:
				var v : haxe.io.Bytes = v;
				#if neko
				var chars = new String(base_encode(v.getData(),untyped BASE64.__s));
				#else
				var i = 0;
				var max = v.length - 2;
				var chars = "";
				var b64 = BASE64;
				while( i < max ) {
					var b1 = v.get(i++);
					var b2 = v.get(i++);
					var b3 = v.get(i++);
					chars += b64.charAt(b1 >> 2)
						+ b64.charAt(((b1 << 4) | (b2 >> 4)) & 63)
						+ b64.charAt(((b2 << 2) | (b3 >> 6)) & 63)
						+ b64.charAt(b3 & 63);
				}
				if( i == max ) {
					var b1 = v.get(i++);
					var b2 = v.get(i++);
					chars += b64.charAt(b1 >> 2)
						+ b64.charAt(((b1 << 4) | (b2 >> 4)) & 63)
						+ b64.charAt((b2 << 2) & 63);
				} else if( i == max + 1 ) {
					var b1 = v.get(i++);
					chars += b64.charAt(b1 >> 2) + b64.charAt((b1 << 4) & 63);
				}
				#end
				buf.writeString("s");
				buf.writeString(Std.string(chars.length));
				buf.writeString(":");
				buf.writeString(chars);
			default:
				cache.pop();
				buf.writeString("c");
				serializeString(Type.getClassName(c));
				cache.push(v);
				#if flash9
				serializeClassFields(v,c);
				#else
				serializeFields(v);
				#end
			}
		case TObject:
			if( useCache && serializeRef(v) )
				return;
			buf.writeString("o");
			serializeFields(v);
		case TEnum(e):
			if( useCache && serializeRef(v) )
				return;
			cache.pop();
			buf.writeString(useEnumIndex?"j":"w");
			serializeString(Type.getEnumName(e));
			#if neko
			if( useEnumIndex ) {
				buf.writeString(":");
				buf.writeString(v.index);
			} else
				serializeString(new String(v.tag));
			buf.writeString(":");
			if( v.args == null )
				buf.writeString("0");
			else {
				var l : Int = untyped __dollar__asize(v.args);
				buf.writeString(Std.string(l));
				for( i in 0...l )
					serialize(v.args[i]);
			}
			#elseif flash9
			if( useEnumIndex ) {
				buf.writeString(":");
				buf.writeString(v.index);
			} else
				serializeString(v.tag);
			buf.writeString(":");
			var pl : Array<Dynamic> = v.params;
			if( pl == null )
				buf.writeString("0");
			else {
				buf.writeString(Std.string(pl.length));
				for( p in pl )
					serialize(p);
			}
			#elseif php
			if( useEnumIndex ) {
				buf.writeString(":");
				buf.writeString(v.index);
			} else
				serializeString(v.tag);
			buf.writeString(":");
			var l : Int = untyped __call__("count", v.params);
			if( l == 0 || v.params == null)
				buf.writeString("0");
			else {
				buf.writeString(Std.string(l));
				for( i in 0...l )
					serialize(untyped __field__(v, __php__("params"), i));
			}
			#else
			if( useEnumIndex ) {
				buf.writeString(":");
				buf.writeString(v[1]);
			} else
				serializeString(v[0]);
			buf.writeString(":");
			var l = v[untyped "length"];
			buf.writeString(Std.string(l - 2));
			for( i in 2...l )
				serialize(v[i]);
			#end
			cache.push(v);
		case TFunction:
			throw "Cannot serialize function";
		default:
			throw "Cannot serialize "+Std.string(v);
		}
	}

	public function serializeException( e : Dynamic ) {
		buf.writeString("x");
		#if flash9
		if( untyped __is__(e,__global__["Error"]) ) {
			var e : flash.Error = e;
			var s = e.getStackTrace();
			if( s == null )
				serialize(e.message);
			else
				serialize(s);
			return;
		}
		#end
		serialize(e);
	}

	/**
		Serialize a single value, sending output to [out].
		@param v Value to be serialized
		@param out Output stream
	**/
	public static function run( v : Dynamic, out : Output ) : Void {
		var s = new Serializer(out);
		s.serialize(v);
	}

	#if neko
	static var base_encode = neko.Lib.load("std","base_encode",2);
	#end

}

