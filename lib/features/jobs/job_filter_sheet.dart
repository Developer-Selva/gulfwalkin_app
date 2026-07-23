import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/models/category.dart';
import '../../shared/theme/app_colors.dart';
import 'job_list_provider.dart';

class JobFilterSheet extends ConsumerStatefulWidget {
  const JobFilterSheet({super.key});

  @override
  ConsumerState<JobFilterSheet> createState() => _JobFilterSheetState();
}

class _JobFilterSheetState extends ConsumerState<JobFilterSheet> {
  late String? _category;
  late String? _state;
  late String  _sort;

  @override
  void initState() {
    super.initState();
    final f = ref.read(jobFilterProvider);
    _category = f.category;
    _state    = f.state;
    _sort     = f.sort;
  }

  int get _activeCount =>
      (_category != null ? 1 : 0) + (_state != null ? 1 : 0) + (_sort != 'latest' ? 1 : 0);

  void _apply() {
    ref.read(jobFilterProvider.notifier).state = ref
        .read(jobFilterProvider)
        .copyWith(
          search:        ref.read(jobFilterProvider).search,
          category:      _category,
          state:         _state,
          sort:          _sort,
          clearCategory: _category == null,
          clearState:    _state == null,
        );
    Navigator.pop(context);
  }

  void _reset() => setState(() {
        _category = null;
        _state    = null;
        _sort     = 'latest';
      });

  @override
  Widget build(BuildContext context) {
    final cats   = ref.watch(_categoriesProvider);
    final states = ref.watch(_statesProvider);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: DraggableScrollableSheet(
        initialChildSize: 0.72,
        minChildSize:     0.5,
        maxChildSize:     0.92,
        expand: false,
        builder: (_, ctrl) => Container(
          color: AppColors.surface,
          child: Column(
            children: [
              // ── Handle ──────────────────────────────────────────────────────
              const SizedBox(height: 10),
              Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),

              // ── Header ──────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    const Text('Filters',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(width: 8),
                    if (_activeCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('$_activeCount',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                      ),
                    const Spacer(),
                    TextButton(
                      onPressed: _reset,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        padding: EdgeInsets.zero,
                      ),
                      child: const Text('Reset all'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // ── Content ──────────────────────────────────────────────────────
              Expanded(
                child: ListView(
                  controller: ctrl,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                  children: [
                    const _SectionLabel(label: 'Sort By', icon: Icons.sort),
                    const SizedBox(height: 10),
                    _SortToggle(
                      selected: _sort,
                      onChanged: (v) => setState(() => _sort = v),
                    ),
                    const SizedBox(height: 24),

                    const _SectionLabel(label: 'Category', icon: Icons.category_outlined),
                    const SizedBox(height: 10),
                    cats.when(
                      loading: () => const _SkeletonChips(),
                      error:   (_, __) => const SizedBox.shrink(),
                      data:    (list) => _ChipWrap(
                        items:    list.map((c) => c.name).toList(),
                        selected: _category,
                        onTap:    (v) => setState(() => _category = _category == v ? null : v),
                      ),
                    ),
                    const SizedBox(height: 24),

                    const _SectionLabel(label: 'Location', icon: Icons.location_on_outlined),
                    const SizedBox(height: 10),
                    states.when(
                      loading: () => const _SkeletonChips(),
                      error:   (_, __) => const SizedBox.shrink(),
                      data:    (list) => _ChipWrap(
                        items:    list,
                        selected: _state,
                        onTap:    (v) => setState(() => _state = _state == v ? null : v),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),

              // ── Apply button ─────────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ElevatedButton(
                        onPressed: _apply,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor:     Colors.transparent,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(
                          _activeCount > 0
                              ? 'Apply $_activeCount filter${_activeCount > 1 ? 's' : ''}'
                              : 'Apply',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Widgets ──────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final IconData icon;
  const _SectionLabel({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary)),
        ],
      );
}

class _SortToggle extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  const _SortToggle({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _SortOption(
          label: 'Latest',
          icon: Icons.schedule,
          value: 'latest',
          selected: selected == 'latest',
          onTap: () => onChanged('latest'),
        ),
        const SizedBox(width: 12),
        _SortOption(
          label: 'Highest Salary',
          icon: Icons.trending_up,
          value: 'salary',
          selected: selected == 'salary',
          onTap: () => onChanged('salary'),
        ),
      ],
    );
  }
}

class _SortOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  const _SortOption({
    required this.label,
    required this.icon,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.cardBorder,
              width: selected ? 0 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  color: selected ? Colors.white : AppColors.textSecondary, size: 20),
              const SizedBox(height: 4),
              Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : AppColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChipWrap extends StatelessWidget {
  final List<String> items;
  final String? selected;
  final ValueChanged<String> onTap;

  const _ChipWrap({required this.items, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: items.map((item) {
          final isSelected = selected == item;
          return GestureDetector(
            onTap: () => onTap(item),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.cardBorder,
                ),
              ),
              child: Text(
                item,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
          );
        }).toList(),
      );
}

class _SkeletonChips extends StatelessWidget {
  const _SkeletonChips();

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 8, runSpacing: 8,
        children: List.generate(
          6,
          (_) => Container(
            width: 80, height: 36,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      );
}

// ── Local data providers ─────────────────────────────────────────────────────

final _categoriesProvider = FutureProvider.autoDispose<List<Category>>((ref) async {
  final res = await ref.read(dioProvider).get('/categories');
  return (res.data['data'] as List)
      .map((e) => Category.fromJson(e as Map<String, dynamic>))
      .toList();
});

final _statesProvider = FutureProvider.autoDispose<List<String>>((ref) async {
  final res = await ref.read(dioProvider).get('/states');
  return (res.data['data'] as List).map((e) => e['name'] as String).toList();
});
