// JSON from MySQL/PHP can arrive as int, double, or String depending on the
// driver (mysqlnd vs libmysqlclient) and how values were stored. Never use
// `as int?` directly — use this helper everywhere an integer field is parsed.
int? _parseInt(dynamic v) {
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

class JobPosition {
  final String category;
  final int? vacancies;
  final String? salaryRange;
  final String? workingHours;

  const JobPosition({
    required this.category,
    this.vacancies,
    this.salaryRange,
    this.workingHours,
  });

  factory JobPosition.fromJson(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      return JobPosition(
        category:     raw['category'] as String? ?? 'Position',
        vacancies:    _parseInt(raw['vacancies']),
        salaryRange:  raw['salary_range'] as String?,
        workingHours: raw['working_hours'] as String?,
      );
    }
    return JobPosition(category: raw.toString());
  }
}

class Job {
  final int id;
  final String title;
  final Map<String, String>? titleTranslations;
  final String category;
  final String? subCategory;
  final String location;
  final String country;
  final String? salaryRange;
  final int vacancies;
  final String? deadline;
  final String? image1Url;
  final String? description;
  final Map<String, String>? descriptionTranslations;
  final String? requirements;
  final List<JobPosition>? positions;
  final String? industry;
  final String? company;
  final String? workingHours;
  final String? interviewInfo;
  final String? contactPhone;
  final String? contactEmail;
  final bool isBookmarked;
  final bool hasApplied;
  final String createdAt;
  final String? status;
  final JobEmployer? employer;

  const Job({
    required this.id,
    required this.title,
    this.titleTranslations,
    required this.category,
    this.subCategory,
    required this.location,
    required this.country,
    this.salaryRange,
    required this.vacancies,
    this.deadline,
    this.image1Url,
    this.description,
    this.descriptionTranslations,
    this.requirements,
    this.positions,
    this.industry,
    this.company,
    this.workingHours,
    this.interviewInfo,
    this.contactPhone,
    this.contactEmail,
    this.isBookmarked = false,
    this.hasApplied = false,
    required this.createdAt,
    this.status,
    this.employer,
  });

  /// Returns the translated title for [locale] if available, falls back to English.
  String localizedTitle(String locale) {
    if (locale != 'en') {
      final t = titleTranslations?[locale];
      if (t != null && t.isNotEmpty) return t;
    }
    return title;
  }

  /// Returns the translated description for [locale] if available, falls back to English.
  String? localizedDescription(String locale) {
    if (locale != 'en') {
      final t = descriptionTranslations?[locale];
      if (t != null && t.isNotEmpty) return t;
    }
    return description;
  }

  static Map<String, String>? _parseTranslations(dynamic raw) {
    if (raw is! Map) return null;
    return raw.map((k, v) => MapEntry(k.toString(), v?.toString() ?? ''));
  }

  factory Job.fromJson(Map<String, dynamic> j) => Job(
        id:                     _parseInt(j['id']) ?? 0,
        title:                  j['title'] as String,
        titleTranslations:      _parseTranslations(j['title_translations']),
        category:               j['category'] as String,
        subCategory:            j['sub_category'] is List
                                    ? (j['sub_category'] as List).map((e) => e.toString()).join(', ')
                                    : j['sub_category'] as String?,
        location:               j['location'] as String,
        country:                j['country'] as String,
        salaryRange:            j['salary_range'] as String?,
        vacancies:              _parseInt(j['vacancies']) ?? 1,
        deadline:               j['deadline'] as String?,
        image1Url:              j['image1_url'] as String?,
        description:            j['description'] as String?,
        descriptionTranslations: _parseTranslations(j['description_translations']),
        requirements:           j['requirements'] as String?,
        positions:              (j['positions'] as List?)?.map((e) => JobPosition.fromJson(e)).toList(),
        industry:               j['industry'] as String?,
        company:                j['company'] as String?,
        workingHours:           j['working_hours'] as String?,
        interviewInfo:          j['interview_info'] as String?,
        contactPhone:           j['contact_phone'] as String?,
        contactEmail:           j['contact_email'] as String?,
        isBookmarked:           j['is_bookmarked'] as bool? ?? false,
        hasApplied:             j['has_applied'] as bool? ?? false,
        createdAt:              j['created_at'] as String,
        status:                 j['status'] as String?,
        employer:               j['employer'] != null ? JobEmployer.fromJson(j['employer'] as Map<String, dynamic>) : null,
      );

  Map<String, dynamic> toJson() => {
        'id':                   id,
        'title':                title,
        'title_translations':   titleTranslations,
        'category':             category,
        'sub_category':         subCategory,
        'location':             location,
        'country':              country,
        'salary_range':         salaryRange,
        'vacancies':            vacancies,
        'deadline':             deadline,
        'image1_url':           image1Url,
        'industry':             industry,
        'company':              company,
        'is_bookmarked':        isBookmarked,
        'has_applied':          hasApplied,
        'created_at':           createdAt,
        'status':               status,
        'employer':             employer == null ? null : {
          'id':           employer!.id,
          'company_name': employer!.companyName,
          'logo_url':     employer!.logoUrl,
        },
      };

  Job copyWith({bool? isBookmarked, bool? hasApplied, List<JobPosition>? positions, String? status}) => Job(
        id:                      id,
        title:                   title,
        titleTranslations:       titleTranslations,
        category:                category,
        subCategory:             subCategory,
        location:                location,
        country:                 country,
        salaryRange:             salaryRange,
        vacancies:               vacancies,
        deadline:                deadline,
        image1Url:               image1Url,
        description:             description,
        descriptionTranslations: descriptionTranslations,
        requirements:            requirements,
        positions:               positions ?? this.positions,
        industry:                industry,
        company:                 company,
        workingHours:            workingHours,
        interviewInfo:           interviewInfo,
        contactPhone:            contactPhone,
        contactEmail:            contactEmail,
        isBookmarked:            isBookmarked ?? this.isBookmarked,
        hasApplied:              hasApplied   ?? this.hasApplied,
        createdAt:               createdAt,
        status:                  status ?? this.status,
        employer:                employer,
      );
}

class JobEmployer {
  final int id;
  final String companyName;
  final String? logoUrl;
  final String? about;
  final String? country;
  final String? website;

  const JobEmployer({
    required this.id,
    required this.companyName,
    this.logoUrl,
    this.about,
    this.country,
    this.website,
  });

  factory JobEmployer.fromJson(Map<String, dynamic> j) => JobEmployer(
        id:          _parseInt(j['id']) ?? 0,
        companyName: j['company_name'] as String,
        logoUrl:     j['logo_url'] as String?,
        about:       j['about'] as String?,
        country:     j['country'] as String?,
        website:     j['website'] as String?,
      );
}
