class Advertisement {
  final int id;
  final String? company;
  final String? offerTitle;
  final String? imageUrl;
  final String? expiryDate;

  const Advertisement({
    required this.id,
    this.company,
    this.offerTitle,
    this.imageUrl,
    this.expiryDate,
  });

  factory Advertisement.fromJson(Map<String, dynamic> j) => Advertisement(
        id:          j['id'] as int,
        company:     j['company'] as String?,
        offerTitle:  j['offer_title'] as String?,
        imageUrl:    j['image_url'] as String?,
        expiryDate:  j['expiry_date'] as String?,
      );
}
