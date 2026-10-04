// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '__APP_DISPLAY_NAME__';

  @override
  String get loginTitle => '欢迎使用';

  @override
  String get loginDescription => '登录后即可体验这套可复用的应用模板。';

  @override
  String get authUiRequired => '请将此页面替换为项目对应的身份认证登录流程。';

  @override
  String get demoSignIn => '使用演示账号继续';

  @override
  String get signingIn => '正在登录…';

  @override
  String get articlesTitle => '发现';

  @override
  String get articleDetails => '内容详情';

  @override
  String get settingsTitle => '设置';

  @override
  String get componentsTitle => '组件展示';

  @override
  String get appearance => '外观';

  @override
  String get language => '语言';

  @override
  String get systemTheme => '跟随系统';

  @override
  String get lightTheme => '浅色';

  @override
  String get darkTheme => '深色';

  @override
  String get english => 'English';

  @override
  String get chinese => '简体中文';

  @override
  String get signOut => '退出登录';

  @override
  String get signOutTitle => '退出登录？';

  @override
  String get signOutMessage => '你可以随时重新登录。';

  @override
  String get cancel => '取消';

  @override
  String get confirm => '确定';

  @override
  String get retry => '重试';

  @override
  String get loading => '正在加载';

  @override
  String get emptyTitle => '这里还没有内容';

  @override
  String get emptyMessage => '新内容将在这里显示。';

  @override
  String get errorTitle => '发生了一点问题';

  @override
  String get offlineError => '请检查网络连接后重试。';

  @override
  String get configurationError => '使用此环境前，请先配置对应的数据服务。';

  @override
  String get detailMissing => '这条内容已不可用。';

  @override
  String get loadMore => '加载更多';

  @override
  String get demoBadge => '演示';

  @override
  String get retrying => '正在重试…';

  @override
  String get requestFailed => '暂时无法完成请求。';

  @override
  String get showComponents => '查看通用组件';

  @override
  String get formComponents => '按钮与表单';

  @override
  String get asyncComponents => '异步状态';

  @override
  String get actionComponents => '弹窗与操作菜单';

  @override
  String get paginationComponents => '分页列表';

  @override
  String get emailPlaceholder => '电子邮箱';

  @override
  String exampleItem(int number) {
    return '示例条目 $number';
  }

  @override
  String get goBack => '返回';

  @override
  String get errorDetails => '错误详情';

  @override
  String get refresh => '刷新';

  @override
  String pageNumber(int page) {
    return '第 $page 页';
  }
}
