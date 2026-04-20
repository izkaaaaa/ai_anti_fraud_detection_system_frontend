import 'package:flutter/material.dart';
import 'package:ai_anti_fraud_detection_system_frontend/pages/LearningCenter/PostDetailPage.dart';
import 'package:ai_anti_fraud_detection_system_frontend/utils/DioRequest.dart';
import 'package:ai_anti_fraud_detection_system_frontend/services/auth_service.dart';
import 'package:animations/animations.dart';

const _accent = Color(0xFF58A183);
const _bg = Color(0xFFF8FAF9);

// ==================== 案例库卡片（两列，绿色系，更扁平） ====================
class CaseCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final int index;

  const CaseCard({super.key, required this.item, required this.index});

  static const _bgImages = [
    'lib/UIimages/案例库背景1.png',
    'lib/UIimages/案例库背景2.png',
    'lib/UIimages/案例库背景3.png',
  ];

  @override
  Widget build(BuildContext context) {
    final title = item['title']?.toString() ?? '未知案例';
    final bgAsset = _bgImages[index % _bgImages.length];

    return OpenContainer(
      transitionType: ContainerTransitionType.fadeThrough,
      transitionDuration: const Duration(milliseconds: 500),
      openBuilder: (context, _) => PostDetailPage(data: item, source: 'case'),
      closedBuilder: (context, openContainer) => _ClosedCaseCard(
        title: title,
        bgAsset: bgAsset,
        fraudType: item['fraud_type']?.toString() ?? '',
        onTap: openContainer,
      ),
      closedElevation: 0,
      closedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      closedColor: Colors.white,
    );
  }
}

class _ClosedCaseCard extends StatelessWidget {
  final String title;
  final String bgAsset;
  final String fraudType;
  final VoidCallback onTap;

  const _ClosedCaseCard({
    required this.title,
    required this.bgAsset,
    required this.fraudType,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
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
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(bgAsset, fit: BoxFit.cover),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.77),
                      Colors.white.withValues(alpha: 0.66),
                    ],
                  ),
                ),
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF22C55E).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        fraudType,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF22C55E),
                          fontWeight: FontWeight.w600,
                        ),
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
                    _SectionRecommend(
                      userInfo: _userInfo,
                      accentColor: _accent,
                    ),
                    _SectionCaseList(userInfo: _userInfo),
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

// ==================== 为你推荐（PageView轮播，视频优先） ====================
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
          height: 220,
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

// ==================== 推荐卡片（使用OpenContainer容器转换） ====================
class _RecommendCard extends StatelessWidget {
  final Map<String, dynamic> item;

  const _RecommendCard({required this.item});

  Color get _cardColor {
    switch (item['type']?.toString()) {
      case 'video':
        return const Color(0xFF10B981);
      case 'case':
        return const Color(0xFF3B82F6);
      case 'slogan':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF58A183);
    }
  }

  int? get _videoIndex {
    final url = item['video_url']?.toString() ??
        item['url']?.toString() ??
        item['video_id']?.toString() ??
        '';
    final match = RegExp(r'(\d+)').firstMatch(url);
    if (match != null) {
      final idx = int.tryParse(match.group(1) ?? '');
      if (idx != null && idx >= 1 && idx <= 10) return idx;
    }
    return null;
  }

  String get _coverAsset {
    final idx = _videoIndex;
    if (idx != null) {
      return 'lib/assets/edu_video/$idx.png';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final type = item['type']?.toString();
    final title = item['title']?.toString() ?? item['content']?.toString() ?? '';
    final fraudType = item['fraud_type']?.toString() ?? '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 16),
      child: AspectRatio(
        aspectRatio: 1 / 2,
        child: OpenContainer(
          transitionType: ContainerTransitionType.fadeThrough,
          transitionDuration: const Duration(milliseconds: 500),
          openBuilder: (context, _) => PostDetailPage(data: item, source: 'recommendation'),
          closedBuilder: (context, openContainer) => _ClosedRecommendCard(
            item: item,
            cardColor: _cardColor,
            videoIndex: _videoIndex,
            coverAsset: _coverAsset,
            onTap: openContainer,
          ),
          closedElevation: 4,
          closedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          closedColor: _cardColor,
        ),
      ),
    );
  }
}

// ==================== 关闭状态的推荐卡片组件（用于OpenContainer） ====================
class _ClosedRecommendCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final Color cardColor;
  final int? videoIndex;
  final String coverAsset;
  final VoidCallback onTap;

  const _ClosedRecommendCard({
    required this.item,
    required this.cardColor,
    required this.videoIndex,
    required this.coverAsset,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final type = item['type']?.toString();
    final title = item['title']?.toString() ?? item['content']?.toString() ?? '';
    final fraudType = item['fraud_type']?.toString() ?? '';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: cardColor.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (type == 'video' && videoIndex != null)
                Image.asset(
                  coverAsset,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildGradientBg(),
                )
              else
                _buildGradientBg(),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.1),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.5),
                      ],
                      stops: const [0, 0.4, 0.85],
                    ),
                  ),
                ),
              ),
              if (type == 'video')
                Center(
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.play_arrow_rounded,
                      color: cardColor,
                      size: 32,
                    ),
                  ),
                ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (fraudType.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            fraudType,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.95),
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
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
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ],
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

  Widget _buildGradientBg() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cardColor.withValues(alpha: 0.85),
            cardColor,
          ],
        ),
      ),
    );
  }
}

// ==================== 案例库（分类Tab + 两列Grid） ====================
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
                      itemBuilder: (context, i) => CaseCard(item: _filteredCases[i], index: i),
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
