import 'package:flutter/material.dart';
import '../state/session.dart';
import 'owner/owner_dashboard_screen.dart';
import 'storekeeper/storekeeper_dashboard_screen.dart';
import 'cashier/cashier_dashboard_screen.dart';
import 'customer/marketplace_screen.dart';
import 'login_screen.dart';

/// Baada ya login, hii inapiga /auth/me/ na kuelekeza dashboard sahihi
/// kulingana na role ya mtumiaji.
class RoleRouterScreen extends StatefulWidget {
  const RoleRouterScreen({super.key});

  @override
  State<RoleRouterScreen> createState() => _RoleRouterScreenState();
}

class _RoleRouterScreenState extends State<RoleRouterScreen> {
  final Session _session = Session();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _route();
  }

  Future<void> _route() async {
    final ok = await _session.loadCurrentUser();
    if (!mounted) return;

    if (!ok || _session.currentUser == null) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
      return;
    }

    final role = _session.currentUser!.role;
    Widget target;
    switch (role) {
      case "owner":
        target = const OwnerDashboardScreen();
        break;
      case "storekeeper":
        target = const StorekeeperDashboardScreen();
        break;
      case "cashier":
        target = const CashierDashboardScreen();
        break;
      case "customer":
        target = const MarketplaceScreen();
        break;
      default:
        target = const LoginScreen(); // super_admin: dashboard yake bado haijajengwa
    }

    setState(() => _loading = false);
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => target),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
