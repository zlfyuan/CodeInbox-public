// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'CodeInbox';

  @override
  String get tabInbox => 'Inbox';

  @override
  String get tabAlerts => 'Alerts';

  @override
  String get tabRepos => 'Repos';

  @override
  String get tabMe => 'Me';

  @override
  String get welcomeHeadline =>
      'One inbox for GitHub, Gitee, GitLab, Codeup, Gongfeng, and CODING review requests.';

  @override
  String get welcomeSubheadline =>
      'Aggregate PR/MR review requests from every forge you use.';

  @override
  String get inboxTitle => 'Inbox';

  @override
  String get inboxFilterNeedsReview => 'Needs my review';

  @override
  String get inboxSearchHint => 'Filter by title or repo';

  @override
  String get inboxNoMatchesTitle => 'No matches';

  @override
  String get inboxNoMatchesSubtitle => 'Try another title or repo name.';

  @override
  String get inboxLoadingTitle => 'Loading…';

  @override
  String get inboxAllCaughtUpTitle => 'You\'re all caught up';

  @override
  String get inboxAllCaughtUpSubtitleSingle =>
      'Add a second platform so reviews land in one place.';

  @override
  String get inboxAllCaughtUpSubtitleGitee =>
      'Gitee only scans your 20 most recently updated repos.';

  @override
  String get inboxAddAnotherPlatform => 'Add another platform';

  @override
  String get inboxLoadMore => 'Load more';

  @override
  String get alertsTitle => 'Alerts';

  @override
  String get alertsSearchHint => 'Filter by title, repo, or reason';

  @override
  String get alertsNoMatchesTitle => 'No matches';

  @override
  String get alertsNoMatchesSubtitle => 'Try another platform or keyword.';

  @override
  String get alertsNoUnreadTitle => 'No unread notifications';

  @override
  String get alertsNoUnreadSubtitle =>
      'Pull to refresh. Some platforms only expose a weak inbox.';

  @override
  String get reposTitle => 'Repos';

  @override
  String get reposSearchHint => 'Filter by name, language, or topic';

  @override
  String get reposNoMatchesTitle => 'No matches';

  @override
  String get reposNoMatchesSubtitle => 'Try another name, language, or topic.';

  @override
  String get reposFilteredEmptyTitle => 'No repos match these filters';

  @override
  String get reposFilteredEmptySubtitle => 'Clear some filters to see more.';

  @override
  String get reposEmptyTitle => 'No repositories yet';

  @override
  String get reposEmptySubtitle => 'Add an account, then pull to refresh.';

  @override
  String get sortByTooltip => 'Sort by';

  @override
  String get sortByUpdated => 'Recently updated';

  @override
  String get sortByName => 'Name A→Z';

  @override
  String get sortByStars => 'Most stars';

  @override
  String get sortByOpenPrs => 'Most open PRs';

  @override
  String get filterHideArchived => 'Hide archived';

  @override
  String get filterPublicOnly => 'Public only';

  @override
  String get filterAll => 'All';

  @override
  String get repoSheetOpenInBrowser => 'Open in browser';

  @override
  String get repoSheetCopyUrl => 'Copy URL';

  @override
  String get repoSheetUrlCopied => 'URL copied';

  @override
  String repoMetaUpdated(String date) {
    return 'Updated $date';
  }

  @override
  String get repoMetaArchived => 'archived';

  @override
  String get repoMetaFork => 'fork';

  @override
  String repoOpenPrPill(int count) {
    return '$count open';
  }

  @override
  String get repoDetailTabOverview => 'Overview';

  @override
  String get repoDetailTabPullRequests => 'Pull requests';

  @override
  String repoDetailTabPullRequestsCount(int count) {
    return 'Pull requests ($count)';
  }

  @override
  String get repoDetailStatStars => 'Stars';

  @override
  String get repoDetailStatForks => 'Forks';

  @override
  String get repoDetailStatIssues => 'Issues';

  @override
  String repoDetailMetaCreated(String date) {
    return 'Created $date';
  }

  @override
  String repoDetailMetaUpdated(Object date) {
    return 'Updated $date';
  }

  @override
  String get repoDetailReadmeHeader => 'README';

  @override
  String get repoDetailReadmeEmpty => 'No README in this repository.';

  @override
  String get repoDetailShowMore => 'Show more';

  @override
  String get repoDetailShowLess => 'Show less';

  @override
  String get repoDetailLoadFailed => 'Failed to load';

  @override
  String get repoDetailLoadFailedReadme => 'Failed to load README';

  @override
  String get repoDetailNoOpenPrs => 'No open pull requests';

  @override
  String repoDetailNoOpenPrsSubtitle(String repo) {
    return 'Nothing open on $repo. Review requests on other repos are in Inbox.';
  }

  @override
  String get repoDetailDraft => 'draft';

  @override
  String get repoDetailSheetOpenInBrowser => 'Open in browser';

  @override
  String get repoDetailSheetCopyWebUrl => 'Copy web URL';

  @override
  String get repoDetailSheetCopyCloneUrlHttps => 'Copy clone URL (HTTPS)';

  @override
  String get repoDetailSheetCopyCloneUrlSsh => 'Copy clone URL (SSH)';

  @override
  String get repoDetailWebUrlCopied => 'Web URL copied';

  @override
  String get repoDetailCloneUrlCopied => 'Clone URL copied';

  @override
  String get repoDetailStatSubscribers => 'Subscribers';

  @override
  String get repoDetailTabIssues => 'Issues';

  @override
  String repoDetailTabIssuesCount(Object count) {
    return 'Issues ($count)';
  }

  @override
  String get repoDetailTabCode => 'Code';

  @override
  String get repoDetailNoBranches => 'No branches';

  @override
  String get repoDetailNoCommits => 'No commits';

  @override
  String get repoDetailBranchProtected => 'protected';

  @override
  String get repoDetailCodeUnsupported =>
      'This platform does not support code browsing';

  @override
  String repoDetailCodeBranchesHeader(Object count) {
    return 'Branches ($count)';
  }

  @override
  String repoDetailCodeCommitsHeader(Object count) {
    return 'Commits ($count)';
  }

  @override
  String get repoDetailTabContributors => 'Contributors';

  @override
  String get repoDetailNoContributors => 'No contributors';

  @override
  String repoDetailNoContributorsSubtitle(Object repo) {
    return '$repo has no contributors yet.';
  }

  @override
  String repoDetailContributions(Object count) {
    return '$count contributions';
  }

  @override
  String get repoDetailNoOpenIssues => 'No open issues';

  @override
  String repoDetailNoOpenIssuesSubtitle(Object repo) {
    return '$repo has no open issues.';
  }

  @override
  String get repoDetailStarTooltip => 'Star';

  @override
  String get repoDetailUnstarTooltip => 'Unstar';

  @override
  String get repoDetailStarFailed => 'Action failed, please retry';

  @override
  String get issueStateOpen => 'Open';

  @override
  String get issueStateClosed => 'Closed';

  @override
  String issueDetailMetaLine(String author, String date) {
    return '$author opened on $date';
  }

  @override
  String issueDetailAssignees(String logins) {
    return 'Assignees: $logins';
  }

  @override
  String issueDetailCommentsHeader(int count) {
    return 'Comments ($count)';
  }

  @override
  String get issueDetailNoComments => 'No comments yet.';

  @override
  String prDetailBranchLine(String author, String source, String target) {
    return '$author  $source → $target';
  }

  @override
  String prDetailChipCi(String status) {
    return 'CI $status';
  }

  @override
  String get prDetailChipNotMergeable => 'not mergeable';

  @override
  String prDetailFilesHeader(int count) {
    return 'Files ($count)';
  }

  @override
  String get prDetailNoFiles =>
      'No file list. Open in browser for the full diff.';

  @override
  String prDetailFileStat(int additions, int deletions, String status) {
    return '+$additions  −$deletions  $status';
  }

  @override
  String prDetailCommentsHeader(int count) {
    return 'Comments ($count)';
  }

  @override
  String get prDetailNoComments => 'No comments yet.';

  @override
  String prDetailCommentPath(String path, int line) {
    return '$path:$line';
  }

  @override
  String get prDetailReviewApproved => 'Approved';

  @override
  String get prDetailReviewRequestedChanges => 'Requested changes';

  @override
  String get prDetailReviewCommentPosted => 'Comment posted';

  @override
  String get prDetailReviewMerged => 'Merged';

  @override
  String get prDetailReviewFailed => 'Review failed';

  @override
  String get prDetailReviewButton => 'Review';

  @override
  String get prDetailMergeButton => 'Merge';

  @override
  String get prDetailReviewSheetTitle => 'Review';

  @override
  String get prDetailReviewSheetCommentHint => 'Optional comment';

  @override
  String get prDetailReviewSheetComment => 'Comment';

  @override
  String get prDetailReviewSheetApprove => 'Approve';

  @override
  String get prDetailReviewSheetRequestChanges => 'Request changes';

  @override
  String get prDetailMergeDialogTitle => 'Merge this pull request?';

  @override
  String prDetailMergeDialogContent(String repo, int number) {
    return '$repo #$number will be merged on the remote.';
  }

  @override
  String get prDetailCancel => 'Cancel';

  @override
  String get diffOpenInBrowser => 'Open in browser';

  @override
  String get diffBinary =>
      'This file is binary or the forge did not return a text diff.';

  @override
  String get diffTruncated => 'Showing a truncated diff.';

  @override
  String get diffTapHint => 'Tap a green or unchanged line to comment on it.';

  @override
  String get diffLineComment => 'Line comment';

  @override
  String diffCommentOnLine(int line) {
    return 'Comment on line $line';
  }

  @override
  String get diffLineNumberLabel => 'Line number';

  @override
  String get diffCommentHint => 'Comment on this file';

  @override
  String get diffPostComment => 'Post comment';

  @override
  String get diffCommentPosted => 'Comment posted';

  @override
  String get diffCommentFailed => 'Comment failed';

  @override
  String get diffOmittedLines => '… remaining lines omitted';

  @override
  String get accountsTitle => 'Accounts';

  @override
  String get accountsAddGithub => 'Add GitHub';

  @override
  String get accountsAddGitee => 'Add Gitee';

  @override
  String get accountsAddGitlab => 'Add GitLab';

  @override
  String get accountsAddCodeup => 'Add Codeup';

  @override
  String get accountsAddGongfeng => 'Add Gongfeng';

  @override
  String get accountsAddCoding => 'Add CODING';

  @override
  String get accountsRevokeGithub => 'Revoke a GitHub token on the website';

  @override
  String get accountsRevokeGitee => 'Revoke a Gitee token on the website';

  @override
  String get accountsRevokeGitlab => 'Revoke a GitLab token on the website';

  @override
  String get accountsRevokeCodeup => 'Revoke a Codeup token on the website';

  @override
  String get accountsRevokeGongfeng => 'Revoke a Gongfeng token on the website';

  @override
  String get accountsRevokeCoding => 'Revoke a CODING token on the website';

  @override
  String get accountsRemoveDialogTitle => 'Remove account?';

  @override
  String accountsRemoveDialogContent(String name) {
    return 'Deletes the local token for $name. Revoke it on the platform website too.';
  }

  @override
  String get accountsRemoveCancel => 'Cancel';

  @override
  String get accountsRemoveConfirm => 'Remove';

  @override
  String get accountDetailTitle => 'Account details';

  @override
  String get accountDetailDisplayName => 'Display name';

  @override
  String get accountDetailLogin => 'Username';

  @override
  String get accountDetailPlatform => 'Platform';

  @override
  String get accountDetailBaseUrl => 'Server URL';

  @override
  String get accountDetailOrgId => 'Organization ID';

  @override
  String get accountDetailAuthType => 'Auth type';

  @override
  String get accountDetailAccountId => 'Account ID';

  @override
  String get accountDetailCreatedAt => 'Added at';

  @override
  String addAccountTitle(String platform) {
    return 'Add $platform';
  }

  @override
  String get addAccountBaseUrl => 'Base URL';

  @override
  String get addAccountApiDomain => 'API domain';

  @override
  String get addAccountOrgId => 'Organization ID';

  @override
  String get addAccountOrgIdHint => 'Required for 中心版';

  @override
  String addAccountOpenTokenPage(String platform) {
    return 'Open $platform token page';
  }

  @override
  String get addAccountPat => 'Personal access token';

  @override
  String get addAccountDisplayName => 'Display name (optional)';

  @override
  String get addAccountVerifySave => 'Verify & save';

  @override
  String get addAccountErrorNoToken => 'Paste a token first.';

  @override
  String addAccountErrorNoTeam(String url) {
    return 'Set your team URL ($url).';
  }

  @override
  String get addAccountErrorVerifyFailed => 'Could not verify token';

  @override
  String get addAccountHelpGithub =>
      'Create a classic Personal Access Token with repo, notifications, and read:user. Fine-grained tokens cannot read notifications reliably.';

  @override
  String get addAccountHelpGitee =>
      'Create a private token with user_info, projects, pull requests, and notifications.';

  @override
  String get addAccountHelpGitlab =>
      'Create a personal access token with the api scope. For self-hosted GitLab, set the Base URL first (https://gitlab.example.com).';

  @override
  String get addAccountHelpCodeup =>
      'Create a Yunxiao personal access token with 代码管理 · 合并请求 and 代码仓库. 中心版 needs Organization ID; Region 版 uses the instance API domain and can leave Organization ID empty.';

  @override
  String get addAccountHelpGongfeng =>
      'Create a private token at Profile → Account. For a self-hosted 工蜂 instance, set the Base URL first (https://git.example.com).';

  @override
  String addAccountHelpCoding(String url) {
    return 'Set your team URL ($url). Create a personal access token with vcs:repository and vcs:merge (rw to comment/merge).';
  }

  @override
  String get mineTitle => 'Me';

  @override
  String get mineAccounts => 'Accounts';

  @override
  String mineAccountsSubtitle(int count) {
    return '$count connected';
  }

  @override
  String get mineAppearance => 'Appearance';

  @override
  String get mineAppearanceSubtitle => 'Follows system';

  @override
  String get mineAbout => 'About';

  @override
  String mineAboutSubtitle(String version) {
    return 'CodeInbox $version';
  }

  @override
  String get mineTokensExplanation =>
      'Tokens stay on this device in the system secret store. There is no CodeInbox backend in this version.';

  @override
  String get mineNoAccountsTitle => 'No accounts';

  @override
  String get mineNoAccountsSubtitle => 'Add GitHub or Gitee from Accounts.';

  @override
  String get imageAlt => '[image]';

  @override
  String get retry => 'Retry';

  @override
  String get clear => 'Clear';

  @override
  String get openInBrowser => 'Open in browser';

  @override
  String get platformGithub => 'GitHub';

  @override
  String get platformGitee => 'Gitee';

  @override
  String get platformGitlab => 'GitLab';

  @override
  String get platformCodeup => 'Codeup';

  @override
  String get platformGongfeng => 'Gongfeng';

  @override
  String get platformCoding => 'CODING';

  @override
  String get crStateOpen => 'Open';

  @override
  String get crStateMerged => 'Merged';

  @override
  String get crStateClosed => 'Closed';

  @override
  String get repoVisibilityPublic => 'Public';

  @override
  String get repoVisibilityInternal => 'Internal';

  @override
  String get repoVisibilityPrivate => 'Private';
}
