// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expense.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ExpenseAdapter extends TypeAdapter<Expense> {
  @override
  final int typeId = 0;

  @override
  Expense read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Expense(
      id: fields[0] as String,
      title: fields[1] as String,
      amount: fields[2] as double,
      date: fields[3] as DateTime,
      category: fields[4] as String,
      currency: fields[5] as String,
      isRecurring: fields[6] == null ? false : fields[6] as bool,
      recurrenceInterval: fields[7] == null ? 'None' : fields[7] as String,
      nextRecurrenceDate: fields[8] as DateTime?,
      account: fields[9] == null ? 'Cash' : fields[9] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Expense obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.date)
      ..writeByte(4)
      ..write(obj.category)
      ..writeByte(5)
      ..write(obj.currency)
      ..writeByte(6)
      ..write(obj.isRecurring)
      ..writeByte(7)
      ..write(obj.recurrenceInterval)
      ..writeByte(8)
      ..write(obj.nextRecurrenceDate)
      ..writeByte(9)
      ..write(obj.account);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpenseAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
