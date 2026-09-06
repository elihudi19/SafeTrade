import 'package:flutter/material.dart';
import '../../services/dashboard_service.dart';
import '../../services/predictive_alert_service.dart';
import '../../models/predictive_alert.dart';
import '../../l10n/tr.dart';
import '../../widgets/language_switcher.dart';
import '../login_screen.dart';
import '../../services/api_client.dart';
import 'staff_create_screen.dart';
import 'profit_loss_report_screen.dart';

class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  final _dashboardService = DashboardService();
  final _alertService = PredictiveAlertService();

  Map<String, dynamic>? _overview;
  List<PredictiveAlert> _alerts = [];
  bool _loading = true;
  bool _recomputing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await _dashboardService.ownerOverview();
    final alerts = await _alertService.listAlerts();
    setState(() {
      _overview = data;
      _alerts = alerts;
      _loading = false;
    });
  }

  Future<void> _recompute() async {
    setState(() => _recomputing = true);
    await _alertService.recompute();
    final alerts = await _alertService.listAlerts();
    setState(() { _alerts = alerts; _recomputing = false; });
  }

  Future<void> _acknowledge(PredictiveAlert alert) async {
    await _alertService.acknowledge(alert.id);
    setState(() => _alerts.removeWhere((a) => a.id == alert.id));
  }

  Future<void> _logout() async {
    await ApiClient().clearTokens();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  Widget _buildProductAlertCard(PredictiveAlert alert) {
    final isFastMoving = alert.alertType == "fast_moving";
    final d = alert.detail;

    final title = tr(context, isFastMoving ? "fast_moving_title" : "slow_moving_title");
    final icon = isFastMoving ? Icons.trending_up : Icons.trending_down;
    final color = isFastMoving ? Colors.orange : Colors.blueGrey;

    final lines = <String>[];
    if (isFastMoving) {
      lines.add("${tr(context, "current_stock_label")}: ${d["current_stock"]}");
      if (d["days_until_stockout"] != null) {
        lines.add("${tr(context, "days_until_stockout_label")} ${d["days_until_stockout"]}");
      }
      lines.add(
        "${tr(context, "daily_sales_pace_label")}: ${d["avg_daily_sales_7d"]}/${tr(context, "per_day_label")}",
      );
      if (d["trend_percent_week_vs_month"] != null) {
        final trend = d["trend_percent_week_vs_month"];
        lines.add("${tr(context, "trend_label")}: ${trend > 0 ? '+' : ''}$trend%");
      }
      lines.add("${tr(context, "lead_time_label")}: ${d["lead_time_days"]} ${tr(context, "days_unit")}");
      if (d["suggested_reorder_quantity"] != null) {
        lines.add("${tr(context, "suggested_reorder_label")} ${d["suggested_reorder_quantity"]}");
      }
    } else {
      lines.add("${tr(context, "current_stock_label")}: ${d["current_stock"]}");
      lines.add("${tr(context, "sold_last_30_days_label")}: ${d["sold_last_30_days"]}");
      if (d["days_of_stock_at_current_pace"] != null) {
        lines.add(
          "${tr(context, "days_of_stock_remaining_label")}: ${d["days_of_stock_at_current_pace"]}",
        );
      }
    }

    return _alertCardShell(alert, title, icon, color, lines);
  }

  Widget _buildBusinessTrendCard(PredictiveAlert alert) {
    final isLoss = alert.alertType == "loss_warning";
    final d = alert.detail;
    final title = tr(context, isLoss ? "loss_warning_title" : "profit_trend_title");
    final icon = isLoss ? Icons.warning_amber : Icons.show_chart;
    final color = isLoss ? Colors.red : Colors.green;

    final lines = <String>[
      "${tr(context, "avg_daily_profit_7d_label")}: TZS ${d["average_daily_profit_last_7_days"]}",
      "${tr(context, "projected_monthly_label")}: TZS ${d["projected_monthly_profit_at_current_pace"]}",
    ];
    if (d["recommendation"] != null) lines.add(d["recommendation"]);

    return _alertCardShell(alert, title, icon, color, lines);
  }

  Widget _alertCardShell(
    PredictiveAlert alert, String title, IconData icon, Color color, List<String> lines,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        subtitle: Text(lines.join("\n")),
        isThreeLine: true,
        trailing: IconButton(
          icon: const Icon(Icons.check_circle_outline),
          tooltip: tr(context, "acknowledge_tooltip"),
          onPressed: () => _acknowledge(alert),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stores = (_overview?["stores"] as List?) ?? [];
    return Scaffold(
      appBar: AppBar(
        title: Text(tr(context, "owner_dashboard_title")),
        actions: [
          const LanguageSwitcher(),
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const StaffCreateScreen()),
        ),
        icon: const Icon(Icons.person_add),
        label: Text(tr(context, "add_staff_button")),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                children: [
                  if (stores.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(tr(context, "no_stores_message")),
                    )
                  else
                    ...stores.map((s) {
                      final isLoss = s["today_is_loss"] == true;
                      final netProfit = s["today_net_profit"];
                      return Card(
                        margin: const EdgeInsets.all(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(s["store_name"],
                                      style: const TextStyle(
                                          fontSize: 18, fontWeight: FontWeight.bold)),
                                  GestureDetector(
                                    onTap: () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => ProfitLossReportScreen(
                                          storeId: s["store_id"], storeName: s["store_name"],
                                        ),
                                      ),
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isLoss ? Colors.red.shade50 : Colors.green.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: isLoss ? Colors.red : Colors.green,
                                        ),
                                      ),
                                      child: Text(
                                        "${tr(context, isLoss ? "loss_label" : "profit_label")}: TZS $netProfit",
                                        style: TextStyle(
                                          color: isLoss ? Colors.red.shade800 : Colors.green.shade800,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "${tr(context, "warehouse_label")}: ${s["warehouse_stock_total"]} ${tr(context, "pieces_unit")}",
                              ),
                              Text(
                                "${tr(context, "counter_label")}: ${s["counter_stock_total"]} ${tr(context, "pieces_unit")}",
                              ),
                              Text("${tr(context, "active_shifts_label")}: ${s["active_shifts"]}"),
                              Text("${tr(context, "today_sales_label")}: TZS ${s["today_sales"]}"),
                              if ((s["open_discrepancy_flags"] ?? 0) > 0)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    "${tr(context, "discrepancy_flags_label")}: ${s["open_discrepancy_flags"]}",
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => ProfitLossReportScreen(
                                        storeId: s["store_id"], storeName: s["store_name"],
                                      ),
                                    ),
                                  ),
                                  child: Text(tr(context, "view_profit_loss_report_button")),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  const Divider(height: 32),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(tr(context, "predictive_analytics_title"),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                        TextButton.icon(
                          onPressed: _recomputing ? null : _recompute,
                          icon: _recomputing
                              ? const SizedBox(
                                  width: 14, height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.refresh, size: 18),
                          label: Text(tr(context, "recompute_button")),
                        ),
                      ],
                    ),
                  ),
                  if (_alerts.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(tr(context, "no_alerts_message")),
                    )
                  else
                    ..._alerts.map((a) => a.isBusinessLevel
                        ? _buildBusinessTrendCard(a)
                        : _buildProductAlertCard(a)),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}
