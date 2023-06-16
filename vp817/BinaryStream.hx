package vp817;

import haxe.io.FPHelper;
import haxe.Int32;
import haxe.Int64;
import haxe.io.Error;
import haxe.io.BytesBuffer;
import haxe.io.Bytes;

var EndOfStreamReached:Error = Error.Overflow;
var VarIntTooBig:Error = Error.Overflow;

class BinaryStream {
	public var buffer:BytesBuffer;
	public var readingPos:Int;
	public var isBigEndian:Bool;

	public function new(buffer:BytesBuffer, readingPos:Int, bigEndain:Bool):Void {
		this.buffer = buffer;
		this.readingPos = readingPos;
		this.isBigEndian = bigEndain;
	}

	static public function allocate(bigEndain:Bool):BinaryStream {
		return new BinaryStream(new BytesBuffer(), 0, bigEndain);
	}

	public function getBytes():Bytes {
		return this.buffer.getBytes();
	}

	public function write(value:Bytes):Void {
		if (value.length < 0 || this.buffer.length < 0 || this.eos()) {
			throw EndOfStreamReached;
		}

		this.buffer.add(value);
	}

	public function readBit(offset:Int):Int {
		this.readingPos += offset;
		return this.getBytes().get(this.readingPos - offset);
	}

	public function eos():Bool {
		return (this.readingPos > this.buffer.length) ? true : false;
	}

	public function rewind():Void {
		this.readingPos = 0;
	}

	public function swapEndainness():Void {
		this.isBigEndian = this.isBigEndian == true ? false : true;
	}

	public function writeInt8(value:Int, signed:Bool):Void {
		var temp:Bytes = Bytes.alloc(1);
		temp.set(0, value & (signed == true ? 0x7f : 0xff));
		this.write(temp);
	}

	public function writeBool(value:Bool):Void {
		this.writeInt8(value == true ? 1 : 0, false);
	}

	public function writeInt16(value:Int, signed:Bool):Void {
		var temp:Bytes = Bytes.alloc(2);
		var v:Int = signed == true ? 0x7fff : 0xffff;
		if (this.isBigEndian) {
			temp.set(0, (value & v) >> 8);
			temp.set(1, value & v);
		} else {
			temp.set(0, value & v);
			temp.set(1, (value & v) >> 8);
		}
		this.write(temp);
	}

	public function writeInt32(value:Int32):Void {
		var temp:Bytes = Bytes.alloc(4);
		if (this.isBigEndian) {
			temp.set(0, value >> 24);
			temp.set(1, value >> 16);
			temp.set(2, value >> 8);
			temp.set(3, value);
		} else {
			temp.set(0, value);
			temp.set(1, value >> 8);
			temp.set(2, value >> 16);
			temp.set(3, value >> 24);
		}
		this.write(temp);
	}

	public function writeInt64(value:Int64) {
		this.writeInt32(value.high);
		this.writeInt32(value.low);
	}

	public function writeFloat(value:Float) {
		this.writeInt32(FPHelper.floatToI32(value));
	}

	public function writeDouble(value:Float) {
		var val: Int64 = FPHelper.doubleToI64(value);
		this.writeInt32(val.high);
		this.writeInt32(val.low);
	}

	public function writeVarInt(value:Int):Void {
		value &= 0xffffffff;

		for (i in 0...5) {
			var toWrite = value & 0x7f;
			value >>>= 7;
			if (value != 0x00) {
				this.writeInt8(toWrite | 0x80 false);
			} else {
				this.writeInt8(toWrite, false);
				break;
			}
		}
	}

	public function writeZigZag32(value:Int):Void {
		this.writeVarInt((value << 1) ^ (value >> 31));
	}

	public function readInt8(signed:Bool):Int {
		return this.readBit(1) & (signed == true ? 0x7f : 0xff);
	}

	public function readBool():Bool {
		return this.readInt8(false) == 1 ? true : false;
	}

	public function readInt16(signed:Bool):Int {
		var value:Int = 0;
		var v:Int = signed == true ? 0x7fff : 0xffff;
		if (this.isBigEndian) {
			value |= (this.readBit(1) & v) << 8;
			value |= this.readBit(1) & v;
		} else {
			value |= this.readBit(1) & v;
			value |= (this.readBit(1) & v) << 8;
		}
		return value;
	}

	public function readInt32():Int32 {
		var value:Int32 = 0;
		if (this.isBigEndian) {
			value |= this.readBit(1) << 24;
			value |= this.readBit(1) << 16;
			value |= this.readBit(1) << 8;
			value |= this.readBit(1);
		} else {
			value |= this.readBit(1);
			value |= this.readBit(1) << 8;
			value |= this.readBit(1) << 16;
			value |= this.readBit(1) << 24;
		}
		return value;
	}

	public function readInt64():Int64 {
		return Int64.make(this.readInt32(), this.readInt32());
	}

	public function readFloat():Float {
		var value:Int = 0;
		value |= this.readBit(1) << 24;
		value |= this.readBit(1) << 16;
		value |= this.readBit(1) << 8;
		value |= this.readBit(1);
		return FPHelper.i32ToFloat(value);
	}

	public function readDouble():Float {
		var value:Int64 = Int64.make(this.readInt32(), this.readInt32());
		return FPHelper.i64ToDouble(value.low, value.high);
	}

	public function readVarInt():Int {
		var value:Int = 0;
		var i:Int = 0;
		while (i < 35) {
			var toRead:Int = this.readInt8(false);
			value |= (toRead & 0x7f) << i;
			if ((toRead & 0x80) == 0x00) {
				return value;
			}

			i += 7;
		} // 0 7 14 21 28

		throw VarIntTooBig;
	}

	public function readZigZag32():Int {
		var value:Int = this.readVarInt();
		return (value >> 1) ^ -(value & 1);
	}
}
