import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/models/admin_models.dart';
import '../core/models/order_models.dart';
import '../state/app_controller.dart';
import 'admin_order_detail_page.dart';
import 'admin_report_detail_page.dart';
import 'admin_user_detail_page.dart';
import 'widgets/logout_confirm_dialog.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key, required this.controller});

  final AppController controller;

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _currentIndex = 0;

  void _selectIndex(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  Future<void> _handleLogout() async {
    final confirmed = await showLogoutConfirmDialog(
      context,
      message: '确定要退出管理员账号吗？',
    );
    if (!confirmed) {
      return;
    }
    await widget.controller.logout();
  }

  @override
  Widget build(BuildContext context) {
    const titles = ['概览', '用户', '订单', '举报', '配置'];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_currentIndex]),
        actions: [
          IconButton(
            tooltip: '退出登录',
            onPressed: _handleLogout,
            icon: const Icon(Icons.logout_outlined),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          AdminOverviewPage(controller: widget.controller),
          AdminUsersPage(controller: widget.controller),
          AdminOrdersPage(controller: widget.controller),
          AdminReportsPage(controller: widget.controller),
          AdminConfigPage(controller: widget.controller),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        key: ValueKey(_currentIndex),
        selectedIndex: _currentIndex,
        onDestinationSelected: _selectIndex,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: '概览',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_alt_outlined),
            selectedIcon: Icon(Icons.people_alt),
            label: '用户',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: '订单',
          ),
          NavigationDestination(
            icon: Icon(Icons.report_outlined),
            selectedIcon: Icon(Icons.report),
            label: '举报',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: '配置',
          ),
        ],
      ),
    );
  }
}

class AdminOverviewPage extends StatefulWidget {
  const AdminOverviewPage({super.key, required this.controller});

  final AppController controller;

  @override
  State<AdminOverviewPage> createState() => _AdminOverviewPageState();
}

class _AdminOverviewPageState extends State<AdminOverviewPage> {
  late Future<AdminOverview> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.controller.api.adminOverview();
  }

  Future<void> _reload() async {
    setState(() {
      _future = widget.controller.api.adminOverview();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _reload,
      child: FutureBuilder<AdminOverview>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _AdminLoadingView();
          }
          if (snapshot.hasError) {
            return _AdminErrorView(
              message: snapshot.error?.toString() ?? '加载失败，请稍后重试',
              onRetry: () => _reload(),
            );
          }

          final data = snapshot.data;
          if (data == null) {
            return const _AdminEmptyView(message: '暂无概览数据');
          }

          final items = [
            _OverviewItem('订单总数', data.totalOrders, Icons.receipt_long),
            _OverviewItem('待处理订单', data.openOrders, Icons.pending_actions),
            _OverviewItem('异常订单', data.abnormalOrders, Icons.warning_amber),
            _OverviewItem('待处理举报', data.pendingReports, Icons.report),
            _OverviewItem('已禁用用户', data.bannedUsers, Icons.block),
          ];

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                '管理概览',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                '这里展示管理员当前最关心的核心数据。',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.35,
                ),
                itemBuilder: (context, index) {
                  return _OverviewCard(item: items[index]);
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key, required this.controller});

  final AppController controller;

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  static const int _pageSize = 10;

  final TextEditingController _keywordController = TextEditingController();
  late Future<AdminUserPage> _future;
  int _page = 1;
  String _selectedStatus = '';

  @override
  void initState() {
    super.initState();
    _keywordController.addListener(_handleKeywordChanged);
    _future = _load();
  }

  @override
  void dispose() {
    _keywordController.removeListener(_handleKeywordChanged);
    _keywordController.dispose();
    super.dispose();
  }

  void _handleKeywordChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<AdminUserPage> _load() {
    final keyword = _keywordController.text.trim();
    return widget.controller.api.adminUsers(
      keyword: keyword.isEmpty ? null : keyword,
      status: _selectedStatus.isEmpty ? null : _selectedStatus,
      page: _page,
      pageSize: _pageSize,
    );
  }

  Future<void> _reload({bool resetPage = false}) async {
    if (resetPage) {
      _page = 1;
    }
    setState(() {
      _future = _load();
    });
    await _future;
  }

  void _changeStatusFilter(String value) {
    if (_selectedStatus == value) {
      return;
    }
    setState(() {
      _selectedStatus = value;
    });
    unawaited(_reload(resetPage: true));
  }

  void _clearKeyword() {
    _keywordController.clear();
    unawaited(_reload(resetPage: true));
  }

  void _goToPage(int page) {
    if (page < 1 || page == _page) {
      return;
    }
    setState(() {
      _page = page;
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _reload,
      child: FutureBuilder<AdminUserPage>(
        future: _future,
        builder: (context, snapshot) {
          final data = snapshot.data;
          final hasData = data != null && data.list.isNotEmpty;
          final hasNext =
              data != null && data.page * data.pageSize < data.total;
          final hasPrevious = _page > 1;

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              _SearchPanel(
                controller: _keywordController,
                hintText: '搜索账号、昵称、手机号或用户 ID',
                onSearch: () => _reload(resetPage: true),
                onClear: _clearKeyword,
              ),
              const SizedBox(height: 12),
              _ChipFilterRow(
                options: const [
                  _ChipOption(label: '全部', value: ''),
                  _ChipOption(label: '正常', value: 'ACTIVE'),
                  _ChipOption(label: '已禁用', value: 'BANNED'),
                ],
                selectedValue: _selectedStatus,
                onChanged: _changeStatusFilter,
              ),
              const SizedBox(height: 14),
              if (snapshot.connectionState == ConnectionState.waiting)
                const _SectionLoadingCard(text: '正在加载用户...')
              else if (snapshot.hasError)
                _SectionErrorCard(
                  message: snapshot.error?.toString() ?? '加载失败，请稍后重试',
                  onRetry: () => _reload(),
                )
              else if (!hasData)
                const _SectionEmptyCard(title: '暂无用户数据', hint: '可以换个关键词试试。')
              else ...[
                ...data.list.map(
                  (user) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _AdminUserCard(
                      user: user,
                      onTap: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => AdminUserDetailPage(
                              controller: widget.controller,
                              user: user,
                              onChanged: () => unawaited(_reload()),
                            ),
                          ),
                        );
                        await _reload();
                      },
                    ),
                  ),
                ),
                _CompactPagination(
                  page: data.page,
                  hasPrevious: hasPrevious,
                  hasNext: hasNext,
                  onPrevious: hasPrevious ? () => _goToPage(_page - 1) : null,
                  onNext: hasNext ? () => _goToPage(_page + 1) : null,
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class AdminOrdersPage extends StatefulWidget {
  const AdminOrdersPage({super.key, required this.controller});

  final AppController controller;

  @override
  State<AdminOrdersPage> createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends State<AdminOrdersPage> {
  static const int _pageSize = 10;

  final TextEditingController _keywordController = TextEditingController();
  late Future<AdminOrderPage> _future;
  int _page = 1;
  String _selectedType = '';
  String _selectedStatus = '';

  @override
  void initState() {
    super.initState();
    _keywordController.addListener(_handleKeywordChanged);
    _future = _load();
  }

  @override
  void dispose() {
    _keywordController.removeListener(_handleKeywordChanged);
    _keywordController.dispose();
    super.dispose();
  }

  void _handleKeywordChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<AdminOrderPage> _load() {
    final keyword = _keywordController.text.trim();
    return widget.controller.api.adminOrders(
      keyword: keyword.isEmpty ? null : keyword,
      status: _selectedStatus.isEmpty ? null : _selectedStatus,
      type: _selectedType.isEmpty ? null : _selectedType,
      page: _page,
      pageSize: _pageSize,
    );
  }

  Future<void> _reload({bool resetPage = false}) async {
    if (resetPage) {
      _page = 1;
    }
    setState(() {
      _future = _load();
    });
    await _future;
  }

  void _changeType(String value) {
    if (_selectedType == value) {
      return;
    }
    setState(() {
      _selectedType = value;
    });
    unawaited(_reload(resetPage: true));
  }

  void _changeStatus(String value) {
    if (_selectedStatus == value) {
      return;
    }
    setState(() {
      _selectedStatus = value;
    });
    unawaited(_reload(resetPage: true));
  }

  void _clearKeyword() {
    _keywordController.clear();
    unawaited(_reload(resetPage: true));
  }

  void _goToPage(int page) {
    if (page < 1 || page == _page) {
      return;
    }
    setState(() {
      _page = page;
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _reload,
      child: FutureBuilder<AdminOrderPage>(
        future: _future,
        builder: (context, snapshot) {
          final data = snapshot.data;
          final hasData = data != null && data.list.isNotEmpty;
          final hasNext =
              data != null && data.page * data.pageSize < data.total;
          final hasPrevious = _page > 1;

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              _SearchPanel(
                controller: _keywordController,
                hintText: '搜索取件地、送达地、备注或联系方式',
                onSearch: () => _reload(resetPage: true),
                onClear: _clearKeyword,
              ),
              const SizedBox(height: 12),
              _ChipFilterRow(
                options: const [
                  _ChipOption(label: '全部', value: ''),
                  _ChipOption(label: '快递', value: 'EXPRESS'),
                  _ChipOption(label: '餐食', value: 'FOOD'),
                  _ChipOption(label: '代取送', value: 'DELIVERY'),
                ],
                selectedValue: _selectedType,
                onChanged: _changeType,
              ),
              const SizedBox(height: 10),
              _ChipFilterRow(
                options: const [
                  _ChipOption(label: '全部状态', value: ''),
                  _ChipOption(label: '待接单', value: 'OPEN'),
                  _ChipOption(label: '已接单', value: 'ACCEPTED'),
                  _ChipOption(label: '配送中', value: 'IN_PROGRESS'),
                  _ChipOption(label: '已送达', value: 'DELIVERED'),
                  _ChipOption(label: '已完成', value: 'COMPLETED'),
                  _ChipOption(label: '已取消', value: 'CANCELLED'),
                  _ChipOption(label: '已过期', value: 'EXPIRED'),
                ],
                selectedValue: _selectedStatus,
                onChanged: _changeStatus,
              ),
              const SizedBox(height: 14),
              if (snapshot.connectionState == ConnectionState.waiting)
                const _SectionLoadingCard(text: '正在加载订单...')
              else if (snapshot.hasError)
                _SectionErrorCard(
                  message: snapshot.error?.toString() ?? '加载失败，请稍后重试',
                  onRetry: () => _reload(),
                )
              else if (!hasData)
                const _SectionEmptyCard(title: '暂无订单数据', hint: '可以换个搜索词或分类试试。')
              else ...[
                ...data.list.map(
                  (order) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _AdminOrderCard(
                      order: order,
                      onTap: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => AdminOrderDetailPage(
                              controller: widget.controller,
                              orderId: order.id,
                              onChanged: () => unawaited(_reload()),
                            ),
                          ),
                        );
                        await _reload();
                      },
                    ),
                  ),
                ),
                _CompactPagination(
                  page: data.page,
                  hasPrevious: hasPrevious,
                  hasNext: hasNext,
                  onPrevious: hasPrevious ? () => _goToPage(_page - 1) : null,
                  onNext: hasNext ? () => _goToPage(_page + 1) : null,
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class AdminReportsPage extends StatefulWidget {
  const AdminReportsPage({super.key, required this.controller});

  final AppController controller;

  @override
  State<AdminReportsPage> createState() => _AdminReportsPageState();
}

class _AdminReportsPageState extends State<AdminReportsPage> {
  static const int _pageSize = 10;

  final TextEditingController _keywordController = TextEditingController();
  late Future<AdminReportPage> _future;
  int _page = 1;
  String _selectedStatus = '';

  @override
  void initState() {
    super.initState();
    _keywordController.addListener(_handleKeywordChanged);
    _future = _load();
  }

  @override
  void dispose() {
    _keywordController.removeListener(_handleKeywordChanged);
    _keywordController.dispose();
    super.dispose();
  }

  void _handleKeywordChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<AdminReportPage> _load() {
    final keyword = _keywordController.text.trim();
    return widget.controller.api.adminReports(
      keyword: keyword.isEmpty ? null : keyword,
      status: _selectedStatus.isEmpty ? null : _selectedStatus,
      page: _page,
      pageSize: _pageSize,
    );
  }

  Future<void> _reload({bool resetPage = false}) async {
    if (resetPage) {
      _page = 1;
    }
    setState(() {
      _future = _load();
    });
    await _future;
  }

  void _changeStatus(String value) {
    if (_selectedStatus == value) {
      return;
    }
    setState(() {
      _selectedStatus = value;
    });
    unawaited(_reload(resetPage: true));
  }

  void _clearKeyword() {
    _keywordController.clear();
    unawaited(_reload(resetPage: true));
  }

  void _goToPage(int page) {
    if (page < 1 || page == _page) {
      return;
    }
    setState(() {
      _page = page;
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _reload,
      child: FutureBuilder<AdminReportPage>(
        future: _future,
        builder: (context, snapshot) {
          final data = snapshot.data;
          final hasData = data != null && data.list.isNotEmpty;
          final hasNext =
              data != null && data.page * data.pageSize < data.total;
          final hasPrevious = _page > 1;

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              _SearchPanel(
                controller: _keywordController,
                hintText: '搜索分类、目标类型、描述或编号',
                onSearch: () => _reload(resetPage: true),
                onClear: _clearKeyword,
              ),
              const SizedBox(height: 12),
              _ChipFilterRow(
                options: const [
                  _ChipOption(label: '全部', value: ''),
                  _ChipOption(label: '待处理', value: 'OPEN'),
                  _ChipOption(label: '已处理', value: 'RESOLVED'),
                  _ChipOption(label: '已驳回', value: 'REJECTED'),
                ],
                selectedValue: _selectedStatus,
                onChanged: _changeStatus,
              ),
              const SizedBox(height: 14),
              if (snapshot.connectionState == ConnectionState.waiting)
                const _SectionLoadingCard(text: '正在加载举报...')
              else if (snapshot.hasError)
                _SectionErrorCard(
                  message: snapshot.error?.toString() ?? '加载失败，请稍后重试',
                  onRetry: () => _reload(),
                )
              else if (!hasData)
                const _SectionEmptyCard(title: '暂无举报数据', hint: '可以换个关键词或状态试试。')
              else ...[
                ...data.list.map(
                  (report) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _AdminReportCard(
                      report: report,
                      onTap: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => AdminReportDetailPage(
                              controller: widget.controller,
                              report: report,
                              onChanged: () => unawaited(_reload()),
                            ),
                          ),
                        );
                        await _reload();
                      },
                    ),
                  ),
                ),
                _CompactPagination(
                  page: data.page,
                  hasPrevious: hasPrevious,
                  hasNext: hasNext,
                  onPrevious: hasPrevious ? () => _goToPage(_page - 1) : null,
                  onNext: hasNext ? () => _goToPage(_page + 1) : null,
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class AdminConfigPage extends StatefulWidget {
  const AdminConfigPage({super.key, required this.controller});

  final AppController controller;

  @override
  State<AdminConfigPage> createState() => _AdminConfigPageState();
}

class _AdminConfigPageState extends State<AdminConfigPage> {
  final _formKey = GlobalKey<FormState>();
  final _runnerController = TextEditingController();
  final _requesterController = TextEditingController();
  final _expireController = TextEditingController();
  final _concurrentController = TextEditingController();
  final _dailyController = TextEditingController();

  late Future<AdminConfig> _future;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _runnerController.dispose();
    _requesterController.dispose();
    _expireController.dispose();
    _concurrentController.dispose();
    _dailyController.dispose();
    super.dispose();
  }

  Future<AdminConfig> _load() async {
    final config = await widget.controller.api.adminConfig();
    if (!mounted) {
      return config;
    }
    _runnerController.text = config.cancelWindowRunnerMinutes.toString();
    _requesterController.text = config.cancelWindowRequesterMinutes.toString();
    _expireController.text = config.expireGraceMinutes.toString();
    _concurrentController.text = config.maxConcurrentOrders.toString();
    _dailyController.text = config.maxDailyAccept.toString();
    return config;
  }

  Future<void> _reload() async {
    setState(() {
      _future = _load();
    });
    await _future;
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    setState(() {
      _submitting = true;
    });

    try {
      await widget.controller.api.adminUpdateConfig(
        cancelWindowRunnerMinutes: int.parse(_runnerController.text.trim()),
        cancelWindowRequesterMinutes: int.parse(
          _requesterController.text.trim(),
        ),
        expireGraceMinutes: int.parse(_expireController.text.trim()),
        maxConcurrentOrders: int.parse(_concurrentController.text.trim()),
        maxDailyAccept: int.parse(_dailyController.text.trim()),
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('系统配置已更新')));
      await _reload();
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
    return RefreshIndicator(
      onRefresh: _reload,
      child: FutureBuilder<AdminConfig>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _AdminLoadingView();
          }
          if (snapshot.hasError) {
            return _AdminErrorView(
              message: snapshot.error?.toString() ?? '加载失败，请稍后重试',
              onRetry: () => _reload(),
            );
          }

          final config = snapshot.data;
          if (config == null) {
            return const _AdminEmptyView(message: '暂无系统配置');
          }

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '系统配置',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '最近更新时间：${_formatDateTime(config.updatedAt)}',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _NumberField(
                          controller: _runnerController,
                          label: '接单方取消窗口（分钟）',
                        ),
                        const SizedBox(height: 14),
                        _NumberField(
                          controller: _requesterController,
                          label: '发单方取消窗口（分钟）',
                        ),
                        const SizedBox(height: 14),
                        _NumberField(
                          controller: _expireController,
                          label: '订单过期宽限（分钟）',
                        ),
                        const SizedBox(height: 14),
                        _NumberField(
                          controller: _concurrentController,
                          label: '最大并发订单数',
                        ),
                        const SizedBox(height: 14),
                        _NumberField(
                          controller: _dailyController,
                          label: '每日最大接单数',
                        ),
                        const SizedBox(height: 18),
                        FilledButton(
                          onPressed: _submitting ? null : _submit,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: Text(_submitting ? '保存中...' : '保存配置'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _OverviewItem {
  const _OverviewItem(this.label, this.value, this.icon);

  final String label;
  final int value;
  final IconData icon;
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.item});

  final _OverviewItem item;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(item.icon, color: Theme.of(context).colorScheme.primary),
            Text(
              '${item.value}',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            Text(item.label, style: TextStyle(color: Colors.grey.shade700)),
          ],
        ),
      ),
    );
  }
}

class _SearchPanel extends StatelessWidget {
  const _SearchPanel({
    required this.controller,
    required this.hintText,
    required this.onSearch,
    required this.onClear,
  });

  final TextEditingController controller;
  final String hintText;
  final VoidCallback onSearch;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textInputAction: TextInputAction.search,
      onSubmitted: (_) => onSearch(),
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: controller.text.trim().isEmpty
            ? IconButton(
                onPressed: onSearch,
                icon: const Icon(Icons.arrow_forward_rounded),
              )
            : IconButton(
                onPressed: onClear,
                icon: const Icon(Icons.close_rounded),
              ),
      ),
    );
  }
}

class _ChipFilterRow extends StatelessWidget {
  const _ChipFilterRow({
    required this.options,
    required this.selectedValue,
    required this.onChanged,
  });

  final List<_ChipOption> options;
  final String selectedValue;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: options
            .map((item) {
              final selected = item.value == selectedValue;
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: ChoiceChip(
                  label: Text(item.label),
                  selected: selected,
                  onSelected: (_) => onChanged(item.value),
                  selectedColor: const Color(0xFFDCFCE7),
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                    side: BorderSide(
                      color: selected
                          ? const Color(0xFF22C55E)
                          : const Color(0xFFD1D5DB),
                    ),
                  ),
                  labelStyle: TextStyle(
                    color: selected
                        ? const Color(0xFF166534)
                        : const Color(0xFF374151),
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              );
            })
            .toList(growable: false),
      ),
    );
  }
}

class _ChipOption {
  const _ChipOption({required this.label, required this.value});

  final String label;
  final String value;
}

class _AdminUserCard extends StatelessWidget {
  const _AdminUserCard({required this.user, required this.onTap});

  final AdminUserSummary user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFFE2E8F0),
                    backgroundImage: user.avatarUrl != null
                        ? NetworkImage(user.avatarUrl!)
                        : null,
                    child: user.avatarUrl == null
                        ? Text(
                            user.displayName.substring(0, 1),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF334155),
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.displayName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '@${user.username}',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.grey.shade500,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _MiniTag(text: adminUserRoleLabel(user.role)),
                  const SizedBox(width: 8),
                  _MiniTag(
                    text: adminUserStatusLabel(user.status),
                    color: user.status == 'ACTIVE'
                        ? const Color(0xFF16A34A)
                        : const Color(0xFFDC2626),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _PlainInfoLine(label: '手机号', value: user.phoneText),
              _PlainInfoLine(
                label: '创建时间',
                value: _formatDateTime(user.createdAt),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminOrderCard extends StatelessWidget {
  const _AdminOrderCard({required this.order, required this.onTap});

  final AdminOrderSummary order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _MiniTag(text: orderTypeLabel(order.type)),
                  const SizedBox(width: 8),
                  _MiniTag(
                    text: orderStatusLabel(order.status),
                    color: _orderStatusColor(order.status),
                  ),
                  if (order.abnormalFlag) ...[
                    const SizedBox(width: 8),
                    const _MiniTag(text: '异常', color: Color(0xFFDC2626)),
                  ],
                  const Spacer(),
                  Text(
                    '¥${order.rewardAmount}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _RouteLine(
                icon: Icons.radio_button_checked_rounded,
                color: const Color(0xFF0F766E),
                label: '取件',
                value: order.pickupLocation,
              ),
              const SizedBox(height: 10),
              _RouteLine(
                icon: Icons.location_on_rounded,
                color: const Color(0xFFEA580C),
                label: '送达',
                value: order.dropoffLocation,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '发单人 ${order.requesterDisplayName}',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.grey.shade500,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _PlainInfoLine(
                label: '期望时间',
                value: _formatDateTime(order.expectedTime),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminReportCard extends StatelessWidget {
  const _AdminReportCard({required this.report, required this.onTap});

  final AdminReportSummary report;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _MiniTag(text: report.category),
                  const SizedBox(width: 8),
                  _MiniTag(
                    text: adminReportStatusLabel(report.status),
                    color: _reportStatusColor(report.status),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.grey.shade500,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '${report.targetType} #${report.targetId}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                report.description?.trim().isNotEmpty == true
                    ? report.description!
                    : '暂无详细说明',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey.shade700, height: 1.45),
              ),
              const SizedBox(height: 10),
              _PlainInfoLine(
                label: '提交时间',
                value: _formatDateTime(report.createdAt),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RouteLine extends StatelessWidget {
  const _RouteLine({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        SizedBox(
          width: 34,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _MiniTag extends StatelessWidget {
  const _MiniTag({required this.text, this.color = const Color(0xFF2563EB)});

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

class _PlainInfoLine extends StatelessWidget {
  const _PlainInfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('$label  ', style: TextStyle(color: Colors.grey.shade600)),
        Expanded(child: Text(value)),
      ],
    );
  }
}

class _CompactPagination extends StatelessWidget {
  const _CompactPagination({
    required this.page,
    required this.hasPrevious,
    required this.hasNext,
    required this.onPrevious,
    required this.onNext,
  });

  final int page;
  final bool hasPrevious;
  final bool hasNext;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final textStyle = TextStyle(
      fontSize: 12,
      color: Colors.grey.shade600,
      fontWeight: FontWeight.w600,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 2, 4, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _PageAction(
            enabled: hasPrevious,
            label: '上一页',
            icon: Icons.chevron_left_rounded,
            onTap: onPrevious,
          ),
          const SizedBox(width: 10),
          Text('第 $page 页', style: textStyle),
          const SizedBox(width: 10),
          _PageAction(
            enabled: hasNext,
            label: '下一页',
            icon: Icons.chevron_right_rounded,
            trailingIcon: true,
            onTap: onNext,
          ),
        ],
      ),
    );
  }
}

class _PageAction extends StatelessWidget {
  const _PageAction({
    required this.enabled,
    required this.label,
    required this.icon,
    required this.onTap,
    this.trailingIcon = false,
  });

  final bool enabled;
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool trailingIcon;

  @override
  Widget build(BuildContext context) {
    final color = enabled ? const Color(0xFF0F766E) : const Color(0xFF9CA3AF);
    final content = [
      if (!trailingIcon) Icon(icon, size: 14, color: color),
      if (!trailingIcon) const SizedBox(width: 1),
      Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
      if (trailingIcon) const SizedBox(width: 1),
      if (trailingIcon) Icon(icon, size: 14, color: color),
    ];

    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(999),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(mainAxisSize: MainAxisSize.min, children: content),
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({required this.controller, required this.label});

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label),
      validator: (value) {
        final text = value?.trim() ?? '';
        final parsed = int.tryParse(text);
        if (parsed == null) {
          return '请输入整数';
        }
        if (parsed < 0) {
          return '不能小于 0';
        }
        return null;
      },
    );
  }
}

class _AdminLoadingView extends StatelessWidget {
  const _AdminLoadingView();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(height: 220),
        Center(child: CircularProgressIndicator()),
      ],
    );
  }
}

class _AdminEmptyView extends StatelessWidget {
  const _AdminEmptyView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 220),
        Center(
          child: Text(message, style: TextStyle(color: Colors.grey.shade600)),
        ),
      ],
    );
  }
}

class _AdminErrorView extends StatelessWidget {
  const _AdminErrorView({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 32),
        _SectionErrorCard(
          message: message,
          onRetry: () => unawaited(onRetry()),
        ),
      ],
    );
  }
}

class _SectionLoadingCard extends StatelessWidget {
  const _SectionLoadingCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 12),
            Text(text),
          ],
        ),
      ),
    );
  }
}

class _SectionEmptyCard extends StatelessWidget {
  const _SectionEmptyCard({required this.title, required this.hint});

  final String title;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            Icon(Icons.inbox_outlined, size: 44, color: Colors.grey.shade500),
            const SizedBox(height: 12),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              hint,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionErrorCard extends StatelessWidget {
  const _SectionErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '加载失败',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(message),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('重新加载')),
          ],
        ),
      ),
    );
  }
}

String _formatDateTime(DateTime? value) {
  if (value == null) {
    return '时间待定';
  }
  return DateFormat('yyyy-MM-dd HH:mm').format(value.toLocal());
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
