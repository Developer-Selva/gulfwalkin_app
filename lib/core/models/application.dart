class Application {
  final int id;
  final String status;
  final String appliedAt;
  final ApplicationJob? job;

  const Application({
    required this.id,
    required this.status,
    required this.appliedAt,
    this.job,
  });

  factory Application.fromJson(Map<String, dynamic> j) => Application(
        id:        j['id'] as int,
        status:    j['status'] as String,
        appliedAt: j['applied_at'] as String,
        job:       j['job'] != null ? ApplicationJob.fromJson(j['job'] as Map<String, dynamic>) : null,
      );
}

class ApplicationJob {
  final int id;
  final String title;
  final String? location;
  final String? country;
  final String? salaryRange;
  final String? image1Url;

  const ApplicationJob({
    required this.id,
    required this.title,
    this.location,
    this.country,
    this.salaryRange,
    this.image1Url,
  });

  factory ApplicationJob.fromJson(Map<String, dynamic> j) => ApplicationJob(
        id:          j['id'] as int,
        title:       j['title'] as String,
        location:    j['location'] as String?,
        country:     j['country'] as String?,
        salaryRange: j['salary_range'] as String?,
        image1Url:   j['image1_url'] as String?,
      );
}
