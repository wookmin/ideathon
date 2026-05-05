part of 'receipt_analysis.dart';

class ReceiptAnalysisAdapter extends TypeAdapter<ReceiptAnalysis> {
  @override
  final int typeId = 2;

  @override
  ReceiptAnalysis read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ReceiptAnalysis(
      currency: fields[0] as String,
      countryCode: fields[1] as String,
      country: fields[2] as String,
      city: fields[3] as String,
      totalAmount: fields[4] as double,
      hasServiceCharge: fields[5] as bool,
      verdict: fields[6] as String,
      verdictLabel: fields[7] as String,
      verdictEmoji: fields[8] as String,
      premiumPct: fields[9] as double,
      touristPremium: fields[10] as String,
      summary: fields[11] as String,
      items: (fields[12] as List).cast<ReceiptAnalysisItem>(),
      analysis: fields[13] as String,
      tipSuggestedPct: fields[14] as double,
      tipCulture: fields[15] as String,
      savingTips: (fields[16] as List).cast<String>(),
      failureReason: null,
      failureDetail: null,
    );
  }

  @override
  void write(BinaryWriter writer, ReceiptAnalysis obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)
      ..write(obj.currency)
      ..writeByte(1)
      ..write(obj.countryCode)
      ..writeByte(2)
      ..write(obj.country)
      ..writeByte(3)
      ..write(obj.city)
      ..writeByte(4)
      ..write(obj.totalAmount)
      ..writeByte(5)
      ..write(obj.hasServiceCharge)
      ..writeByte(6)
      ..write(obj.verdict)
      ..writeByte(7)
      ..write(obj.verdictLabel)
      ..writeByte(8)
      ..write(obj.verdictEmoji)
      ..writeByte(9)
      ..write(obj.premiumPct)
      ..writeByte(10)
      ..write(obj.touristPremium)
      ..writeByte(11)
      ..write(obj.summary)
      ..writeByte(12)
      ..write(obj.items)
      ..writeByte(13)
      ..write(obj.analysis)
      ..writeByte(14)
      ..write(obj.tipSuggestedPct)
      ..writeByte(15)
      ..write(obj.tipCulture)
      ..writeByte(16)
      ..write(obj.savingTips);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReceiptAnalysisAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ReceiptAnalysisItemAdapter extends TypeAdapter<ReceiptAnalysisItem> {
  @override
  final int typeId = 3;

  @override
  ReceiptAnalysisItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ReceiptAnalysisItem(
      name: fields[0] as String,
      paid: fields[1] as String,
      avg: fields[2] as String,
      status: fields[3] as String,
    );
  }

  @override
  void write(BinaryWriter writer, ReceiptAnalysisItem obj) {
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
      other is ReceiptAnalysisItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
