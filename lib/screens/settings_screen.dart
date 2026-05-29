import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_state.dart';
import '../providers/theme_state.dart';
import '../widgets/glass_container.dart';
import 'login_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final isDarkMode = ref.watch(themeStateProvider);

    final isTelugu = authState.languageCode == 'te';

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0F2027), Color(0xFF2C5364)],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            isTelugu ? 'అప్లికేషన్ సెట్టింగులు' : 'Application Settings',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // User identity card
            GlassContainer(
              child: Row(
                children: [
                  Container(
                    width: 55,
                    height: 55,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00D2FF), Color(0xFF0072FF)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00D2FF).withOpacity(0.3),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.business_center, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          authState.userName.isNotEmpty ? authState.userName : 'Sri Siva Gayathri Admin',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          authState.userEmail.isNotEmpty ? authState.userEmail : 'admin@ssg.com',
                          style: const TextStyle(color: Colors.white60, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.cyanAccent, size: 12),
                            const SizedBox(width: 4),
                            const Text('Rajampalli', style: TextStyle(color: Colors.cyanAccent, fontSize: 11)),
                            const SizedBox(width: 12),
                            const Icon(Icons.phone, color: Colors.cyanAccent, size: 12),
                            const SizedBox(width: 4),
                            const Text('7036657769', style: TextStyle(color: Colors.cyanAccent, fontSize: 11)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),

            // Preferences
            Text(
              isTelugu ? 'ప్రాధాన్యతలు' : 'Preferences',
              style: const TextStyle(color: Colors.white70, fontSize: 13, letterSpacing: 0.5),
            ),
            const SizedBox(height: 10),

            GlassContainer(
              padding: 0,
              child: Column(
                children: [
                  // Dark Mode
                  ListTile(
                    leading: const Icon(Icons.dark_mode, color: Colors.cyanAccent),
                    title: Text(
                      isTelugu ? 'డార్క్ మోడ్' : 'Dark Mode Theme',
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      isTelugu ? 'అప్లికేషన్ థీమ్ మార్చండి' : 'Enable premium night mode aesthetic',
                      style: const TextStyle(color: Colors.white50, fontSize: 11),
                    ),
                    trailing: Switch(
                      value: isDarkMode,
                      activeColor: Colors.cyanAccent,
                      onChanged: (val) {
                        ref.read(themeStateProvider.notifier).toggleTheme();
                        ref.read(authStateProvider.notifier).syncDarkModeSetting(val);
                      },
                    ),
                  ),
                  const Divider(color: Colors.white12, height: 1),

                  // Language
                  ListTile(
                    leading: const Icon(Icons.translate, color: Colors.cyanAccent),
                    title: Text(
                      isTelugu ? 'భాష మార్చండి' : 'Select Language',
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      isTelugu ? 'ప్రస్తుతం: తెలుగు' : 'Current: English',
                      style: const TextStyle(color: Colors.white50, fontSize: 11),
                    ),
                    trailing: DropdownButton<String>(
                      dropdownColor: const Color(0xFF1E293B),
                      value: authState.languageCode,
                      style: const TextStyle(color: Colors.cyanAccent),
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(value: 'en', child: Text('English')),
                        DropdownMenuItem(value: 'te', child: Text('తెలుగు (Telugu)')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          ref.read(authStateProvider.notifier).setLanguage(val);
                        }
                      },
                    ),
                  ),
                  const Divider(color: Colors.white12, height: 1),

                  // Notification settings
                  ListTile(
                    leading: const Icon(Icons.notifications_active_outlined, color: Colors.cyanAccent),
                    title: Text(
                      isTelugu ? 'నోటిఫికేషన్లు' : 'Push Notifications',
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: const Text(
                      'Low stock alerts & billing reminders',
                      style: TextStyle(color: Colors.white50, fontSize: 11),
                    ),
                    trailing: Switch(
                      value: true,
                      activeColor: Colors.cyanAccent,
                      onChanged: (val) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(val ? 'Notifications enabled' : 'Notifications disabled')),
                        );
                      },
                    ),
                  ),
                  const Divider(color: Colors.white12, height: 1),

                  // Cloud backup
                  ListTile(
                    leading: const Icon(Icons.cloud_upload_outlined, color: Colors.cyanAccent),
                    title: Text(
                      isTelugu ? 'ఆటోమేటిక్ బ్యాకప్' : 'Auto Cloud Sync Backup',
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: const Text(
                      'Auto backup to Firebase Cloud',
                      style: TextStyle(color: Colors.white50, fontSize: 11),
                    ),
                    trailing: const Text(
                      'ONLINE',
                      style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Firebase Cloud database sync completed!')),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // About section
            Text(
              isTelugu ? 'గురించి' : 'About',
              style: const TextStyle(color: Colors.white70, fontSize: 13, letterSpacing: 0.5),
            ),
            const SizedBox(height: 10),

            GlassContainer(
              padding: 0,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.info_outline, color: Colors.white60),
                    title: const Text('App Version', style: TextStyle(color: Colors.white)),
                    trailing: const Text('v1.0.0', style: TextStyle(color: Colors.white50, fontSize: 12)),
                  ),
                  const Divider(color: Colors.white12, height: 1),
                  const ListTile(
                    leading: Icon(Icons.business, color: Colors.white60),
                    title: Text('Sri Siva Gayathri Enterprizes', style: TextStyle(color: Colors.white)),
                    subtitle: Text('Rajampalli | Ph: 7036657769 / 9000990191', style: TextStyle(color: Colors.white50, fontSize: 11)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),

            // Sign out
            GlassContainer(
              padding: 0,
              child: ListTile(
                leading: const Icon(Icons.logout, color: Colors.redAccent),
                title: Text(
                  isTelugu ? 'లాగ్ అవుట్' : 'Sign Out / Logout',
                  style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                ),
                onTap: () async {
                  await ref.read(authStateProvider.notifier).logout();
                  if (!context.mounted) return;
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (Route<dynamic> route) => false,
                  );
                },
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
