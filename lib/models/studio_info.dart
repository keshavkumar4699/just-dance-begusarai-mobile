class StudioInfo {
  final String studioName;
  final String directorName;
  final String mobile;
  final String address;
  final String? instagram;
  final String? youtube;
  final String ownerFooter;

  const StudioInfo({
    required this.studioName,
    required this.directorName,
    required this.mobile,
    required this.address,
    this.instagram,
    this.youtube,
    required this.ownerFooter,
  });

  Map<String, dynamic> toMap() {
    return {
      'studioName': studioName,
      'directorName': directorName,
      'mobile': mobile,
      'address': address,
      'instagram': instagram,
      'youtube': youtube,
      'ownerFooter': ownerFooter,
    };
  }

  factory StudioInfo.fromMap(Map<String, dynamic> map) {
    return StudioInfo(
      studioName: map['studioName'] as String? ?? 'Studio Crow',
      directorName: map['directorName'] as String? ?? 'Rahul Raja Sir',
      mobile: map['mobile'] as String? ?? '+919999999999',
      address: map['address'] as String? ?? 'Begusarai, Bihar',
      instagram: map['instagram'] as String?,
      youtube: map['youtube'] as String?,
      ownerFooter: map['ownerFooter'] as String? ?? '– Rahul Raja Sir 🕺',
    );
  }

  static StudioInfo get defaultInfo => const StudioInfo(
        studioName: 'Studio Crow',
        directorName: 'Rahul Raja Sir',
        mobile: '+919999999999',
        address: 'Begusarai, Bihar',
        instagram: '@studiocrow',
        youtube: 'StudioCrowOfficial',
        ownerFooter: '– Rahul Raja Sir 🕺',
      );
}
