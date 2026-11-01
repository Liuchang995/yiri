import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/app_colors.dart';
import '../../data/preferences/preferences.dart';

class PermissionSetupPage extends ConsumerStatefulWidget {
  const PermissionSetupPage({super.key});

  @override
  ConsumerState<PermissionSetupPage> createState() =>
      _PermissionSetupPageState();
}

class _PermissionSetupPageState extends ConsumerState<PermissionSetupPage> {
  bool _requesting = false;

  Future<void> _continue() async {
    if (_requesting) return;
    setState(() => _requesting = true);

    const timeout = Duration(seconds: 10);
    await Permission.locationWhenInUse.request().timeout(
      timeout,
      onTimeout: () => PermissionStatus.denied,
    );
    await Permission.camera.request().timeout(
      timeout,
      onTimeout: () => PermissionStatus.denied,
    );
    if (await Permission.photos.isDenied) {
      await Permission.photos.request().timeout(
        timeout,
        onTimeout: () => PermissionStatus.denied,
      );
    }

    final preferences = ref.read(sharedPreferencesProvider);
    await preferences.setBool(permissionsOnboardedKey, true);
    if (!mounted) return;
    context.go('/home');
  }

  Future<void> _later() async {
    final preferences = ref.read(sharedPreferencesProvider);
    await preferences.setBool(permissionsOnboardedKey, true);
    if (!mounted) return;
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '让一日更好地记录',
                    style: TextStyle(
                      color: colors.text,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '下一步会依次请求定位、相机和相册权限。定位只用于城市和天气，不会记录街道。你随时可以拒绝。',
                    style: TextStyle(
                      color: colors.secondaryText,
                      fontSize: 13,
                      height: 1.7,
                    ),
                  ),
                  const SizedBox(height: 32),
                  const _PermissionRow(
                    icon: Icons.location_on_outlined,
                    title: '定位 · 仅城市',
                    subtitle: '获取当天天气，城市随日记保存',
                  ),
                  const _PermissionRow(
                    icon: Icons.photo_camera_outlined,
                    title: '相机',
                    subtitle: '为日记拍摄照片，照片只在本机',
                  ),
                  const _PermissionRow(
                    icon: Icons.photo_library_outlined,
                    title: '相册',
                    subtitle: '从相册选择日记图片',
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    height: 48,
                    child: FilledButton(
                      onPressed: _requesting ? null : _continue,
                      style: FilledButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: colors.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(_requesting ? '正在请求…' : '继续'),
                    ),
                  ),
                  TextButton(
                    onPressed: _requesting ? null : _later,
                    child: Text(
                      '以后再说',
                      style: TextStyle(
                        color: colors.secondaryText,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PermissionRow extends StatelessWidget {
  const _PermissionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        children: [
          Icon(icon, size: 22, color: colors.primary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: colors.text, fontSize: 14)),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(color: colors.secondaryText, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
