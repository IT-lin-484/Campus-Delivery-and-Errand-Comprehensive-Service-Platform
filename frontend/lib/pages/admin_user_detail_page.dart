import 'package:flutter/material.dart';

import '../core/models/admin_models.dart';
import '../core/network/api_exception.dart';
import '../state/app_controller.dart';
import 'widgets/admin_text_input_dialog.dart';

class AdminUserDetailPage extends StatefulWidget {
  const AdminUserDetailPage({
    super.key,
    required this.controller,
    required this.user,
    this.onChanged,
  });

  final AppController controller;
  final AdminUserSummary user;
  final VoidCallback? onChanged;

  @override
  State<AdminUserDetailPage> createState() => _AdminUserDetailPageState();
}

class _AdminUserDetailPageState extends State<AdminUserDetailPage> {
  late AdminUserSummary _user;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _user = widget.user;
  }

  Future<void> _changeStatus() async {
    final targetStatus = _user.status == 'ACTIVE' ? 'BANNED' : 'ACTIVE';
    final note = await showAdminTextInputDialog(
      context,
      title: targetStatus == 'BANNED' ? '确认禁用用户' : '确认恢复用户',
      labelText: '备注',
      hintText: '请输入操作说明',
      confirmText: targetStatus == 'BANNED' ? '禁用' : '恢复',
      initialValue: targetStatus == 'BANNED' ? '管理员禁用账号' : '管理员恢复账号',
    );
    if (!mounted || note == null || _submitting) {
      return;
    }

    setState(() {
      _submitting = true;
    });

    try {
      final updated = await widget.controller.api.adminUpdateUserStatus(
        userId: _user.id,
        status: targetStatus,
        note: note.trim().isEmpty ? null : note.trim(),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _user = updated;
      });
      widget.onChanged?.call();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('用户状态已更新')));
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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('用户详情')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: const Color(0xFFE2E8F0),
                        backgroundImage: _user.avatarUrl != null
                            ? NetworkImage(_user.avatarUrl!)
                            : null,
                        child: _user.avatarUrl == null
                            ? Text(
                                _user.displayName.substring(0, 1),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF334155),
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _user.displayName,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '@${_user.username}',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _AdminTag(text: adminUserRoleLabel(_user.role)),
                      _AdminTag(
                        text: adminUserStatusLabel(_user.status),
                        color: _user.status == 'ACTIVE'
                            ? const Color(0xFF16A34A)
                            : const Color(0xFFDC2626),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _InfoRow(label: '用户 ID', value: '#${_user.id}'),
                  _InfoRow(label: '手机号', value: _user.phoneText),
                  _InfoRow(
                    label: '创建时间',
                    value: _formatDateTime(_user.createdAt),
                  ),
                  _InfoRow(
                    label: '更新时间',
                    value: _formatDateTime(_user.updatedAt),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _submitting ? null : _changeStatus,
                    child: Text(
                      _submitting
                          ? '提交中...'
                          : (_user.status == 'ACTIVE' ? '禁用用户' : '恢复用户'),
                    ),
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

String _formatDateTime(DateTime? value) {
  if (value == null) {
    return '时间待定';
  }
  final local = value.toLocal();
  return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} '
      '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}
