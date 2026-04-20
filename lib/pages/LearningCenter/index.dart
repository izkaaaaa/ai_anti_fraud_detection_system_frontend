import 'dart:async';
import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:ai_anti_fraud_detection_system_frontend/pages/LearningCenter/PostDetailPage.dart';
import 'package:ai_anti_fraud_detection_system_frontend/utils/DioRequest.dart';
import 'package:ai_anti_fraud_detection_system_frontend/services/auth_service.dart';

const _accent = Color(0xFF58A183);
const _bg = Color(0xFFF8FAF9);

// ==================== 案例库卡片（两列，绿色系，更扁平） ====================
class CaseCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final int index;

  const CaseCard({super.key, required this.item, required this.index});

  @override
  Widget build(BuildContext context) {
    final title = item['title']?.toString() ?? '未知案例';
    final fraudType = item['fraud_type']?.toString();
    final bgIndex = (index % 3) + 1;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PostDetailPage(data: item, source: 'case'),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -8,
              bottom: -8,
              child: Opacity(
                opacity: 0.08,
                child: Image.asset('lib/UIimages/案例库背景$bgIndex.png', width: 80, height: 80, fit: BoxFit.contain),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF58A183).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    fraudType?.isNotEmpty == true ? fraudType! : '诈骗',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF58A183), fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F1923), height: 1.4),
                ),
              ],
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
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.gavel, color: Color(0xFF10B981), size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: _expanded ? null : 2,
                          overflow: _expanded ? null : TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: _expanded ? const Color(0xFF10B981) : const Color(0xFF0F1923),
                          ),
                        ),
                        if (!_expanded && fraudType.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              fraudType,
                              style: const TextStyle(
                                fontSize: 11,
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
                    child: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF9CA3AF), size: 22),
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 1,
                    color: const Color(0xFFE5E7EB),
                    margin: const EdgeInsets.only(bottom: 14),
                  ),
                  Text(
                    content,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF6B7280),
                      height: 1.9,
                    ),
                  ),
                  if (penalty != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDC2626).withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 15),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              '处罚: $penalty',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFFDC2626),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PostDetailPage(data: widget.item, source: 'law'),
                        ),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '查看全文 →',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF10B981),
                            fontWeight: FontWeight.w600,
                          ),
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
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ==================== 为你推荐（视频轮播 + 标语 + 案例） ====================
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
  final PageController _videoPageController = PageController(viewportFraction: 0.88);
  int _videoPage = 0;
  Timer? _sloganTimer;
  int _sloganIndex = 0;

  List<Map<String, dynamic>> get _videos =>
      _items.where((i) => i['type'] == 'video').toList();

  List<Map<String, dynamic>> get _cases =>
      _items.where((i) => i['type'] == 'case').toList();

  List<Map<String, dynamic>> get _slogans =>
      _items.where((i) => i['type'] == 'slogan').toList();

  @override
  void initState() {
    super.initState();
    _load();
    _startSloganTimer();
  }

  @override
  void dispose() {
    _videoPageController.dispose();
    _sloganTimer?.cancel();
    super.dispose();
  }

  void _startSloganTimer() {
    _sloganTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_slogans.isNotEmpty && mounted) {
        setState(() => _sloganIndex = (_sloganIndex + 1) % _slogans.length);
      }
    });
  }

  Future<void> _load() async {
    final userId = widget.userInfo?['user_id'];
    if (userId == null) { setState(() => _loading = false); return; }
    try {
      final res = await dioRequest.get(
        '/api/education/recommendations/profile/$userId', params: {'limit': 20},
      );
      if (res != null && res['data'] != null) {
        final data = res['data'];
        setState(() {
          _items = [
            ...(data['videos'] as List?)?.cast<Map<String, dynamic>>().map((v) => {'type': 'video', ...v}) ?? [],
            ...(data['cases'] as List?)?.cast<Map<String, dynamic>>().map((c) => {'type': 'case', ...c}) ?? [],
            ...(data['slogans'] as List?)?.cast<Map<String, dynamic>>().map((s) => {'type': 'slogan', ...s}) ?? [],
          ];
          _loading = false;
        });
      } else { setState(() => _loading = false); }
    } catch (e) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: CircularProgressIndicator(color: _accent)),
      );
    }
    if (_items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: Text('暂无推荐内容', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13))),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 视频轮播
        if (_videos.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              height: 300,
              child: Stack(
                children: [
                  PageView.builder(
                    controller: _videoPageController,
                    itemCount: _videos.length,
                    onPageChanged: (i) => setState(() => _videoPage = i),
                    itemBuilder: (context, i) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: _VideoCard(item: _videos[i]),
                    ),
                  ),
                  if (_videos.length > 1)
                    Positioned(
                      bottom: 12, left: 0, right: 0,
                      child: Center(
                        child: SmoothPageIndicator(
                          controller: _videoPageController,
                          count: _videos.length,
                          effect: const ExpandingDotsEffect(
                            dotWidth: 8,
                            dotHeight: 8,
                            spacing: 6,
                            expansionFactor: 4,
                            activeDotColor: Color(0xFF58A183),
                            dotColor: Color(0xFFD1D5DB),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],

        // 标语轮播
        if (_slogans.isNotEmpty) ...[
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Image.asset('lib/UIimages/警察.png', width: 40, height: 40,
                  errorBuilder: (_, __, ___) => Container(width: 40, height: 40,
                    decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.warning_amber, color: Colors.grey))),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('安讯提醒您：', style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 500),
                        child: Text(_slogans[_sloganIndex]['content']?.toString() ?? _slogans[_sloganIndex]['slogan']?.toString() ?? '',
                          key: ValueKey(_sloganIndex),
                          style: const TextStyle(fontSize: 15, color: Color(0xFF0F1923), fontWeight: FontWeight.w600, height: 1.3)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],

        // 参考案例
        if (_cases.isNotEmpty) ...[
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Container(width: 4, height: 20, decoration: BoxDecoration(color: const Color(0xFF58A183), borderRadius: BorderRadius.circular(2))),
                const SizedBox(width: 8),
                const Text('参考案例', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF0F1923))),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _cases.asMap().entries.map<Widget>((e) {
                return SizedBox(
                  width: (MediaQuery.of(context).size.width - 32 - 12) / 2,
                  child: CaseCard(item: e.value, index: e.key),
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }
}

// ==================== 视频卡片（竖屏高卡片） ====================
class _VideoCard extends StatelessWidget {
  final Map<String, dynamic> item;
  const _VideoCard({required this.item});

  int? get _videoIndex {
    final url = item['video_url']?.toString() ?? item['url']?.toString() ?? item['video_id']?.toString() ?? '';
    final match = RegExp(r'(\d+)').firstMatch(url);
    if (match != null) { final idx = int.tryParse(match.group(1) ?? ''); if (idx != null && idx >= 1 && idx <= 10) return idx; }
    return null;
  }
  String get _coverAsset { final idx = _videoIndex; return idx != null ? 'lib/assets/edu_video/$idx.png' : ''; }

  @override
  Widget build(BuildContext context) {
    final title = item['title']?.toString() ?? '';
    final fraudType = item['fraud_type']?.toString() ?? '';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PostDetailPage(data: item, source: 'recommendation'),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 12, offset: const Offset(0, 6))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (_coverAsset.isNotEmpty)
                Image.asset(_coverAsset, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: const Color(0xFF10B981)))
              else Container(color: const Color(0xFF10B981)),
              Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [Colors.black.withValues(alpha: 0.05), Colors.transparent, Colors.black.withValues(alpha: 0.65)], stops: const [0, 0.35, 0.85]))),
              Center(child: Container(width: 52, height: 52, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.92), shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 2))]),
                child: const Icon(Icons.play_arrow_rounded, color: Color(0xFF10B981), size: 34))),
              Positioned(top: 10, right: 10, child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(4)),
                child: const Text('视频', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)))),
              Positioned(left: 12, right: 12, bottom: 14, child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  if (fraudType.isNotEmpty) ...[
                    Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.25), borderRadius: BorderRadius.circular(4)),
                      child: Text(fraudType, style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600))),
                    const SizedBox(height: 6),
                  ],
                  Text(title, maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white, height: 1.3)),
                ])),
            ],
          ),
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
        const SizedBox(height: 8),
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
                  : Column(
                      children: _filteredLaws.map((law) => LawExpandTile(item: law)).toList(),
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
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
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
