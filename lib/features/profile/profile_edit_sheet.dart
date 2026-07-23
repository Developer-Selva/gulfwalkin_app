import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/error_handler.dart';
import '../../shared/theme/app_colors.dart';
import 'profile_provider.dart';

enum ProfileEditSection { basic, career, location, preferences, additional }

// Common languages for Gulf-region workers
const _kCommonLanguages = [
  'English', 'Arabic', 'Hindi', 'Malayalam', 'Tamil', 'Telugu', 'Urdu',
  'Bengali', 'Kannada', 'Marathi', 'Punjabi', 'Tagalog', 'Sinhala',
  'French', 'German', 'Chinese', 'Korean', 'Japanese',
];

class ProfileEditSheet extends ConsumerStatefulWidget {
  final ProfileEditSection section;
  const ProfileEditSheet({super.key, required this.section});

  @override
  ConsumerState<ProfileEditSheet> createState() => _ProfileEditSheetState();
}

class _ProfileEditSheetState extends ConsumerState<ProfileEditSheet> {
  final _formKey = GlobalKey<FormState>();
  bool _saving   = false;
  String? _error;

  // ── Basic ──
  late TextEditingController _firstName;
  late TextEditingController _lastName;
  late TextEditingController _phone;
  late TextEditingController _mobile;
  String? _gender;

  // ── Career ──
  late TextEditingController _expYears;
  late TextEditingController _abroadExp;
  late TextEditingController _positions;
  late TextEditingController _industry;
  late List<String>          _skillTags;
  late TextEditingController _expectedSalary;

  // ── Location ──
  late TextEditingController _country;
  late TextEditingController _state;
  late TextEditingController _district;
  late TextEditingController _address;

  // ── Preferences ──
  late TextEditingController _workLocation;
  late List<String>          _languageTags;
  late bool _passport;
  late bool _drivingLicence;
  late bool _cvSearchable;

  // ── Additional ──
  late TextEditingController _dateOfBirth;
  late TextEditingController _educationQualification;
  late TextEditingController _nationality;
  late TextEditingController _training;
  late TextEditingController _certificates;
  String? _maritalStatus;

  static List<String> _parseTags(String? s) =>
      s == null || s.isEmpty
          ? []
          : s.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

  @override
  void initState() {
    super.initState();
    final p = ref.read(profileProvider).valueOrNull;

    _firstName              = TextEditingController(text: p?.firstName);
    _lastName               = TextEditingController(text: p?.lastName);
    _phone                  = TextEditingController(text: p?.phone);
    _mobile                 = TextEditingController(text: p?.mobile);
    _gender                 = p?.gender;

    _expYears               = TextEditingController(text: p?.expYears?.toString());
    _abroadExp              = TextEditingController(text: p?.abroadExp?.toString());
    _positions              = TextEditingController(text: p?.positions);
    _industry               = TextEditingController(text: p?.industry);
    _skillTags              = _parseTags(p?.skills);
    _expectedSalary         = TextEditingController(text: p?.expectedSalary);

    _country                = TextEditingController(text: p?.country);
    _state                  = TextEditingController(text: p?.state);
    _district               = TextEditingController(text: p?.district);
    _address                = TextEditingController(text: p?.address);

    _workLocation           = TextEditingController(text: p?.workLocation);
    _languageTags           = _parseTags(p?.languages);
    _passport               = p?.passport ?? false;
    _drivingLicence         = p?.drivingLicence ?? false;
    _cvSearchable           = p?.cvSearchable ?? true;

    _dateOfBirth            = TextEditingController(text: p?.dateOfBirth);
    _educationQualification = TextEditingController(text: p?.educationQualification);
    _nationality            = TextEditingController(text: p?.nationality);
    _training               = TextEditingController(text: p?.training);
    _certificates           = TextEditingController(text: p?.certificates);
    _maritalStatus          = p?.maritalStatus;
  }

  @override
  void dispose() {
    for (final c in [
      _firstName, _lastName, _phone, _mobile,
      _expYears, _abroadExp, _positions, _industry, _expectedSalary,
      _country, _state, _district, _address,
      _workLocation,
      _dateOfBirth, _educationQualification, _nationality, _training, _certificates,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _saving = true; _error = null; });

    try {
      await ref.read(profileProvider.notifier).saveProfile(_buildPayload());
      if (mounted) {
        Navigator.pop(context);
      }
    } on DioException catch (e) {
      setState(() => _error = handleDioError(e));
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Map<String, dynamic> _buildPayload() {
    switch (widget.section) {
      case ProfileEditSection.basic:
        return {
          'first_name': _firstName.text.trim(),
          'last_name':  _lastName.text.trim(),
          'phone':      _phone.text.trim(),
          'mobile':     _mobile.text.trim(),
          if (_gender != null) 'gender': _gender,
        };
      case ProfileEditSection.career:
        return {
          if (_expYears.text.isNotEmpty)
            'exp_years': int.tryParse(_expYears.text),
          if (_abroadExp.text.isNotEmpty)
            'abroad_exp': int.tryParse(_abroadExp.text),
          'positions':       _positions.text.trim(),
          'industry':        _industry.text.trim(),
          'skills':          _skillTags.join(', '),
          'expected_salary': _expectedSalary.text.trim(),
        };
      case ProfileEditSection.location:
        return {
          'country':  _country.text.trim(),
          'state':    _state.text.trim(),
          'district': _district.text.trim(),
          'address':  _address.text.trim(),
        };
      case ProfileEditSection.preferences:
        return {
          'work_location':   _workLocation.text.trim(),
          'languages':       _languageTags.join(', '),
          'passport':        _passport,
          'driving_licence': _drivingLicence,
          'cv_searchable':   _cvSearchable,
        };
      case ProfileEditSection.additional:
        return {
          'date_of_birth':            _dateOfBirth.text.trim(),
          'education_qualification':  _educationQualification.text.trim(),
          'nationality':              _nationality.text.trim(),
          'training':                 _training.text.trim(),
          'certificates':             _certificates.text.trim(),
          if (_maritalStatus != null) 'marital_status': _maritalStatus,
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollCtrl) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text(_title, style: const TextStyle(fontWeight: FontWeight.w700)),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              TextButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Save',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, color: AppColors.primary)),
              ),
            ],
          ),
          body: Form(
            key: _formKey,
            child: ListView(
              controller: scrollCtrl,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.error, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(_error!,
                              style: const TextStyle(color: AppColors.error, fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                ],
                ..._buildFields(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String get _title {
    switch (widget.section) {
      case ProfileEditSection.basic:        return 'Basic Information';
      case ProfileEditSection.career:       return 'Career Profile';
      case ProfileEditSection.location:     return 'Location';
      case ProfileEditSection.preferences:  return 'Work Preferences';
      case ProfileEditSection.additional:   return 'Additional Details';
    }
  }

  List<Widget> _buildFields() {
    switch (widget.section) {
      case ProfileEditSection.basic:
        return [
          _field(_firstName, 'First Name', required: true),
          _field(_lastName,  'Last Name'),
          _field(_phone,  'Phone', keyboard: TextInputType.phone),
          _field(_mobile, 'Mobile', keyboard: TextInputType.phone),
          _dropdown(
            label:   'Gender',
            value:   _gender,
            items:   const ['Male', 'Female', 'Other'],
            onChanged: (v) => setState(() => _gender = v),
          ),
        ];
      case ProfileEditSection.career:
        return [
          _numField(_expYears,  'Years of Experience'),
          _numField(_abroadExp, 'Years of Abroad Experience'),
          _field(_positions, 'Job Positions / Roles',
              hint: 'e.g. Driver, Cleaner, Mason'),
          _field(_industry,  'Industry',
              hint: 'e.g. Construction, Hospitality'),
          _TagInputField(
            label: 'Skills',
            hint: 'Type a skill and tap Add',
            tags: _skillTags,
            onChanged: (v) => setState(() => _skillTags = v),
          ),
          _field(_expectedSalary, 'Expected Salary',
              hint: 'e.g. 1500 AED / month'),
        ];
      case ProfileEditSection.location:
        return [
          _field(_country,  'Country'),
          _field(_state,    'State / Emirate'),
          _field(_district, 'District / City'),
          _field(_address,  'Full Address', maxLines: 3),
        ];
      case ProfileEditSection.preferences:
        return [
          _field(_workLocation, 'Preferred Work Location',
              hint: 'e.g. Dubai, Abu Dhabi, Qatar'),
          _TagInputField(
            label: 'Languages Known',
            hint: 'Type a language and tap Add',
            tags: _languageTags,
            onChanged: (v) => setState(() => _languageTags = v),
            suggestions: _kCommonLanguages,
          ),
          _toggle('Have Passport',       _passport,
              (v) => setState(() => _passport = v)),
          _toggle('Have Driving Licence', _drivingLicence,
              (v) => setState(() => _drivingLicence = v)),
          _toggle('CV Searchable by Employers', _cvSearchable,
              (v) => setState(() => _cvSearchable = v)),
        ];
      case ProfileEditSection.additional:
        return [
          _datePicker('Date of Birth', _dateOfBirth),
          _field(_educationQualification, 'Education Qualification',
              hint: 'e.g. B.Sc, Diploma, 12th Pass'),
          _dropdown(
            label:   'Marital Status',
            value:   _maritalStatus,
            items:   const ['Single', 'Married', 'Other'],
            onChanged: (v) => setState(() => _maritalStatus = v),
          ),
          _field(_nationality, 'Nationality', hint: 'e.g. Indian, Pakistani'),
          _field(_training,    'Training / Courses', maxLines: 3),
          _field(_certificates,'Certificates', maxLines: 3),
        ];
    }
  }

  // ── Field builders ────────────────────────────────────────────────────────

  Widget _field(
    TextEditingController ctrl,
    String label, {
    String? hint,
    bool required = false,
    int maxLines = 1,
    TextInputType keyboard = TextInputType.text,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: TextFormField(
          controller: ctrl,
          keyboardType: keyboard,
          maxLines: maxLines,
          decoration: InputDecoration(labelText: label, hintText: hint),
          validator: required
              ? (v) => v!.trim().isEmpty ? 'Required' : null
              : null,
        ),
      );

  Widget _numField(TextEditingController ctrl, String label) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: TextFormField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(labelText: label, hintText: '0'),
          validator: (v) {
            if (v == null || v.isEmpty) return null;
            final n = int.tryParse(v);
            if (n == null || n < 0 || n > 50) return '0–50';
            return null;
          },
        ),
      );

  Widget _dropdown({
    required String label,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: DropdownButtonFormField<String>(
          initialValue: value,
          decoration: InputDecoration(labelText: label),
          items: items
              .map((i) => DropdownMenuItem(value: i, child: Text(i)))
              .toList(),
          onChanged: onChanged,
        ),
      );

  Widget _toggle(String label, bool value, void Function(bool) onChanged) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppColors.primary,
        ),
      );

  Widget _datePicker(String label, TextEditingController ctrl) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: TextFormField(
          controller: ctrl,
          readOnly: true,
          decoration: InputDecoration(
            labelText: label,
            hintText: 'YYYY-MM-DD',
            suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
          ),
          onTap: () async {
            final initial = DateTime.tryParse(ctrl.text) ?? DateTime(1990);
            final picked = await showDatePicker(
              context: context,
              initialDate: initial,
              firstDate: DateTime(1950),
              lastDate: DateTime.now().subtract(const Duration(days: 365 * 15)),
            );
            if (picked != null) {
              ctrl.text =
                  '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
            }
          },
        ),
      );
}

// ─── Tag chip input ───────────────────────────────────────────────────────────

class _TagInputField extends StatefulWidget {
  final String label;
  final String? hint;
  final List<String> tags;
  final ValueChanged<List<String>> onChanged;
  final List<String>? suggestions;

  const _TagInputField({
    required this.label,
    required this.tags,
    required this.onChanged,
    this.hint,
    this.suggestions,
  });

  @override
  State<_TagInputField> createState() => _TagInputFieldState();
}

class _TagInputFieldState extends State<_TagInputField> {
  final _ctrl = TextEditingController();
  late List<String> _tags;

  @override
  void initState() {
    super.initState();
    _tags = List.from(widget.tags);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _add(String raw) {
    // Allow pasting comma-separated values
    final parts = raw.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty);
    bool changed = false;
    for (final part in parts) {
      if (!_tags.contains(part)) {
        _tags.add(part);
        changed = true;
      }
    }
    if (changed) {
      _ctrl.clear();
      setState(() {});
      widget.onChanged(List.from(_tags));
    } else {
      _ctrl.clear();
    }
  }

  void _remove(String tag) {
    setState(() => _tags.remove(tag));
    widget.onChanged(List.from(_tags));
  }

  void _toggleSuggestion(String tag) {
    if (_tags.contains(tag)) {
      _remove(tag);
    } else {
      setState(() => _tags.add(tag));
      widget.onChanged(List.from(_tags));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section label
          Text(widget.label,
              style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),

          // Existing tag chips
          if (_tags.isNotEmpty) ...[
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _tags.map((tag) => Chip(
                label: Text(tag,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.primary)),
                deleteIcon: const Icon(Icons.close, size: 14, color: AppColors.primary),
                onDeleted: () => _remove(tag),
                backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                side: BorderSide(color: AppColors.primary.withValues(alpha: 0.25)),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                labelPadding: const EdgeInsets.only(left: 4),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              )).toList(),
            ),
            const SizedBox(height: 8),
          ],

          // Input + Add button
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: _ctrl,
                  decoration: InputDecoration(
                    hintText: widget.hint ?? 'Type and tap Add',
                    isDense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  onFieldSubmitted: _add,
                  textInputAction: TextInputAction.done,
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () => _add(_ctrl.text),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 46),
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  textStyle: const TextStyle(fontWeight: FontWeight.w600),
                ),
                child: const Text('Add'),
              ),
            ],
          ),

          // Suggestion chips (for languages)
          if (widget.suggestions != null) ...[
            const SizedBox(height: 10),
            const Text('Quick select:',
                style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textHint,
                    fontStyle: FontStyle.italic)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: widget.suggestions!.map((s) {
                final selected = _tags.contains(s);
                return GestureDetector(
                  onTap: () => _toggleSuggestion(s),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primary.withValues(alpha: 0.12)
                          : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected
                            ? AppColors.primary
                            : AppColors.cardBorder,
                      ),
                    ),
                    child: Text(s,
                        style: TextStyle(
                            fontSize: 12,
                            color: selected
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.w400)),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
