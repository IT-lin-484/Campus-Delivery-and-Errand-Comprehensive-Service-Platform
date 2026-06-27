import 'package:flutter/material.dart';

import '../core/models/admin_models.dart';
import '../core/models/order_models.dart';
import '../core/network/api_exception.dart';
import '../state/app_controller.dart';
import 'widgets/admin_text_input_dialog.dart';

class AdminOrderDetailPage extends StatefulWidget {
  const AdminOrderDetailPage({
    super.key,
    required this.controller,
    required this.orderId,
    this.onChanged,
  });

  final AppController controller;
  final int orderId;
  final VoidCallback? onChanged;

  @override
  State<AdminOrderDetailPage> createState() => _AdminOrderDetailPageState();
}

class _AdminOrderDetailPageState extends State<AdminOrderDetailPage> {
  late Future<AdminOrderDetail> _future;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<AdminOrderDetail> _load() {
    return widget.controller.api.adminOrderDetail(widget.orderId);
  }

  Future<void> _reload({bool notifyParent = false}) async {
    setState(() {
      _future = _load();
    });
    await _future;
    if (notifyParent) {
      widget.onChanged?.call();
    }
  }

  Future<void> _forceCancel() async {
    final reason = await showAdminTextInputDialog(
      context,
      title: '强制取消订单',
      labelText: '取消原因',
      hintText: '请输入取消原因',
      confirmText: '确认取消',
      initialValue: '管理员强制取消订单',
      requiredInput: true,
    );
    if (reason == null) {
      return;
    }

    await _runAction(
      () => widget.controller.api.adminForceCancel(
        orderId: widget.orderId,
        reason: reason.trim(),
      ),
      successMessage: '订单已强制取消',
    );
  }

  Future<void> _forceComplete() async {
    final note = await showAdminTextInputDialog(
      context,
      title: '强制完成订单',
      labelText: '处理说明',
      hintText: '可填写处理说明',
      confirmText: '确认完成',
      initialValue: '管理员强制完成订单',
    );
    if (note == null) {
      return;
    }

    await _runAction(
      () => widget.controller.api.adminForceComplete(
        orderId: widget.orderId,
        note: note.trim().isEmpty ? null : note.trim(),
      ),
      successMessage: '订单已强制完成',
    );
  }

  Future<void> _markException() async {
    final note = await showAdminTextInputDialog(
      context,
      title: '标记异常',
      labelText: '异常说明',
      hintText: '请输入异常说明',
      confirmText: '确认提交',
      initialValue: '管理员标记订单异常',
      requiredInput: true,
    );
    if (note == null) {
      return;
    }

    await _runAction(
      () => widget.controller.api.adminMarkException(
        orderId: widget.orderId,
        note: note.trim(),
      ),
      successMessage: '订单已标记异常',
    );
  }

  Future<void> _runAction(
    Future<void> Function() action, {
    required String successMessage,
  }) async {
    if (_submitting) {
      return;
    }

    setState(() {
      _submitting = true;
    });

    try {
      await action();
      await _reload(notifyParent: true);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('订单详情')),
      body: FutureBuilder<AdminOrderDetail>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _AdminErrorState(
              message: snapshot.error?.toString() ?? '加载失败，请稍后重试',
              onRetry: _reload,
            );
          }

          final order = snapshot.data;
          if (order == null) {
            return _AdminErrorState(message: '订单不存在', onRetry: _reload);
          }

          final isFinal = const [
            'CANCELLED',
            'COMPLETED',
            'EXPIRED',
          ].contains(order.status);

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
                          _AdminTag(text: orderTypeLabel(order.type)),
                          _AdminTag(
                            text: orderStatusLabel(order.status),
                            color: _orderStatusColor(order.status),
                          ),
                          if (order.abnormalFlag)
                            const _AdminTag(
                              text: '异常',
                              color: Color(0xFFDC2626),
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
                      _InfoRow(label: '订单 ID', value: '#${order.id}'),
                      _InfoRow(label: '发单人', value: order.requesterDisplayName),
                      _InfoRow(label: '接单人', value: order.runnerDisplayName),
                      _InfoRow(label: '赏金', value: '¥${order.rewardAmount}'),
                      _InfoRow(
                        label: '期望时间',
                        value: _formatDateTime(order.expectedTime),
                      ),
                      _InfoRow(
                        label: '联系形式',
                        value:
                            '${contactModeLabel(order.contactMode)} / ${order.contactValueMasked ?? '-'}',
                      ),
                      _InfoRow(
                        label: '备注',
                        value: order.remark?.trim().isNotEmpty == true
                            ? order.remark!
                            : '暂无备注',
                      ),
                      if (order.cancelReason?.trim().isNotEmpty == true)
                        _InfoRow(label: '取消原因', value: order.cancelReason!),
                      if (order.abnormalNote?.trim().isNotEmpty == true)
                        _InfoRow(label: '异常说明', value: order.abnormalNote!),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          FilledButton.tonal(
                            onPressed: _submitting || isFinal
                                ? null
                                : _forceCancel,
                            child: const Text('强制取消'),
                          ),
                          FilledButton.tonal(
                            onPressed: _submitting || isFinal
                                ? null
                                : _forceComplete,
                            child: const Text('强制完成'),
                          ),
                          FilledButton.tonal(
                            onPressed: _submitting ? null : _markException,
                            child: Text(order.abnormalFlag ? '更新异常' : '标记异常'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (order.statusLogs.isNotEmpty) ...[
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '状态记录',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 12),
                        ...order.statusLogs.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${orderStatusLabel(item.fromStatus ?? '')} -> ${orderStatusLabel(item.toStatus ?? '')}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '操作人 #${item.operatorId ?? 0} · ${_formatDateTime(item.createdAt)}',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                                if (item.note?.trim().isNotEmpty == true) ...[
                                  const SizedBox(height: 4),
                                  Text(item.note!),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _AdminErrorState extends StatelessWidget {
  const _AdminErrorState({required this.message, required this.onRetry});

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

class _AdminTag extends StatelessWidget {
  const _AdminTag({required this.text, this.color = const Color(0xFF2563EB)});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(24),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

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
            width: 88,
            child: Text(label, style: TextStyle(color: Colors.grey.shade600)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

Color _orderStatusColor(String status) {
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
  final local = value.toLocal();
  return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} '
      '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}
