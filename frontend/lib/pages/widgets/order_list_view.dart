import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/models/order_models.dart';
import 'order_summary_card.dart';

typedef OrderPageFetcher =
    Future<OrderPage> Function({
      required int page,
      required int pageSize,
      String? keyword,
      String? type,
    });

typedef OrderTapHandler =
    Future<void> Function(OrderSummary order, VoidCallback refresh);

class OrderListView extends StatefulWidget {
  const OrderListView({
    super.key,
    required this.fetchPage,
    required this.onTapOrder,
    required this.emptyMessage,
    this.emptyHint,
    this.showFilters = true,
  });

  final OrderPageFetcher fetchPage;
  final OrderTapHandler onTapOrder;
  final String emptyMessage;
  final String? emptyHint;
  final bool showFilters;

  @override
  State<OrderListView> createState() => _OrderListViewState();
}

class _OrderListViewState extends State<OrderListView> {
  static const int _pageSize = 10;
  static const List<_CategoryOption> _categories = [
    _CategoryOption(label: '全部', value: ''),
    _CategoryOption(label: '快递', value: 'EXPRESS'),
    _CategoryOption(label: '餐食', value: 'FOOD'),
    _CategoryOption(label: '代取送', value: 'DELIVERY'),
  ];

  final TextEditingController _keywordController = TextEditingController();

  late Future<OrderPage> _future;
  int _page = 1;
  String _selectedType = '';

  @override
  void initState() {
    super.initState();
    _keywordController.addListener(_handleKeywordChanged);
    _future = _loadOrders();
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

  Future<OrderPage> _loadOrders() {
    final keyword = _keywordController.text.trim();
    return widget.fetchPage(
      page: _page,
      pageSize: _pageSize,
      keyword: keyword.isEmpty ? null : keyword,
      type: _selectedType.isEmpty ? null : _selectedType,
    );
  }

  Future<void> _reload({bool resetPage = false}) async {
    if (resetPage) {
      _page = 1;
    }
    setState(() {
      _future = _loadOrders();
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
      _future = _loadOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _reload,
      child: FutureBuilder<OrderPage>(
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
              if (widget.showFilters) ...[
                _FilterHeader(
                  keywordController: _keywordController,
                  selectedType: _selectedType,
                  categories: _categories,
                  onSearch: () => _reload(resetPage: true),
                  onClearKeyword: _clearKeyword,
                  onTypeChanged: _changeType,
                ),
                const SizedBox(height: 14),
              ],
              if (snapshot.connectionState == ConnectionState.waiting)
                const _LoadingCard()
              else if (snapshot.hasError)
                _ErrorCard(
                  message: snapshot.error?.toString() ?? '加载失败，请稍后重试',
                  onRetry: _reload,
                )
              else if (!hasData)
                _EmptyCard(title: widget.emptyMessage, hint: widget.emptyHint)
              else ...[
                ...data.list.map(
                  (order) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: OrderSummaryCard(
                      order: order,
                      onTap: () {
                        unawaited(
                          widget.onTapOrder(order, () {
                            unawaited(_reload());
                          }),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                _PaginationFooter(
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

class _FilterHeader extends StatelessWidget {
  const _FilterHeader({
    required this.keywordController,
    required this.selectedType,
    required this.categories,
    required this.onSearch,
    required this.onClearKeyword,
    required this.onTypeChanged,
  });

  final TextEditingController keywordController;
  final String selectedType;
  final List<_CategoryOption> categories;
  final VoidCallback onSearch;
  final VoidCallback onClearKeyword;
  final ValueChanged<String> onTypeChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: keywordController,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => onSearch(),
          decoration: InputDecoration(
            hintText: '搜索取件地、送达地或备注',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: keywordController.text.trim().isEmpty
                ? IconButton(
                    onPressed: onSearch,
                    icon: const Icon(Icons.arrow_forward_rounded),
                  )
                : IconButton(
                    onPressed: onClearKeyword,
                    icon: const Icon(Icons.close_rounded),
                  ),
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: categories
                .map((item) {
                  final selected = item.value == selectedType;
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: ChoiceChip(
                      label: Text(item.label),
                      selected: selected,
                      onSelected: (_) => onTypeChanged(item.value),
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
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  );
                })
                .toList(growable: false),
          ),
        ),
      ],
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: const [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('正在加载订单...'),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function({bool resetPage}) onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '订单加载失败',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(message),
            const SizedBox(height: 16),
            FilledButton(onPressed: () => onRetry(), child: const Text('重新加载')),
          ],
        ),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.title, this.hint});

  final String title;
  final String? hint;

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
            if (hint != null) ...[
              const SizedBox(height: 8),
              Text(
                hint!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PaginationFooter extends StatelessWidget {
  const _PaginationFooter({
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

class _CategoryOption {
  const _CategoryOption({required this.label, required this.value});

  final String label;
  final String value;
}
