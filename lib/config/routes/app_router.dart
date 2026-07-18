// lib/config/routes/app_router.dart - Add stock out routes
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/login_screen.dart';
import '../../features/auth/presentation/pages/forgot_password_screen.dart';
import '../../features/auth/presentation/pages/signup_screen.dart';
import '../../features/product/presentation/pages/product_form_screen.dart';
import '../../features/product/presentation/pages/product_list_screen.dart';
import '../../features/stock_in/presentation/pages/stock_in_form_screen.dart';
import '../../features/stock_in/presentation/pages/stock_in_history_screen.dart';
import '../../features/stock_out/presentation/pages/stock_out_form_screen.dart'; 
import '../../features/stock_out/presentation/pages/stock_out_history_screen.dart'; 
import '../../features/dashboard/presentation/pages/dashboard_screen.dart';
import '../../features/settings/presentation/pages/settings_screen.dart';
import '../../shared/models/product_type.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/sign-up',
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const DashboardScreen(),
      ),
      // Products
      GoRoute(
        path: '/products',
        builder: (context, state) => const ProductListScreen(),
      ),
      GoRoute(
        path: '/products/add',
        builder: (context, state) => const ProductFormScreen(),
      ),
      GoRoute(
        path: '/products/edit/:code',
        builder: (context, state) {
          final product = state.extra as ProductType?;
          return ProductFormScreen(existingProduct: product);
        },
      ),
      // Stock In
      GoRoute(
        path: '/stock-in',
        builder: (context, state) => const StockInFormScreen(),
      ),
      GoRoute(
        path: '/stock-in/history',
        builder: (context, state) => const StockInHistoryScreen(),
      ),
      // Stock Out - NEW
      GoRoute(
        path: '/stock-out',
        builder: (context, state) => const StockOutFormScreen(),
      ),
      GoRoute(
        path: '/stock-out/history',
        builder: (context, state) => const StockOutHistoryScreen(),
      ),
      // Settings
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
});