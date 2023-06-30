package vp817;

import haxe.io.FPHelper;
import haxe.Int32;
import haxe.Int64;
import haxe.io.Error;
import haxe.io.Bytes;

var EndOfStream:Error = Error.Overflow;
var VarIntTooBig:Error = Error.Overflow;

class BinaryStream {
	public var buffer:Bytes;
	public var writingPos:Int;
	public var readingPos:Int;
	public var isBigEndian:Bool;

	static var BitShiftMapTable:Map<Int, Map<Int, Array<Int>>> = [
		16 => [0 => [8, 0], 1 => [0, 8]],
		24 => [0 => [16, 8, 0], 1 => [0, 8, 16]],
		32 => [0 => [24, 16, 8, 0], 1 => [0, 8, 16, 24]]
	];

	static var LimitsTable:Map<Int, Map<Int, Array<Int>>> = [
		8 => [0 => [0x00, 0xff], 1 => [-(0x80), 0x7f]],
		16 => [0 => [0x00, 0xffff], 1 => [-(0x8000), 0x7fff]],
		24 => [0 => [0x00, 0x00ffffff], 1 => [-(0x800000), 0x7fffff]],
		32 => [0 => [0x00, 0xffffffff], 1 => [-(0x80000000), 0x7fffffff]]
	];

	static public function signInt(bitSize:Int, value:Int) {
		if (bitSize == 8) {
			return (value + (1 << 7)) % (1 << 8) - (1 << 7);
		}
		return value < (1 << (bitSize - 1)) ? value : value - (1 << bitSize);
	}

	static public function limit(value:Int, bitSize:Int, signed:Bool):Int {
		var retValue = value;
		var limitTable:Map<Int, Array<Int>> = BinaryStream.LimitsTable[bitSize];
		if (!signed) {
			if (retValue < limitTable[0][0]) {
				retValue = limitTable[0][0];
			} else if (retValue > limitTable[0][1]) {
				retValue &= limitTable[0][1];
			}
		} else {
			retValue = BinaryStream.signInt(bitSize, retValue);
			if (retValue < limitTable[1][0]) {
				retValue = limitTable[1][0];
			} else if (retValue > limitTable[1][1]) {
				retValue &= limitTable[1][1];
			}
		}
		return retValue;
	}

	static public function writeValueIntoBytes(bytes:Bytes, bitSize:Int, bigEndian:Bool, value:Int):Void {
		var shiftMap:Map<Int, Array<Int>> = BinaryStream.BitShiftMapTable[bitSize];
		var byteArray:Array<Int> = bigEndian ? shiftMap[0] : shiftMap[1];
		var i:Int = 0;
		for (v in byteArray) {
			bytes.set(i, value >> v);
			++i;
		}
	}

	static public function readValueFromBytes(bytes:Bytes, bitSize:Int, bigEndian:Bool):Int {
		var shiftMap:Map<Int, Array<Int>> = BinaryStream.BitShiftMapTable[bitSize];
		var byteArray:Array<Int> = bigEndian ? shiftMap[0] : shiftMap[1];
		var value:Int = 0;
		var i:Int = 0;
		for (v in byteArray) {
			value |= bytes.get(i) << v;
			++i;
		}
		return value;
	}

	public function new(buffer:Bytes, writingPos:Int, readingPos:Int, bigEndain:Bool):Void {
		this.buffer = buffer;
		this.writingPos = writingPos;
		this.readingPos = readingPos;
		this.isBigEndian = bigEndain;
	}

	static public function allocate(size:Int, bigEndain:Bool):BinaryStream {
		return new BinaryStream(Bytes.alloc(size), 0, 0, bigEndain);
	}

	public function write(value:Bytes):Void {
		if (this.eos()) throw EndOfStream;

		var bytesSize:Int = value.length;
		this.buffer.blit(this.writingPos, value, 0, bytesSize);
		this.writingPos += bytesSize;
	}

	public function read(size:Int):Bytes {
		this.readingPos += size;
		return this.buffer.sub(this.readingPos - size, this.readingPos);
	}

	public function eos():Bool {
		return (this.readingPos > this.buffer.length) ? true : false;
	}

	public function rewind():Void {
		this.writingPos = 0;
		this.readingPos = 0;
	}

	public function reset():Void {
		this.buffer = Bytes.alloc(0);
		this.writingPos = 0;
		this.readingPos = 0;
	}

	public function swapEndainness():Void {
		this.isBigEndian = this.isBigEndian == true ? false : true;
	}

	public function writeInt8(value:Int, signed:Bool):Void {
		var temp:Bytes = Bytes.alloc(1);
		value = BinaryStream.limit(value, 8, signed);
		temp.set(0, value);
		this.write(temp);
	}

	public function writeBool(value:Bool):Void {
		this.writeInt8(value == true ? 1 : 0, false);
	}

	public function writeInt16(value:Int, signed:Bool):Void {
		var temp:Bytes = Bytes.alloc(2);
		value = BinaryStream.limit(value, 16, signed);
		BinaryStream.writeValueIntoBytes(temp, 16, this.isBigEndian, value);
		this.write(temp);
	}

	public function writeInt32(value:Int32, signed:Bool):Void {
		var temp:Bytes = Bytes.alloc(4);
		value = BinaryStream.limit(value, 32, signed);
		BinaryStream.writeValueIntoBytes(temp, 32, this.isBigEndian, value);
		this.write(temp);
	}

	public function writeInt64(value:Int64, signed:Bool):Void {
		this.writeInt32(value.high, signed);
		this.writeInt32(value.low, signed);
	}

	public function writeFloat(value:Float):Void {
		this.writeInt32(FPHelper.floatToI32(value), true);
	}

	public function writeDouble(value:Float):Void {
		var idouble:Int64 = FPHelper.doubleToI64(value);
		this.writeInt32(idouble.high, true);
		this.writeInt32(idouble.low, true);
	}

	public function writeVarInt(value:Int32):Void {
		for (i in 0...5) {
			var toWrite = value & 0x7f;
			value >>>= 7;
			if (value != 0x00) {
				this.writeInt8(toWrite | 0x80, false);
			} else {
				this.writeInt8(toWrite, false);
				break;
			}
		}
	}

	public function writeVarLong(value:Int64):Void {
		this.writeVarInt(value.high);
		this.writeVarInt(value.low);
	}

	public function writeZigZag32(value:Int32):Void {
		this.writeVarInt((value << 1) ^ (value >> 31));
	}

	public function writeZigZag64(value:Int64):Void {
		this.writeZigZag32(value.high);
		this.writeZigZag32(value.low);
	}

	public function readInt8(signed:Bool):Int {
		var value:Int = this.read(1).get(0);
		value = BinaryStream.limit(value, 8, signed);
		return value;
	}

	public function readBool():Bool {
		return this.readInt8(false) == 1 ? true : false;
	}

	public function readInt16(signed:Bool):Int {
		var value:Int = BinaryStream.readValueFromBytes(this.read(2), 16, this.isBigEndian);
		value = BinaryStream.limit(value, 16, signed);
		return value;
	}

	public function readInt32(signed:Bool):Int32 {
		var value:Int32 = BinaryStream.readValueFromBytes(this.read(4), 32, this.isBigEndian);
		value = BinaryStream.limit(value, 32, signed);
		return value;
	}

	public function readInt64():Int64 {
		return Int64.make(this.readInt32(false), this.readInt32(false));
	}

	public function readFloat():Float {
		return FPHelper.i32ToFloat(this.readInt32(true));
	}

	public function readDouble():Float {
		var value:Int64 = Int64.make(this.readInt32(false), this.readInt32(false));
		return FPHelper.i64ToDouble(value.low, value.high);
	}

	public function readVarInt():Int32 {
		var value:Int32 = 0;
		var i:Int = 0;
		while (i < 35) {
			var toRead:Int = this.readInt8(false);
			value |= (toRead & 0x7f) << i;
			if ((toRead & 0x80) == 0x00) {
				return value;
			}

			i += 7;
		}

		throw VarIntTooBig;
	}

	public function readVarLong():Int64 {
		return Int64.make(this.readVarInt(), this.readVarInt());
	}

	public function readZigZag32():Int32 {
		var value:Int32 = this.readVarInt();
		return (value >> 1) ^ -(value & 1);
	}

	public function readZigZag64():Int64 {
		return Int64.make(this.readZigZag32(), this.readZigZag32());
	}

	public function readRemaining() {
		return this.read(this.buffer.length - this.readingPos);
	}
}
