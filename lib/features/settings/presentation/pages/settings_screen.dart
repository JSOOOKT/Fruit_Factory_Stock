// lib/features/settings/presentation/pages/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../shared/localization/app_localizations.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.settingsTitle),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Info Section
            _buildUserSection(context, user),
            const SizedBox(height: 24),
            
            // Language Section
            _buildLanguageSection(context),
            const SizedBox(height: 16),
            
            // Theme Section
            _buildThemeSection(context),
            const SizedBox(height: 16),
            
            // About Section
            _buildAboutSection(context),
            const SizedBox(height: 16),
            
            // Logout Button
            _buildLogoutButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildUserSection(BuildContext context, dynamic user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'User Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.person),
              title: Text(user?.name ?? 'Guest'),
              subtitle: Text(user?.email ?? 'Not logged in'),
            ),
            ListTile(
              leading: const Icon(Icons.admin_panel_settings),
              title: Text('Role: ${user?.role ?? 'None'}'),
              subtitle: Text('ID: ${user?.uid ?? 'N/A'}'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageSection(BuildContext context) {
    final currentLocale = context.locale;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Language / ภาษา',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    leading: const Icon(Icons.check_circle, color: Colors.green),
                    title: const Text('ไทย'),
                    subtitle: const Text('Thai'),
                    trailing: currentLocale.languageCode == 'th'
                        ? const Icon(Icons.check, color: Colors.green)
                        : null,
                    onTap: () {
                      context.setLocale(const Locale('th'));
                      _showSnackbar('เปลี่ยนภาษาเป็นไทย');
                    },
                  ),
                ),
                Expanded(
                  child: ListTile(
                    leading: const Icon(Icons.check_circle, color: Colors.blue),
                    title: const Text('English'),
                    subtitle: const Text('อังกฤษ'),
                    trailing: currentLocale.languageCode == 'en'
                        ? const Icon(Icons.check, color: Colors.blue)
                        : null,
                    onTap: () {
                      context.setLocale(const Locale('en'));
                      _showSnackbar('Language changed to English');
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Theme / รูปแบบ',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    leading: const Icon(Icons.light_mode, color: Colors.amber),
                    title: const Text(AppLocalizations.light),
                    onTap: () {
                      // TODO: Implement theme switching
                      _showSnackbar('Light theme selected');
                    },
                  ),
                ),
                Expanded(
                  child: ListTile(
                    leading: const Icon(Icons.dark_mode, color: Colors.purple),
                    title: const Text(AppLocalizations.dark),
                    onTap: () {
                      // TODO: Implement theme switching
                      _showSnackbar('Dark theme selected');
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'About / เกี่ยวกับ',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('Fruit Factory Stock'),
              subtitle: const Text('Version 1.0.0'),
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Developed by'),
              subtitle: const Text('Fruit Factory Team'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogout,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
        ),
        child: _isLoading
            ? const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              )
            : const Text(AppLocalizations.logout),
      ),
    );
  }

  Future<void> _handleLogout() async {
    setState(() => _isLoading = true);
    
    try {
      await ref.read(authStateProvider.notifier).signOut();
      
      if (mounted) {
        context.go('/login');
        _showSnackbar('Logged out successfully');
      }
    } catch (e) {
      _showSnackbar('Error logging out: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}