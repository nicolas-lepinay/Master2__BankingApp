import 'package:equatable/equatable.dart';

class FollowedTransaction extends Equatable {
  final int id;
  final int transactionId;
  final DateTime followedDate;

  const FollowedTransaction({
    required this.id,
    required this.transactionId,
    required this.followedDate,
  });

  FollowedTransaction copyWith({
    int? id,
    int? transactionId,
    DateTime? followedDate,
  }) {
    return FollowedTransaction(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      followedDate: followedDate ?? this.followedDate,
    );
  }

  @override
  List<Object?> get props => [id, transactionId, followedDate];

  @override
  bool get stringify => true;
}