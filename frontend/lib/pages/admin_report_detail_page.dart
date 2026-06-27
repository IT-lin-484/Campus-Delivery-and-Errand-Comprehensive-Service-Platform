import 'package:flutter/material.dart';

import '../core/models/admin_models.dart';
import '../core/network/api_exception.dart';
import '../state/app_controller.dart';
import 'widgets/admin_text_input_dialog.dart';

class AdminReportDetailPage extends StatefulWidget {
  const AdminReportDetailPage({
    super.key,
    required this.controller,
    required this.report,
    this.onChanged,
  });

  final AppController controller;
  final AdminReportSummary report;
  final VoidCallback? onChanged;

  @override
  State<AdminReportDetailPage> createState() => _AdminReportDetailPageState();
}

class _AdminReportDetailPageState extends State<AdminReportDetailPage> {
  late AdminReportSummary _report;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _report = widget.report;
  }

  Future<void> _handle(String status) async {
    final note = await showAdminTextInputDialog(
      context,
      title: status == 'RESOLVED' ? '处理举报' : '驳回举报',
      labelText: '处理说明',
      hintText: '可填写处理说明',
      confirmText: '确认提交',
      initialValue: status == 'RESOLVED' ? '管理员已处理举报' : '管理员已驳回举报',
    );
    if (note == null || _submitting) {
      return;
    }

    setState(() {
      _submitting = true;
    });

    try {
      final updated = await widget.controller.api.adminHandleReport(
        reportId: _report.id,
        status: status,
        handleNote: note.trim().isEmpty ? null : note.trim(),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _report = updated;
      });
      widget.onChanged?.call();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('举报状态已更新')));
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
    final canHandle = _report.status == 'OPEN';

    return Scaffold(
      appBar: AppBar(title: const Text('举报详情')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _AdminTag(text: _report.category),
                      _AdminTag(
                        text: adminReportStatusLabel(_report.status),
                        color: _reportStatusColor(_report.status),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _InfoRow(label: '举报 ID', value: '#${_report.id}'),
                  _InfoRow(
                    label: '举报目标',
                    value: '${_report.targetType} #${_report.targetId}',
                  ),
                  _InfoRow(
                    label: '举报人',
                    value: _report.reporterId == null
                        ? '匿名'
                        : '#${_report.reporterId}',
                  ),
                  _InfoRow(
                    label: '提交时间',
                    value: _formatDateTime(_report.createdAt),
                  ),
                  _InfoRow(
                    label: '处理时间',
                    value: _formatDateTime(_report.handledAt),
                  ),
                  _InfoRow(
                    label: '举报说明',
                    value: _report.description?.trim().isNotEmpty == true
                        ? _report.description!
                        : '暂无说明',
                  ),
                  if (_report.handleNote?.trim().isNotEmpty == true)
                    _InfoRow(label: '处理说明', value: _report.handleNote!),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      FilledButton.tonal(
                        onPressed: canHandle && !_submitting
                            ? () => _handle('RESOLVED')
                            : null,
                        child: const Text('处理通过'),
                      ),
                      FilledButton.tonal(
                        onPressed: canHandle && !_submitting
                            ? () => _handle('REJECTED')
                            : null,
                        child: const Text('驳回举报'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
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

Color _reportStatusColor(String status) {
  switch (status) {
    case 'OPEN':
      return const Color(0xFFF59E0B);
    case 'RESOLVED':
      return const Color(0xFF16A34A);
    case 'REJECTED':
      return const Color(0xFFDC2626);
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
