import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/models/order_models.dart';

class OrderSummaryCard extends StatelessWidget {
  const OrderSummaryCard({
    super.key,
    required this.order,
    required this.onTap,
    this.showStatus = true,
  });

  final OrderSummary order;
  final VoidCallback onTap;
  final bool showStatus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final avatarUrl = order.requesterAvatarUrl?.trim();
    final hasAvatar = avatarUrl != null && avatarUrl.isNotEmpty;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _Tag(
                    text: orderTypeLabel(order.type),
                    color: const Color(0xFF0F766E),
                    backgroundColor: const Color(0xFFE6FFFB),
                  ),
                  if (showStatus) ...[
                    const SizedBox(width: 8),
                    _Tag(
                      text: orderStatusLabel(order.status),
                      color: _statusColor(order.status),
                      backgroundColor: _statusBackgroundColor(order.status),
                    ),
                  ],
                  const Spacer(),
                  Text(
                    '¥${order.rewardAmount}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF111827),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _RouteLine(
                icon: Icons.radio_button_checked_rounded,
                color: const Color(0xFF0F766E),
                label: '取件',
                value: order.pickupLocation,
              ),
              const SizedBox(height: 10),
              _RouteLine(
                icon: Icons.location_on_rounded,
                color: const Color(0xFFEA580C),
                label: '送达',
                value: order.dropoffLocation,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: const Color(0xFFE2E8F0),
                    backgroundImage: hasAvatar ? NetworkImage(avatarUrl) : null,
                    child: !hasAvatar
                        ? Text(
                            order.requesterDisplayName.substring(0, 1),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF334155),
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '发布者  ${order.requesterDisplayName}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _InfoPill(
                icon: Icons.schedule_outlined,
                text: '期望 ${_formatDateTime(order.expectedTime)}',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RouteLine extends StatelessWidget {
  const _RouteLine({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        SizedBox(
          width: 34,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({
    required this.text,
    required this.color,
    required this.backgroundColor,
  });

  final String text;
  final Color color;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(color: Colors.grey.shade700)),
        ],
      ),
    );
  }
}

Color _statusColor(String status) {
  switch (status) {
    case 'OPEN':
      return const Color(0xFF2563EB);
    case 'ACCEPTED':
      return const Color(0xFFD97706);
    case 'IN_PROGRESS':
      return const Color(0xFF0F766E);
    case 'DELIVERED':
      return const Color(0xFF7C3AED);
    case 'COMPLETED':
      return const Color(0xFF16A34A);
    case 'CANCELLED':
      return const Color(0xFFDC2626);
    case 'EXPIRED':
      return const Color(0xFF6B7280);
    default:
      return const Color(0xFF2563EB);
  }
}

Color _statusBackgroundColor(String status) {
  switch (status) {
    case 'OPEN':
      return const Color(0xFFEFF6FF);
    case 'ACCEPTED':
      return const Color(0xFFFFF7ED);
    case 'IN_PROGRESS':
      return const Color(0xFFECFEFF);
    case 'DELIVERED':
      return const Color(0xFFF5F3FF);
    case 'COMPLETED':
      return const Color(0xFFF0FDF4);
    case 'CANCELLED':
      return const Color(0xFFFEF2F2);
    case 'EXPIRED':
      return const Color(0xFFF3F4F6);
    default:
      return const Color(0xFFEFF6FF);
  }
}

String _formatDateTime(DateTime? value) {
  if (value == null) {
    return '待定';
  }
  return DateFormat('MM-dd HH:mm').format(value.toLocal());
}
