import 'package:flutter/material.dart';
import '../../models/student_interval.dart';
import '../../services/fees_service.dart';
import '../../services/session_service.dart';

class FeesScreen extends StatefulWidget {
  const FeesScreen({super.key});

  @override
  State<FeesScreen> createState() => _FeesScreenState();
}

class _FeesScreenState extends State<FeesScreen> {
  final _service = FeesService();
  List<StudentInterval> _intervals = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final studentId = await SessionService.getStudentId();
      if (studentId == null) throw Exception('Not logged in');
      final data = await _service.getStudentIntervals(studentId);
      if (!mounted) return;
      setState(() {
        _intervals = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'paid':
        return Colors.green;
      case 'partial':
        return Colors.orange;
      default:
        return Colors.redAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Summary
    final totalFees =
        _intervals.fold<double>(0, (p, e) => p + e.totalFees);
    final totalPaid =
        _intervals.fold<double>(0, (p, e) => p + e.paidAmount);
    final totalDue =
        _intervals.fold<double>(0, (p, e) => p + e.dueAmount);

    return Scaffold(
      appBar: AppBar(title: const Text('Fees')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: Column(
                    children: [
                      // Summary card
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.all(12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF4A90E2), Color(0xFF357ABD)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Total Fees',
                                style: TextStyle(color: Colors.white70)),
                            Text(
                              '₹${totalFees.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _miniStat(
                                      'Paid', totalPaid, Colors.greenAccent),
                                ),
                                Expanded(
                                  child: _miniStat(
                                      'Due', totalDue, Colors.redAccent),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: _intervals.isEmpty
                            ? ListView(
                                children: const [
                                  SizedBox(height: 100),
                                  Center(child: Text('No fee records')),
                                ],
                              )
                            : ListView.builder(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                itemCount: _intervals.length,
                                itemBuilder: (_, i) {
                                  final iv = _intervals[i];
                                  return Card(
                                    margin:
                                        const EdgeInsets.only(bottom: 10),
                                    child: ExpansionTile(
                                      leading: CircleAvatar(
                                        backgroundColor: _statusColor(
                                            iv.status),
                                        child: Text(
                                          '${iv.intervalNumber}',
                                          style: const TextStyle(
                                              color: Colors.white),
                                        ),
                                      ),
                                      title: Text(
                                          'Interval ${iv.intervalNumber}'),
                                      subtitle: Text(
                                        '${_date(iv.startDate)} → ${_date(iv.endDate)}',
                                        style:
                                            const TextStyle(fontSize: 12),
                                      ),
                                      trailing: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '₹${iv.totalFees.toStringAsFixed(0)}',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                          Text(
                                            iv.status.toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 11,
                                              color:
                                                  _statusColor(iv.status),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                              16, 0, 16, 16),
                                          child: Column(
                                            children: [
                                              _row('Total Fees',
                                                  '₹${iv.totalFees.toStringAsFixed(2)}'),
                                              _row('Paid',
                                                  '₹${iv.paidAmount.toStringAsFixed(2)}'),
                                              _row('Due',
                                                  '₹${iv.dueAmount.toStringAsFixed(2)}'),
                                              if (iv.lastPaymentDate !=
                                                  null)
                                                _row(
                                                    'Last Payment',
                                                    _date(
                                                        iv.lastPaymentDate!)),
                                              if (iv.paymentMode != null)
                                                _row('Payment Mode',
                                                    iv.paymentMode!),
                                              if (iv.utr != null)
                                                _row('UTR', iv.utr!),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _miniStat(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70)),
        Text(
          '₹${value.toStringAsFixed(2)}',
          style: TextStyle(
              color: color, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value,
              style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  String _date(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}