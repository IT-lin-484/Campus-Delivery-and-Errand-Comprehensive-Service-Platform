import 'package:flutter/material.dart';

import '../core/models/notification_models.dart';
import '../core/network/chat_socket_client.dart';
import '../state/app_controller.dart';
import 'friend_list_page.dart';
import 'my_orders_page.dart';
import 'profile_edit_page.dart';
import 'widgets/app_avatar.dart';
import 'widgets/logout_confirm_dialog.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({
    super.key,
    required this.controller,
    required this.chatSocketClient,
    required this.summary,
    required this.onRefreshSummary,
  });

  final AppController controller;
  final ChatSocketClient chatSocketClient;
  final UnreadNotificationSummary? summary;
  final Future<void> Function() onRefreshSummary;

  @override
  Widget build(BuildContext context) {
    final user = controller.currentUser;
    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final myOrderNoticeCount = summary?.myOrderNoticeCount ?? 0;
    final friendRequestUnreadCount = summary?.friendRequestUnreadCount ?? 0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F766E), Color(0xFF115E59)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    AppAvatar(
                      radius: 32,
                      label: AppAvatar.labelFrom(user.nickname, user.username),
                      imageUrl: user.avatarUrl,
                      backgroundColor: Colors.white.withAlpha(40),
                      textStyle: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.nickname,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '@${user.username}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    FilledButton.tonal(
                      onPressed: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                ProfileEditPage(controller: controller),
                          ),
                        );
                        await onRefreshSummary();
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF115E59),
                      ),
                      child: const Text('编辑资料'),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _HeaderStatCard(
                        label: '订单提醒',
                        value: myOrderNoticeCount,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _HeaderStatCard(
                        label: '好友申请',
                        value: friendRequestUnreadCount,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        _MenuCard(
          children: [
            _MenuTile(
              icon: Icons.person_outline_rounded,
              title: '账号资料',
              subtitle: '头像、用户名、手机号与个人简介',
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ProfileEditPage(controller: controller),
                  ),
                );
                await onRefreshSummary();
              },
            ),
            const Divider(height: 1),
            _MenuTile(
              icon: Icons.receipt_long_outlined,
              title: '我的订单',
              subtitle: '查看我发布的和我接取的订单',
              badgeCount: myOrderNoticeCount,
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => MyOrdersPage(
                      controller: controller,
                      chatSocketClient: chatSocketClient,
                    ),
                  ),
                );
                await onRefreshSummary();
              },
            ),
            const Divider(height: 1),
            _MenuTile(
              icon: Icons.people_outline_rounded,
              title: '我的好友',
              subtitle: '查看好友、好友申请与聊天入口',
              badgeCount: friendRequestUnreadCount,
              onTap: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => FriendListPage(
                      controller: controller,
                      chatSocketClient: chatSocketClient,
                    ),
                  ),
                );
                await onRefreshSummary();
              },
            ),
          ],
        ),
        const SizedBox(height: 18),
        OutlinedButton.icon(
          onPressed: () async {
            final confirmed = await showLogoutConfirmDialog(context);
            if (!confirmed) {
              return;
            }
            await controller.logout();
          },
          icon: const Icon(Icons.logout_rounded),
          label: const Text('退出登录'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ],
    );
  }
}

class _HeaderStatCard extends StatelessWidget {
  const _HeaderStatCard({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(24),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Text(
            value > 99 ? '99+' : '$value',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  const _MenuCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(child: Column(children: children));
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badgeCount = 0,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: Theme.of(context).colorScheme.primary),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          if (badgeCount > 0) _CountBadge(count: badgeCount),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(subtitle),
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
