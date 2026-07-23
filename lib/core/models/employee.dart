int? _parseInt(dynamic v) {
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

class ProfileSection {
  final String key;
  final String label;
  final int max;
  final int earned;
  final String hint;

  const ProfileSection({
    required this.key,
    required this.label,
    required this.max,
    required this.earned,
    required this.hint,
  });

  double get percent => max > 0 ? earned / max : 0.0;

  factory ProfileSection.fromJson(Map<String, dynamic> j) => ProfileSection(
        key:    j['key'] as String,
        label:  j['label'] as String,
        max:    _parseInt(j['max']) ?? 0,
        earned: _parseInt(j['earned']) ?? 0,
        hint:   j['hint'] as String,
      );
}

class Employee {
  final int id;
  final String firstName;
  final String? lastName;
  final String email;
  final String? phone;
  final String? mobile;
  final String? gender;
  final String? maritalStatus;
  final String? dateOfBirth;
  final String? nationality;
  final String? country;
  final String? state;
  final String? district;
  final String? address;
  final String? educationQualification;
  final int? expYears;
  final int? abroadExp;
  final String? positions;
  final String? industry;
  final String? skills;
  final String? languages;
  final String? workLocation;
  final String? expectedSalary;
  final String? training;
  final String? certificates;
  final bool passport;
  final bool drivingLicence;
  final bool cvSearchable;
  final String? photoUrl;
  final String? resumeUrl;
  final int profileScore;
  final String? profileLabel;
  final List<ProfileSection> profileSections;
  final String? status;
  final bool emailVerified;

  const Employee({
    required this.id,
    required this.firstName,
    this.lastName,
    required this.email,
    this.phone,
    this.mobile,
    this.gender,
    this.maritalStatus,
    this.dateOfBirth,
    this.nationality,
    this.country,
    this.state,
    this.district,
    this.address,
    this.educationQualification,
    this.expYears,
    this.abroadExp,
    this.positions,
    this.industry,
    this.skills,
    this.languages,
    this.workLocation,
    this.expectedSalary,
    this.training,
    this.certificates,
    this.passport = false,
    this.drivingLicence = false,
    this.cvSearchable = true,
    this.photoUrl,
    this.resumeUrl,
    this.profileScore = 0,
    this.profileLabel,
    this.profileSections = const [],
    this.status,
    this.emailVerified = false,
  });

  String get fullName =>
      [firstName, lastName].whereType<String>().where((s) => s.isNotEmpty).join(' ');

  Employee copyWith({
    String? firstName,
    String? lastName,
    String? phone,
    String? mobile,
    String? gender,
    String? maritalStatus,
    String? dateOfBirth,
    String? nationality,
    String? country,
    String? state,
    String? district,
    String? address,
    String? educationQualification,
    int? expYears,
    int? abroadExp,
    String? positions,
    String? industry,
    String? skills,
    String? languages,
    String? workLocation,
    String? expectedSalary,
    String? training,
    String? certificates,
    bool? passport,
    bool? drivingLicence,
    bool? cvSearchable,
    String? photoUrl,
    String? resumeUrl,
    int? profileScore,
    String? profileLabel,
    List<ProfileSection>? profileSections,
  }) =>
      Employee(
        id:                     id,
        firstName:              firstName               ?? this.firstName,
        lastName:               lastName                ?? this.lastName,
        email:                  email,
        phone:                  phone                   ?? this.phone,
        mobile:                 mobile                  ?? this.mobile,
        gender:                 gender                  ?? this.gender,
        maritalStatus:          maritalStatus           ?? this.maritalStatus,
        dateOfBirth:            dateOfBirth             ?? this.dateOfBirth,
        nationality:            nationality             ?? this.nationality,
        country:                country                 ?? this.country,
        state:                  state                   ?? this.state,
        district:               district                ?? this.district,
        address:                address                 ?? this.address,
        educationQualification: educationQualification  ?? this.educationQualification,
        expYears:               expYears                ?? this.expYears,
        abroadExp:              abroadExp               ?? this.abroadExp,
        positions:              positions               ?? this.positions,
        industry:               industry                ?? this.industry,
        skills:                 skills                  ?? this.skills,
        languages:              languages               ?? this.languages,
        workLocation:           workLocation            ?? this.workLocation,
        expectedSalary:         expectedSalary          ?? this.expectedSalary,
        training:               training                ?? this.training,
        certificates:           certificates            ?? this.certificates,
        passport:               passport                ?? this.passport,
        drivingLicence:         drivingLicence          ?? this.drivingLicence,
        cvSearchable:           cvSearchable            ?? this.cvSearchable,
        photoUrl:               photoUrl                ?? this.photoUrl,
        resumeUrl:              resumeUrl               ?? this.resumeUrl,
        profileScore:           profileScore            ?? this.profileScore,
        profileLabel:           profileLabel            ?? this.profileLabel,
        profileSections:        profileSections         ?? this.profileSections,
        status:                 status,
        emailVerified:          emailVerified,
      );

  factory Employee.fromJson(Map<String, dynamic> j) => Employee(
        id:                     _parseInt(j['id']) ?? 0,
        firstName:              j['first_name'] as String,
        lastName:               j['last_name'] as String?,
        email:                  j['email'] as String,
        phone:                  j['phone'] as String?,
        mobile:                 j['mobile'] as String?,
        gender:                 j['gender'] as String?,
        maritalStatus:          j['marital_status'] as String?,
        dateOfBirth:            j['date_of_birth'] as String?,
        nationality:            j['nationality'] as String?,
        country:                j['country'] as String?,
        state:                  j['state'] as String?,
        district:               j['district'] as String?,
        address:                j['address'] as String?,
        educationQualification: j['education_qualification'] as String?,
        expYears:               _parseInt(j['exp_years']),
        abroadExp:              _parseInt(j['abroad_exp']),
        positions:              j['positions'] as String?,
        industry:               j['industry'] as String?,
        skills:                 j['skills'] as String?,
        languages:              j['languages'] as String?,
        workLocation:           j['work_location'] as String?,
        expectedSalary:         j['expected_salary'] as String?,
        training:               j['training'] as String?,
        certificates:           j['certificates'] as String?,
        passport:               j['passport'] as bool? ?? false,
        drivingLicence:         j['driving_licence'] as bool? ?? false,
        cvSearchable:           j['cv_searchable'] as bool? ?? true,
        photoUrl:               j['photo_url'] as String?,
        resumeUrl:              j['resume_url'] as String?,
        profileScore:           _parseInt(j['profile_score']) ?? 0,
        profileLabel:           j['profile_label'] as String?,
        profileSections: (j['profile_sections'] as List<dynamic>? ?? [])
            .map((e) => ProfileSection.fromJson(e as Map<String, dynamic>))
            .toList(),
        status:                 j['status'] as String?,
        emailVerified:          j['email_verified'] as bool? ?? false,
      );
}
