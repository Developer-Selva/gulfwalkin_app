int? _parseInt(dynamic v) {
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

class TopCompany {
  final int id;
  final String companyName;
  final String? logoUrl;
  final String? country;
  final int activeJobs;

  const TopCompany({
    required this.id,
    required this.companyName,
    this.logoUrl,
    this.country,
    required this.activeJobs,
  });

  factory TopCompany.fromJson(Map<String, dynamic> j) => TopCompany(
        id:          _parseInt(j['id']) ?? 0,
        companyName: j['company_name'] as String,
        logoUrl:     j['logo_url'] as String?,
        country:     j['country'] as String?,
        activeJobs:  _parseInt(j['active_jobs']) ?? 0,
      );
}
