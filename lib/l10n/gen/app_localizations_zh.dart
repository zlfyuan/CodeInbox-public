// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'CodeInbox';

  @override
  String get tabInbox => '收件箱';

  @override
  String get tabAlerts => '通知';

  @override
  String get tabRepos => '仓库';

  @override
  String get tabMe => '我的';

  @override
  String get welcomeHeadline =>
      '统一收件箱:GitHub / Gitee / GitLab / Codeup / 工蜂 / CODING 的评审请求一处看完。';

  @override
  String get welcomeSubheadline => '把每个代码托管平台的 PR/MR 评审请求聚合到一起。';

  @override
  String get inboxTitle => '收件箱';

  @override
  String get inboxFilterNeedsReview => '需要我评审';

  @override
  String get inboxSearchHint => '按标题或仓库名筛选';

  @override
  String get inboxNoMatchesTitle => '无匹配项';

  @override
  String get inboxNoMatchesSubtitle => '换个标题或仓库名试试。';

  @override
  String get inboxLoadingTitle => '加载中…';

  @override
  String get inboxAllCaughtUpTitle => '全部已处理';

  @override
  String get inboxAllCaughtUpSubtitleSingle => '添加另一个平台,评审就能集中在一处。';

  @override
  String get inboxAllCaughtUpSubtitleGitee => 'Gitee 只会扫描最近 20 个有更新的仓库。';

  @override
  String get inboxAddAnotherPlatform => '添加其他平台';

  @override
  String get inboxLoadMore => '加载更多';

  @override
  String get alertsTitle => '通知';

  @override
  String get alertsSearchHint => '按标题、仓库名或触发原因筛选';

  @override
  String get alertsNoMatchesTitle => '无匹配项';

  @override
  String get alertsNoMatchesSubtitle => '换个平台或关键词试试。';

  @override
  String get alertsNoUnreadTitle => '没有未读通知';

  @override
  String get alertsNoUnreadSubtitle => '下拉刷新。部分平台的通知接口能力较弱。';

  @override
  String get reposTitle => '仓库';

  @override
  String get reposSearchHint => '按名称、语言或话题筛选';

  @override
  String get reposNoMatchesTitle => '无匹配项';

  @override
  String get reposNoMatchesSubtitle => '换个名称、语言或话题试试。';

  @override
  String get reposFilteredEmptyTitle => '没有符合条件的仓库';

  @override
  String get reposFilteredEmptySubtitle => '清除一些筛选条件看看更多。';

  @override
  String get reposEmptyTitle => '还没有仓库';

  @override
  String get reposEmptySubtitle => '添加账号后下拉刷新。';

  @override
  String get sortByTooltip => '排序';

  @override
  String get sortByUpdated => '最近更新';

  @override
  String get sortByName => '名称 A→Z';

  @override
  String get sortByStars => 'Star 数最多';

  @override
  String get sortByOpenPrs => 'Open PR 最多';

  @override
  String get filterHideArchived => '隐藏已归档';

  @override
  String get filterPublicOnly => '仅公开';

  @override
  String get filterAll => '全部';

  @override
  String get repoSheetOpenInBrowser => '在浏览器中打开';

  @override
  String get repoSheetCopyUrl => '复制 URL';

  @override
  String get repoSheetUrlCopied => '已复制 URL';

  @override
  String repoMetaUpdated(String date) {
    return '更新于 $date';
  }

  @override
  String get repoMetaArchived => '已归档';

  @override
  String get repoMetaFork => '派生';

  @override
  String repoOpenPrPill(int count) {
    return '$count 个待办';
  }

  @override
  String get repoDetailTabOverview => '概览';

  @override
  String get repoDetailTabPullRequests => 'Pull requests';

  @override
  String repoDetailTabPullRequestsCount(int count) {
    return 'Pull requests ($count)';
  }

  @override
  String get repoDetailStatStars => 'Star';

  @override
  String get repoDetailStatForks => '派生';

  @override
  String get repoDetailStatIssues => 'Issue';

  @override
  String repoDetailMetaCreated(String date) {
    return '创建于 $date';
  }

  @override
  String repoDetailMetaUpdated(Object date) {
    return '更新于 $date';
  }

  @override
  String get repoDetailReadmeHeader => 'README';

  @override
  String get repoDetailReadmeEmpty => '该仓库没有 README。';

  @override
  String get repoDetailShowMore => '展开更多';

  @override
  String get repoDetailShowLess => '收起';

  @override
  String get repoDetailLoadFailed => '加载失败';

  @override
  String get repoDetailLoadFailedReadme => 'README 加载失败';

  @override
  String get repoDetailNoOpenPrs => '没有 open 的 PR';

  @override
  String repoDetailNoOpenPrsSubtitle(String repo) {
    return '$repo 上没有 open PR。其他仓库的评审请求在收件箱里。';
  }

  @override
  String get repoDetailDraft => '草稿';

  @override
  String get repoDetailSheetOpenInBrowser => '在浏览器中打开';

  @override
  String get repoDetailSheetCopyWebUrl => '复制网页链接';

  @override
  String get repoDetailSheetCopyCloneUrlHttps => '复制克隆地址 (HTTPS)';

  @override
  String get repoDetailSheetCopyCloneUrlSsh => '复制克隆地址 (SSH)';

  @override
  String get repoDetailWebUrlCopied => '已复制网页链接';

  @override
  String get repoDetailCloneUrlCopied => '已复制克隆地址';

  @override
  String get repoDetailStatSubscribers => '订阅者';

  @override
  String get repoDetailTabIssues => 'Issues';

  @override
  String repoDetailTabIssuesCount(Object count) {
    return 'Issues ($count)';
  }

  @override
  String get repoDetailTabCode => '代码';

  @override
  String get repoDetailNoBranches => '没有分支';

  @override
  String get repoDetailNoCommits => '没有提交';

  @override
  String get repoDetailBranchProtected => '已保护';

  @override
  String get repoDetailCodeUnsupported => '该平台暂不支持代码浏览';

  @override
  String repoDetailCodeBranchesHeader(Object count) {
    return '分支 ($count)';
  }

  @override
  String repoDetailCodeCommitsHeader(Object count) {
    return '提交 ($count)';
  }

  @override
  String get repoDetailTabContributors => '贡献者';

  @override
  String get repoDetailNoContributors => '没有贡献者';

  @override
  String repoDetailNoContributorsSubtitle(Object repo) {
    return '$repo 还没有贡献者记录。';
  }

  @override
  String repoDetailContributions(Object count) {
    return '$count 次贡献';
  }

  @override
  String get repoDetailNoOpenIssues => '没有 open 的 Issue';

  @override
  String repoDetailNoOpenIssuesSubtitle(Object repo) {
    return '$repo 上没有 open Issue。';
  }

  @override
  String get repoDetailStarTooltip => '标星';

  @override
  String get repoDetailUnstarTooltip => '取消标星';

  @override
  String get repoDetailStarFailed => '操作失败,请重试';

  @override
  String get issueStateOpen => 'Open';

  @override
  String get issueStateClosed => 'Closed';

  @override
  String issueDetailMetaLine(String author, String date) {
    return '$author  提交于 $date';
  }

  @override
  String issueDetailAssignees(String logins) {
    return '受理人: $logins';
  }

  @override
  String issueDetailCommentsHeader(int count) {
    return '评论 ($count)';
  }

  @override
  String get issueDetailNoComments => '暂无评论。';

  @override
  String prDetailBranchLine(String author, String source, String target) {
    return '$author  $source → $target';
  }

  @override
  String prDetailChipCi(String status) {
    return 'CI $status';
  }

  @override
  String get prDetailChipNotMergeable => '无法合并';

  @override
  String prDetailFilesHeader(int count) {
    return '文件 ($count)';
  }

  @override
  String get prDetailNoFiles => '没有文件列表。在浏览器中打开查看完整 diff。';

  @override
  String prDetailFileStat(int additions, int deletions, String status) {
    return '+$additions  −$deletions  $status';
  }

  @override
  String prDetailCommentsHeader(int count) {
    return '评论 ($count)';
  }

  @override
  String get prDetailNoComments => '暂无评论。';

  @override
  String prDetailCommentPath(String path, int line) {
    return '$path:$line';
  }

  @override
  String get prDetailReviewApproved => '已通过';

  @override
  String get prDetailReviewRequestedChanges => '已请求修改';

  @override
  String get prDetailReviewCommentPosted => '评论已发布';

  @override
  String get prDetailReviewMerged => '已合并';

  @override
  String get prDetailReviewFailed => '评审失败';

  @override
  String get prDetailReviewButton => '评审';

  @override
  String get prDetailMergeButton => '合并';

  @override
  String get prDetailReviewSheetTitle => '评审';

  @override
  String get prDetailReviewSheetCommentHint => '可选评论';

  @override
  String get prDetailReviewSheetComment => '评论';

  @override
  String get prDetailReviewSheetApprove => '通过';

  @override
  String get prDetailReviewSheetRequestChanges => '请求修改';

  @override
  String get prDetailMergeDialogTitle => '合并这个 PR?';

  @override
  String prDetailMergeDialogContent(String repo, int number) {
    return '$repo #$number 将在远端合并。';
  }

  @override
  String get prDetailCancel => '取消';

  @override
  String get diffOpenInBrowser => '在浏览器中打开';

  @override
  String get diffBinary => '该文件是二进制，或平台没有返回文本 diff。';

  @override
  String get diffTruncated => '仅显示截断后的 diff。';

  @override
  String get diffTapHint => '点绿色或未改动的行即可评论。';

  @override
  String get diffLineComment => '行评论';

  @override
  String diffCommentOnLine(int line) {
    return '评论第 $line 行';
  }

  @override
  String get diffLineNumberLabel => '行号';

  @override
  String get diffCommentHint => '评论该文件';

  @override
  String get diffPostComment => '发布评论';

  @override
  String get diffCommentPosted => '评论已发布';

  @override
  String get diffCommentFailed => '评论失败';

  @override
  String get diffOmittedLines => '… 其余行已省略';

  @override
  String get accountsTitle => '账号';

  @override
  String get accountsAddGithub => '添加 GitHub';

  @override
  String get accountsAddGitee => '添加 Gitee';

  @override
  String get accountsAddGitlab => '添加 GitLab';

  @override
  String get accountsAddCodeup => '添加 Codeup';

  @override
  String get accountsAddGongfeng => '添加工蜂';

  @override
  String get accountsAddCoding => '添加 CODING';

  @override
  String get accountsRevokeGithub => '在网站上吊销 GitHub token';

  @override
  String get accountsRevokeGitee => '在网站上吊销 Gitee token';

  @override
  String get accountsRevokeGitlab => '在网站上吊销 GitLab token';

  @override
  String get accountsRevokeCodeup => '在网站上吊销 Codeup token';

  @override
  String get accountsRevokeGongfeng => '在网站上吊销工蜂 token';

  @override
  String get accountsRevokeCoding => '在网站上吊销 CODING token';

  @override
  String get accountsRemoveDialogTitle => '删除账号?';

  @override
  String accountsRemoveDialogContent(String name) {
    return '会删除 $name 的本地 token。建议同时在平台网站上吊销。';
  }

  @override
  String get accountsRemoveCancel => '取消';

  @override
  String get accountsRemoveConfirm => '删除';

  @override
  String get accountDetailTitle => '账号详情';

  @override
  String get accountDetailDisplayName => '显示名称';

  @override
  String get accountDetailLogin => '用户名';

  @override
  String get accountDetailPlatform => '平台';

  @override
  String get accountDetailBaseUrl => '服务地址';

  @override
  String get accountDetailOrgId => '组织 ID';

  @override
  String get accountDetailAuthType => '认证方式';

  @override
  String get accountDetailAccountId => '账号 ID';

  @override
  String get accountDetailCreatedAt => '添加时间';

  @override
  String addAccountTitle(String platform) {
    return '添加 $platform';
  }

  @override
  String get addAccountBaseUrl => 'Base URL';

  @override
  String get addAccountApiDomain => 'API 域名';

  @override
  String get addAccountOrgId => 'Organization ID';

  @override
  String get addAccountOrgIdHint => '中心版必填';

  @override
  String addAccountOpenTokenPage(String platform) {
    return '打开 $platform token 页';
  }

  @override
  String get addAccountPat => '个人访问令牌 (Personal access token)';

  @override
  String get addAccountDisplayName => '显示名(可选)';

  @override
  String get addAccountVerifySave => '校验并保存';

  @override
  String get addAccountErrorNoToken => '请先粘贴 token。';

  @override
  String addAccountErrorNoTeam(String url) {
    return '请填写团队 URL($url)。';
  }

  @override
  String get addAccountErrorVerifyFailed => '校验 token 失败';

  @override
  String get addAccountHelpGithub =>
      '创建一个经典 Personal Access Token,勾选 repo、notifications 与 read:user。Fine-grained token 读取 notifications 不稳定。';

  @override
  String get addAccountHelpGitee =>
      '创建私人令牌,勾选 user_info、projects、pull requests 与 notifications。';

  @override
  String get addAccountHelpGitlab =>
      '创建 Personal access token,勾选 api 作用域。自建 GitLab 请先填 Base URL(https://gitlab.example.com)。';

  @override
  String get addAccountHelpCodeup =>
      '创建云效个人访问令牌,勾选「代码管理 · 合并请求」与「代码仓库」。中心版需填 Organization ID;Region 版走实例 API 域名,Organization ID 可留空。';

  @override
  String get addAccountHelpGongfeng =>
      '在「个人中心 → 账号」创建私人 token。自建工蜂请先填 Base URL(https://git.example.com)。';

  @override
  String addAccountHelpCoding(String url) {
    return '先填团队 URL($url)。创建 Personal access token,勾选 vcs:repository 与 vcs:merge(评论/合并需要读写权限)。';
  }

  @override
  String get mineTitle => '我的';

  @override
  String get mineAccounts => '账号';

  @override
  String mineAccountsSubtitle(int count) {
    return '已连接 $count 个';
  }

  @override
  String get mineAppearance => '外观';

  @override
  String get mineAppearanceSubtitle => '跟随系统';

  @override
  String get mineAbout => '关于';

  @override
  String mineAboutSubtitle(String version) {
    return 'CodeInbox $version';
  }

  @override
  String get mineTokensExplanation => 'token 仅保存在本机的系统密钥库中,本版本没有 CodeInbox 后端。';

  @override
  String get mineNoAccountsTitle => '暂无账号';

  @override
  String get mineNoAccountsSubtitle => '前往「账号」添加 GitHub 或 Gitee。';

  @override
  String get imageAlt => '[图片]';

  @override
  String get retry => '重试';

  @override
  String get clear => '清除';

  @override
  String get openInBrowser => '在浏览器中打开';

  @override
  String get platformGithub => 'GitHub';

  @override
  String get platformGitee => 'Gitee';

  @override
  String get platformGitlab => 'GitLab';

  @override
  String get platformCodeup => 'Codeup';

  @override
  String get platformGongfeng => '工蜂';

  @override
  String get platformCoding => 'CODING';

  @override
  String get crStateOpen => 'Open';

  @override
  String get crStateMerged => '已合并';

  @override
  String get crStateClosed => '已关闭';

  @override
  String get repoVisibilityPublic => '公开';

  @override
  String get repoVisibilityInternal => '内部';

  @override
  String get repoVisibilityPrivate => '私有';
}

/// The translations for Chinese, as used in China (`zh_CN`).
class AppLocalizationsZhCn extends AppLocalizationsZh {
  AppLocalizationsZhCn() : super('zh_CN');

  @override
  String get appTitle => 'CodeInbox';

  @override
  String get tabInbox => '收件箱';

  @override
  String get tabAlerts => '通知';

  @override
  String get tabRepos => '仓库';

  @override
  String get tabMe => '我的';

  @override
  String get welcomeHeadline =>
      '统一收件箱:GitHub / Gitee / GitLab / Codeup / 工蜂 / CODING 的评审请求一处看完。';

  @override
  String get welcomeSubheadline => '把每个代码托管平台的 PR/MR 评审请求聚合到一起。';

  @override
  String get inboxTitle => '收件箱';

  @override
  String get inboxFilterNeedsReview => '需要我评审';

  @override
  String get inboxSearchHint => '按标题或仓库名筛选';

  @override
  String get inboxNoMatchesTitle => '无匹配项';

  @override
  String get inboxNoMatchesSubtitle => '换个标题或仓库名试试。';

  @override
  String get inboxLoadingTitle => '加载中…';

  @override
  String get inboxAllCaughtUpTitle => '全部已处理';

  @override
  String get inboxAllCaughtUpSubtitleSingle => '添加另一个平台,评审就能集中在一处。';

  @override
  String get inboxAllCaughtUpSubtitleGitee => 'Gitee 只会扫描最近 20 个有更新的仓库。';

  @override
  String get inboxAddAnotherPlatform => '添加其他平台';

  @override
  String get inboxLoadMore => '加载更多';

  @override
  String get alertsTitle => '通知';

  @override
  String get alertsSearchHint => '按标题、仓库名或触发原因筛选';

  @override
  String get alertsNoMatchesTitle => '无匹配项';

  @override
  String get alertsNoMatchesSubtitle => '换个平台或关键词试试。';

  @override
  String get alertsNoUnreadTitle => '没有未读通知';

  @override
  String get alertsNoUnreadSubtitle => '下拉刷新。部分平台的通知接口能力较弱。';

  @override
  String get reposTitle => '仓库';

  @override
  String get reposSearchHint => '按名称、语言或话题筛选';

  @override
  String get reposNoMatchesTitle => '无匹配项';

  @override
  String get reposNoMatchesSubtitle => '换个名称、语言或话题试试。';

  @override
  String get reposFilteredEmptyTitle => '没有符合条件的仓库';

  @override
  String get reposFilteredEmptySubtitle => '清除一些筛选条件看看更多。';

  @override
  String get reposEmptyTitle => '还没有仓库';

  @override
  String get reposEmptySubtitle => '添加账号后下拉刷新。';

  @override
  String get sortByTooltip => '排序';

  @override
  String get sortByUpdated => '最近更新';

  @override
  String get sortByName => '名称 A→Z';

  @override
  String get sortByStars => 'Star 数最多';

  @override
  String get sortByOpenPrs => 'Open PR 最多';

  @override
  String get filterHideArchived => '隐藏已归档';

  @override
  String get filterPublicOnly => '仅公开';

  @override
  String get filterAll => '全部';

  @override
  String get repoSheetOpenInBrowser => '在浏览器中打开';

  @override
  String get repoSheetCopyUrl => '复制 URL';

  @override
  String get repoSheetUrlCopied => '已复制 URL';

  @override
  String repoMetaUpdated(String date) {
    return '更新于 $date';
  }

  @override
  String get repoMetaArchived => '已归档';

  @override
  String get repoMetaFork => '派生';

  @override
  String repoOpenPrPill(int count) {
    return '$count 个待办';
  }

  @override
  String get repoDetailTabOverview => '概览';

  @override
  String get repoDetailTabPullRequests => 'Pull requests';

  @override
  String repoDetailTabPullRequestsCount(int count) {
    return 'Pull requests ($count)';
  }

  @override
  String get repoDetailStatStars => 'Star';

  @override
  String get repoDetailStatForks => '派生';

  @override
  String get repoDetailStatIssues => 'Issue';

  @override
  String repoDetailMetaCreated(String date) {
    return '创建于 $date';
  }

  @override
  String repoDetailMetaUpdated(Object date) {
    return '更新于 $date';
  }

  @override
  String get repoDetailReadmeHeader => 'README';

  @override
  String get repoDetailReadmeEmpty => '该仓库没有 README。';

  @override
  String get repoDetailShowMore => '展开更多';

  @override
  String get repoDetailShowLess => '收起';

  @override
  String get repoDetailLoadFailed => '加载失败';

  @override
  String get repoDetailLoadFailedReadme => 'README 加载失败';

  @override
  String get repoDetailNoOpenPrs => '没有 open 的 PR';

  @override
  String repoDetailNoOpenPrsSubtitle(String repo) {
    return '$repo 上没有 open PR。其他仓库的评审请求在收件箱里。';
  }

  @override
  String get repoDetailDraft => '草稿';

  @override
  String get repoDetailSheetOpenInBrowser => '在浏览器中打开';

  @override
  String get repoDetailSheetCopyWebUrl => '复制网页链接';

  @override
  String get repoDetailSheetCopyCloneUrlHttps => '复制克隆地址 (HTTPS)';

  @override
  String get repoDetailSheetCopyCloneUrlSsh => '复制克隆地址 (SSH)';

  @override
  String get repoDetailWebUrlCopied => '已复制网页链接';

  @override
  String get repoDetailCloneUrlCopied => '已复制克隆地址';

  @override
  String get repoDetailStatSubscribers => '订阅者';

  @override
  String get repoDetailTabIssues => 'Issues';

  @override
  String repoDetailTabIssuesCount(Object count) {
    return 'Issues ($count)';
  }

  @override
  String get repoDetailTabCode => '代码';

  @override
  String get repoDetailNoBranches => '没有分支';

  @override
  String get repoDetailNoCommits => '没有提交';

  @override
  String get repoDetailBranchProtected => '已保护';

  @override
  String get repoDetailCodeUnsupported => '该平台暂不支持代码浏览';

  @override
  String repoDetailCodeBranchesHeader(Object count) {
    return '分支 ($count)';
  }

  @override
  String repoDetailCodeCommitsHeader(Object count) {
    return '提交 ($count)';
  }

  @override
  String get repoDetailTabContributors => '贡献者';

  @override
  String get repoDetailNoContributors => '没有贡献者';

  @override
  String repoDetailNoContributorsSubtitle(Object repo) {
    return '$repo 还没有贡献者记录。';
  }

  @override
  String repoDetailContributions(Object count) {
    return '$count 次贡献';
  }

  @override
  String get repoDetailNoOpenIssues => '没有 open 的 Issue';

  @override
  String repoDetailNoOpenIssuesSubtitle(Object repo) {
    return '$repo 上没有 open Issue。';
  }

  @override
  String get repoDetailStarTooltip => '标星';

  @override
  String get repoDetailUnstarTooltip => '取消标星';

  @override
  String get repoDetailStarFailed => '操作失败,请重试';

  @override
  String get issueStateOpen => 'Open';

  @override
  String get issueStateClosed => 'Closed';

  @override
  String issueDetailMetaLine(String author, String date) {
    return '$author  提交于 $date';
  }

  @override
  String issueDetailAssignees(String logins) {
    return '受理人: $logins';
  }

  @override
  String issueDetailCommentsHeader(int count) {
    return '评论 ($count)';
  }

  @override
  String get issueDetailNoComments => '暂无评论。';

  @override
  String prDetailBranchLine(String author, String source, String target) {
    return '$author  $source → $target';
  }

  @override
  String prDetailChipCi(String status) {
    return 'CI $status';
  }

  @override
  String get prDetailChipNotMergeable => '无法合并';

  @override
  String prDetailFilesHeader(int count) {
    return '文件 ($count)';
  }

  @override
  String get prDetailNoFiles => '没有文件列表。在浏览器中打开查看完整 diff。';

  @override
  String prDetailFileStat(int additions, int deletions, String status) {
    return '+$additions  −$deletions  $status';
  }

  @override
  String prDetailCommentsHeader(int count) {
    return '评论 ($count)';
  }

  @override
  String get prDetailNoComments => '暂无评论。';

  @override
  String prDetailCommentPath(String path, int line) {
    return '$path:$line';
  }

  @override
  String get prDetailReviewApproved => '已通过';

  @override
  String get prDetailReviewRequestedChanges => '已请求修改';

  @override
  String get prDetailReviewCommentPosted => '评论已发布';

  @override
  String get prDetailReviewMerged => '已合并';

  @override
  String get prDetailReviewFailed => '评审失败';

  @override
  String get prDetailReviewButton => '评审';

  @override
  String get prDetailMergeButton => '合并';

  @override
  String get prDetailReviewSheetTitle => '评审';

  @override
  String get prDetailReviewSheetCommentHint => '可选评论';

  @override
  String get prDetailReviewSheetComment => '评论';

  @override
  String get prDetailReviewSheetApprove => '通过';

  @override
  String get prDetailReviewSheetRequestChanges => '请求修改';

  @override
  String get prDetailMergeDialogTitle => '合并这个 PR?';

  @override
  String prDetailMergeDialogContent(String repo, int number) {
    return '$repo #$number 将在远端合并。';
  }

  @override
  String get prDetailCancel => '取消';

  @override
  String get diffOpenInBrowser => '在浏览器中打开';

  @override
  String get diffBinary => '该文件是二进制，或平台没有返回文本 diff。';

  @override
  String get diffTruncated => '仅显示截断后的 diff。';

  @override
  String get diffTapHint => '点绿色或未改动的行即可评论。';

  @override
  String get diffLineComment => '行评论';

  @override
  String diffCommentOnLine(int line) {
    return '评论第 $line 行';
  }

  @override
  String get diffLineNumberLabel => '行号';

  @override
  String get diffCommentHint => '评论该文件';

  @override
  String get diffPostComment => '发布评论';

  @override
  String get diffCommentPosted => '评论已发布';

  @override
  String get diffCommentFailed => '评论失败';

  @override
  String get diffOmittedLines => '… 其余行已省略';

  @override
  String get accountsTitle => '账号';

  @override
  String get accountsAddGithub => '添加 GitHub';

  @override
  String get accountsAddGitee => '添加 Gitee';

  @override
  String get accountsAddGitlab => '添加 GitLab';

  @override
  String get accountsAddCodeup => '添加 Codeup';

  @override
  String get accountsAddGongfeng => '添加工蜂';

  @override
  String get accountsAddCoding => '添加 CODING';

  @override
  String get accountsRevokeGithub => '在网站上吊销 GitHub token';

  @override
  String get accountsRevokeGitee => '在网站上吊销 Gitee token';

  @override
  String get accountsRevokeGitlab => '在网站上吊销 GitLab token';

  @override
  String get accountsRevokeCodeup => '在网站上吊销 Codeup token';

  @override
  String get accountsRevokeGongfeng => '在网站上吊销工蜂 token';

  @override
  String get accountsRevokeCoding => '在网站上吊销 CODING token';

  @override
  String get accountsRemoveDialogTitle => '删除账号?';

  @override
  String accountsRemoveDialogContent(String name) {
    return '会删除 $name 的本地 token。建议同时在平台网站上吊销。';
  }

  @override
  String get accountsRemoveCancel => '取消';

  @override
  String get accountsRemoveConfirm => '删除';

  @override
  String get accountDetailTitle => '账号详情';

  @override
  String get accountDetailDisplayName => '显示名称';

  @override
  String get accountDetailLogin => '用户名';

  @override
  String get accountDetailPlatform => '平台';

  @override
  String get accountDetailBaseUrl => '服务地址';

  @override
  String get accountDetailOrgId => '组织 ID';

  @override
  String get accountDetailAuthType => '认证方式';

  @override
  String get accountDetailAccountId => '账号 ID';

  @override
  String get accountDetailCreatedAt => '添加时间';

  @override
  String addAccountTitle(String platform) {
    return '添加 $platform';
  }

  @override
  String get addAccountBaseUrl => 'Base URL';

  @override
  String get addAccountApiDomain => 'API 域名';

  @override
  String get addAccountOrgId => 'Organization ID';

  @override
  String get addAccountOrgIdHint => '中心版必填';

  @override
  String addAccountOpenTokenPage(String platform) {
    return '打开 $platform token 页';
  }

  @override
  String get addAccountPat => '个人访问令牌 (Personal access token)';

  @override
  String get addAccountDisplayName => '显示名(可选)';

  @override
  String get addAccountVerifySave => '校验并保存';

  @override
  String get addAccountErrorNoToken => '请先粘贴 token。';

  @override
  String addAccountErrorNoTeam(String url) {
    return '请填写团队 URL($url)。';
  }

  @override
  String get addAccountErrorVerifyFailed => '校验 token 失败';

  @override
  String get addAccountHelpGithub =>
      '创建一个经典 Personal Access Token,勾选 repo、notifications 与 read:user。Fine-grained token 读取 notifications 不稳定。';

  @override
  String get addAccountHelpGitee =>
      '创建私人令牌,勾选 user_info、projects、pull requests 与 notifications。';

  @override
  String get addAccountHelpGitlab =>
      '创建 Personal access token,勾选 api 作用域。自建 GitLab 请先填 Base URL(https://gitlab.example.com)。';

  @override
  String get addAccountHelpCodeup =>
      '创建云效个人访问令牌,勾选「代码管理 · 合并请求」与「代码仓库」。中心版需填 Organization ID;Region 版走实例 API 域名,Organization ID 可留空。';

  @override
  String get addAccountHelpGongfeng =>
      '在「个人中心 → 账号」创建私人 token。自建工蜂请先填 Base URL(https://git.example.com)。';

  @override
  String addAccountHelpCoding(String url) {
    return '先填团队 URL($url)。创建 Personal access token,勾选 vcs:repository 与 vcs:merge(评论/合并需要读写权限)。';
  }

  @override
  String get mineTitle => '我的';

  @override
  String get mineAccounts => '账号';

  @override
  String mineAccountsSubtitle(int count) {
    return '已连接 $count 个';
  }

  @override
  String get mineAppearance => '外观';

  @override
  String get mineAppearanceSubtitle => '跟随系统';

  @override
  String get mineAbout => '关于';

  @override
  String mineAboutSubtitle(String version) {
    return 'CodeInbox $version';
  }

  @override
  String get mineTokensExplanation => 'token 仅保存在本机的系统密钥库中,本版本没有 CodeInbox 后端。';

  @override
  String get mineNoAccountsTitle => '暂无账号';

  @override
  String get mineNoAccountsSubtitle => '前往「账号」添加 GitHub 或 Gitee。';

  @override
  String get imageAlt => '[图片]';

  @override
  String get retry => '重试';

  @override
  String get clear => '清除';

  @override
  String get openInBrowser => '在浏览器中打开';

  @override
  String get platformGithub => 'GitHub';

  @override
  String get platformGitee => 'Gitee';

  @override
  String get platformGitlab => 'GitLab';

  @override
  String get platformCodeup => 'Codeup';

  @override
  String get platformGongfeng => '工蜂';

  @override
  String get platformCoding => 'CODING';

  @override
  String get crStateOpen => 'Open';

  @override
  String get crStateMerged => '已合并';

  @override
  String get crStateClosed => '已关闭';

  @override
  String get repoVisibilityPublic => '公开';

  @override
  String get repoVisibilityInternal => '内部';

  @override
  String get repoVisibilityPrivate => '私有';
}
