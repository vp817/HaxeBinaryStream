package vp817;

import haxe.io.FPHelper;
import haxe.Int32;
import haxe.Int64;
import haxe.io.Error;
import haxe.io.BytesBuffer;
import haxe.io.Bytes;

var EndOfStreamReached:Error = Error.Overflow;

class BinaryStream {
	public var buffer:BytesBuffer;
	public var offset:Int;

	public function new(buffer:BytesBuffer, offset:Int):Void {
		this.buffer = buffer;
		this.offset = offset;
	}

	static public function allocate():BinaryStream {
		return new BinaryStream(new BytesBuffer(), 0);
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

	public function readBit(size:Int):Int {
		this.offset += size;
		return this.getBytes().get(this.offset - size);
	}

	public function eos():Bool {
		return (this.offset > this.buffer.length) ? true : false;
	}

	public function rewind():Void {
		this.offset = 0;
	}

	public function writeUnsignedByte(value:UInt):Void {
		var temp:Bytes = Bytes.alloc(1);
		temp.set(0, value);
		this.write(temp);
	}

	public function writeByte(value:Int):Void {
		var temp:Bytes = Bytes.alloc(1);
		temp.set(0, value & 0x7f);
		this.write(temp);
	}

	public function writeBool(value:Bool):Void {
		this.writeUnsignedByte(value == true ? 1 : 0);
	}

	public function writeUnsignedShortBe(value:UInt):Void {
		var temp:Bytes = Bytes.alloc(2);
		temp.set(0, (value & 0xffff) >> 8);
		temp.set(1, value & 0xffff);
		this.write(temp);
	}

	public function writeShortBe(value:Int):Void {
		var temp:Bytes = Bytes.alloc(2);
		temp.set(0, (value & 0x7fff) >> 8);
		temp.set(1, value & 0x7fff);
		this.write(temp);
	}

	public function writeUnsignedShortLe(value:UInt):Void {
		var temp:Bytes = Bytes.alloc(2);
		temp.set(0, value & 0xffff);
		temp.set(1, (value & 0xffff) >> 8);
		this.write(temp);
	}

	public function writeShortLe(value:Int):Void {
		var temp:Bytes = Bytes.alloc(2);
		temp.set(0, value & 0x7fff);
		temp.set(1, (value & 0x7fff) >> 8);
		this.write(temp);
	}

	public function writeUnsignedLongBe32(value:Int32):Void {
		var temp:Bytes = Bytes.alloc(4);
		temp.set(0, value >> 24);
		temp.set(1, value >> 16);
		temp.set(2, value >> 8);
		temp.set(3, value);
		this.write(temp);
	}

	public function writeUnsignedLongBe64(value:Int64) {
		this.writeUnsignedLongBe32(value.high);
		this.writeUnsignedLongBe32(value.low);
	}

	public function writeLongBe32(value:Int32):Void {
		this.writeUnsignedLongBe32(value);
	}

	public function writeLongBe64(value:Int64):Void {
		this.writeUnsignedLongBe64(value);
	}

	public function writeUnsignedLongLe32(value:Int32):Void {
		var temp:Bytes = Bytes.alloc(4);
		temp.set(0, value);
		temp.set(1, value >> 8);
		temp.set(2, value >> 16);
		temp.set(3, value >> 24);
		this.write(temp);
	}

	public function writeUnsignedLongLe64(value:Int64) {
		this.writeUnsignedLongLe32(value.high);
		this.writeUnsignedLongLe32(value.low);
	}

	public function writeLongLe32(value:Int32):Void {
		this.writeUnsignedLongLe32(value);
	}

	public function writeLongLe64(value:Int64):Void {
		this.writeUnsignedLongLe64(value);
	}

	public function writeUnsignedIntBe(value:Int32):Void {
		this.writeUnsignedLongBe32(value & 0xffffffff);
	}

	public function writeIntBe(value:Int32):Void {
		this.writeLongBe32(value & 0xffffffff);
	}

	public function writeUnsignedIntLe(value:Int32):Void {
		this.writeUnsignedLongLe32(value & 0xffffffff);
	}

	public function writeIntLe(value:Int32):Void {
		this.writeLongLe32(value & 0xffffffff);
	}

	public function writeFloat(value:Float) {
		this.writeUnsignedIntBe(FPHelper.floatToI32(value));
	}

	public function writeDouble(value:Float) {
		var val: Int64 = FPHelper.doubleToI64(value);
		this.writeUnsignedIntBe(val.high);
		this.writeUnsignedIntBe(val.low);
	}

	public function readUnsignedByte():UInt {
		return this.readBit(1);
	}

	public function readByte():Int {
		return this.readBit(1) & 0x7f;
	}

	public function readBool():Bool {
		return this.readUnsignedByte() == 1 ? true : false;
	}

	public function readUnsignedShortBe():UInt {
		var value:UInt = 0;
		value |= (this.readBit(1) & 0xffff) << 8;
		value |= this.readBit(1) & 0xffff;
		return value;
	}

	public function readShortBe():Int {
		var value:Int = 0;
		value |= (this.readBit(1) & 0x7fff) << 8;
		value |= this.readBit(1) & 0x7fff;
		return value;
	}

	public function readUnsignedShortLe():UInt {
		var value:UInt = 0;
		value |= this.readBit(1) & 0xffff;
		value |= (this.readBit(1) & 0xffff) << 8;
		return value;
	}

	public function readShortLe():Int {
		var value:Int = 0;
		value |= this.readBit(1) & 0x7fff;
		value |= (this.readBit(1) & 0x7fff) << 8;
		return value;
	}

	public function readUnsignedLongBe32():Int32 {
		var value:Int32 = 0;
		value |= this.readBit(1) << 24;
		value |= this.readBit(1) << 16;
		value |= this.readBit(1) << 8;
		value |= this.readBit(1);
		return value;
	}

	public function readLongBe32():Int64 {
		return this.readUnsignedLongBe32();
	}

	public function readUnsignedLongBe64():Int64 {
		return Int64.make(this.readUnsignedLongBe32(), this.readUnsignedLongBe32());
	}

	public function readLongBe64():Int64 {
		return this.readUnsignedLongBe64();
	}

	public function readUnsignedLongLe32():Int32 {
		var value:Int32 = 0;
		value |= this.readBit(1);
		value |= this.readBit(1) << 8;
		value |= this.readBit(1) << 16;
		value |= this.readBit(1) << 24;
		return value;
	}

	public function readLongLe32():Int64 {
		return this.readUnsignedLongLe32();
	}

	public function readUnsignedLongLe64():Int64 {
		return Int64.make(this.readUnsignedLongLe32(), this.readUnsignedLongLe32());
	}

	public function readLongLe64():Int64 {
		return this.readUnsignedLongLe64();
	}

	public function readUnsignedIntBe():Int32 {
		return this.readUnsignedLongBe32();
	}

	public function readIntBe():Int32 {
		return this.readUnsignedIntBe();
	}

	public function readUnsignedIntLe():Int32 {
		return this.readUnsignedLongLe32();
	}

	public function readIntLe():Int32 {
		return this.readUnsignedIntLe();
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
		var value:Int64 = Int64.make(this.readUnsignedIntBe(), this.readUnsignedIntBe());
		return FPHelper.i64ToDouble(value.low, value.high);
	}
}
