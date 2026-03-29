import 'package:flutter/material.dart';
import 'package:ai_anti_fraud_detection_system_frontend/contants/theme.dart';
import 'package:ai_anti_fraud_detection_system_frontend/utils/DioRequest.dart';
import 'package:ai_anti_fraud_detection_system_frontend/services/auth_service.dart';

const _kAccent = Color(0xFF58A183);
const _kBg = Color(0xFFF8FAF9);

class LearningCenterPage extends StatefulWidget {
  const LearningCenterPage({super.key});

  @override
  State<LearningCenterPage> createState() => _LearningCenterPageState();
}

class _LearningCenterPageState extends State<LearningCenterPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _userInfo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserInfo();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserInfo() async {
    try {
      final userInfo = await AuthService().getCurrentUser();
      setState(() {
        _userInfo = userInfo;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          '学习中心',
          style: TextStyle(
            color: Color(0xFF0F1923),
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFE9F2EC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: _kAccent,
                borderRadius: BorderRadius.circular(10),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: const Color(0xFF6B7280),
              labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              padding: const EdgeInsets.all(3),
              tabs: const [
                Tab(text: '推荐'),
                Tab(text: '案例库'),
                Tab(text: '法律库'),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _kAccent))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildRecommendationsTab(),
                _buildCasesTab(),
                _buildLawsTab(),
              ],
            ),
    );
  }

  Widget _buildRecommendationsTab() {
    return RecommendationsTab(userInfo: _userInfo);
  }

  Widget _buildCasesTab() {
    return CasesTab(userInfo: _userInfo);
  }

  Widget _buildLawsTab() {
    return LawsTab(userInfo: _userInfo);
  }
}

// ==================== 推荐标签页 ====================
class RecommendationsTab extends StatefulWidget {
  final Map<String, dynamic>? userInfo;

  const RecommendationsTab({super.key, this.userInfo});

  @override
  State<RecommendationsTab> createState() => _RecommendationsTabState();
}

class _RecommendationsTabState extends State<RecommendationsTab> {
  bool _isLoading = true;
  List<dynamic> _recommendations = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userId = widget.userInfo?['user_id'];
      if (userId == null) {
        setState(() {
          _errorMessage = '用户未登录';
          _isLoading = false;
        });
        return;
      }

      print('📚 加载个性化推荐: userId=$userId');
      final response = await dioRequest.get(
        '/api/education/recommendations/profile/$userId',
        params: {'limit': 10},
      );

      print('📦 推荐响应: $response');

      if (response != null && response['data'] != null) {
        final data = response['data'];
        final cases = (data['cases'] as List?) ?? [];
        final slogans = (data['slogans'] as List?) ?? [];
        final videos = (data['videos'] as List?) ?? [];

        final allItems = [
          ...cases.map((c) => {'type': 'case', ...c}),
          ...slogans.map((s) => {'type': 'slogan', ...s}),
          ...videos.map((v) => {'type': 'video', ...v}),
        ];

        setState(() {
          _recommendations = allItems;
          _isLoading = false;
        });
      } else {
        setState(() {
          _recommendations = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ 加载推荐失败: $e');
      setState(() {
        _errorMessage = '加载失败: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: _kAccent));
    }

    if (_errorMessage != null) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height - 200,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildServerErrorCard(),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadRecommendations,
                icon: const Icon(Icons.refresh),
                label: const Text('重试'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kAccent,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_recommendations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lightbulb_outline, size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            const Text('暂无推荐内容', style: TextStyle(fontSize: 15, color: Color(0xFF9CA3AF))),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadRecommendations,
      color: _kAccent,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        itemCount: _recommendations.length,
        itemBuilder: (context, index) => _buildRecommendationCard(_recommendations[index]),
      ),
    );
  }

  Widget _buildRecommendationCard(Map<String, dynamic> item) {
    final type = item['type'];
    final title = item['title'] ?? item['content'] ?? '未知';
    final fraudType = item['fraud_type'] ?? '';

    IconData icon;
    Color color;

    switch (type) {
      case 'case':
        icon = Icons.description_outlined;
        color = const Color(0xFF3B82F6);
        break;
      case 'slogan':
        icon = Icons.lightbulb_outlined;
        color = const Color(0xFFF59E0B);
        break;
      case 'video':
        icon = Icons.play_circle_outline;
        color = const Color(0xFF10B981);
        break;
      default:
        icon = Icons.article_outlined;
        color = _kAccent;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F1923),
                  ),
                ),
                if (fraudType.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      fraudType,
                      style: TextStyle(
                        fontSize: 11,
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Color(0xFFCBD5E1), size: 20),
        ],
      ),
    );
  }

  Widget _buildServerErrorCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFCA5A5), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 20),
              const SizedBox(width: 8),
              const Text(
                '后端服务异常',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFDC2626),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '教育API服务暂时不可用，请稍后重试或联系管理员。',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF7F1D1D),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== 案例库标签页 ====================
class CasesTab extends StatefulWidget {
  final Map<String, dynamic>? userInfo;

  const CasesTab({super.key, this.userInfo});

  @override
  State<CasesTab> createState() => _CasesTabState();
}

class _CasesTabState extends State<CasesTab> {
  bool _isLoading = true;
  List<dynamic> _cases = [];
  String? _errorMessage;
  String? _selectedFraudType;
  List<String> _fraudTypes = [];

  @override
  void initState() {
    super.initState();
    _loadCases();
  }

  Future<void> _loadCases() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userId = widget.userInfo?['user_id'];
      if (userId == null) {
        setState(() {
          _errorMessage = '用户未登录';
          _isLoading = false;
        });
        return;
      }

      print('📚 加载案例库: userId=$userId');
      final params = <String, dynamic>{'limit': 20};
      if (_selectedFraudType != null) {
        params['fraud_type'] = _selectedFraudType;
      }

      final response = await dioRequest.get(
        '/api/education/recommendations/library/$userId',
        params: params,
      );

      if (response != null && response['data'] != null) {
        final data = response['data'];
        final cases = (data['cases'] as List?) ?? [];

        // 提取诈骗类型
        final types = <String>{};
        for (var c in cases) {
          if (c['fraud_type'] != null) {
            types.add(c['fraud_type'].toString());
          }
        }

        setState(() {
          _cases = cases;
          _fraudTypes = types.toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _cases = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ 加载案例库失败: $e');
      setState(() {
        _errorMessage = '加载失败: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: _kAccent));
    }

    return Column(
      children: [
        if (_fraudTypes.isNotEmpty)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() => _selectedFraudType = null);
                    _loadCases();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _selectedFraudType == null ? _kAccent : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _selectedFraudType == null ? _kAccent : const Color(0xFFE5E7EB),
                      ),
                    ),
                    child: Text(
                      '全部',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _selectedFraudType == null ? Colors.white : const Color(0xFF6B7280),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ..._fraudTypes.map((type) {
                  final isSelected = _selectedFraudType == type;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _selectedFraudType = type);
                        _loadCases();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? _kAccent : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? _kAccent : const Color(0xFFE5E7EB),
                          ),
                        ),
                        child: Text(
                          type,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : const Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        Expanded(
          child: _errorMessage != null
              ? SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height - 300,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildServerErrorCard(),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _loadCases,
                          icon: const Icon(Icons.refresh),
                          label: const Text('重试'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _kAccent,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : _cases.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.folder_open_outlined, size: 56, color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          const Text('暂无案例', style: TextStyle(fontSize: 15, color: Color(0xFF9CA3AF))),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadCases,
                      color: _kAccent,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        itemCount: _cases.length,
                        itemBuilder: (context, index) => _buildCaseCard(_cases[index]),
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildServerErrorCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFCA5A5), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 20),
              const SizedBox(width: 8),
              const Text(
                '后端服务异常',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFDC2626),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '教育API服务暂时不可用，请稍后重试或联系管理员。',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF7F1D1D),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaseCard(Map<String, dynamic> case_) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  case_['title'] ?? '未知案例',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F1923),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  case_['fraud_type'] ?? '未分类',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF3B82F6),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            case_['description'] ?? case_['content'] ?? '暂无描述',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== 法律库标签页 ====================
class LawsTab extends StatefulWidget {
  final Map<String, dynamic>? userInfo;

  const LawsTab({super.key, this.userInfo});

  @override
  State<LawsTab> createState() => _LawsTabState();
}

class _LawsTabState extends State<LawsTab> {
  bool _isLoading = true;
  List<dynamic> _laws = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadLaws();
  }

  Future<void> _loadLaws() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userId = widget.userInfo?['user_id'];
      if (userId == null) {
        setState(() {
          _errorMessage = '用户未登录';
          _isLoading = false;
        });
        return;
      }

      print('📚 加载法律库: userId=$userId');
      final response = await dioRequest.get(
        '/api/education/recommendations/library/$userId',
        params: {'limit': 20},
      );

      if (response != null && response['data'] != null) {
        final data = response['data'];
        final laws = (data['laws'] as List?) ?? [];

        setState(() {
          _laws = laws;
          _isLoading = false;
        });
      } else {
        setState(() {
          _laws = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ 加载法律库失败: $e');
      setState(() {
        _errorMessage = '加载失败: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: _kAccent));
    }

    if (_errorMessage != null) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height - 200,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildServerErrorCard(),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadLaws,
                icon: const Icon(Icons.refresh),
                label: const Text('重试'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kAccent,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_laws.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.gavel_outlined, size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            const Text('暂无法律条款', style: TextStyle(fontSize: 15, color: Color(0xFF9CA3AF))),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadLaws,
      color: _kAccent,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        itemCount: _laws.length,
        itemBuilder: (context, index) => _buildLawCard(_laws[index]),
      ),
    );
  }

  Widget _buildServerErrorCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFCA5A5), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 20),
              const SizedBox(width: 8),
              const Text(
                '后端服务异常',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFDC2626),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '教育API服务暂时不可用，请稍后重试或联系管理员。',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF7F1D1D),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLawCard(Map<String, dynamic> law) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.gavel, color: Color(0xFF10B981), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  law['title'] ?? '未知法律',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F1923),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            law['content'] ?? '暂无内容',
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
              height: 1.5,
            ),
          ),
          if (law['penalty'] != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '处罚: ${law['penalty']}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFFDC2626),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

