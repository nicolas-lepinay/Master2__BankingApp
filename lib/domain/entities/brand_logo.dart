import 'package:equatable/equatable.dart';

class BrandLogo extends Equatable {
  final String brandId;
  final String domain;
  final String name;
  final String icon;
  final bool? claimed;
  final double? score;
  final double? qualityScore;
  final bool? verified;

  const BrandLogo({
    required this.brandId,
    required this.domain,
    required this.name,
    required this.icon,
    this.claimed,
    this.score,
    this.qualityScore,
    this.verified,
  });

  factory BrandLogo.fromJson(Map<String, dynamic> json) {
    return BrandLogo(
      brandId: json['brandId'] as String? ?? '',
      domain: json['domain'] as String? ?? '',
      name: json['name'] as String? ?? '',
      icon: json['icon'] as String? ?? '',
      claimed: json['claimed'] as bool?,
      score: (json['_score'] as num?)?.toDouble(),
      qualityScore: (json['qualityScore'] as num?)?.toDouble(),
      verified: json['verified'] as bool?,
    );
  }

  BrandLogo copyWith({
    String? brandId,
    String? domain,
    String? name,
    String? icon,
    bool? claimed,
    double? score,
    double? qualityScore,
    bool? verified,
  }) {
    return BrandLogo(
      brandId: brandId ?? this.brandId,
      domain: domain ?? this.domain,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      claimed: claimed ?? this.claimed,
      score: score ?? this.score,
      qualityScore: qualityScore ?? this.qualityScore,
      verified: verified ?? this.verified,
    );
  }

  @override
  List<Object?> get props => [
        brandId,
        domain,
        name,
        icon,
        claimed,
        score,
        qualityScore,
        verified,
      ];

  @override
  bool get stringify => true;
}