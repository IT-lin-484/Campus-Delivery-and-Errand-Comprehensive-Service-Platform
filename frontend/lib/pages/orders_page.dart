import 'package:flutter/material.dart';

import '../core/network/chat_socket_client.dart';
import '../state/app_controller.dart';
import 'order_detail_page.dart';
import 'widgets/order_list_view.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({
    super.key,
    required this.controller,
    required this.chatSocketClient,
  });

  final AppController controller;
  final ChatSocketClient chatSocketClient;

  @override
  State<OrdersPage> createState() => OrdersPageState();
}

class OrdersPageState extends State<OrdersPage> {
  int _refreshToken = 0;

  void refresh() {
    setState(() {
      _refreshToken++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return OrderListView(
      key: ValueKey(_refreshToken),
      emptyMessage: '暂时没有可接订单',
      emptyHint: '可以换个关键词搜索，或者稍后再来看看。',
      fetchPage:
          ({
            required int page,
            required int pageSize,
            String? keyword,
            String? type,
          }) {
            return widget.controller.api.listOrders(
              status: 'OPEN',
              type: type,
              keyword: keyword,
              page: page,
              pageSize: pageSize,
            );
          },
      onTapOrder: (order, refresh) async {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => OrderDetailPage(
              controller: widget.controller,
              chatSocketClient: widget.chatSocketClient,
              orderId: order.id,
              onChanged: refresh,
            ),
          ),
        );
      },
    );
  }
}
