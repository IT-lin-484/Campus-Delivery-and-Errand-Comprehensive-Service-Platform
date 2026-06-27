import 'package:flutter/material.dart';

import '../../core/config/app_config.dart';

class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    required this.label,
    this.imageUrl,
    this.radius = 24,
    this.backgroundColor,
    this.textStyle,
  });

  final String label;
  final String? imageUrl;
  final double radius;
  final Color? backgroundColor;
  final TextStyle? textStyle;

  static String labelFrom(String primary, [String secondary = '']) {
    final source = primary.trim().isNotEmpty
        ? primary.trim()
        : secondary.trim();
    if (source.isEmpty) {
      return '我';
    }
    return source.substring(0, 1);
  }

  @override
  Widget build(BuildContext context) {
    final resolvedImageUrl = imageUrl?.trim();
    final avatarTextStyle =
        textStyle ??
        Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        );

    return CircleAvatar(
      radius: radius,
      backgroundColor:
          backgroundColor ?? Theme.of(context).colorScheme.primaryContainer,
      foregroundImage: resolvedImageUrl != null && resolvedImageUrl.isNotEmpty
          ? NetworkImage(AppConfig.resolveApiUrl(resolvedImageUrl))
          : null,
      child: Text(label, style: avatarTextStyle),
    );
  }
}
