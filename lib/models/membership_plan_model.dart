class MembershipPlan {
  final int id;
  final String name;
  final int period;
  final String description;
  final int amount;

  MembershipPlan({
    required this.id,
    required this.name,
    required this.period,
    required this.description,
    required this.amount,
  });

  factory MembershipPlan.fromJson(Map<String, dynamic> json) => MembershipPlan(
      id: (json['membership_plan_id'] as num).toInt(),
      name: json['name'] ?? '',
      period: (json['period'] as num).toInt(),
      description: json['description'] ?? '',
      amount: (json['amount'] as num).toInt(),
    );

  Map<String, dynamic> toJson() => {
        'membership_plan_id': id,
        'name': name,
        'period': period,
        'description': description,
        'amount': amount,
      };
}
