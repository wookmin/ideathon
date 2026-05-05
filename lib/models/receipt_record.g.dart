part of 'receipt_record.dart';

class ReceiptRecordAdapter extends TypeAdapter<ReceiptRecord> {
  @override
  final int typeId = 0;

  @override
  ReceiptRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ReceiptRecord(
      id: fields[0] as String,
      date: fields[1] as DateTime,
      country: fields[2] as String,
      countryCode: fields[3] as String,
      currency: fields[4] as String,
      originalAmount: fields[5] as double,
      krwAmount: fields[6] as double,
      exchangeRate: fields[7] as double,
      rawOcrText: fields[8] as String,
      items: (fields[9] as List).cast<ReceiptItem>(),
      verdict: fields[10] as String,
      tipPct: fields[11] as double,
      tipKrw: fields[12] as double,
      memo: fields[13] as String,
      imagePath: fields[14] as String?,
      analysis: fields[15] as String,
      city: fields[16] as String,
    );
  }

  @override
  void write(BinaryWriter writer, ReceiptRecord obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.country)
      ..writeByte(3)
      ..write(obj.countryCode)
      ..writeByte(4)
      ..write(obj.currency)
      ..writeByte(5)
      ..write(obj.originalAmount)
      ..writeByte(6)
      ..write(obj.krwAmount)
      ..writeByte(7)
      ..write(obj.exchangeRate)
      ..writeByte(8)
      ..write(obj.rawOcrText)
      ..writeByte(9)
      ..write(obj.items)
      ..writeByte(10)
      ..write(obj.verdict)
      ..writeByte(11)
      ..write(obj.tipPct)
      ..writeByte(12)
      ..write(obj.tipKrw)
      ..writeByte(13)
      ..write(obj.memo)
      ..writeByte(14)
      ..write(obj.imagePath)
      ..writeByte(15)
      ..write(obj.analysis)
      ..writeByte(16)
      ..write(obj.city);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReceiptRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ReceiptItemAdapter extends TypeAdapter<ReceiptItem> {
  @override
  final int typeId = 1;

  @override
  ReceiptItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ReceiptItem(
      name: fields[0] as String,
      paid: fields[1] as String,
      avg: fields[2] as String,
      status: fields[3] as String,
    );
  }

  @override
  void write(BinaryWriter writer, ReceiptItem obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.paid)
      ..writeByte(2)
      ..write(obj.avg)
      ..writeByte(3)
      ..write(obj.status);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReceiptItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
