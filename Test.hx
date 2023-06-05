import haxe.Int64;
import vp817.BinaryStream;

class Main {
	static public function main():Void {
		var stream:BinaryStream = BinaryStream.allocate();

		untyped stream.writeUnsignedByte(0x04);
		untyped stream.writeUnsignedByte(0x05);
		untyped stream.writeUnsignedByte(0x06);
		untyped stream.writeUnsignedByte(0x07);
		untyped stream.writeUnsignedByte(0x08);
		untyped stream.writeUnsignedByte(0x0a);
		untyped stream.writeUnsignedByte(0x0b);
		untyped stream.writeUnsignedShortBe(19132);
		untyped stream.writeUnsignedLongBe64(Int64.fromFloat(13870178403718));
		untyped stream.writeBool(true);
		untyped stream.writeBool(false);
		untyped stream.writeUnsignedIntBe(19328173);
		trace(stream.readUnsignedByte());
		trace(stream.readUnsignedByte());
		trace(stream.readUnsignedByte());
		trace(stream.readUnsignedByte());
		trace(stream.readUnsignedByte());
		trace(stream.readUnsignedByte());
		trace(stream.readUnsignedByte());
		trace(stream.readUnsignedShortBe());
		trace(stream.readUnsignedLongBe64());
		trace(stream.readBool());
		trace(stream.readBool());
		trace(stream.readUnsignedIntBe());
		untyped stream.writeByte(0x04);
		untyped stream.writeByte(0x05);
		untyped stream.writeByte(0x06);
		untyped stream.writeByte(0x07);
		untyped stream.writeByte(0x08);
		untyped stream.writeByte(0x0a);
		untyped stream.writeByte(0x0b);
		untyped stream.writeShortBe(19132);
		untyped stream.writeLongBe64(Int64.fromFloat(13870178403718));
		untyped stream.writeIntBe(19328173);
		trace(stream.readByte());
		trace(stream.readByte());
		trace(stream.readByte());
		trace(stream.readByte());
		trace(stream.readByte());
		trace(stream.readByte());
		trace(stream.readByte());
		trace(stream.readShortBe());
		trace(stream.readLongBe64());
		trace(stream.readIntBe());
		untyped stream.writeUnsignedShortLe(19132);
		untyped stream.writeShortLe(19132);
		untyped stream.writeUnsignedLongLe64(Int64.fromFloat(13870178403718));
		untyped stream.writeLongLe64(Int64.fromFloat(138701784037185));
		untyped stream.writeUnsignedIntLe(9138138);
		untyped stream.writeIntLe(1038158);
		trace(stream.readUnsignedShortLe());
		trace(stream.readShortLe());
		trace(stream.readUnsignedLongLe64());
		trace(stream.readLongLe64());
		trace(stream.readUnsignedIntLe());
		trace(stream.readIntLe());
		stream.writeFloat(10.5);
		trace(stream.readFloat());
		stream.writeDouble(10.44444444444);
		trace(stream.readDouble());
	}
}
