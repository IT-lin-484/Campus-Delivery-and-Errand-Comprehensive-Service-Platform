import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/models/order_models.dart';
import '../core/network/api_exception.dart';
import '../core/network/chat_socket_client.dart';
import '../state/app_controller.dart';
import 'chat_page.dart';
import 'edit_order_page.dart';

class OrderDetailPage extends StatefulWidget {
  const OrderDetailPage({
    super.key,
    required this.controller,
    required this.chatSocketClient,
    required this.orderId,
    this.onChanged,
  });

  final AppController controller;
  final ChatSocketClient chatSocketClient;
  final int orderId;
  final VoidCallback? onChanged;

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  late Future<OrderDetail> _future;
  bool _submitting = false;
  bool _openingChat = false;

  @override
  void initState() {
    super.initState();
    _future = widget.controller.api.getOrder(widget.orderId);
  }

  Future<void> _reload({bool notifyParent = false}) async {
    setState(() {
      _future = widget.controller.api.getOrder(widget.orderId);
    });
    await _future;
    if (notifyParent) {
      widget.onChanged?.call();
    }
  }

  Future<void> _runAction(
    Future<void> Function() action, {
    required String successMessage,
    bool notifyParent = true,
  }) async {
    if (_submitting) {
      return;
    }

    setState(() {
      _submitting = true;
    });

    try {
      await action();
      await _reload(notifyParent: notifyParent);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(successMessage)));
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('操作失败，请稍后重试')));
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  Future<void> _acceptOrder() async {
    await _runAction(() async {
      await widget.controller.api.acceptOrder(widget.orderId);
    }, successMessage: '接单成功');
  }

  Future<void> _confirmOrder() async {
    await _runAction(() async {
      await widget.controller.api.confirmOrder(widget.orderId);
    }, successMessage: '订单已确认完成');
  }

  Future<void> _updateRunnerStatus(
    String toStatus,
    String successMessage,
  ) async {
    await _runAction(() async {
      await widget.controller.api.updateOrderStatus(
        id: widget.orderId,
        request: UpdateOrderStatusRequest(toStatus: toStatus),
      );
    }, successMessage: successMessage);
  }

  Future<void> _cancelOrder() async {
    final reason = await _showTextInputDialog(
      title: '取消订单',
      hintText: '可以填写取消原因，留空也可以提交',
      confirmText: '确认取消',
    );
    if (reason == null) {
      return;
    }

    await _runAction(() async {
      await widget.controller.api.cancelOrder(
        id: widget.orderId,
        reason: reason.trim().isEmpty ? null : reason.trim(),
      );
    }, successMessage: '订单已取消');
  }

  Future<void> _editOrder(OrderDetail order) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            EditOrderPage(controller: widget.controller, order: order),
      ),
    );
    if (changed == true) {
      await _reload(notifyParent: true);
    }
  }

  Future<void> _reportOrder() async {
    final payload = await _showReportDialog();
    if (payload == null) {
      return;
    }

    await _runAction(
      () async {
        await widget.controller.api.createOrderReport(
          orderId: widget.orderId,
          category: payload.category,
          description: payload.description,
        );
      },
      successMessage: '举报已提交',
      notifyParent: false,
    );
  }

  Future<void> _openChat(OrderDetail order) async {
    final targetUserId = _resolveChatTargetUserId(order);
    if (targetUserId == null || _openingChat) {
      return;
    }

    setState(() {
      _openingChat = true;
    });

    try {
      final conversation = await widget.controller.api
          .createPrivateConversation(friendId: targetUserId, orderId: order.id);
      if (!mounted) {
        return;
      }
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatPage(
            controller: widget.controller,
            chatSocketClient: widget.chatSocketClient,
            conversation: conversation,
          ),
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('打开聊天失败，请稍后重试')));
    } finally {
      if (mounted) {
        setState(() {
          _openingChat = false;
        });
      }
    }
  }

  int? _resolveChatTargetUserId(OrderDetail order) {
    final currentUserId = widget.controller.currentUser?.id;
    if (currentUserId == null) {
      return null;
    }
    if (currentUserId == order.requesterId) {
      return order.runnerId;
    }
    if (currentUserId == order.runnerId) {
      return order.requesterId;
    }
    if (order.status == 'OPEN') {
      return order.requesterId;
    }
    return null;
  }

  Future<String?> _showTextInputDialog({
    required String title,
    required String hintText,
    required String confirmText,
  }) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            maxLength: 200,
            maxLines: 3,
            decoration: InputDecoration(hintText: hintText),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('返回'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: Text(confirmText),
            ),
          ],
        );
      },
    );
  }

  Future<_ReportPayload?> _showReportDialog() {
    final descriptionController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String category = '订单问题';

    return showDialog<_ReportPayload>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('提交举报'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: category,
                        decoration: const InputDecoration(labelText: '举报分类'),
                        items: const [
                          DropdownMenuItem(value: '订单问题', child: Text('订单问题')),
                          DropdownMenuItem(
                            value: '超时未送达',
                            child: Text('超时未送达'),
                          ),
                          DropdownMenuItem(value: '态度恶劣', child: Text('态度恶劣')),
                          DropdownMenuItem(value: '其他', child: Text('其他')),
                        ],
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          setState(() {
                            category = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: descriptionController,
                        maxLength: 500,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: '详细说明',
                          hintText: '请简要描述遇到的问题',
                        ),
                        validator: (value) {
                          final text = value?.trim() ?? '';
                          if (text.isEmpty) {
                            return '请填写详细说明';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: () {
                    if (formKey.currentState?.validate() != true) {
                      return;
                    }
                    Navigator.of(context).pop(
                      _ReportPayload(
                        category: category,
                        description: descriptionController.text.trim(),
                      ),
                    );
                  },
                  child: const Text('提交'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _previewImage(String url) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.black,
          insetPadding: const EdgeInsets.all(12),
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: InteractiveViewer(
              child: Image.network(
                url,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox(
                  height: 240,
                  child: Center(
                    child: Text(
                      '图片加载失败',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('订单详情')),
      body: FutureBuilder<OrderDetail>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ErrorState(
              message: snapshot.error?.toString() ?? '加载失败，请稍后重试',
              onRetry: _reload,
            );
          }

          final order = snapshot.data;
          if (order == null) {
            return _ErrorState(message: '订单不存在', onRetry: _reload);
          }

          final currentUserId = widget.controller.currentUser?.id;
          final isRequester =
              currentUserId != null && order.requesterId == currentUserId;
          final isRunner =
              currentUserId != null && order.runnerId == currentUserId;
          final isParticipant = isRequester || isRunner;
          final canAccept =
              currentUserId != null && !isRequester && order.status == 'OPEN';
          final canEdit = isRequester && order.status == 'OPEN';
          final canCancel =
              (isRequester || isRunner) &&
              !const [
                'CANCELLED',
                'COMPLETED',
                'EXPIRED',
              ].contains(order.status);
          final canStart = isRunner && order.status == 'ACCEPTED';
          final canFinish = isRunner && order.status == 'IN_PROGRESS';
          final canConfirm = isRequester && order.status == 'DELIVERED';
          final canReport = isParticipant && order.status != 'OPEN';
          final canChat = _resolveChatTargetUserId(order) != null;
          final hasActions =
              canAccept ||
              canChat ||
              canEdit ||
              canCancel ||
              canStart ||
              canFinish ||
              canConfirm ||
              canReport;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _Tag(
                            text: orderTypeLabel(order.type),
                            color: const Color(0xFF2563EB),
                          ),
                          _Tag(
                            text: orderStatusLabel(order.status),
                            color: _statusColor(order.status),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${order.pickupLocation} -> ${order.dropoffLocation}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _DetailRow(
                        label: '发布者',
                        value: order.requesterDisplayName,
                      ),
                      _DetailRow(label: '赏金', value: '¥${order.rewardAmount}'),
                      _DetailRow(
                        label: '期望时间',
                        value: _formatDateTime(order.expectedTime),
                      ),
                      _DetailRow(
                        label: '联系形式',
                        value: _buildContactValue(order),
                      ),
                      _DetailRow(
                        label: '备注',
                        value: (order.remark?.trim().isNotEmpty ?? false)
                            ? order.remark!
                            : '暂无备注',
                      ),
                      if (hasActions) ...[
                        const SizedBox(height: 12),
                        Divider(color: Colors.grey.shade200),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            if (canAccept)
                              FilledButton(
                                onPressed: _submitting ? null : _acceptOrder,
                                child: const Text('接单'),
                              ),
                            if (canChat)
                              OutlinedButton.icon(
                                onPressed: _openingChat
                                    ? null
                                    : () => _openChat(order),
                                icon: const Icon(Icons.chat_bubble_outline),
                                label: Text(_openingChat ? '打开中...' : '聊天'),
                              ),
                            if (canStart)
                              FilledButton.tonal(
                                onPressed: _submitting
                                    ? null
                                    : () => _updateRunnerStatus(
                                        'IN_PROGRESS',
                                        '已更新为配送中',
                                      ),
                                child: const Text('开始配送'),
                              ),
                            if (canFinish)
                              FilledButton.tonal(
                                onPressed: _submitting
                                    ? null
                                    : () => _updateRunnerStatus(
                                        'DELIVERED',
                                        '已标记为送达',
                                      ),
                                child: const Text('标记送达'),
                              ),
                            if (canConfirm)
                              FilledButton(
                                onPressed: _submitting ? null : _confirmOrder,
                                child: const Text('确认完成'),
                              ),
                            if (canEdit)
                              OutlinedButton(
                                onPressed: _submitting
                                    ? null
                                    : () => _editOrder(order),
                                child: const Text('修改订单'),
                              ),
                            if (canCancel)
                              OutlinedButton(
                                onPressed: _submitting ? null : _cancelOrder,
                                child: const Text('取消订单'),
                              ),
                            if (canReport)
                              OutlinedButton(
                                onPressed: _submitting ? null : _reportOrder,
                                child: const Text('举报'),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (order.cancelReason != null ||
                  order.cancelRequest != null) ...[
                const SizedBox(height: 16),
                _SectionCard(
                  title: '取消信息',
                  children: [
                    if (order.cancelReason != null)
                      _DetailRow(label: '取消原因', value: order.cancelReason!),
                    if (order.cancelRequest != null)
                      _DetailRow(
                        label: '申请说明',
                        value: order.cancelRequest!.reason,
                      ),
                  ],
                ),
              ],
              if (order.deliveryImages.isNotEmpty) ...[
                const SizedBox(height: 16),
                _SectionCard(
                  title: '配送凭证',
                  children: order.deliveryImages
                      .map(
                        (image) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _ImageTile(
                            image: image,
                            onTap: () => _previewImage(image.imageUrl),
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  String _buildContactValue(OrderDetail order) {
    final label = contactModeLabel(order.contactMode);
    if (order.contactValue == null || order.contactValue!.trim().isEmpty) {
      return label;
    }
    return '$label / ${order.contactValue}';
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function({bool notifyParent}) onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: () => onRetry(), child: const Text('重新加载')),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 84,
            child: Text(label, style: TextStyle(color: Colors.grey.shade600)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageTile extends StatelessWidget {
  const _ImageTile({required this.image, required this.onTap});

  final OrderDeliveryImage image;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                image.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey.shade200,
                  alignment: Alignment.center,
                  child: const Text('图片加载失败'),
                ),
              ),
            ),
            if (image.note?.trim().isNotEmpty == true)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  image.note!,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(28),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ReportPayload {
  const _ReportPayload({required this.category, required this.description});

  final String category;
  final String description;
}

Color _statusColor(String status) {
  switch (status) {
    case 'OPEN':
      return const Color(0xFF2563EB);
    case 'ACCEPTED':
      return const Color(0xFFF59E0B);
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

String _formatDateTime(DateTime? value) {
  if (value == null) {
    return '时间待定';
  }
  return DateFormat('yyyy-MM-dd HH:mm').format(value.toLocal());
}
