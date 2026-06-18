import '../../models/ledger_record.dart';

class BankBillCategoryResolution {
  const BankBillCategoryResolution({
    required this.category,
    this.detail = '',
  });

  final String category;
  final String detail;
}

/// 在既有主分类映射基础上，尝试根据平台分类与交易描述细化到子分类。
class BankBillSubcategoryResolver {
  const BankBillSubcategoryResolver();

  BankBillCategoryResolution refine({
    required String parentCategory,
    required LedgerRecordType type,
    String? platformCategory,
    String? counterparty,
    String? description,
    String? summary,
  }) {
    final context = _buildContext(
      platformCategory: platformCategory,
      counterparty: counterparty,
      description: description,
      summary: summary,
    );
    if (context.isEmpty) {
      return BankBillCategoryResolution(category: parentCategory);
    }

    final crossParent = _matchCrossParent(
      context: context,
      platformCategory: platformCategory,
      parentCategory: parentCategory,
      type: type,
    );
    if (crossParent != null) {
      return BankBillCategoryResolution(
        category: crossParent,
        detail: '细分为「$crossParent」',
      );
    }

    final subcategory = _matchSubcategory(
      parentCategory: parentCategory,
      type: type,
      context: context,
      platformCategory: platformCategory,
    );
    if (subcategory != null) {
      return BankBillCategoryResolution(
        category: subcategory,
        detail: '细分为「$subcategory」',
      );
    }

    return BankBillCategoryResolution(category: parentCategory);
  }

  String _buildContext({
    String? platformCategory,
    String? counterparty,
    String? description,
    String? summary,
  }) {
    return [
      platformCategory,
      counterparty,
      description,
      summary,
    ].where((value) => value != null && value.trim().isNotEmpty).join(' ');
  }

  String? _matchCrossParent({
    required String context,
    required String? platformCategory,
    required String parentCategory,
    required LedgerRecordType type,
  }) {
    if (type != LedgerRecordType.expense && type != LedgerRecordType.income) {
      return null;
    }

    final platform = platformCategory?.trim() ?? '';
    final allowInfer = parentCategory == '其他';

    if (platform == '酒店旅游' || _containsAny(context, const ['酒店', '携程', '飞猪', '民宿', '机票'])) {
      if (allowInfer || parentCategory == '旅行') {
        if (_containsAny(context, const ['门票', '景区', '乐园', '展览'])) {
          return '景区门票';
        }
        return '机票酒店';
      }
    }

    if (platform == '服饰装扮' ||
        _containsAny(context, const ['服饰', '鞋', '衣帽', '外套', '连衣裙'])) {
      if (allowInfer || parentCategory == '购物') {
        return '服饰鞋包';
      }
    }

    if (platform == '宠物' || _containsAny(context, const ['宠物', '猫粮', '狗粮'])) {
      if (allowInfer || parentCategory == '宠物') {
        if (_containsAny(context, const ['医院', '医疗', '疫苗', '驱虫'])) {
          return '宠物医疗';
        }
        if (_containsAny(context, const ['用品', '玩具', '猫砂'])) {
          return '宠物用品';
        }
        return '宠物食品';
      }
    }

    if (type == LedgerRecordType.income) {
      return null;
    }

    if (platform == '充值缴费') {
      if (_containsAny(context, const ['话费', '移动', '联通', '电信', '充值'])) {
        return '话费流量';
      }
      if (_containsAny(context, const ['宽带', '光纤', '网络'])) {
        return '宽带网络';
      }
    }

    if (allowInfer && _containsAny(context, const ['外卖', '美团', '饿了么', '淘宝闪购'])) {
      return '早中晚餐';
    }

    if (type == LedgerRecordType.expense) {
      final charging = _matchCrossParentTransport(
        context: context,
        parentCategory: parentCategory,
        allowInfer: allowInfer,
        keywords: const [
          '充电订单',
          '充电站',
          '先充后付',
          '换电',
          '新能源',
          '快电',
          '加油',
          '石化',
          '石油',
          '壳牌',
          '中石油',
          '中石化',
        ],
        subcategory: '加油充电',
      );
      if (charging != null) {
        return charging;
      }

      final toll = _matchCrossParentTransport(
        context: context,
        parentCategory: parentCategory,
        allowInfer: allowInfer,
        keywords: const ['ETC', '通行费', '高速', '过路费', '路桥费'],
        subcategory: '高速费',
      );
      if (toll != null) {
        return toll;
      }
    }

    return null;
  }

  String? _matchCrossParentTransport({
    required String context,
    required String parentCategory,
    required bool allowInfer,
    required List<String> keywords,
    required String subcategory,
  }) {
    if (!_containsAny(context, keywords)) {
      return null;
    }
    if (allowInfer ||
        parentCategory == '购物' ||
        parentCategory == '交通' ||
        parentCategory == '其他') {
      return subcategory;
    }
    return null;
  }

  String? _matchSubcategory({
    required String parentCategory,
    required LedgerRecordType type,
    required String context,
    required String? platformCategory,
  }) {
    final platform = platformCategory?.trim() ?? '';

    if (type == LedgerRecordType.income) {
      return switch (parentCategory) {
        '工资' => _matchFirst(context, const [
          _KeywordRule(['年终', '年终奖'], '年终奖金'),
          _KeywordRule(['绩效', '提成', '奖金'], '绩效提成'),
          _KeywordRule(['代发', '工资', '工资薪金'], '基本工资'),
        ]),
        '兼职' => _matchFirst(context, const [
          _KeywordRule(['稿酬', '稿费', '写作'], '稿酬稿费'),
          _KeywordRule(['副业', '兼职'], '副业收入'),
        ]),
        '奖金' => _matchFirst(context, const [
          _KeywordRule(['年终'], '年终奖金'),
          _KeywordRule(['绩效', '提成'], '绩效提成'),
        ]),
        _ => null,
      };
    }

    if (type == LedgerRecordType.expense) {
      return switch (parentCategory) {
        '餐饮' => _matchDining(context, platform),
        '交通' => _matchTransport(context, platform),
        '购物' => _matchShopping(context, platform),
        '居住' => _matchHousing(context, platform),
        '娱乐' => _matchEntertainment(context, platform),
        '医疗' => _matchMedical(context, platform),
        '学习' => _matchEducation(context, platform),
        '旅行' => _matchTravel(context, platform),
        '通讯' => _matchCommunication(context, platform),
        '美容' => _matchBeauty(context, platform),
        '宠物' => _matchPets(context, platform),
        '社交' => _matchSocial(context, platform),
        '转账' => _matchFirst(context, const [
          _KeywordRule(['红包'], '礼金红包'),
          _KeywordRule(['请客', '送礼', '聚餐'], '请客送礼'),
        ]),
        '红包' => '礼金红包',
        _ => null,
      };
    }

    return null;
  }

  String? _matchDining(String context, String platform) {
    if (platform == '餐饮美食') {
      if (_containsAny(context, const ['外卖', '美团', '饿了么', '淘宝闪购', '套餐', '饭店', '餐厅', '食堂', '碗', '粉', '面', '饭'])) {
        return '早中晚餐';
      }
      if (_containsAny(context, const ['咖啡', '奶茶', '茶饮', '星巴克', '瑞幸', '喜茶', '奈雪'])) {
        return '咖啡奶茶';
      }
      if (_containsAny(context, const ['水果', '蔬菜', '生鲜', '零食'])) {
        return '零食水果';
      }
      if (_containsAny(context, const ['粮油', '调味', '酱油', '米面'])) {
        return '粮油调味';
      }
      if (_containsAny(context, const ['烟', '酒', '茶', '茶叶'])) {
        return '烟酒茶叶';
      }
    }

    return _matchFirst(context, const [
      _KeywordRule(['外卖', '美团', '饿了么', '淘宝闪购', '套餐饭', '餐厅', '饭店', '食堂', '早餐', '午餐', '晚餐', '夜宵'], '早中晚餐'),
      _KeywordRule(['咖啡', '奶茶', '茶饮', '星巴克', '瑞幸', '喜茶', '奈雪', 'coco'], '咖啡奶茶'),
      _KeywordRule(['水果', '蔬菜', '生鲜', '零食', '坚果'], '零食水果'),
      _KeywordRule(['粮油', '调味', '酱油', '醋', '米', '面', '油'], '粮油调味'),
      _KeywordRule(['烟', '酒', '茶叶', '白酒', '啤酒'], '烟酒茶叶'),
    ]);
  }

  String? _matchTransport(String context, String platform) {
    if (platform == '爱车养车' || platform == '交通出行') {
      if (_containsAny(context, const ['ETC', '通行费', '高速', '过路费', '路桥费'])) {
        return '高速费';
      }
      if (_containsAny(context, const ['加油', '充电', '石化', '石油'])) {
        return '加油充电';
      }
      if (_containsAny(context, const ['停车', '泊车', '车位'])) {
        return '停车';
      }
      if (_containsAny(context, const ['地铁', '公交', '轨道', '乘车码'])) {
        return '公交地铁';
      }
      if (_containsAny(context, const ['滴滴', '打车', '出租', '高德打车', '网约车', '曹操', '花小猪'])) {
        return '打车租车';
      }
      if (_containsAny(context, const ['火车', '高铁', '12306', '机票', '航班', '飞机', '航空'])) {
        return '火车飞机';
      }
      if (_containsAny(context, const ['保养', '修车', '维修', '洗车', '轮胎'])) {
        return '保养修车';
      }
    }

    return _matchFirst(context, const [
      _KeywordRule(['ETC', '通行费', '高速', '过路费', '路桥费'], '高速费'),
      _KeywordRule(['加油', '充电', '石化', '石油'], '加油充电'),
      _KeywordRule(['停车', '泊车'], '停车'),
      _KeywordRule(['地铁', '公交', '乘车码'], '公交地铁'),
      _KeywordRule(['滴滴', '打车', '出租', '高德', '网约车'], '打车租车'),
      _KeywordRule(['火车', '高铁', '12306', '机票', '航班', '飞机'], '火车飞机'),
      _KeywordRule(['保养', '修车', '洗车', '轮胎'], '保养修车'),
    ]);
  }

  String? _matchShopping(String context, String platform) {
    if (platform == '日用百货' || _containsAny(context, const ['便利店', '超市', '百货', '连锁超市'])) {
      return '日用百货';
    }
    if (_containsAny(context, const ['快捷支付', '银联', '无卡', '扫码', '收钱码'])) {
      return '日用百货';
    }
    if (platform == '数码电器' || _containsAny(context, const ['数码', '电器', '手机', '电脑', '相机', '家电'])) {
      return '数码家电';
    }
    if (platform == '家居家装' || _containsAny(context, const ['家装', '家具', '装修', '建材', '五金'])) {
      return '日用百货';
    }

    return _matchFirst(context, const [
      _KeywordRule(['便利店', '超市', '百货', '日用'], '日用百货'),
      _KeywordRule(['服饰', '鞋', '包', '衣', '帽'], '服饰鞋包'),
      _KeywordRule(['数码', '电器', '手机', '电脑', '家电'], '数码家电'),
      _KeywordRule(['护肤', '美妆', '化妆', '面膜'], '美妆护肤'),
    ]);
  }

  String? _matchHousing(String context, String platform) {
    if (platform == '住房物业' || _containsAny(context, const ['房租', '租金', '租房'])) {
      return '房租';
    }
    if (platform == '充值缴费' &&
        _containsAny(context, const ['电费', '燃气', '水费', '电力', '水务', '供电'])) {
      return '水电燃气';
    }
    if (_containsAny(context, const ['物业', '管理费'])) {
      return '物业维修';
    }
    if (_containsAny(context, const ['家具', '家居', '装修', '装饰'])) {
      return '家居装饰';
    }

    return _matchFirst(context, const [
      _KeywordRule(['房租', '租金'], '房租'),
      _KeywordRule(['电费', '燃气', '水费', '电力'], '水电燃气'),
      _KeywordRule(['物业'], '物业维修'),
      _KeywordRule(['家具', '家居', '装修'], '家居装饰'),
    ]);
  }

  String? _matchEntertainment(String context, String platform) {
    if (platform == '文化休闲' &&
        _containsAny(context, const ['电影', '影城', '淘票', '观影', '演出', '话剧'])) {
      return '电影演出';
    }
    if (platform == '运动户外' || _containsAny(context, const ['健身', '游泳', '球馆', '瑜伽'])) {
      return '运动健身';
    }

    return _matchFirst(context, const [
      _KeywordRule(['电影', '影城', '淘票', '观影', '演出'], '电影演出'),
      _KeywordRule(['游戏', '电竞', 'steam', '点券'], '游戏电竞'),
      _KeywordRule(['健身', '游泳', '瑜伽', '球馆'], '运动健身'),
      _KeywordRule(['聚会', 'KTV', '酒吧'], '聚会社交'),
    ]);
  }

  String? _matchMedical(String context, String platform) {
    if (platform == '医疗健康') {
      if (_containsAny(context, const ['体检', '保健'])) {
        return '体检保健';
      }
      if (_containsAny(context, const ['牙', '眼科', '视力'])) {
        return '牙齿眼科';
      }
      return '看病买药';
    }

    return _matchFirst(context, const [
      _KeywordRule(['医院', '诊所', '药', '药房', '挂号'], '看病买药'),
      _KeywordRule(['体检', '保健'], '体检保健'),
      _KeywordRule(['牙', '眼科'], '牙齿眼科'),
    ]);
  }

  String? _matchEducation(String context, String platform) {
    if (platform == '教育') {
      return '培训课程';
    }

    return _matchFirst(context, const [
      _KeywordRule(['培训', '课程', '辅导', '网课'], '培训课程'),
      _KeywordRule(['书', '教材', '资料'], '书籍资料'),
      _KeywordRule(['考试', '报名', '认证'], '考试报名'),
    ]);
  }

  String? _matchTravel(String context, String platform) {
    return _matchFirst(context, const [
      _KeywordRule(['机票', '酒店', '民宿', '携程', '飞猪'], '机票酒店'),
      _KeywordRule(['门票', '景区', '乐园'], '景区门票'),
      _KeywordRule(['旅游', '旅行', '纪念品'], '旅游购物'),
    ]);
  }

  String? _matchCommunication(String context, String platform) {
    return _matchFirst(context, const [
      _KeywordRule(['话费', '移动', '联通', '电信', '充值'], '话费流量'),
      _KeywordRule(['宽带', '光纤', '网络'], '宽带网络'),
    ]);
  }

  String? _matchBeauty(String context, String platform) {
    if (platform == '美容美发') {
      return '护肤美发';
    }

    return _matchFirst(context, const [
      _KeywordRule(['美发', '理发', '护肤', '化妆', 'spa'], '护肤美发'),
      _KeywordRule(['医美', '美容', '护理'], '医美护理'),
    ]);
  }

  String? _matchPets(String context, String platform) {
    return _matchFirst(context, const [
      _KeywordRule(['医院', '医疗', '疫苗', '驱虫'], '宠物医疗'),
      _KeywordRule(['用品', '玩具', '猫砂'], '宠物用品'),
      _KeywordRule(['粮', '罐头', '零食'], '宠物食品'),
    ]);
  }

  String? _matchSocial(String context, String platform) {
    if (platform == '转账红包' || platform == '人情往来') {
      if (_containsAny(context, const ['红包'])) {
        return '礼金红包';
      }
      return '请客送礼';
    }

    return _matchFirst(context, const [
      _KeywordRule(['红包', '礼金'], '礼金红包'),
      _KeywordRule(['请客', '送礼', '聚餐'], '请客送礼'),
    ]);
  }

  String? _matchFirst(String context, List<_KeywordRule> rules) {
    for (final rule in rules) {
      if (_containsAny(context, rule.keywords)) {
        return rule.subcategory;
      }
    }
    return null;
  }

  bool _containsAny(String text, List<String> keywords) {
    final normalized = text.toLowerCase();
    for (final keyword in keywords) {
      if (normalized.contains(keyword.toLowerCase())) {
        return true;
      }
    }
    return false;
  }
}

class _KeywordRule {
  const _KeywordRule(this.keywords, this.subcategory);

  final List<String> keywords;
  final String subcategory;
}
