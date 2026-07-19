import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/auth/presentation/pages/login_screen.dart';
import '../../features/auth/presentation/pages/signup_screen.dart';
import '../../features/splash/presentation/pages/splash_screen.dart';
import '../../features/dashboard/presentation/pages/dashboard_screen.dart';
import '../../features/products/presentation/pages/product_list_screen.dart';
import '../../features/products/presentation/pages/product_form_screen.dart';
import '../../features/products/data/models/product_model.dart';
import '../../features/stock_in/presentation/pages/stock_in_screen.dart';
import '../../features/stock_in/presentation/pages/stock_in_history_screen.dart';
import '../../features/stock_out/presentation/pages/stock_out_screen.dart';
import '../../features/stock_out/presentation/pages/stock_out_history_screen.dart';
import '../../features/settings/presentation/pages/settings_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      // Splash Screen
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      // Auth Routes
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/sign-up',
        name: 'signup',
        builder: (context, state) => const SignUpScreen(),
      ),
      // Dashboard (Protected)
      GoRoute(
        path: '/',
        name: 'dashboard',
        builder: (context, state) => const DashboardScreen(),
        redirect: (context, state) {
          final isAuth = ref.read(isAuthenticatedProvider);
          return isAuth ? null : '/login';
        },
      ),
      // Settings (Protected)
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
        redirect: (context, state) {
          final isAuth = ref.read(isAuthenticatedProvider);
          return isAuth ? null : '/login';
        },
      ),
      // Product Routes (Protected)
      GoRoute(
        path: '/products',
        name: 'products',
        builder: (context, state) => const ProductListScreen(),
        redirect: (context, state) {
          final isAuth = ref.read(isAuthenticatedProvider);
          return isAuth ? null : '/login';
        },
      ),
      GoRoute(
        path: '/products/add',
        name: 'add-product',
        builder: (context, state) => const ProductFormScreen(),
        redirect: (context, state) {
          final isAuth = ref.read(isAuthenticatedProvider);
          return isAuth ? null : '/login';
        },
      ),
      GoRoute(
        path: '/products/edit/:id',
        name: 'edit-product',
        builder: (context, state) {
          final product = state.extra as Product?;
          return ProductFormScreen(existingProduct: product);
        },
        redirect: (context, state) {
          final isAuth = ref.read(isAuthenticatedProvider);
          return isAuth ? null : '/login';
        },
      ),
      // Stock In Routes (Protected)
      GoRoute(
        path: '/stock-in',
        name: 'stock-in',
        builder: (context, state) => const StockInScreen(),
        redirect: (context, state) {
          final isAuth = ref.read(isAuthenticatedProvider);
          return isAuth ? null : '/login';
        },
      ),
      GoRoute(
        path: '/stock-in/history',
        name: 'stock-in-history',
        builder: (context, state) => const StockInHistoryScreen(),
        redirect: (context, state) {
          final isAuth = ref.read(isAuthenticatedProvider);
          return isAuth ? null : '/login';
        },
      ),
      // Stock Out Routes (Protected)
      GoRoute(
        path: '/stock-out',
        name: 'stock-out',
        builder: (context, state) => const StockOutScreen(),
        redirect: (context, state) {
          final isAuth = ref.read(isAuthenticatedProvider);
          return isAuth ? null : '/login';
        },
      ),
      GoRoute(
        path: '/stock-out/history',
        name: 'stock-out-history',
        builder: (context, state) => const StockOutHistoryScreen(),
        redirect: (context, state) {
          final isAuth = ref.read(isAuthenticatedProvider);
          return isAuth ? null : '/login';
        },
      ),
    ],
  );
});
