import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:enbridge/theme/app_theme.dart';
import 'package:enbridge/core/supabase/supabase_client.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:enbridge/screens/about_screen.dart';
import 'package:enbridge/screens/privacy_policy_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _profile;
  Map<String, dynamic>? _notificationSettings;
  int _totalFocusMinutes = 0;
  int _totalTasksDone = 0;
  int _totalGoals = 0;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final responses = await Future.wait<dynamic>([
        supabase.from('profiles').select().eq('id', user.id).maybeSingle(),
        supabase.from('focus_sessions').select('session_duration_minutes').eq('user_id', user.id),
        supabase.from('tasks').select('id').eq('user_id', user.id).eq('completed', true),
        // Count ALL goals (not filtered by status so nothing is missed)
        supabase.from('goals').select('id').eq('user_id', user.id),
        supabase.from('notification_settings').select().eq('user_id', user.id).maybeSingle(),
      ]);

      if (mounted) {
        setState(() {
          _profile = responses[0] as Map<String, dynamic>?;

          final sessions = responses[1] as List<dynamic>;
          _totalFocusMinutes = sessions.fold<int>(
              0, (prev, e) => prev + ((e['session_duration_minutes'] as int?) ?? 0));

          _totalTasksDone = (responses[2] as List<dynamic>).length;
          _totalGoals = (responses[3] as List<dynamic>).length;

          _notificationSettings = responses[4] as Map<String, dynamic>?;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _editName() async {
    final ctrl = TextEditingController(text: _profile?['name'] ?? '');
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: Text('Edit Name', style: AppTextStyles.cardTitle),
        content: TextField(
          controller: ctrl,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.bgCard,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14.r), borderSide: BorderSide.none),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: Text('Save', style: TextStyle(color: AppColors.accentGreen)),
          ),
        ],
      )
    );

    if (newName != null && newName.isNotEmpty) {
      setState(() {
        _profile ??= {};
        _profile!['name'] = newName;
      });
      await supabase.from('profiles').upsert({'id': supabase.auth.currentUser!.id, 'name': newName});
      _fetchData();
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (file == null) return;

    try {
      final userId = supabase.auth.currentUser!.id;
      final bytes = await File(file.path).readAsBytes();
      final path = '$userId/avatar.jpg';

      await supabase.storage.from('avatars').uploadBinary(
        path,
        bytes,
        fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
      );

      final publicUrl = supabase.storage.from('avatars').getPublicUrl(path);

      await supabase.from('profiles').upsert({
        'id': userId,
        'avatar_url': publicUrl,
      });

      if (mounted) {
        setState(() {
          _profile ??= {};
          _profile!['avatar_url'] = publicUrl;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(children: [
              Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Text('Profile photo updated!', style: TextStyle(color: Colors.white)),
            ]),
            backgroundColor: const Color(0xFF152D1E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString().toLowerCase();
        String friendly;
        if (msg.contains('bucket not found') || msg.contains('404')) {
          friendly = 'Storage not set up yet. Go to Supabase → Storage and create a public bucket named \'avatars\'';
        } else if (msg.contains('row-level security') || msg.contains('rls')) {
          friendly = 'Upload permission denied. Check Supabase Storage policies for the avatars bucket.';
        } else {
          friendly = 'Failed to upload photo. Please try again.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(child: Text(friendly, style: const TextStyle(color: Colors.white))),
            ]),
            backgroundColor: const Color(0xFF2D1515),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            duration: const Duration(seconds: 6),
          ),
        );
      }
    }
  }

  Future<void> _toggleNotifications(bool val) async {
    final userId = supabase.auth.currentUser!.id;

    if (val) {
      final status = await Permission.notification.request();
      if (status.isGranted) {
        setState(() {
          _notificationSettings ??= {};
          _notificationSettings!['push_enabled'] = true;
        });
        await supabase.from('notification_settings').upsert({
          'user_id': userId,
          'push_enabled': true,
        });
        _fetchData();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enable notifications in device settings')),
          );
        }
      }
    } else {
      setState(() {
        _notificationSettings ??= {};
        _notificationSettings!['push_enabled'] = false;
      });
      await supabase.from('notification_settings').upsert({
        'user_id': userId,
        'push_enabled': false,
      });
      _fetchData();
    }
  }

  void _openContactSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: EdgeInsets.fromLTRB(24.w, 28.h, 24.w, 40.h),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40.w, height: 4.h,
                decoration: BoxDecoration(
                  color: AppColors.border.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            SizedBox(height: 24.h),
            Text('Contact Us', style: GoogleFonts.playfairDisplay(fontSize: 24.sp, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            SizedBox(height: 16.h),
            Text(
              'Have feedback or need help? Reach us at enbridge784@gmail.com',
              style: AppTextStyles.bodyMedium,
            ),
            SizedBox(height: 24.h),
            ElevatedButton(
              onPressed: () async {
                final uri = Uri.parse('mailto:enbridge784@gmail.com');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentGreen,
                foregroundColor: Colors.black,
                minimumSize: Size(double.infinity, 50.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50.r)),
              ),
              child: const Text('Send email', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteAccount() {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        title: const Text('Delete Account', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          'This will permanently delete your account and all data. This cannot be undone.',
          style: TextStyle(color: Color(0xFF888880)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await supabase.from('tasks').delete().eq('user_id', userId);
                await supabase.from('goals').delete().eq('user_id', userId);
                await supabase.from('habits').delete().eq('user_id', userId);
                await supabase.from('profiles').delete().eq('id', userId);
                await supabase.auth.signOut();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting account: $e')));
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Color(0xFFE74C3C))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.bgPrimary,
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Shimmer.fromColors(
              baseColor: const Color(0xFF1A1A1A),
              highlightColor: const Color(0xFF2A2A2A),
              child: Column(
                children: [
                   SizedBox(height: 48.h),
                   Container(width: 100.w, height: 100.w, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white)),
                   SizedBox(height: 16.h),
                   Container(width: 150.w, height: 24.h, color: Colors.white),
                   SizedBox(height: 32.h),
                   Container(width: double.infinity, height: 100.h, color: Colors.white),
                ]
              ),
            ),
          ),
        ),
      );
    }

    final avatarUrl = _profile?['avatar_url'] as String?;
    final name = _profile?['name'] as String? ?? 'User';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';
    final email = supabase.auth.currentUser?.email ?? '';
    final pushEnabled = _notificationSettings?['push_enabled'] == true;

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            children: [
              SizedBox(height: 40.h),
              
              // Avatar with camera overlay
              GestureDetector(
                onTap: _pickAndUploadAvatar,
                child: Stack(
                  children: [
                    Container(
                      width: 120.w,
                      height: 120.w,
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.border, width: 2),
                      ),
                      clipBehavior: Clip.hardEdge,
                      child: avatarUrl != null 
                        ? CachedNetworkImage(imageUrl: avatarUrl, fit: BoxFit.cover)
                        : Center(child: Text(initial, style: GoogleFonts.inter(fontSize: 48.sp, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
                    ),
                    Positioned(
                      bottom: 4.w,
                      right: 4.w,
                      child: Container(
                        width: 30.w,
                        height: 30.w,
                        decoration: const BoxDecoration(
                          color: AppColors.accentGreen,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16.sp),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24.h),
              
              // Name and Email
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(name, style: AppTextStyles.displayHeading.copyWith(fontSize: 28.sp)),
                  SizedBox(width: 8.w),
                  GestureDetector(
                    onTap: _editName,
                    child: Icon(Icons.edit_rounded, color: AppColors.textSecondary, size: 20.sp),
                  ),
                ],
              ),
              SizedBox(height: 4.h),
              Text(email, style: AppTextStyles.bodyMedium),
              SizedBox(height: 40.h),

              // Stats
              Row(
                children: [
                  Expanded(child: _statCol(_formatFocusTime(_totalFocusMinutes), 'Focus')),
                  Container(width: 1, height: 40.h, color: AppColors.border),
                  Expanded(child: _statCol('$_totalTasksDone', 'Tasks')),
                  Container(width: 1, height: 40.h, color: AppColors.border),
                  Expanded(child: _statCol('$_totalGoals', 'Goals')),
                ],
              ),
              SizedBox(height: 48.h),

              // Settings
              Container(
                decoration: BoxDecoration(
                  color: AppColors.bgElevated,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _settingsRow(
                      icon: Icons.notifications_active_outlined,
                      title: 'Push Notifications',
                      trailing: Switch(
                        value: pushEnabled,
                        activeThumbColor: AppColors.accentGreen,
                        onChanged: _toggleNotifications,
                      ),
                    ),
                    Divider(color: AppColors.border, height: 1),
                    _settingsRow(
                      icon: Icons.info_outline_rounded,
                      title: 'About Enbridge',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen())),
                    ),
                    Divider(color: AppColors.border, height: 1),
                    _settingsRow(
                      icon: Icons.privacy_tip_outlined,
                      title: 'Privacy Policy',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen())),
                    ),
                    Divider(color: AppColors.border, height: 1),
                    _settingsRow(
                      icon: Icons.email_outlined,
                      title: 'Contact Us',
                      onTap: _openContactSheet,
                    ),
                    Divider(color: AppColors.border, height: 1),
                    _settingsRow(
                      icon: Icons.delete_outline_rounded,
                      title: 'Delete Account',
                      titleColor: Colors.redAccent,
                      iconColor: Colors.redAccent,
                      onTap: _confirmDeleteAccount,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 40.h),

              ElevatedButton(
                onPressed: () async {
                  await supabase.auth.signOut();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.bgCard,
                  foregroundColor: Colors.redAccent,
                  minimumSize: Size(double.infinity, 56.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50.r), side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.3))),
                ),
                child: Text('Log out', style: AppTextStyles.cardTitle.copyWith(color: Colors.redAccent)),
              ),
              SizedBox(height: 60.h),
            ],
          ),
        ),
      ),
    );
  }

  /// Format total focus minutes: shows "45m", "1h", "1h 30m"
  String _formatFocusTime(int totalMinutes) {
    if (totalMinutes == 0) return '0m';
    if (totalMinutes < 60) return '${totalMinutes}m';
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }

  Widget _statCol(String value, String label) {
    return Column(
      children: [
        Text(value, style: AppTextStyles.displayHeading.copyWith(fontSize: 24.sp)),
        SizedBox(height: 4.h),
        Text(label, style: AppTextStyles.bodySmall),
      ],
    );
  }

  Widget _settingsRow({
    required IconData icon,
    required String title,
    Widget? trailing,
    VoidCallback? onTap,
    Color? titleColor,
    Color? iconColor,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: iconColor ?? AppColors.textPrimary, size: 24.sp),
      title: Text(title, style: AppTextStyles.bodyMedium.copyWith(color: titleColor ?? AppColors.textPrimary)),
      trailing: trailing ?? Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 24.sp),
      contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
    );
  }
}
