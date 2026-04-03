import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../pages/manage_locations_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();
    final isDarkMode = provider.isDarkMode;

    return Scaffold(
      backgroundColor: isDarkMode
          ? Colors.black
          : CupertinoColors.systemGroupedBackground,
      appBar: AppBar(
        title: const Text('Ayarlar'),
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 20),
          _buildSettingsGroup(
            isDarkMode: isDarkMode,
            title: 'Genel',
            subtitle: 'Tema, saat biçimi, bildirim sesi.',
            icon: Icons.text_fields,
            children: [
              _buildSwitchTile(
                isDarkMode: isDarkMode,
                title: '24 Saat Biçimi',
                value: provider.is24HourFormat,
                onChanged: (val) =>
                    context.read<TaskProvider>().set24HourFormat(val),
              ),
              const Divider(height: 1),
              _buildSwitchTile(
                isDarkMode: isDarkMode,
                title: 'Uygulama İçi Sesler',
                value: provider.isSoundEnabled,
                onChanged: (val) =>
                    context.read<TaskProvider>().setSoundEnabled(val),
              ),
              const Divider(height: 1),
              _buildSwitchTile(
                isDarkMode: isDarkMode,
                title: 'Koyu Tema',
                value: isDarkMode,
                onChanged: (val) => context.read<TaskProvider>().toggleTheme(),
              ),
            ],
          ),
          const SizedBox(height: 30),
          _buildSettingsGroup(
            isDarkMode: isDarkMode,
            title: 'Bildirimler',
            subtitle: 'Durum çubuğu, Titreşim, Ses Seviyesi.',
            icon: Icons.notifications_none,
            children: [
              _buildSwitchTile(
                isDarkMode: isDarkMode,
                title: 'Bildirimlere İzin Ver',
                value: provider.isNotificationEnabled,
                onChanged: (val) =>
                    context.read<TaskProvider>().setNotificationEnabled(val),
              ),
              const Divider(height: 1),
              _buildSwitchTile(
                isDarkMode: isDarkMode,
                title: 'Bildirim Sesi',
                value: provider.isNotificationSound,
                onChanged: provider.isNotificationEnabled
                    ? (val) =>
                          context.read<TaskProvider>().setNotificationSound(val)
                    : null,
              ),
              const Divider(height: 1),
              _buildSwitchTile(
                isDarkMode: isDarkMode,
                title: 'Titreşim',
                value: provider.isNotificationVibration,
                onChanged: provider.isNotificationEnabled
                    ? (val) => context
                          .read<TaskProvider>()
                          .setNotificationVibration(val)
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 30),
          _buildSettingsGroup(
            isDarkMode: isDarkMode,
            title: 'Konum',
            subtitle: 'Evden çıkış kontrolleri için ev konumu tanımlayın.',
            icon: Icons.location_on,
            children: [
              ListTile(
                title: Text(
                  'Kayıtlı Konumları Yönet',
                  style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                ),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ManageLocationsPage(),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildSettingsGroup({
    required bool isDarkMode,
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: isDarkMode ? Colors.white70 : Colors.black87),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode ? Colors.white54 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF1C1C1E) : Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required bool isDarkMode,
    required String title,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
      ),
      trailing: CupertinoSwitch(
        value: value,
        onChanged: onChanged,
        activeTrackColor: CupertinoColors.systemBlue,
      ),
    );
  }
}
