import 'package:flutter/material.dart';

import '../core/models/order_models.dart';
import '../core/network/api_exception.dart';
import '../state/app_controller.dart';

class CreateOrderPage extends StatefulWidget {
  const CreateOrderPage({
    super.key,
    required this.controller,
    required this.onCreated,
  });

  final AppController controller;
  final VoidCallback onCreated;

  @override
  State<CreateOrderPage> createState() => _CreateOrderPageState();
}

class _CreateOrderPageState extends State<CreateOrderPage> {
  final _formKey = GlobalKey<FormState>();
  final _pickupController = TextEditingController();
  final _dropoffController = TextEditingController();
  final _rewardController = TextEditingController(text: '10');
  final _contactValueController = TextEditingController();
  final _remarkController = TextEditingController();

  String _type = 'EXPRESS';
  String _contactMode = 'IN_APP';
  DateTime? _expectedTime;
  bool _submitting = false;
  String? _errorText;

  @override
  void dispose() {
    _pickupController.dispose();
    _dropoffController.dispose();
    _rewardController.dispose();
    _contactValueController.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  Future<void> _pickExpectedTime() async {
    final now = DateTime.now();
    final initialDate = _expectedTime ?? now.add(const Duration(hours: 1));
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
    );
    if (date == null || !mounted) {
      return;
    }

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );
    if (time == null || !mounted) {
      return;
    }

    setState(() {
      _expectedTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    final expectedTime = _expectedTime;
    if (expectedTime == null) {
      setState(() {
        _errorText = '请选择期望完成时间';
      });
      return;
    }

    final reward = int.tryParse(_rewardController.text.trim());
    if (reward == null) {
      setState(() {
        _errorText = '赏金格式不正确';
      });
      return;
    }

    setState(() {
      _submitting = true;
      _errorText = null;
    });

    try {
      await widget.controller.api.createOrder(
        CreateOrderRequest(
          type: _type,
          pickupLocation: _pickupController.text.trim(),
          dropoffLocation: _dropoffController.text.trim(),
          expectedTime: expectedTime,
          rewardAmount: reward,
          contactMode: _contactMode,
          contactValue: _normalize(_contactValueController.text),
          remark: _normalize(_remarkController.text),
        ),
      );
      _resetForm();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('订单发布成功')));
      widget.onCreated();
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorText = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorText = '发布失败，请稍后重试';
      });
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    setState(() {
      _pickupController.clear();
      _dropoffController.clear();
      _rewardController.text = '10';
      _contactValueController.clear();
      _remarkController.clear();
      _expectedTime = null;
      _type = 'EXPRESS';
      _contactMode = 'IN_APP';
      _errorText = null;
    });
  }

  String? _normalize(String value) {
    final text = value.trim();
    return text.isEmpty ? null : text;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '订单信息',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _type,
                    decoration: const InputDecoration(labelText: '订单分类'),
                    items: const [
                      DropdownMenuItem(value: 'EXPRESS', child: Text('快递')),
                      DropdownMenuItem(value: 'FOOD', child: Text('餐食')),
                      DropdownMenuItem(value: 'DELIVERY', child: Text('代取送')),
                    ],
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() {
                        _type = value;
                      });
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _pickupController,
                    decoration: const InputDecoration(
                      labelText: '取件地点',
                      hintText: '请输入取件地点',
                    ),
                    maxLength: 120,
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (text.isEmpty) {
                        return '请输入取件地点';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _dropoffController,
                    decoration: const InputDecoration(
                      labelText: '送达地点',
                      hintText: '请输入送达地点',
                    ),
                    maxLength: 120,
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (text.isEmpty) {
                        return '请输入送达地点';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  InkWell(
                    onTap: _submitting ? null : _pickExpectedTime,
                    borderRadius: BorderRadius.circular(18),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: '期望完成时间',
                        hintText: '请选择时间',
                        suffixIcon: Icon(Icons.calendar_today_outlined),
                      ),
                      child: Text(
                        _expectedTime == null
                            ? '请选择期望完成时间'
                            : _formatDateTime(_expectedTime!),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _rewardController,
                    decoration: const InputDecoration(
                      labelText: '赏金',
                      hintText: '请输入赏金金额',
                      prefixText: '¥ ',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      final amount = int.tryParse(text);
                      if (amount == null) {
                        return '请输入整数金额';
                      }
                      if (amount < 1) {
                        return '赏金不能小于 1';
                      }
                      if (amount > 50) {
                        return '赏金不能超过 50';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '联系信息',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _contactMode,
                    decoration: const InputDecoration(labelText: '联系形式'),
                    items: const [
                      DropdownMenuItem(value: 'IN_APP', child: Text('站内联系')),
                      DropdownMenuItem(value: 'PHONE', child: Text('电话联系')),
                    ],
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() {
                        _contactMode = value;
                      });
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _contactValueController,
                    decoration: InputDecoration(
                      labelText: _contactMode == 'PHONE' ? '联系电话' : '补充联系方式',
                      hintText: _contactMode == 'PHONE'
                          ? '请输入手机号'
                          : '例如微信号或其他联系说明',
                    ),
                    maxLength: 64,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _remarkController,
                    decoration: const InputDecoration(
                      labelText: '备注',
                      hintText: '可补充楼栋、时间要求或其他说明',
                    ),
                    maxLines: 4,
                    maxLength: 200,
                  ),
                ],
              ),
            ),
          ),
          if (_errorText != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFDA4AF)),
              ),
              child: Text(
                _errorText!,
                style: const TextStyle(color: Color(0xFFBE123C)),
              ),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _submitting ? null : _submit,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(_submitting ? '提交中...' : '发布订单'),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime value) {
    final date = value.toLocal();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$month-$day $hour:$minute';
  }
}
