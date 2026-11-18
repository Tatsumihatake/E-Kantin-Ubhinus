import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

class SellerShell extends StatelessWidget {
  const SellerShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.lunch_dining_outlined), selectedIcon: Icon(Icons.lunch_dining), label: 'Produk'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Pesanan'),
          NavigationDestination(icon: Icon(Icons.storefront_outlined), selectedIcon: Icon(Icons.storefront), label: 'Kantin'),
        ],
      ),
    );
  }
}
