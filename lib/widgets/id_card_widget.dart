import 'package:flutter/material.dart';
import '../models/student.dart';
import '../constants.dart';
import '../theme/app_colors.dart';
import '../theme/app_fonts.dart';

class IDCardWidget extends StatelessWidget {
  final Student student;

  const IDCardWidget({
    Key? key,
    required this.student,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.586, // Standard ID Card ratio (85.6mm x 53.98mm)
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.gold, width: 1.5),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1E1E24),
              Color(0xFF0F0F12),
            ],
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black87,
              blurRadius: 10,
              offset: Offset(0, 4),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Stack(
            children: [
              // Background Poster Image overlay with opacity
              Positioned.fill(
                child: Opacity(
                  opacity: 0.15,
                  child: Image.asset(
                    AppConstants.posterAsset,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(color: AppColors.background),
                  ),
                ),
              ),

              // Content Layer
              Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Bar with Studio Logo & Name
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.gold,
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              AppConstants.logoAsset,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.music_note, color: Colors.black, size: 18),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppConstants.appName.toUpperCase(),
                              style: AppFonts.displayHeader(fontSize: 13, color: AppColors.gold),
                            ),
                            Text(
                              AppConstants.appTagline,
                              style: AppFonts.subtitleText(fontSize: 8, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.gold.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.gold, width: 0.8),
                          ),
                          child: Text(
                            'STUDENT ID',
                            style: AppFonts.subtitleText(color: AppColors.gold, fontWeight: FontWeight.bold, fontSize: 8),
                          ),
                        ),
                      ],
                    ),

                    const Divider(color: AppColors.borderGold, height: 16),

                    // Body Section: Photo / Avatar + Student Info
                    Expanded(
                      child: Row(
                        children: [
                          // Student Avatar / Photo Box
                          Container(
                            width: 65,
                            height: 75,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceLight,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.gold, width: 1),
                            ),
                            child: student.photoPath != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(7),
                                    child: Image.network(
                                      student.photoPath!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(Icons.person, color: AppColors.gold, size: 36),
                                    ),
                                  )
                                : const Icon(Icons.person, color: AppColors.gold, size: 36),
                          ),
                          const SizedBox(width: 12),

                          // Info Text
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  student.name,
                                  style: AppFonts.titleHeader(fontSize: 16, color: AppColors.ivory),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "ID: JDA-2026-${(student.id ?? 0).toString().padLeft(3, '0')}",
                                  style: AppFonts.numberText(fontSize: 11, color: AppColors.gold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Batch: ${student.batchTiming}",
                                  style: AppFonts.subtitleText(fontSize: 9, color: AppColors.textPrimary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "Styles: ${student.danceStyles.join(', ')}",
                                  style: AppFonts.subtitleText(fontSize: 9, color: AppColors.textSecondary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),

                          // Mini QR Code Mockup
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.qr_code_2,
                              color: Colors.black,
                              size: 40,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
