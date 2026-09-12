// profile_screen.dart — SAFE//SPIT
//
// UI RESKIN: Matches website design language.
// Colors: beige background, black text, acid-green accent, orange for danger.
// Typography: SpaceMono labels, Space Grotesk values.
// Layout: Responsive via LayoutBuilder; 2-column on tablets (>=600px).
//
// NOTE: No logic changes — only UI/styling.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/player_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final playerService = context.watch<PlayerService>();
    final profile = playerService.currentProfile;
    final hPad = responsivePaddingH(context);

    if (profile == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: _buildAppBar(context),
        body: Center(
          child: Text(
            'NO PROFILE DATA',
            style: AppTextStyles.technicalLabel.copyWith(color: AppColors.gray),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final tab = isTablet(context);

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: hPad, vertical: AppSpacing.lg),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: tab ? 700 : double.infinity),
                  child: tab
                      ? _buildTabletLayout(context, profile, playerService)
                      : _buildPhoneLayout(context, profile, playerService),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ── App Bar ─────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final labelSize = responsiveFontSize(context, base: 11, scale: 0.025, max: 13);
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppColors.black.withValues(alpha: 0.15)),
      ),
      title: Text(
        'OPERATOR PROFILE',
        style: AppTextStyles.technicalLabel.copyWith(
          fontSize: labelSize,
          letterSpacing: 3.0,
          color: AppColors.black,
        ),
      ),
      centerTitle: true,
      iconTheme: const IconThemeData(color: AppColors.black),
    );
  }

  // ── Phone layout (single column) ─────────────────────────────────────────

  Widget _buildPhoneLayout(
    BuildContext context,
    dynamic profile,
    PlayerService playerService,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildCallsignHeader(context, profile),
        const SizedBox(height: AppSpacing.lg),
        _buildStatsCard(context, profile),
        const SizedBox(height: AppSpacing.lg),
        _buildActionsColumn(context, playerService),
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }

  // ── Tablet layout (2 columns) ─────────────────────────────────────────────

  Widget _buildTabletLayout(
    BuildContext context,
    dynamic profile,
    PlayerService playerService,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildCallsignHeader(context, profile),
        const SizedBox(height: AppSpacing.lg),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildStatsCard(context, profile)),
            const SizedBox(width: AppSpacing.lg),
            Expanded(child: _buildActionsColumn(context, playerService)),
          ],
        ),
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }

  // ── Callsign header block ─────────────────────────────────────────────────

  Widget _buildCallsignHeader(BuildContext context, dynamic profile) {
    final callsignSize = responsiveFontSize(context, base: 32, scale: 0.09, max: 64);
    final labelSize = responsiveFontSize(context, base: 10, scale: 0.025, max: 12);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        border: AppBorders.heavy,
        color: AppColors.black,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CALLSIGN',
            style: AppTextStyles.technicalMeta.copyWith(
              fontSize: labelSize,
              color: AppColors.gray,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              profile.displayName ?? 'UNKNOWN',
              style: AppTextStyles.heroHeading(fontSize: callsignSize).copyWith(
                color: AppColors.acidGreen,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Stats card ────────────────────────────────────────────────────────────

  Widget _buildStatsCard(BuildContext context, dynamic profile) {
    return Container(
      decoration: BoxDecoration(border: AppBorders.strong),
      child: Column(
        children: [
          _buildStatRow(context, 'GAMES PLAYED', '${profile.gamesPlayed}'),
          const AppDivider(),
          _buildStatRow(context, 'BEST SCORE', '${profile.bestScore.toInt()} PTS'),
          const AppDivider(),
          _buildStatRow(context, 'TOTAL SCORE', '${profile.totalScore.toInt()} PTS'),
        ],
      ),
    );
  }

  Widget _buildStatRow(BuildContext context, String label, String value) {
    final labelSize = responsiveFontSize(context, base: 9, scale: 0.024, max: 11);
    final valSize = responsiveFontSize(context, base: 16, scale: 0.04, max: 22);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.technicalLabel.copyWith(
              fontSize: labelSize,
              color: AppColors.gray,
            ),
          ),
          Text(
            value,
            style: AppTextStyles.technicalValue.copyWith(
              fontSize: valSize,
              color: AppColors.black,
            ),
          ),
        ],
      ),
    );
  }

  // ── Actions column ────────────────────────────────────────────────────────

  Widget _buildActionsColumn(BuildContext context, PlayerService playerService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTacticalButton(
          label: 'CHANGE CALLSIGN',
          filled: false,
          onPressed: () => _showChangeNameDialog(context, playerService),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppTacticalButton(
          label: 'RESET DATA',
          filled: false,
          borderColor: AppColors.orange,
          textColor: AppColors.orange,
          onPressed: () => _confirmReset(context, playerService),
        ),
      ],
    );
  }

  // ── Dialogs ───────────────────────────────────────────────────────────────

  Future<void> _showChangeNameDialog(
      BuildContext context, PlayerService service) async {
    final controller =
        TextEditingController(text: service.currentProfile?.displayName);
    final hPad = responsivePaddingH(context);

    final newName = await showDialog<String>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppColors.background,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        child: Padding(
          padding: EdgeInsets.all(hPad),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'CHANGE CALLSIGN',
                style: AppTextStyles.technicalLabel.copyWith(
                  fontSize: 12,
                  color: AppColors.black,
                  letterSpacing: 3.0,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Container(height: 1, color: AppColors.black.withValues(alpha: 0.15)),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: controller,
                style: AppTextStyles.technicalValue.copyWith(
                  color: AppColors.black,
                  fontSize: 18,
                ),
                textCapitalization: TextCapitalization.characters,
                maxLength: 12,
                cursorColor: AppColors.black,
                decoration: InputDecoration(
                  counterText: '',
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide(
                        color: AppColors.black.withValues(alpha: 0.3)),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide(color: AppColors.black, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'CANCEL',
                      style: AppTextStyles.technicalLabel.copyWith(
                          color: AppColors.gray),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  TextButton(
                    onPressed: () =>
                        Navigator.pop(context, controller.text.trim()),
                    child: Text(
                      'SAVE',
                      style: AppTextStyles.technicalLabel.copyWith(
                        color: AppColors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (newName != null && newName.isNotEmpty) {
      await service.updateDisplayName(newName);
    }
  }

  Future<void> _confirmReset(
      BuildContext context, PlayerService service) async {
    final hPad = responsivePaddingH(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppColors.background,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        child: Padding(
          padding: EdgeInsets.all(hPad),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'RESET DATA?',
                style: AppTextStyles.technicalLabel.copyWith(
                  fontSize: 12,
                  color: AppColors.orange,
                  letterSpacing: 3.0,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Container(height: 1, color: AppColors.orange.withValues(alpha: 0.3)),
              const SizedBox(height: AppSpacing.md),
              Text(
                'This will permanently delete your local stats and profile. Are you sure?',
                style: AppTextStyles.body(fontSize: 14, color: AppColors.black),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(
                      'CANCEL',
                      style: AppTextStyles.technicalLabel.copyWith(
                          color: AppColors.gray),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(
                      'RESET',
                      style: AppTextStyles.technicalLabel.copyWith(
                        color: AppColors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true) {
      await service.resetLocalData();
    }
  }
}
