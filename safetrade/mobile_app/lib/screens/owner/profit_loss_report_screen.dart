import 'package:flutter/material.dart';
import '../../services/profit_loss_service.dart';
import '../../l10n/tr.dart';
import '../../widgets/language_switcher.dart';

class ProfitLossReportScreen extends StatefulWidget {
  final String storeId;
  final String storeName;
  const ProfitLossReportScreen({super.key, required this.storeId, required this.storeName});

  @override
  State<ProfitLossReportScreen> createState() => _ProfitLossReportScreenState();
}

class _ProfitLossReportScreenState extends State<ProfitLossReportScreen> {
  final _service = ProfitLossService();
  String _period = "daily";
  Map<String, dynamic>? _report;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final report = await _service.getReport(widget.storeId, period: _period);
    setState(() { _report = report; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final r = _report;
    final isLoss = r?["is_loss"] == true;

    return Scaffold(
      appBar: AppBar(
        title: Text("${tr(context, "profit_loss_report_title")} — ${widget.storeName}"),
        actions: const [LanguageSwitcher(), SizedBox(width: 8)],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SegmentedButton<String>(
              segments: [
                ButtonSegment(value: "daily", label: Text(tr(context, "period_daily"))),
                ButtonSegment(value: "weekly", label: Text(tr(context, "period_weekly"))),
                ButtonSegment(value: "monthly", label: Text(tr(context, "period_monthly"))),
              ],
              selected: {_period},
              onSelectionChanged: (selection) {
                setState(() => _period = selection.first);
                _load();
              },
            ),
          ),
          if (_loading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (r == null)
            const Expanded(child: Center(child: Text("Imeshindikana kupata ripoti.")))
          else
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    color: isLoss ? Colors.red.shade50 : Colors.green.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Text(
                            tr(context, isLoss ? "loss_label" : "profit_label"),
                            style: TextStyle(
                              color: isLoss ? Colors.red.shade800 : Colors.green.shade800,
                              fontWeight: FontWeight.bold, fontSize: 14,
                            ),
                          ),
                          Text(
                            "TZS ${r["net_profit"]}",
                            style: TextStyle(
                              color: isLoss ? Colors.red.shade800 : Colors.green.shade800,
                              fontWeight: FontWeight.bold, fontSize: 28,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _reportRow(tr(context, "revenue_label"), r["revenue"]),
                  _reportRow(tr(context, "cogs_label"), r["cost_of_goods_sold"]),
                  _reportRow(tr(context, "gross_profit_label"), r["gross_profit"], bold: true),
                  const Divider(),
                  _reportRow(tr(context, "transport_expenses_label"), r["transport_expenses"]),
                  _reportRow(tr(context, "other_expenses_label"), r["other_operating_expenses"]),
                  const Divider(),
                  _reportRow(tr(context, "net_profit_label"), r["net_profit"], bold: true),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _reportRow(String label, dynamic value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
          Text("TZS $value", style: TextStyle(fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}
