class ProfileModel {
  final String name;
  final String email;
  final String? profileUrl;
  final String phone;
  final String? emergencyContact;
  final String? emergencyPhone;
  final String? joiningDate;
  final String? membershipPlanId;
  final String? feeStatus;
  final double? amountDue;
  final String? feeDueDate;
  final String? height;
  final String? targetWeight;
  final String? bloodGroup;
  final String? dob;
  final String? lastUpdatedOn;

  ProfileModel({
    required this.name,
    required this.email,
    this.profileUrl,
    required this.phone,
    this.emergencyContact,
    this.emergencyPhone,
    this.joiningDate,
    this.membershipPlanId,
    this.feeStatus,
    this.amountDue,
    this.feeDueDate,
    this.height,
    this.targetWeight,
    this.bloodGroup,
    this.dob,
    this.lastUpdatedOn,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      profileUrl: json['profile_url'],
      phone: json['phone'] ?? '',
      emergencyContact: json['emg_contact'],
      emergencyPhone: json['emg_contact_no'],
      joiningDate: json['joining_date'],
      membershipPlanId: json['membership_plan_id']?.toString(),
      feeStatus: json['fee_status'],
      amountDue: (json['amount_due'] is num) ? (json['amount_due'] as num).toDouble() : null,
      feeDueDate: json['fee_due_date'],
      height: json['height']?.toString(),
      targetWeight: json['target_weight']?.toString(),
      bloodGroup: json['blood_group'],
      dob: json['dob'],
      lastUpdatedOn: json['last_updated_on'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'profile_url': profileUrl,
      'phone': phone,
      'emg_contact': emergencyContact,
      'emg_contact_no': emergencyPhone,
      'joining_date': joiningDate,
      'membership_plan_id': membershipPlanId,
      'fee_status': feeStatus,
      'amount_due': amountDue,
      'fee_due_date': feeDueDate,
      'height': height,
      'target_weight': targetWeight,
      'blood_group': bloodGroup,
      'dob': dob,
      'last_updated_on': lastUpdatedOn,
    };
  }
}
