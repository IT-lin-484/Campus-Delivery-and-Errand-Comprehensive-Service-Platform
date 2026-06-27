import 'dart:async';

import 'package:flutter/material.dart';

import '../core/models/notification_models.dart';
import '../core/network/chat_socket_client.dart';
import '../state/app_controller.dart';
import 'order_detail_page.dart';
import 'widgets/order_list_view.dart';

class MyOrdersPage extends StatefulWidget {
  const MyOrdersPage({
    super.key,
    required this.controller,
    required this.chatSocketClient,
  });

  final AppController controller;
  final ChatSocketClient chatSocketClient;

  @override
  State<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends State<MyOrdersPage> {
  UnreadNotificationSummary? _summary;

  @override
  void initState() {
    super.initState();
    unawaited(_reloadSummary());
  }

  Future<void> _reloadSummary() async {
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

  @override
  Widget build(BuildContext context) {
    final requesterCount = _summary?.requesterActiveOrderCount ?? 0;
    final runnerCount = _summary?.runnerActiveOrderCount ?? 0;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('我的订单'),
          bottom: TabBar(
            tabs: [
              Tab(
                child: _TabLabelWithBadge(label: '我发布的', count: requesterCount),
              ),
              Tab(
                child: _TabLabelWithBadge(label: '我接取的', count: runnerCount),
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _MyOrderTab(
              controller: widget.controller,
              chatSocketClient: widget.chatSocketClient,
              asRole: 'requester',
              emptyMessage: '你还没有发布过订单',
              emptyHint: '有需要时可以在“发布”页创建新订单。',
              onChanged: _reloadSummary,
            ),
            _MyOrderTab(
              controller: widget.controller,
              chatSocketClient: widget.chatSocketClient,
              asRole: 'runner',
              emptyMessage: '你还没有接取过订单',
              emptyHint: '可以去订单大厅看看有没有合适的订单。',
              onChanged: _reloadSummary,
            ),
          ],
        ),
      ),
    );
  }
}

class _MyOrderTab extends StatelessWidget {
  const _MyOrderTab({
    required this.controller,
    required this.chatSocketClient,
    required this.asRole,
    required this.emptyMessage,
    required this.emptyHint,
    required this.onChanged,
  });

  final AppController controller;
  final ChatSocketClient chatSocketClient;
  final String asRole;
  final String emptyMessage;
  final String emptyHint;
  final Future<void> Function() onChanged;

  @override
  Widget build(BuildContext context) {
    return OrderListView(
      showFilters: false,
      emptyMessage: emptyMessage,
      emptyHint: emptyHint,
      fetchPage:
          ({
            required int page,
            required int pageSize,
            String? keyword,
            String? type,
          }) {
            return controller.api.listMyOrders(
              asRole: asRole,
              keyword: keyword,
              type: type,
              page: page,
              pageSize: pageSize,
            );
          },
      onTapOrder: (order, refresh) async {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => OrderDetailPage(
              controller: controller,
              chatSocketClient: chatSocketClient,
              orderId: order.id,
              onChanged: () {
                refresh();
                unawaited(onChanged());
              },
            ),
          ),
        );
        unawaited(onChanged());
      },
    );
  }
}

class _TabLabelWithBadge extends StatelessWidget {
  const _TabLabelWithBadge({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label),
        if (count > 0) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              count > 99 ? '99+' : '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
