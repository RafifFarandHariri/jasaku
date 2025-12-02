class ChatMessage {
  final String id;
  final String text;
  final bool isMe;
  final DateTime timestamp;
  final MessageType type;
  final String? senderName;
  final String? serviceId;
  final double? proposedPrice;
  final String? offerId;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isMe,
    required this.timestamp,
    this.type = MessageType.text,
    this.senderName,
    this.serviceId,
    this.proposedPrice,
    this.offerId,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      text: json['text'],
      isMe: json['isMe'],
      timestamp: DateTime.parse(json['timestamp']),
      type: MessageType.values[json['type']],
      senderName: json['senderName'],
      serviceId: json['serviceId'],
      proposedPrice: json['proposedPrice'],
      offerId: json['offerId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'isMe': isMe,
      'timestamp': timestamp.toIso8601String(),
      'type': type.index,
      'senderName': senderName,
      'serviceId': serviceId,
      'proposedPrice': proposedPrice,
      'offerId': offerId,
    };
  }
}

class PriceOffer {
  final String id;
  final String serviceId;
  final double originalPrice;
  final double proposedPrice;
  final String message;
  final OfferStatus status;
  final DateTime createdAt;
  final DateTime? respondedAt;

  PriceOffer({
    required this.id,
    required this.serviceId,
    required this.originalPrice,
    required this.proposedPrice,
    required this.message,
    this.status = OfferStatus.pending,
    required this.createdAt,
    this.respondedAt,
  });

  double get discountPercentage {
    return ((originalPrice - proposedPrice) / originalPrice * 100).roundToDouble();
  }
}

enum MessageType {
  text,
  priceOffer,
  offerAccepted,
  offerRejected,
  system,
}

enum OfferStatus {
  pending,
  accepted,
  rejected,
  expired,
}