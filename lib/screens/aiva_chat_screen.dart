import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:enbridge/theme/app_theme.dart';
import 'package:enbridge/core/providers/aiva_provider.dart';
import 'package:enbridge/widgets/aiva_logo_avatar.dart';

class AivaChatScreen extends ConsumerStatefulWidget {
  final String topic;
  const AivaChatScreen({super.key, required this.topic});

  @override
  ConsumerState<AivaChatScreen> createState() => _AivaChatScreenState();
}

class _AivaChatScreenState extends ConsumerState<AivaChatScreen> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Greet the user when the session opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chat = ref.read(aivaChatProvider);
      if (chat.messages.isEmpty) {
        ref
            .read(aivaChatProvider.notifier)
            .sendMessage(
              'Hello! I just started a session on: "${widget.topic}". '
              'Please greet me as AIVA and help me get started.',
            );
      }
    });
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _send() {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;
    _inputCtrl.clear();
    ref.read(aivaChatProvider.notifier).sendMessage(text);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(aivaChatProvider);

    // Auto-scroll when new messages arrive
    ref.listen(aivaChatProvider, (_, next) {
      if (!next.isTyping) _scrollToBottom();
    });

    // Navigate when AIVA triggers a tab change (e.g. starting focus timer)
    ref.listen(aivaChatProvider.select((s) => s.navigateTo), (_, route) {
      if (route != null) {
        ref.read(aivaChatProvider.notifier).clearNavigate();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) context.go(route);
        });
      }
    });

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Background radial glow
          Positioned(
            top: -100,
            right: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.aivaBlue.withValues(alpha: 0.06),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          Column(
            children: [
              // ── Header ────────────────────────────────────────────────────
              _ChatHeader(topic: widget.topic),

              // ── Messages ──────────────────────────────────────────────────
              Expanded(
                child: chatState.messages.isEmpty && !chatState.isTyping
                    ? _EmptyState()
                    : ListView.builder(
                        controller: _scrollCtrl,
                        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
                        itemCount:
                            chatState.messages.length +
                            (chatState.isTyping ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == chatState.messages.length) {
                            return const _TypingIndicator();
                          }
                          final msg = chatState.messages[index];
                          return _MessageBubble(message: msg);
                        },
                      ),
              ),

              // ── Error banner ──────────────────────────────────────────────
              if (chatState.error != null)
                _ErrorBanner(
                  message: chatState.error!,
                  onDismiss: () =>
                      ref.read(aivaChatProvider.notifier).clearError(),
                ),

              // ── Input bar ─────────────────────────────────────────────────
              _InputBar(
                controller: _inputCtrl,
                focusNode: _focusNode,
                isTyping: chatState.isTyping,
                onSend: _send,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _ChatHeader extends StatelessWidget {
  final String topic;
  const _ChatHeader({required this.topic});

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: AppColors.border, width: 1),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 10.h),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: AppColors.textSecondary,
                      size: 18,
                    ),
                  ),
                  AIVALogoAvatar(size: 36.w),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [
                              AppColors.aivaGradStart,
                              AppColors.aivaGradEnd,
                            ],
                          ).createShader(bounds),
                          child: Text(
                            'AIVA',
                            style: GoogleFonts.inter(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Text(
                          topic,
                          style: AppTextStyles.bodySmall.copyWith(
                            fontSize: 11.sp,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Live indicator
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.aivaBlue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: AppColors.aivaBlueMid.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      'LIVE',
                      style: AppTextStyles.labelEyebrow.copyWith(
                        fontSize: 9.sp,
                        color: AppColors.aivaBlueMid,
                      ),
                    ),
                  ),
                  SizedBox(width: 8.w),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Message bubble ────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        mainAxisAlignment: message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (message.isSystem) ...[
            _SystemMessage(text: message.text),
          ] else ...[
            if (!message.isUser) ...[
              AIVALogoAvatar(size: 28.w),
              SizedBox(width: 8.w),
            ],
            Flexible(
              child: message.isUser
                  ? _UserBubble(text: message.text)
                  : _AivaBubble(text: message.text),
            ),
          ],
          if (message.isUser) SizedBox(width: 4.w),
        ],
      ),
    );
  }
}

class _SystemMessage extends StatelessWidget {
  final String text;
  const _SystemMessage({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: AppColors.accentGreen.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: AppColors.accentGreen.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle_outline_rounded,
                size: 13.sp,
                color: AppColors.accentGreen,
              ),
              SizedBox(width: 6.w),
              Flexible(
                child: Text(
                  text,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontSize: 11.sp,
                    color: AppColors.accentGreen,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AivaBubble extends StatelessWidget {
  final String text;
  const _AivaBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(18.r),
        topRight: Radius.circular(18.r),
        bottomRight: Radius.circular(18.r),
        bottomLeft: Radius.circular(4.r),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: AppColors.aivaBlue.withValues(alpha: 0.08),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(18.r),
              topRight: Radius.circular(18.r),
              bottomRight: Radius.circular(18.r),
              bottomLeft: Radius.circular(4.r),
            ),
            border: Border.all(
              color: AppColors.aivaBlueMid.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Text(
            text,
            style: AppTextStyles.bodySmall.copyWith(
              fontSize: 13.sp,
              color: AppColors.textPrimary,
              height: 1.55,
            ),
          ),
        ),
      ),
    );
  }
}

class _UserBubble extends StatelessWidget {
  final String text;
  const _UserBubble({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.accentGreen.withValues(alpha: 0.15),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(18.r),
          topRight: Radius.circular(18.r),
          bottomLeft: Radius.circular(18.r),
          bottomRight: Radius.circular(4.r),
        ),
        border: Border.all(
          color: AppColors.accentGreen.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: AppTextStyles.bodySmall.copyWith(
          fontSize: 13.sp,
          color: AppColors.textPrimary,
          height: 1.55,
        ),
      ),
    );
  }
}

// ── Typing indicator ──────────────────────────────────────────────────────────

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          AIVALogoAvatar(size: 28.w),
          SizedBox(width: 8.w),
          ClipRRect(
            borderRadius: BorderRadius.circular(18.r),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                decoration: BoxDecoration(
                  color: AppColors.aivaBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(18.r),
                  border: Border.all(
                    color: AppColors.aivaBlueMid.withValues(alpha: 0.25),
                  ),
                ),
                child: AnimatedBuilder(
                  animation: _ctrl,
                  builder: (_, _) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(3, (i) {
                      final delay = i / 3;
                      final t = (_ctrl.value - delay).clamp(0.0, 1.0);
                      final opacity =
                          0.3 +
                          0.7 * (t < 0.5 ? t * 2 : (1 - t) * 2).clamp(0.0, 1.0);
                      return Padding(
                        padding: EdgeInsets.symmetric(horizontal: 3.w),
                        child: Opacity(
                          opacity: opacity,
                          child: Container(
                            width: 6.w,
                            height: 6.w,
                            decoration: const BoxDecoration(
                              color: AppColors.aivaBlueMid,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Input bar ─────────────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isTyping;
  final VoidCallback onSend;

  const _InputBar({
    required this.controller,
    required this.focusNode,
    required this.isTyping,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.border, width: 1)),
          ),
          padding: EdgeInsets.fromLTRB(
            16.w,
            10.h,
            16.w,
            MediaQuery.of(context).padding.bottom + 10.h,
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(24.r),
                    border: Border.all(color: AppColors.borderMid),
                  ),
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    enabled: !isTyping,
                    style: AppTextStyles.inputText.copyWith(fontSize: 14.sp),
                    maxLines: 4,
                    minLines: 1,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => onSend(),
                    decoration: InputDecoration(
                      hintText: isTyping
                          ? 'AIVA is thinking…'
                          : 'Ask AIVA anything…',
                      hintStyle: AppTextStyles.inputHint.copyWith(
                        fontSize: 14.sp,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 12.h,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              GestureDetector(
                onTap: isTyping ? null : onSend,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 44.w,
                  height: 44.w,
                  decoration: BoxDecoration(
                    gradient: isTyping
                        ? null
                        : const LinearGradient(
                            colors: [
                              AppColors.aivaGradStart,
                              AppColors.aivaGradEnd,
                            ],
                          ),
                    color: isTyping ? AppColors.bgElevated : null,
                    shape: BoxShape.circle,
                    boxShadow: isTyping
                        ? null
                        : [
                            BoxShadow(
                              color: AppColors.aivaBlue.withValues(alpha: 0.4),
                              blurRadius: 12,
                            ),
                          ],
                  ),
                  child: Icon(
                    isTyping
                        ? Icons.hourglass_empty_rounded
                        : Icons.arrow_upward_rounded,
                    color: isTyping ? AppColors.textTertiary : Colors.white,
                    size: 20.sp,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AIVALogoAvatar(size: 80.w),
          SizedBox(height: 20.h),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [AppColors.aivaGradStart, AppColors.aivaGradEnd],
            ).createShader(bounds),
            child: Text(
              'AIVA',
              style: GoogleFonts.playfairDisplay(
                fontSize: 28.sp,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Your AI productivity companion',
            style: AppTextStyles.bodySmall.copyWith(fontSize: 13.sp),
          ),
        ],
      ),
    );
  }
}

// ── Error banner ──────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;

  const _ErrorBanner({required this.message, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: AppColors.accentRed.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.accentRed.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: AppColors.accentRed,
            size: 16.sp,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.accentRed,
                fontSize: 12.sp,
              ),
            ),
          ),
          GestureDetector(
            onTap: onDismiss,
            child: Icon(
              Icons.close_rounded,
              color: AppColors.accentRed,
              size: 16.sp,
            ),
          ),
        ],
      ),
    );
  }
}
