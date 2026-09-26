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

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final student = await SessionService.getStudent();

      // 🔍 DEBUG
      debugPrint('===== STOPS DEBUG =====');
      debugPrint('student           = $student');
      debugPrint('student.id        = ${student?.id}');
      debugPrint('student.routes    = ${student?.routes}');
      debugPrint('student.routeId   = ${student?.routeId}');
      debugPrint('=======================');

      if (student == null) throw Exception('Not logged in');

      final routeId = student.routeId;
      if (routeId == null || routeId.isEmpty) {
        throw Exception(
            'No route assigned. Please contact your institution.');
      }

      // Fetch route name
      String? routeName;
      try {
        final r = await Supabase.instance.client
            .from('bus_routes')
            .select('name')
            .eq('id', routeId)
            .maybeSingle();
        routeName = r?['name'] as String?;
        debugPrint('🔍 routeName from DB = $routeName');
      } catch (e) {
        debugPrint('❌ route name fetch error: $e');
      }

      // Fetch stops for THIS student's route
      final res = await Supabase.instance.client
          .from('bus_stops')
          .select()
          .eq('route_id', routeId)
          .order('sequence', ascending: true);

      debugPrint('🔍 stops rows returned = ${(res as List).length}');

      final all = (res)
          .map((e) => BusStop.fromMap(e))
          .toList();

      final morning = all
          .where((s) => s.direction.trim().toLowerCase() == 'morning')
          .toList();
      final evening = all
          .where((s) => s.direction.trim().toLowerCase() == 'evening')
          .toList();

      debugPrint('🔍 morning stops = ${morning.length}');
      debugPrint('🔍 evening stops = ${evening.length}');

      if (!mounted) return;
      setState(() {
        _morning = morning;
        _evening = evening;
        _routeName = routeName ?? student.routes;
        _loading = false;
      });
    } catch (e) {
      debugPrint('❌ stops error: $e');
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: Text(
          (_routeName == null || _routeName!.isEmpty)
              ? 'Bus Stops'
              : 'Stops • $_routeName',
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tab,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Morning'),
            Tab(text: 'Evening'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
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
    );
  }

  Widget _list(List<BusStop> stops, String direction) {
    if (stops.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        color: AppColors.primary,
        child: ListView(
          children: [
            const SizedBox(height: 150),
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
        padding: const EdgeInsets.all(12),
        itemCount: stops.length,
        separatorBuilder: (_, _) => const SizedBox(height: 6),
        itemBuilder: (_, i) {
          final s = stops[i];
          return Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                child: Text(
                  '${s.sequence}',
                  style: TextStyle(
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
