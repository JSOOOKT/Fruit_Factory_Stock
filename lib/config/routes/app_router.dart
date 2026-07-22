import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/auth/presentation/pages/login_screen.dart';
import '../../features/auth/presentation/pages/signup_screen.dart';
import '../../features/dashboard/presentation/pages/dashboard_screen.dart';
import '../../features/products/presentation/pages/product_list_screen.dart';
import '../../features/products/presentation/pages/product_form_screen.dart';
import '../../features/products/presentation/pages/product_detail_screen.dart';
import '../../features/products/presentation/pages/product_history_screen.dart';
import '../../features/products/data/models/product_model.dart';
import '../../features/stock_in/presentation/pages/stock_in_screen.dart';
import '../../features/stock_in/presentation/pages/stock_in_history_screen.dart';
import '../../features/stock_out/presentation/pages/stock_out_screen.dart';
import '../../features/stock_out/presentation/pages/stock_out_history_screen.dart';
import '../../features/settings/presentation/pages/settings_screen.dart';
import '../../features/settings/presentation/pages/settings_menu_screen.dart';
import '../../features/settings/presentation/pages/tank_settings_screen.dart';
import '../../features/settings/presentation/pages/report_issue_screen.dart';
import '../../features/settings/presentation/pages/purpose_settings_screen.dart';
import '../../features/factory/presentation/pages/factory_select_screen.dart';
import '../../features/factory/presentation/pages/create_factory_screen.dart';
import '../../features/factory/presentation/pages/edit_factory_screen.dart';
import '../../features/factory/domain/entities/factory.dart';
import '../../features/reports/presentation/pages/report_screen.dart';
import '../../features/reports/presentation/pages/product_tank_summary_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    routes: [
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
      // Factory Routes
      GoRoute(
        path: '/factory/select',
        name: 'factory-select',
        builder: (context, state) => const FactorySelectScreen(),
        redirect: (context, state) {
          final isAuth = ref.read(isAuthenticatedProvider);
          return isAuth ? null : '/login';
        },
      ),
      GoRoute(
        path: '/factory/create',
        name: 'factory-create',
        builder: (context, state) => const CreateFactoryScreen(),
        redirect: (context, state) {
          final isAuth = ref.read(isAuthenticatedProvider);
          return isAuth ? null : '/login';
        },
      ),
      GoRoute(
        path: '/factory/edit',
        name: 'factory-edit',
        builder: (context, state) {
          final factory = state.extra as Factory?;
          if (factory == null) {
            return const Scaffold(
              body: Center(child: Text('ไม่พบข้อมูลโรงงาน')),
            );
          }
          return EditFactoryScreen(factory: factory);
        },
        redirect: (context, state) {
          final isAuth = ref.read(isAuthenticatedProvider);
          final hasFactory = ref.read(hasFactoryProvider);
          
          if (!isAuth) return '/login';
          if (!hasFactory) return '/factory/select';
          return null;
        },
      ),
      // Settings Menu
      GoRoute(
        path: '/settings/menu',
        name: 'settings-menu',
        builder: (context, state) => const SettingsMenuScreen(),
        redirect: (context, state) {
          final isAuth = ref.read(isAuthenticatedProvider);
          final hasFactory = ref.read(hasFactoryProvider);
          
          if (!isAuth) return '/login';
          if (!hasFactory) return '/factory/select';
          return null;
        },
      ),
      // ✅ Profile Settings
      GoRoute(
        path: '/settings/profile',
        name: 'settings-profile',
        builder: (context, state) => const SettingsScreen(),
        redirect: (context, state) {
          final isAuth = ref.read(isAuthenticatedProvider);
          final hasFactory = ref.read(hasFactoryProvider);
          
          if (!isAuth) return '/login';
          if (!hasFactory) return '/factory/select';
          return null;
        },
      ),
      // Settings Sub-routes
      GoRoute(
        path: '/settings/tanks',
        name: 'settings-tanks',
        builder: (context, state) => const TankSettingsScreen(),
        redirect: (context, state) {
          final isAuth = ref.read(isAuthenticatedProvider);
          final hasFactory = ref.read(hasFactoryProvider);
          
          if (!isAuth) return '/login';
          if (!hasFactory) return '/factory/select';
          return null;
        },
      ),
      GoRoute(
        path: '/settings/purposes',
        name: 'settings-purposes',
        builder: (context, state) => const PurposeSettingsScreen(),
        redirect: (context, state) {
          final isAuth = ref.read(isAuthenticatedProvider);
          final hasFactory = ref.read(hasFactoryProvider);
          
          if (!isAuth) return '/login';
          if (!hasFactory) return '/factory/select';
          return null;
        },
      ),
      GoRoute(
        path: '/settings/report-issue',
        name: 'settings-report-issue',
        builder: (context, state) => const ReportIssueScreen(),
        redirect: (context, state) {
          final isAuth = ref.read(isAuthenticatedProvider);
          final hasFactory = ref.read(hasFactoryProvider);
          
          if (!isAuth) return '/login';
          if (!hasFactory) return '/factory/select';
          return null;
        },
      ),
      // Settings (Protected) - เปลี่ยนไปใช้ Settings Menu
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsMenuScreen(),
        redirect: (context, state) {
          final isAuth = ref.read(isAuthenticatedProvider);
          final hasFactory = ref.read(hasFactoryProvider);
          
          if (!isAuth) return '/login';
          if (!hasFactory) return '/factory/select';
          return null;
        },
      ),
      // Reports Routes
      GoRoute(
        path: '/reports',
        name: 'reports',
        builder: (context, state) => const ReportScreen(),
        redirect: (context, state) {
          final isAuth = ref.read(isAuthenticatedProvider);
          final hasFactory = ref.read(hasFactoryProvider);
          
          if (!isAuth) return '/login';
          if (!hasFactory) return '/factory/select';
          return null;
        },
      ),
      GoRoute(
        path: '/reports/product-tank-summary',
        name: 'reports-product-tank-summary',
        builder: (context, state) => const ProductTankSummaryScreen(),
        redirect: (context, state) {
          final isAuth = ref.read(isAuthenticatedProvider);
          final hasFactory = ref.read(hasFactoryProvider);
          
          if (!isAuth) return '/login';
          if (!hasFactory) return '/factory/select';
          return null;
        },
      ),
      // Dashboard (Protected)
      GoRoute(
        path: '/',
        name: 'dashboard',
        builder: (context, state) => const DashboardScreen(),
        redirect: (context, state) {
          final isAuth = ref.read(isAuthenticatedProvider);
          final hasFactory = ref.read(hasFactoryProvider);
          
          if (!isAuth) return '/login';
          if (!hasFactory) return '/factory/select';
          return null;
        },
      ),
      // Product Routes (Protected)
      GoRoute(
        path: '/products',
        name: 'products',
        builder: (context, state) => const ProductListScreen(),
        redirect: (context, state) {
          final isAuth = ref.read(isAuthenticatedProvider);
          final hasFactory = ref.read(hasFactoryProvider);
          
          if (!isAuth) return '/login';
          if (!hasFactory) return '/factory/select';
          return null;
        },
      ),
      GoRoute(
        path: '/products/add',
        name: 'add-product',
        builder: (context, state) => const ProductFormScreen(),
        redirect: (context, state) {
          final isAuth = ref.read(isAuthenticatedProvider);
          final hasFactory = ref.read(hasFactoryProvider);
          
          if (!isAuth) return '/login';
          if (!hasFactory) return '/factory/select';
          return null;
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
          final hasFactory = ref.read(hasFactoryProvider);
          
          if (!isAuth) return '/login';
          if (!hasFactory) return '/factory/select';
          return null;
        },
      ),
      GoRoute(
        path: '/products/detail',
        name: 'product-detail',
        builder: (context, state) {
          final product = state.extra as Product?;
          if (product == null) {
            return const Scaffold(
              body: Center(child: Text('ไม่พบสินค้า')),
            );
          }
          return ProductDetailScreen(product: product);
        },
        redirect: (context, state) {
          final isAuth = ref.read(isAuthenticatedProvider);
          final hasFactory = ref.read(hasFactoryProvider);
          
          if (!isAuth) return '/login';
          if (!hasFactory) return '/factory/select';
          return null;
        },
      ),
      // ✅ Product History Route
      GoRoute(
        path: '/products/history',
        name: 'products-history',
        builder: (context, state) => const ProductHistoryScreen(),
        redirect: (context, state) {
          final isAuth = ref.read(isAuthenticatedProvider);
          final hasFactory = ref.read(hasFactoryProvider);
          
          if (!isAuth) return '/login';
          if (!hasFactory) return '/factory/select';
          return null;
        },
      ),
      // Stock In Routes (Protected)
      GoRoute(
        path: '/stock-in',
        name: 'stock-in',
        builder: (context, state) => const StockInScreen(),
        redirect: (context, state) {
          final isAuth = ref.read(isAuthenticatedProvider);
          final hasFactory = ref.read(hasFactoryProvider);
          
          if (!isAuth) return '/login';
          if (!hasFactory) return '/factory/select';
          return null;
        },
      ),
      GoRoute(
        path: '/stock-in/history',
        name: 'stock-in-history',
        builder: (context, state) => const StockInHistoryScreen(),
        redirect: (context, state) {
          final isAuth = ref.read(isAuthenticatedProvider);
          final hasFactory = ref.read(hasFactoryProvider);
          
          if (!isAuth) return '/login';
          if (!hasFactory) return '/factory/select';
          return null;
        },
      ),
      // Stock Out Routes (Protected)
      GoRoute(
        path: '/stock-out',
        name: 'stock-out',
        builder: (context, state) => const StockOutScreen(),
        redirect: (context, state) {
          final isAuth = ref.read(isAuthenticatedProvider);
          final hasFactory = ref.read(hasFactoryProvider);
          
          if (!isAuth) return '/login';
          if (!hasFactory) return '/factory/select';
          return null;
        },
      ),
      GoRoute(
        path: '/stock-out/history',
        name: 'stock-out-history',
        builder: (context, state) => const StockOutHistoryScreen(),
        redirect: (context, state) {
          final isAuth = ref.read(isAuthenticatedProvider);
          final hasFactory = ref.read(hasFactoryProvider);
          
          if (!isAuth) return '/login';
          if (!hasFactory) return '/factory/select';
          return null;
        },
      ),
    ],
    redirect: (context, state) {
      final isAuth = ref.read(isAuthenticatedProvider);
      final hasFactory = ref.read(hasFactoryProvider);
      final location = state.matchedLocation;
      
      if (!isAuth && location != '/login' && location != '/sign-up') {
        return '/login';
      }
      
      if (isAuth && !hasFactory && 
          location != '/factory/select' && 
          location != '/factory/create') {
        return '/factory/select';
      }
      
      return null;
    },
  );
});
