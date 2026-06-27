import 'package:flutter/material.dart';

import '../core/models/order_models.dart';
import '../core/network/api_exception.dart';
import '../state/app_controller.dart';

class EditOrderPage extends StatefulWidget {
  const EditOrderPage({
    super.key,
    required this.controller,
    required this.order,
  });

  final AppController controller;
  final OrderDetail order;

  @override
  State<EditOrderPage> createState() => _EditOrderPageState();
}

class _EditOrderPageState extends State<EditOrderPage> {
  final _formKey = GlobalKey<FormState>();
  final _pickupController = TextEditingController();
  final _dropoffController = TextEditingController();
  final _rewardController = TextEditingController();
  final _contactValueController = TextEditingController();
  final _remarkController = TextEditingController();

  late String _type;
  late String _contactMode;
  DateTime? _expectedTime;
  bool _submitting = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    final order = widget.order;
    _pickupController.text = order.pickupLocation;
    _dropoffController.text = order.dropoffLocation;
    _rewardController.text = order.rewardAmount.toString();
    _contactValueController.text = order.contactValue ?? '';
    _remarkController.text = order.remark ?? '';
    _type = order.type;
    _contactMode = order.contactMode;
    _expectedTime = order.expectedTime?.toLocal();
  }

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
        _errorText = '请输入正确的赏金';
      });
      return;
    }

    setState(() {
      _submitting = true;
      _errorText = null;
    });

    try {
      await widget.controller.api.updateOrder(
        id: widget.order.id,
        request: UpdateOrderRequest(
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
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
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
        _errorText = '修改失败，请稍后重试';
      });
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  String? _normalize(String value) {
    final text = value.trim();
    return text.isEmpty ? null : text;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('修改订单')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
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
                      decoration: const InputDecoration(labelText: '取件地点'),
                      maxLength: 120,
                      validator: (value) {
                        if ((value?.trim() ?? '').isEmpty) {
                          return '请输入取件地点';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _dropoffController,
                      decoration: const InputDecoration(labelText: '送达地点'),
                      maxLength: 120,
                      validator: (value) {
                        if ((value?.trim() ?? '').isEmpty) {
                          return '请输入送达地点';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    InkWell(
                      onTap: _pickExpectedTime,
                      borderRadius: BorderRadius.circular(14),
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: '期望完成时间'),
                        child: Text(
                          _expectedTime == null
                              ? '请选择期望完成时间'
                              : '${_expectedTime!.year}-${_expectedTime!.month.toString().padLeft(2, '0')}-${_expectedTime!.day.toString().padLeft(2, '0')} ${_expectedTime!.hour.toString().padLeft(2, '0')}:${_expectedTime!.minute.toString().padLeft(2, '0')}',
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _rewardController,
                      decoration: const InputDecoration(
                        labelText: '赏金',
                        prefixText: '¥ ',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        final amount = int.tryParse(value?.trim() ?? '');
                        if (amount == null) {
                          return '请输入正确的赏金';
                        }
                        if (amount < 1 || amount > 50) {
                          return '赏金需在 1 到 50 之间';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
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
                        hintText: _contactMode == 'PHONE' ? '请输入手机号' : '例如微信号',
                      ),
                      maxLength: 64,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _remarkController,
                      decoration: const InputDecoration(
                        labelText: '备注',
                        hintText: '可补充其他说明',
                      ),
                      maxLength: 200,
                      maxLines: 3,
                    ),
                    if (_errorText != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _errorText!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _submitting ? null : _submit,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Text(_submitting ? '保存中...' : '保存修改'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
