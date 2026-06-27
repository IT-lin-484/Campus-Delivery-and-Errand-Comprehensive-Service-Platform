import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/network/api_exception.dart';
import '../state/app_controller.dart';
import 'widgets/app_avatar.dart';

class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({super.key, required this.controller});

  final AppController controller;

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _commonAddressController = TextEditingController();
  final _bioController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  bool _allowFriendRequest = true;
  bool _allowSearch = true;
  bool _messageDnd = false;
  bool _submitting = false;
  bool _uploadingAvatar = false;
  String? _avatarUrl;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    final user = widget.controller.currentUser;
    if (user != null) {
      _usernameController.text = user.username;
      _nicknameController.text = user.nickname;
      _phoneController.text = user.phone ?? '';
      _commonAddressController.text = user.commonAddress ?? '';
      _bioController.text = user.bio ?? '';
      _allowFriendRequest = user.allowFriendRequest;
      _allowSearch = user.allowSearch;
      _messageDnd = user.messageDnd;
      _avatarUrl = user.avatarUrl;
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _nicknameController.dispose();
    _phoneController.dispose();
    _commonAddressController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    if (_uploadingAvatar || _submitting) {
      return;
    }

    try {
      final file = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (file == null || !mounted) {
        return;
      }

      setState(() {
        _uploadingAvatar = true;
        _errorText = null;
      });

      await widget.controller.api.uploadMyAvatar(
        filePath: file.path,
        fileName: file.name,
      );
      await widget.controller.refreshCurrentUser();

      if (!mounted) {
        return;
      }
      setState(() {
        _avatarUrl = widget.controller.currentUser?.avatarUrl;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('头像已更新')));
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
        _errorText = '头像上传失败，请稍后重试';
      });
    } finally {
      if (mounted) {
        setState(() {
          _uploadingAvatar = false;
        });
      }
    }
  }

  Future<void> _save() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    setState(() {
      _submitting = true;
      _errorText = null;
    });

    try {
      await widget.controller.api.updateMyProfile(
        username: _usernameController.text.trim(),
        nickname: _nicknameController.text.trim(),
        phone: _normalize(_phoneController.text),
        commonAddress: _normalize(_commonAddressController.text),
        bio: _normalize(_bioController.text),
        allowFriendRequest: _allowFriendRequest,
        allowSearch: _allowSearch,
        messageDnd: _messageDnd,
      );
      await widget.controller.refreshCurrentUser();
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
        _errorText = '保存失败，请稍后重试';
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

  String? _validateUsername(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return '请输入用户名';
    }
    if (text.length < 4 || text.length > 32) {
      return '用户名长度需为 4-32 位';
    }
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(text)) {
      return '用户名仅支持字母、数字和下划线';
    }
    return null;
  }

  String? _validateNickname(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return '请输入昵称';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return null;
    }
    if (!RegExp(r'^1[3-9]\d{9}$').hasMatch(text)) {
      return '请输入正确的手机号';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.controller.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final busy = _submitting || _uploadingAvatar;

    return Scaffold(
      appBar: AppBar(title: const Text('账号资料')),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: FilledButton.icon(
          onPressed: busy ? null : _save,
          icon: busy
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check_circle_outline),
          label: Text(_submitting ? '保存中' : '保存修改'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        AppAvatar(
                          radius: 42,
                          label: AppAvatar.labelFrom(
                            _nicknameController.text,
                            _usernameController.text,
                          ),
                          imageUrl: _avatarUrl,
                        ),
                        if (_uploadingAvatar)
                          Container(
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(
                              color: Colors.black.withAlpha(90),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      '上传头像',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '建议选择清晰的人像或简洁图标',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      onPressed: busy ? null : _pickAvatar,
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('从相册选择'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '基本信息',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _usernameController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: '用户名',
                        hintText: '4-32 位，仅支持字母、数字、下划线',
                      ),
                      maxLength: 32,
                      validator: _validateUsername,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nicknameController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: '昵称',
                        hintText: '展示给其他用户看的名称',
                      ),
                      maxLength: 64,
                      validator: _validateNickname,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneController,
                      textInputAction: TextInputAction.next,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: '手机号',
                        hintText: '用于订单联系，可留空',
                      ),
                      maxLength: 11,
                      validator: _validatePhone,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _commonAddressController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: '常用地址',
                        hintText: '例如宿舍、教学楼、校门口',
                      ),
                      maxLength: 120,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _bioController,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        labelText: '个人简介',
                        hintText: '简单介绍一下自己',
                      ),
                      maxLength: 200,
                      maxLines: 4,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    value: _allowFriendRequest,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    onChanged: busy
                        ? null
                        : (value) {
                            setState(() {
                              _allowFriendRequest = value;
                            });
                          },
                    title: const Text('允许好友申请'),
                    subtitle: const Text('其他用户可以主动向你发起好友申请'),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    value: _allowSearch,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    onChanged: busy
                        ? null
                        : (value) {
                            setState(() {
                              _allowSearch = value;
                            });
                          },
                    title: const Text('允许被搜索到'),
                    subtitle: const Text('支持通过用户名或昵称搜索到你'),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    value: _messageDnd,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    onChanged: busy
                        ? null
                        : (value) {
                            setState(() {
                              _messageDnd = value;
                            });
                          },
                    title: const Text('消息免打扰'),
                    subtitle: const Text('关闭后仍可正常收发消息'),
                  ),
                ],
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
          ],
        ),
      ),
    );
  }
}
