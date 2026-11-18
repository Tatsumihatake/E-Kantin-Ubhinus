import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../features/admin/pages/admin_sellers_page.dart';
import '../features/auth/pages/login_page.dart';
import '../features/auth/pages/register_page.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/customer/pages/canteen_detail_page.dart';
import '../features/customer/pages/customer_shell.dart';
import '../features/customer/pages/favorite_page.dart';
import '../features/customer/pages/home_page.dart';
import '../features/customer/pages/order_confirmation_page.dart';
import '../features/customer/pages/order_detail_page.dart';
import '../features/customer/pages/order_history_page.dart';
import '../features/customer/pages/payment_page.dart';
import '../features/customer/pages/product_detail_page.dart';
import '../features/customer/pages/profile_page.dart';
import '../features/seller/pages/seller_canteen_page.dart';
import '../features/seller/pages/seller_dashboard_page.dart';
import '../features/seller/pages/seller_orders_page.dart';
import '../features/seller/pages/seller_product_form_page.dart';
import '../features/seller/pages/seller_products_page.dart';
import '../features/seller/pages/seller_shell.dart';
import '../shared/models/catalog.dart';
import '../shared/models/order.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(authProvider);

  return GoRouter(
    initialLocation: auth.isAuthenticated ? auth.homePath : '/login',
    redirect: (context, state) {
      final location = state.matchedLocation;
      final atAuthPage = location == '/login' || location == '/register';

      if (!auth.isAuthenticated) {
        return atAuthPage ? null : '/login';
      }

      if (atAuthPage) {
        return auth.homePath;
      }

      if (auth.isCustomer && (location.startsWith('/seller') || location.startsWith('/admin'))) {
        return '/customer/home';
      }

      if (auth.isSeller && (location.startsWith('/customer') || location.startsWith('/admin'))) {
        return '/seller';
      }

      if (auth.isAdmin && (location.startsWith('/customer') || location.startsWith('/seller'))) {
        return '/admin/sellers';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(path: '/register', builder: (context, state) => const RegisterPage()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => CustomerShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/customer/home', builder: (context, state) => const HomePage()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/customer/favorites', builder: (context, state) => const FavoritePage()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/customer/history', builder: (context, state) => const OrderHistoryPage()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/customer/profile', builder: (context, state) => const ProfilePage()),
            ],
          ),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => SellerShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/seller', builder: (context, state) => const SellerDashboardPage()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/seller/products', builder: (context, state) => const SellerProductsPage()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/seller/orders', builder: (context, state) => const SellerOrdersPage()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/seller/canteen', builder: (context, state) => const SellerCanteenPage()),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/customer/canteen/:canteenId',
        builder: (context, state) => CanteenDetailPage(canteenId: state.pathParameters['canteenId']!),
      ),
      GoRoute(
        path: '/customer/product/:productId',
        builder: (context, state) => ProductDetailPage(productId: state.pathParameters['productId']!),
      ),
      GoRoute(
        path: '/customer/confirm',
        builder: (context, state) {
          final preview = state.extra;

          if (preview is! OrderPreview) {
            return const _RedirectFallback();
          }

          return OrderConfirmationPage(preview: preview);
        },
      ),
      GoRoute(
        path: '/customer/payment/:orderId',
        builder: (context, state) => PaymentPage(orderId: state.pathParameters['orderId']!),
      ),
      GoRoute(
        path: '/customer/orders/:orderId',
        builder: (context, state) => OrderDetailPage(orderId: state.pathParameters['orderId']!),
      ),
      GoRoute(
        path: '/seller/products/new',
        builder: (context, state) => const SellerProductFormPage(),
      ),
      GoRoute(
        path: '/seller/products/:productId/edit',
        builder: (context, state) {
          final product = state.extra;

          return SellerProductFormPage(product: product is Product ? product : null);
        },
      ),
      GoRoute(
        path: '/admin/sellers',
        builder: (context, state) => const AdminSellersPage(),
      ),
    ],
  );
});

class _RedirectFallback extends StatelessWidget {
  const _RedirectFallback();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: TextButton(
          onPressed: () => context.go('/customer/home'),
          child: const Text('Kembali ke Home'),
        ),
      ),
    );
  }
}
