import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/bus_stop.dart';
import '../../services/session_service.dart';
import '../../theme/app_colors.dart';

class StopsScreen extends StatefulWidget {
  const StopsScreen({super.key});

  @override
  State<StopsScreen> createState() => _StopsScreenState();
}

class _StopsScreenState extends State<StopsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  List<BusStop> _morning = [];
  List<BusStop> _evening = [];
  bool _loading = true;
  String? _error;
  String? _routeName;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  /// Top padding that clears the floating top bar.
  double _topPad(BuildContext context) =>
      MediaQuery.of(context).padding.top + kToolbarHeight - 56;

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final student = await SessionService.getStudent();
      if (student == null) throw Exception('Not logged in');

      final routeId = student.routeId;
      if (routeId == null || routeId.isEmpty) {
        throw Exception(
            'No route assigned. Please contact your institution.');
      }

      String? routeName;
      try {
        final r = await Supabase.instance.client
            .from('bus_routes')
            .select('name')
            .eq('id', routeId)
            .maybeSingle();
        routeName = r?['name'] as String?;
      } catch (_) {}

      final res = await Supabase.instance.client
          .from('bus_stops')
          .select()
          .eq('route_id', routeId)
          .order('sequence', ascending: true);

      final all = (res as List)
          .map((e) => BusStop.fromMap(e as Map<String, dynamic>))
          .toList();

      final morning = all
          .where((s) => s.direction.trim().toLowerCase() == 'morning')
          .toList();
      final evening = all
          .where((s) => s.direction.trim().toLowerCase() == 'evening')
          .toList();

      if (!mounted) return;
      setState(() {
        _morning = morning;
        _evening = evening;
        _routeName = routeName ?? student.routes;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPad = _topPad(context);

    return Column(
      children: [
        // ---- Route name strip ----
        if (_routeName != null && _routeName!.isNotEmpty)
          Padding(
            padding: EdgeInsets.fromLTRB(16, topPad, 16, 8),
            child: Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.route_rounded,
                        size: 16, color: AppColors.primary),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Your Route',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _routeName!,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          SizedBox(height: topPad),

        // ---- Tab bar (white pill) ----
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: TabBar(
                controller: _tab,
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.textSecondary,
                indicator: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelStyle: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 14),
                unselectedLabelStyle:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                tabs: const [
                  Tab(text: 'Morning'),
                  Tab(text: 'Evening'),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 8),

        // ---- Tab content ----
        Expanded(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary))
              : _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ),
                    )
                  : TabBarView(
                      controller: _tab,
                      children: [
                        _list(_morning, 'morning'),
                        _list(_evening, 'evening'),
                      ],
                    ),
        ),
      ],
    );
  }

  Widget _list(List<BusStop> stops, String direction) {
    if (stops.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        color: AppColors.primary,
        child: ListView(
          children: [
            const SizedBox(height: 120),
            Center(
              child: Text(
                'No $direction stops',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        itemCount: stops.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final s = stops[i];
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                child: Text(
                  '${s.sequence}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                s.stopName,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: (s.landmark != null && s.landmark!.isNotEmpty)
                  ? Text(s.landmark!)
                  : null,
            ),
          );
        },
      ),
    );
  }
}