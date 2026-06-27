import 'package:flutter/material.dart';

import '../core/network/api_exception.dart';
import '../state/app_controller.dart';

enum _AuthMode { userLogin, userRegister, adminLogin }

class UserLoginPage extends StatelessWidget {
  const UserLoginPage({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return _AuthFormPage(controller: controller, mode: _AuthMode.userLogin);
  }
}

class UserRegisterPage extends StatelessWidget {
  const UserRegisterPage({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return _AuthFormPage(controller: controller, mode: _AuthMode.userRegister);
  }
}

class AdminLoginPage extends StatelessWidget {
  const AdminLoginPage({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return _AuthFormPage(controller: controller, mode: _AuthMode.adminLogin);
  }
}

class _AuthFormPage extends StatefulWidget {
  const _AuthFormPage({required this.controller, required this.mode});

  final AppController controller;
  final _AuthMode mode;

  @override
  State<_AuthFormPage> createState() => _AuthFormPageState();
}

class _AuthFormPageState extends State<_AuthFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _submitting = false;
  bool _obscurePassword = true;
  String? _errorText;

  bool get _isUserRegister => widget.mode == _AuthMode.userRegister;
  bool get _isAdminLogin => widget.mode == _AuthMode.adminLogin;
  bool get _isUserLogin => widget.mode == _AuthMode.userLogin;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _nicknameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    setState(() {
      _submitting = true;
      _errorText = null;
    });

    try {
      if (_isUserRegister) {
        await widget.controller.register(
          username: _usernameController.text.trim(),
          password: _passwordController.text,
          nickname: _nicknameController.text.trim(),
          phone: _phoneController.text.trim(),
        );
      } else {
        await widget.controller.login(
          username: _usernameController.text.trim(),
          password: _passwordController.text,
          admin: _isAdminLogin,
        );
      }
      if (!mounted) {
        return;
      }
      if (!_isUserLogin) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
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
        _errorText = '操作失败，请稍后重试';
      });
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  void _openUserRegister() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => UserRegisterPage(controller: widget.controller),
      ),
    );
  }

  void _openAdminLogin() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AdminLoginPage(controller: widget.controller),
      ),
    );
  }

  void _openUserLogin() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final title = switch (widget.mode) {
      _AuthMode.userLogin => '用户登录',
      _AuthMode.userRegister => '用户注册',
      _AuthMode.adminLogin => '管理员登录',
    };
    final subtitle = switch (widget.mode) {
      _AuthMode.userLogin => '使用你的账号进入校园取送',
      _AuthMode.userRegister => '注册一个新的普通用户账号',
      _AuthMode.adminLogin => '仅管理员可使用此入口',
    };
    final submitText = switch (widget.mode) {
      _AuthMode.userLogin => '登录',
      _AuthMode.userRegister => '注册并登录',
      _AuthMode.adminLogin => '管理员登录',
    };

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF2FBF8), Color(0xFFF7FAFC), Color(0xFFFFFFFF)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: -40,
                right: -20,
                child: _GlowCircle(
                  size: 160,
                  color: const Color(0xFFBBF7D0).withAlpha(90),
                ),
              ),
              Positioned(
                top: 120,
                left: -30,
                child: _GlowCircle(
                  size: 110,
                  color: const Color(0xFFBAE6FD).withAlpha(100),
                ),
              ),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (!_isUserLogin)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: IconButton(
                              onPressed: _openUserLogin,
                              icon: const Icon(Icons.arrow_back_rounded),
                            ),
                          ),
                        const SizedBox(height: 8),
                        Text(
                          '校园取送',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF0F172A),
                              ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '人人为我，我为人人',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey.shade700,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 28),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    subtitle,
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      height: 1.45,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  TextFormField(
                                    controller: _usernameController,
                                    textInputAction: TextInputAction.next,
                                    decoration: const InputDecoration(
                                      labelText: '账号',
                                      hintText: '请输入账号',
                                      prefixIcon: Icon(Icons.person_outline),
                                    ),
                                    validator: (value) {
                                      final text = value?.trim() ?? '';
                                      if (text.isEmpty) {
                                        return '请输入账号';
                                      }
                                      if (text.length < 4 || text.length > 32) {
                                        return '账号长度需在 4 到 32 位之间';
                                      }
                                      if (!RegExp(
                                        r'^[a-zA-Z0-9_]+$',
                                      ).hasMatch(text)) {
                                        return '账号仅支持字母、数字和下划线';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 14),
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: _obscurePassword,
                                    textInputAction: _isUserRegister
                                        ? TextInputAction.next
                                        : TextInputAction.done,
                                    decoration: InputDecoration(
                                      labelText: '密码',
                                      hintText: '请输入密码',
                                      prefixIcon: const Icon(
                                        Icons.lock_outline_rounded,
                                      ),
                                      suffixIcon: IconButton(
                                        onPressed: () {
                                          setState(() {
                                            _obscurePassword =
                                                !_obscurePassword;
                                          });
                                        },
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                        ),
                                      ),
                                    ),
                                    validator: (value) {
                                      final text = value ?? '';
                                      if (text.isEmpty) {
                                        return '请输入密码';
                                      }
                                      if (text.length < 6) {
                                        return '密码至少需要 6 位';
                                      }
                                      if (text.length > 32) {
                                        return '密码不能超过 32 位';
                                      }
                                      return null;
                                    },
                                  ),
                                  if (_isUserRegister) ...[
                                    const SizedBox(height: 14),
                                    TextFormField(
                                      controller: _nicknameController,
                                      textInputAction: TextInputAction.next,
                                      decoration: const InputDecoration(
                                        labelText: '昵称',
                                        hintText: '例如：小张同学',
                                        prefixIcon: Icon(Icons.badge_outlined),
                                      ),
                                      maxLength: 64,
                                    ),
                                    const SizedBox(height: 14),
                                    TextFormField(
                                      controller: _phoneController,
                                      keyboardType: TextInputType.phone,
                                      textInputAction: TextInputAction.done,
                                      decoration: const InputDecoration(
                                        labelText: '手机号',
                                        hintText: '选填，用于订单联系',
                                        prefixIcon: Icon(Icons.phone_outlined),
                                      ),
                                      validator: (value) {
                                        final text = value?.trim() ?? '';
                                        if (text.isEmpty) {
                                          return null;
                                        }
                                        if (!RegExp(
                                          r'^1[3-9]\d{9}$',
                                        ).hasMatch(text)) {
                                          return '手机号格式不正确';
                                        }
                                        return null;
                                      },
                                    ),
                                  ],
                                  if (_errorText != null) ...[
                                    const SizedBox(height: 14),
                                    Text(
                                      _errorText!,
                                      style: const TextStyle(
                                        color: Color(0xFFDC2626),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 22),
                                  FilledButton(
                                    onPressed: _submitting ? null : _submit,
                                    style: FilledButton.styleFrom(
                                      minimumSize: const Size.fromHeight(52),
                                    ),
                                    child: Text(
                                      _submitting ? '请稍候...' : submitText,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Wrap(
                                      spacing: 4,
                                      runSpacing: 2,
                                      children: _buildFooterLinks(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildFooterLinks() {
    if (widget.mode == _AuthMode.userLogin) {
      return [
        _LinkAction(label: '管理员登录', onTap: _openAdminLogin),
        _LinkAction(label: '用户注册', onTap: _openUserRegister),
      ];
    }

    return [_LinkAction(label: '返回用户登录', onTap: _openUserLogin)];
  }
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}

class _LinkAction extends StatelessWidget {
  const _LinkAction({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(label),
    );
  }
}
