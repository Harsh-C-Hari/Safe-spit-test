// onboarding_screen.dart — SAFE//SPIT
//
// UI RESKIN: Matches website design language.
// Colors: beige background (#F3F1EA), black (#111111), acid-green (#C7FF3D).
// Typography: Space Grotesk for heading, SpaceMono for input/labels.
// Layout: Fully responsive via LayoutBuilder + MediaQuery.
//
// NOTE: No logic changes — only UI/styling.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/player_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() async {
    final name = _controller.text.trim();
    if (name.isEmpty) return;

    final playerService = context.read<PlayerService>();
    await playerService.completeOnboarding(name);
    // Router will handle the rest
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final hPad = responsivePaddingH(context);
    final isLand = isLandscape(context);
    final isTab = isTablet(context);

    // Responsive sizes
    final labelSize = responsiveFontSize(context, base: 10, scale: 0.025, max: 13);
    final headingSize = responsiveFontSize(context, base: 28, scale: 0.07, max: 52);
    final inputFontSize = responsiveFontSize(context, base: 20, scale: 0.05, max: 32);

    final contentMaxWidth = isTab ? 500.0 : double.infinity;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: hPad,
                      vertical: isLand ? AppSpacing.md : AppSpacing.xl,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // ── Top label ──────────────────────────────────
                        Center(
                          child: Text(
                            'SAFE//SPIT',
                            style: AppTextStyles.technicalLabel.copyWith(
                              fontSize: labelSize,
                              letterSpacing: 4.0,
                              color: AppColors.gray,
                            ),
                          ),
                        ),
                        SizedBox(height: isLand ? AppSpacing.md : AppSpacing.xxl),

                        // ── Heading ────────────────────────────────────
                        Center(
                          child: Container(
                            constraints: BoxConstraints(maxWidth: contentMaxWidth),
                            child: Text(
                              'ENTER\nCALLSIGN',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.heroHeading(fontSize: headingSize),
                            ),
                          ),
                        ),
                        SizedBox(height: isLand ? AppSpacing.md : AppSpacing.lg),

                        // ── Divider ────────────────────────────────────
                        Center(
                          child: SizedBox(
                            width: (contentMaxWidth == double.infinity)
                                ? size.width * 0.5
                                : contentMaxWidth * 0.5,
                            child: const AppDivider(),
                          ),
                        ),
                        SizedBox(height: isLand ? AppSpacing.md : AppSpacing.lg),

                        // ── Input field ────────────────────────────────
                        Center(
                          child: Container(
                            constraints: BoxConstraints(maxWidth: contentMaxWidth),
                            child: TextField(
                              controller: _controller,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.technicalValue.copyWith(
                                fontSize: inputFontSize,
                                letterSpacing: 4.0,
                                color: AppColors.black,
                              ),
                              maxLength: 12,
                              textCapitalization: TextCapitalization.characters,
                              cursorColor: AppColors.black,
                              decoration: InputDecoration(
                                counterText: '',
                                hintText: 'ALPHA_01',
                                hintStyle: AppTextStyles.technicalLabel.copyWith(
                                  fontSize: inputFontSize * 0.7,
                                  color: AppColors.lightGray,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.zero,
                                  borderSide: BorderSide(
                                    color: AppColors.black.withValues(alpha: 0.3),
                                  ),
                                ),
                                focusedBorder: const OutlineInputBorder(
                                  borderRadius: BorderRadius.zero,
                                  borderSide: BorderSide(color: AppColors.black, width: 2),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 18),
                              ),
                              onSubmitted: (_) => _submit(),
                            ),
                          ),
                        ),
                        SizedBox(height: isLand ? AppSpacing.md : AppSpacing.lg),

                        // ── Submit button ──────────────────────────────
                        Center(
                          child: Container(
                            constraints: BoxConstraints(maxWidth: contentMaxWidth),
                            child: AppTacticalButton(
                              label: 'CONFIRM',
                              onPressed: _submit,
                            ),
                          ),
                        ),
                        SizedBox(height: isLand ? AppSpacing.md : AppSpacing.lg),

                        // ── Footer label ───────────────────────────────
                        Center(
                          child: Text(
                            'TACTICAL TRAJECTORY SYSTEM',
                            style: AppTextStyles.technicalMeta.copyWith(
                              color: AppColors.lightGray,
                              letterSpacing: 2.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
