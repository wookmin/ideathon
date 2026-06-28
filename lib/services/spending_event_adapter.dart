import '../models/card_transaction.dart';

class SpendingEvent {
  const SpendingEvent({
    required this.id,
    required this.occurredAt,
    required this.title,
    required this.amountKrw,
    required this.source,
  });

  final String id;
  final DateTime occurredAt;
  final String title;
  final double amountKrw;
  final String source;
}

SpendingEvent spendingEventFromCardTransaction(CardTransaction transaction) {
  return SpendingEvent(
    id: transaction.id,
    occurredAt: transaction.approvedAt,
    title: transaction.merchantName,
    amountKrw: transaction.amountKrw,
    source: 'card',
  );
}
