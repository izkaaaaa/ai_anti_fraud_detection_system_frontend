import 'package:flutter/material.dart';
import 'package:ai_anti_fraud_detection_system_frontend/pages/LearningCenter/PostDetailPage.dart';
import 'package:ai_anti_fraud_detection_system_frontend/utils/DioRequest.dart';
import 'package:ai_anti_fraud_detection_system_frontend/services/auth_service.dart';

const _accent = Color(0xFF58A183);
const _bg = Color(0xFFF8FAF9);

// ==================== 案例库卡片（两列，绿色系，更扁平） ====================
class CaseCard extends StatelessWidget {
  final Map<String, dynamic> item;

  const CaseCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final title = item['title']?.toString() ?? '未知案例';

    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PostDetailPage(data: item, source: 'case'),
        ),
      ),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F1923),
                height: 1.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              item['fraud_type']?.toString() ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF22C55E),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== 法律库折叠项 ====================
class LawExpandTile extends StatefulWidget {
  final Map<String, dynamic> item;

  const LawExpandTile({super.key, required this.item});

  @override
  State<LawExpandTile> createState() => _LawExpandTileState();
}

class _LawExpandTileState extends State<LawExpandTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final title = widget.item['title']?.toString() ?? '未知法律';
    final content = widget.item['content']?.toString() ?? '';
    final penalty = widget.item['penalty']?.toString();
    final fraudType = widget.item['fraud_type']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.gavel, color: Color(0xFF10B981), size: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: _expanded ? null : 1,
                          overflow: _expanded ? null : TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _expanded ? const Color(0xFF10B981) : const Color(0xFF0F1923),
                          ),
                        ),
                        if (!_expanded && fraudType.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              fraudType,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF10B981),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 200),
                    turns: _expanded ? 0.5 : 0,
                    child: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF9CA3AF), size: 20),
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 1,
                    color: const Color(0xFFE5E7EB),
                    margin: const EdgeInsets.only(bottom: 12),
                  ),
                  Text(
                    content,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B7280),
                      height: 1.7,
                    ),
                  ),
                  if (penalty != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC2626).withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 13),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              '处罚: $penalty',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFFDC2626),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PostDetailPage(data: widget.item, source: 'law'),
                        ),
                      ),
                      child: const Text(
                        '查看全文 →',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF10B981),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ==================== 主页面 ====================
class LearningCenterPage extends StatefulWidget {
  const LearningCenterPage({super.key});

  @override
  State<LearningCenterPage> createState() => _LearningCenterPageState();
}

class _LearningCenterPageState extends State<LearningCenterPage> {
  Map<String, dynamic>? _userInfo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      final info = await AuthService().getCurrentUser();
      setState(() {
        _userInfo = info;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _accent))
          : CustomScrollView(
              slivers: [
                _buildAppBar(),
                SliverList(
                  delegate: SliverChildListDelegate([
                    // 为你推荐（轮播，视频优先，无标题）
                    _SectionRecommend(
                      userInfo: _userInfo,
                      accentColor: _accent,
                    ),

                    // 案例库（分类tab + 两列）
                    _SectionCaseList(userInfo: _userInfo),

                    // 法律库（分类tab + 折叠）
                    _SectionLawList(userInfo: _userInfo),

                    const SizedBox(height: 60),
                  ]),
                ),
              ],
            ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      backgroundColor: _bg,
      elevation: 0,
      scrolledUnderElevation: 0,
      pinned: true,
      expandedHeight: 80,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        title: const Text(
          '学习中心',
          style: TextStyle(
            color: Color(0xFF0F1923),
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ==================== 为你推荐（PageView轮播，视频优先，只显示标题+类型） ====================
class _SectionRecommend extends StatefulWidget {
  final Map<String, dynamic>? userInfo;
  final Color accentColor;

  const _SectionRecommend({this.userInfo, required this.accentColor});

  @override
  State<_SectionRecommend> createState() => _SectionRecommendState();
}

class _SectionRecommendState extends State<_SectionRecommend> {
  bool _loading = true;
  List<Map<String, dynamic>> _items = [];
  final PageController _pageController = PageController(viewportFraction: 0.88);
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final userId = widget.userInfo?['user_id'];
    if (userId == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final res = await dioRequest.get(
        '/api/education/recommendations/profile/$userId',
        params: {'limit': 6},
      );
      if (res != null && res['data'] != null) {
        final data = res['data'];
        final cases = (data['cases'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        final slogans = (data['slogans'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        final videos = (data['videos'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        setState(() {
          // 视频排最前面
          _items = [
            ...videos.map((v) => {'type': 'video', ...v}),
            ...cases.map((c) => {'type': 'case', ...c}),
            ...slogans.map((s) => {'type': 'slogan', ...s}),
          ];
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 165,
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: _accent))
              : _items.isEmpty
                  ? const Center(
                      child: Text('暂无推荐内容',
                          style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)))
                  : Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: PageView.builder(
                            controller: _pageController,
                            itemCount: _items.length,
                            onPageChanged: (i) => setState(() => _currentPage = i),
                            itemBuilder: (context, i) => _RecommendCard(item: _items[i]),
                          ),
                        ),
                        // 底部小点点
                        if (_items.length > 1)
                          Positioned(
                            bottom: 8,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(_items.length, (i) {
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.symmetric(horizontal: 3),
                                  width: i == _currentPage ? 16 : 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: i == _currentPage
                                        ? const Color(0xFF58A183)
                                        : const Color(0xFFD1D5DB),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                );
                              }),
                            ),
                          ),
                      ],
                    ),
        ),
      ],
    );
  }
}

class _RecommendCard extends StatelessWidget {
  final Map<String, dynamic> item;

  const _RecommendCard({required this.item});

  Color get _cardColor {
    switch (item['type']?.toString()) {
      case 'video':
        return const Color(0xFF10B981); // 绿色
      case 'case':
        return const Color(0xFF3B82F6); // 蓝色
      case 'slogan':
        return const Color(0xFFF59E0B); // 橙色
      default:
        return const Color(0xFF58A183);
    }
  }

  @override
  Widget build(BuildContext context) {
    final type = item['type']?.toString();
    final title = item['title']?.toString() ?? item['content']?.toString() ?? '';
    final fraudType = item['fraud_type']?.toString() ?? '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 20),
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PostDetailPage(data: item, source: 'recommendation'),
          ),
        ),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _cardColor.withValues(alpha: 0.85),
                _cardColor,
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: _cardColor.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              // 视频类型显示封面效果（渐变叠加层）
              if (type == 'video')
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0.15),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.2),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.play_arrow, color: Colors.white, size: 26),
                      ),
                    ),
                  ),
                ),
              // 内容
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (fraudType.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          fraudType,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== 案例库（分类Tab + 两列Grid，绿色系） ====================
class _SectionCaseList extends StatefulWidget {
  final Map<String, dynamic>? userInfo;

  const _SectionCaseList({this.userInfo});

  @override
  State<_SectionCaseList> createState() => _SectionCaseListState();
}

class _SectionCaseListState extends State<_SectionCaseList> {
  bool _loading = true;
  List<Map<String, dynamic>> _allCases = [];
  List<String> _categories = ['全部'];
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final userId = widget.userInfo?['user_id'];
    if (userId == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final res = await dioRequest.get(
        '/api/education/recommendations/library/$userId',
        params: {'limit': 50},
      );
      if (res != null && res['data'] != null) {
        final cases = (res['data']['cases'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        final fraudTypes = cases
            .map((c) => c['fraud_type']?.toString())
            .where((t) => t != null && t.isNotEmpty)
            .toSet()
            .cast<String>()
            .toList();
        fraudTypes.sort();
        setState(() {
          _allCases = cases;
          _categories = ['全部', ...fraudTypes];
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredCases {
    if (_selectedTab == 0) return _allCases;
    final cat = _categories[_selectedTab];
    return _allCases.where((c) => c['fraud_type']?.toString() == cat).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('案例库', Icons.library_books_outlined, const Color(0xFF22C55E)),
        // 分类Tab
        if (_categories.length > 1)
          SizedBox(
            height: 36,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (context, i) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _categoryChip(_categories[i], i),
              ),
            ),
          ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _loading
              ? const SizedBox(
                  height: 100,
                  child: Center(child: CircularProgressIndicator(color: _accent)))
              : _filteredCases.isEmpty
                  ? const SizedBox(
                      height: 60,
                      child: Center(
                        child: Text('暂无案例',
                            style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
                      ),
                    )
                  : GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 1.45,
                      ),
                      itemCount: _filteredCases.length,
                      itemBuilder: (context, i) => CaseCard(item: _filteredCases[i]),
                    ),
        ),
      ],
    );
  }

  Widget _categoryChip(String label, int i) {
    final selected = _selectedTab == i;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = i),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF22C55E) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? const Color(0xFF22C55E) : const Color(0xFFE5E7EB),
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: const Color(0xFF22C55E).withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : const Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }
}

// ==================== 法律库（分类Tab + 折叠列表） ====================
class _SectionLawList extends StatefulWidget {
  final Map<String, dynamic>? userInfo;

  const _SectionLawList({this.userInfo});

  @override
  State<_SectionLawList> createState() => _SectionLawListState();
}

class _SectionLawListState extends State<_SectionLawList> {
  bool _loading = true;
  List<Map<String, dynamic>> _allLaws = [];
  List<String> _categories = ['全部'];
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final userId = widget.userInfo?['user_id'];
    if (userId == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final res = await dioRequest.get(
        '/api/education/recommendations/library/$userId',
        params: {'limit': 50},
      );
      if (res != null && res['data'] != null) {
        final laws = (res['data']['laws'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        final fraudTypes = laws
            .map((l) => l['fraud_type']?.toString())
            .where((t) => t != null && t.isNotEmpty)
            .toSet()
            .cast<String>()
            .toList();
        fraudTypes.sort();
        setState(() {
          _allLaws = laws;
          _categories = ['全部', ...fraudTypes];
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredLaws {
    if (_selectedTab == 0) return _allLaws;
    final cat = _categories[_selectedTab];
    return _allLaws.where((l) => l['fraud_type']?.toString() == cat).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('法律库', Icons.gavel_outlined, const Color(0xFF10B981)),
        // 分类Tab
        if (_categories.length > 1)
          SizedBox(
            height: 36,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (context, i) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _lawCategoryChip(_categories[i], i),
              ),
            ),
          ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _loading
              ? const SizedBox(
                  height: 100,
                  child: Center(child: CircularProgressIndicator(color: _accent)))
              : _filteredLaws.isEmpty
                  ? const SizedBox(
                      height: 60,
                      child: Center(
                        child: Text('暂无法律条款',
                            style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _filteredLaws.length,
                      itemBuilder: (context, i) => LawExpandTile(item: _filteredLaws[i]),
                    ),
        ),
      ],
    );
  }

  Widget _lawCategoryChip(String label, int i) {
    final selected = _selectedTab == i;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = i),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF10B981) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? const Color(0xFF10B981) : const Color(0xFFE5E7EB),
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : const Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }
}

// Section 标题通用组件
Widget _sectionTitle(String title, IconData icon, Color color) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
    child: Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    ),
  );
}
