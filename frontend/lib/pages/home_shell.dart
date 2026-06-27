import 'dart:async';

import 'package:flutter/material.dart';

import '../core/models/notification_models.dart';
import '../core/network/chat_socket_client.dart';
import '../state/app_controller.dart';
import 'chat_overview_page.dart';
import 'create_order_page.dart';
import 'orders_page.dart';
import 'profile_page.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    required this.controller,
    required this.chatSocketClient,
  });

  final AppController controller;
  final ChatSocketClient chatSocketClient;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with WidgetsBindingObserver {
  int _currentIndex = 0;
  final GlobalKey<OrdersPageState> _ordersPageKey =
      GlobalKey<OrdersPageState>();
  Timer? _summaryTimer;
  UnreadNotificationSummary? _summary;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_refreshSummary());
    _summaryTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      unawaited(_refreshSummary());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _summaryTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_refreshSummary());
    }
  }

  Future<void> _refreshSummary() async {
    try {
      final summary = await widget.controller.api
          .getUnreadNotificationSummary();
      if (!mounted) {
        return;
      }
      setState(() {
        _summary = summary;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _summary = null;
      });
    }
  }

  void _selectIndex(int index) {
    setState(() {
      _currentIndex = index;
    });
    unawaited(_refreshSummary());
  }

  @override
  Widget build(BuildContext context) {
    const titles = ['订单大厅', '消息', '发布订单', '我的'];
    final chatUnread = _summary?.chatUnreadCount ?? 0;
    final myPageNoticeCount = _summary?.myPageNoticeCount ?? 0;

    return Scaffold(
      appBar: AppBar(title: Text(titles[_currentIndex])),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          OrdersPage(
            key: _ordersPageKey,
            controller: widget.controller,
            chatSocketClient: widget.chatSocketClient,
          ),
          ChatOverviewPage(
            controller: widget.controller,
            chatSocketClient: widget.chatSocketClient,
          ),
          CreateOrderPage(
            controller: widget.controller,
            onCreated: () {
              _ordersPageKey.currentState?.refresh();
              _selectIndex(0);
            },
          ),
          ProfilePage(
            controller: widget.controller,
            chatSocketClient: widget.chatSocketClient,
            summary: _summary,
            onRefreshSummary: _refreshSummary,
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _selectIndex,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.grid_view_rounded),
            selectedIcon: Icon(Icons.grid_view),
            label: '订单',
          ),
          NavigationDestination(
            icon: _NavIconWithBadge(
              icon: Icons.chat_bubble_outline_rounded,
              count: chatUnread,
            ),
            selectedIcon: _NavIconWithBadge(
              icon: Icons.chat_bubble_rounded,
              count: chatUnread,
            ),
            label: '消息',
          ),
          const NavigationDestination(
            icon: Icon(Icons.add_circle_outline_rounded),
            selectedIcon: Icon(Icons.add_circle_rounded),
            label: '发布',
          ),
          NavigationDestination(
            icon: _NavIconWithBadge(
              icon: Icons.person_outline_rounded,
              count: myPageNoticeCount,
            ),
            selectedIcon: _NavIconWithBadge(
              icon: Icons.person_rounded,
              count: myPageNoticeCount,
            ),
            label: '我的',
          ),
        ],
      ),
    );
  }
}

class _NavIconWithBadge extends StatelessWidget {
  const _NavIconWithBadge({required this.icon, required this.count});

  final IconData icon;
  final int count;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) {
      return Icon(icon);
    }

    return Badge(label: Text(count > 99 ? '99+' : '$count'), child: Icon(icon));
  }
}
