import 'dart:io';

import 'package:flutter/material.dart';

import '../widgets/settings_card.dart';
import '../widgets/settings_row.dart';

class ProfileSection extends StatelessWidget {
  const ProfileSection({
    required this.name,
    required this.dob,
    required this.profileImagePath,
    required this.formatDate,
    required this.onNameEdit,
    required this.onDobPick,
    required this.onImagePick,
  });

  final String name;
  final DateTime dob;
  final String? profileImagePath;
  final String Function(DateTime) formatDate;
  final VoidCallback onNameEdit;
  final VoidCallback onDobPick;
  final VoidCallback onImagePick;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        // Profile Header Card
        SettingsCard(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
            child: Row(
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(40),
                  onTap: onImagePick,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: scheme.primary.withValues(alpha: 0.2),
                        backgroundImage:
                            profileImagePath != null &&
                                profileImagePath!.isNotEmpty
                            ? FileImage(File(profileImagePath!))
                            : null,
                        child:
                            profileImagePath == null ||
                                profileImagePath!.isEmpty
                            ? Text(
                                name.isEmpty ? "?" : name[0].toUpperCase(),
                                style: TextStyle(
                                  color: scheme.primary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 24,
                                ),
                              )
                            : null,
                      ),
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: scheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: scheme.surface, width: 2),
                          ),
                          child: Icon(
                            Icons.edit,
                            size: 13,
                            color: scheme.onPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.isEmpty ? "Your Profile" : name,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "DOB ${formatDate(dob)}",
                        style: TextStyle(
                          fontSize: 14,
                          color: scheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        // Settings rows
        SettingsCard(
          child: Column(
            children: [
              SettingsRow(
                icon: Icons.person_outline,
                title: "Name",
                value: name.isEmpty ? "Not set" : name,
                onTap: onNameEdit,
              ),
              const Divider(height: 1),
              SettingsRow(
                icon: Icons.cake_outlined,
                title: "Date of birth",
                value: formatDate(dob),
                onTap: onDobPick,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
