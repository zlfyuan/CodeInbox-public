import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
    Locale('zh', 'CN'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'CodeInbox'**
  String get appTitle;

  /// No description provided for @tabInbox.
  ///
  /// In en, this message translates to:
  /// **'Inbox'**
  String get tabInbox;

  /// No description provided for @tabAlerts.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get tabAlerts;

  /// No description provided for @tabRepos.
  ///
  /// In en, this message translates to:
  /// **'Repos'**
  String get tabRepos;

  /// No description provided for @tabMe.
  ///
  /// In en, this message translates to:
  /// **'Me'**
  String get tabMe;

  /// No description provided for @welcomeHeadline.
  ///
  /// In en, this message translates to:
  /// **'One inbox for GitHub, Gitee, GitLab, Codeup, Gongfeng, and CODING review requests.'**
  String get welcomeHeadline;

  /// No description provided for @welcomeSubheadline.
  ///
  /// In en, this message translates to:
  /// **'Aggregate PR/MR review requests from every forge you use.'**
  String get welcomeSubheadline;

  /// No description provided for @inboxTitle.
  ///
  /// In en, this message translates to:
  /// **'Inbox'**
  String get inboxTitle;

  /// No description provided for @inboxFilterNeedsReview.
  ///
  /// In en, this message translates to:
  /// **'Needs my review'**
  String get inboxFilterNeedsReview;

  /// No description provided for @inboxSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Filter by title or repo'**
  String get inboxSearchHint;

  /// No description provided for @inboxNoMatchesTitle.
  ///
  /// In en, this message translates to:
  /// **'No matches'**
  String get inboxNoMatchesTitle;

  /// No description provided for @inboxNoMatchesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Try another title or repo name.'**
  String get inboxNoMatchesSubtitle;

  /// No description provided for @inboxLoadingTitle.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get inboxLoadingTitle;

  /// No description provided for @inboxAllCaughtUpTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re all caught up'**
  String get inboxAllCaughtUpTitle;

  /// No description provided for @inboxAllCaughtUpSubtitleSingle.
  ///
  /// In en, this message translates to:
  /// **'Add a second platform so reviews land in one place.'**
  String get inboxAllCaughtUpSubtitleSingle;

  /// No description provided for @inboxAllCaughtUpSubtitleGitee.
  ///
  /// In en, this message translates to:
  /// **'Gitee only scans your 20 most recently updated repos.'**
  String get inboxAllCaughtUpSubtitleGitee;

  /// No description provided for @inboxAddAnotherPlatform.
  ///
  /// In en, this message translates to:
  /// **'Add another platform'**
  String get inboxAddAnotherPlatform;

  /// No description provided for @inboxLoadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get inboxLoadMore;

  /// No description provided for @alertsTitle.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get alertsTitle;

  /// No description provided for @alertsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Filter by title, repo, or reason'**
  String get alertsSearchHint;

  /// No description provided for @alertsNoMatchesTitle.
  ///
  /// In en, this message translates to:
  /// **'No matches'**
  String get alertsNoMatchesTitle;

  /// No description provided for @alertsNoMatchesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Try another platform or keyword.'**
  String get alertsNoMatchesSubtitle;

  /// No description provided for @alertsNoUnreadTitle.
  ///
  /// In en, this message translates to:
  /// **'No unread notifications'**
  String get alertsNoUnreadTitle;

  /// No description provided for @alertsNoUnreadSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pull to refresh. Some platforms only expose a weak inbox.'**
  String get alertsNoUnreadSubtitle;

  /// No description provided for @reposTitle.
  ///
  /// In en, this message translates to:
  /// **'Repos'**
  String get reposTitle;

  /// No description provided for @reposSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Filter by name, language, or topic'**
  String get reposSearchHint;

  /// No description provided for @reposNoMatchesTitle.
  ///
  /// In en, this message translates to:
  /// **'No matches'**
  String get reposNoMatchesTitle;

  /// No description provided for @reposNoMatchesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Try another name, language, or topic.'**
  String get reposNoMatchesSubtitle;

  /// No description provided for @reposFilteredEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No repos match these filters'**
  String get reposFilteredEmptyTitle;

  /// No description provided for @reposFilteredEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Clear some filters to see more.'**
  String get reposFilteredEmptySubtitle;

  /// No description provided for @reposEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No repositories yet'**
  String get reposEmptyTitle;

  /// No description provided for @reposEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add an account, then pull to refresh.'**
  String get reposEmptySubtitle;

  /// No description provided for @sortByTooltip.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get sortByTooltip;

  /// No description provided for @sortByUpdated.
  ///
  /// In en, this message translates to:
  /// **'Recently updated'**
  String get sortByUpdated;

  /// No description provided for @sortByName.
  ///
  /// In en, this message translates to:
  /// **'Name A→Z'**
  String get sortByName;

  /// No description provided for @sortByStars.
  ///
  /// In en, this message translates to:
  /// **'Most stars'**
  String get sortByStars;

  /// No description provided for @sortByOpenPrs.
  ///
  /// In en, this message translates to:
  /// **'Most open PRs'**
  String get sortByOpenPrs;

  /// No description provided for @filterHideArchived.
  ///
  /// In en, this message translates to:
  /// **'Hide archived'**
  String get filterHideArchived;

  /// No description provided for @filterPublicOnly.
  ///
  /// In en, this message translates to:
  /// **'Public only'**
  String get filterPublicOnly;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @repoSheetOpenInBrowser.
  ///
  /// In en, this message translates to:
  /// **'Open in browser'**
  String get repoSheetOpenInBrowser;

  /// No description provided for @repoSheetCopyUrl.
  ///
  /// In en, this message translates to:
  /// **'Copy URL'**
  String get repoSheetCopyUrl;

  /// No description provided for @repoSheetUrlCopied.
  ///
  /// In en, this message translates to:
  /// **'URL copied'**
  String get repoSheetUrlCopied;

  /// No description provided for @repoMetaUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated {date}'**
  String repoMetaUpdated(String date);

  /// No description provided for @repoMetaArchived.
  ///
  /// In en, this message translates to:
  /// **'archived'**
  String get repoMetaArchived;

  /// No description provided for @repoMetaFork.
  ///
  /// In en, this message translates to:
  /// **'fork'**
  String get repoMetaFork;

  /// No description provided for @repoOpenPrPill.
  ///
  /// In en, this message translates to:
  /// **'{count} open'**
  String repoOpenPrPill(int count);

  /// No description provided for @repoDetailTabOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get repoDetailTabOverview;

  /// No description provided for @repoDetailTabPullRequests.
  ///
  /// In en, this message translates to:
  /// **'Pull requests'**
  String get repoDetailTabPullRequests;

  /// No description provided for @repoDetailTabPullRequestsCount.
  ///
  /// In en, this message translates to:
  /// **'Pull requests ({count})'**
  String repoDetailTabPullRequestsCount(int count);

  /// No description provided for @repoDetailStatStars.
  ///
  /// In en, this message translates to:
  /// **'Stars'**
  String get repoDetailStatStars;

  /// No description provided for @repoDetailStatForks.
  ///
  /// In en, this message translates to:
  /// **'Forks'**
  String get repoDetailStatForks;

  /// No description provided for @repoDetailStatIssues.
  ///
  /// In en, this message translates to:
  /// **'Issues'**
  String get repoDetailStatIssues;

  /// No description provided for @repoDetailMetaCreated.
  ///
  /// In en, this message translates to:
  /// **'Created {date}'**
  String repoDetailMetaCreated(String date);

  /// No description provided for @repoDetailMetaUpdated.
  ///
  /// In en, this message translates to:
  /// **'Updated {date}'**
  String repoDetailMetaUpdated(Object date);

  /// No description provided for @repoDetailReadmeHeader.
  ///
  /// In en, this message translates to:
  /// **'README'**
  String get repoDetailReadmeHeader;

  /// No description provided for @repoDetailReadmeEmpty.
  ///
  /// In en, this message translates to:
  /// **'No README in this repository.'**
  String get repoDetailReadmeEmpty;

  /// No description provided for @repoDetailShowMore.
  ///
  /// In en, this message translates to:
  /// **'Show more'**
  String get repoDetailShowMore;

  /// No description provided for @repoDetailShowLess.
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get repoDetailShowLess;

  /// No description provided for @repoDetailLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load'**
  String get repoDetailLoadFailed;

  /// No description provided for @repoDetailLoadFailedReadme.
  ///
  /// In en, this message translates to:
  /// **'Failed to load README'**
  String get repoDetailLoadFailedReadme;

  /// No description provided for @repoDetailNoOpenPrs.
  ///
  /// In en, this message translates to:
  /// **'No open pull requests'**
  String get repoDetailNoOpenPrs;

  /// No description provided for @repoDetailNoOpenPrsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing open on {repo}. Review requests on other repos are in Inbox.'**
  String repoDetailNoOpenPrsSubtitle(String repo);

  /// No description provided for @repoDetailDraft.
  ///
  /// In en, this message translates to:
  /// **'draft'**
  String get repoDetailDraft;

  /// No description provided for @repoDetailSheetOpenInBrowser.
  ///
  /// In en, this message translates to:
  /// **'Open in browser'**
  String get repoDetailSheetOpenInBrowser;

  /// No description provided for @repoDetailSheetCopyWebUrl.
  ///
  /// In en, this message translates to:
  /// **'Copy web URL'**
  String get repoDetailSheetCopyWebUrl;

  /// No description provided for @repoDetailSheetCopyCloneUrlHttps.
  ///
  /// In en, this message translates to:
  /// **'Copy clone URL (HTTPS)'**
  String get repoDetailSheetCopyCloneUrlHttps;

  /// No description provided for @repoDetailSheetCopyCloneUrlSsh.
  ///
  /// In en, this message translates to:
  /// **'Copy clone URL (SSH)'**
  String get repoDetailSheetCopyCloneUrlSsh;

  /// No description provided for @repoDetailWebUrlCopied.
  ///
  /// In en, this message translates to:
  /// **'Web URL copied'**
  String get repoDetailWebUrlCopied;

  /// No description provided for @repoDetailCloneUrlCopied.
  ///
  /// In en, this message translates to:
  /// **'Clone URL copied'**
  String get repoDetailCloneUrlCopied;

  /// No description provided for @repoDetailStatSubscribers.
  ///
  /// In en, this message translates to:
  /// **'Subscribers'**
  String get repoDetailStatSubscribers;

  /// No description provided for @repoDetailTabIssues.
  ///
  /// In en, this message translates to:
  /// **'Issues'**
  String get repoDetailTabIssues;

  /// No description provided for @repoDetailTabIssuesCount.
  ///
  /// In en, this message translates to:
  /// **'Issues ({count})'**
  String repoDetailTabIssuesCount(Object count);

  /// No description provided for @repoDetailTabCode.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get repoDetailTabCode;

  /// No description provided for @repoDetailNoBranches.
  ///
  /// In en, this message translates to:
  /// **'No branches'**
  String get repoDetailNoBranches;

  /// No description provided for @repoDetailNoCommits.
  ///
  /// In en, this message translates to:
  /// **'No commits'**
  String get repoDetailNoCommits;

  /// No description provided for @repoDetailBranchProtected.
  ///
  /// In en, this message translates to:
  /// **'protected'**
  String get repoDetailBranchProtected;

  /// No description provided for @repoDetailCodeUnsupported.
  ///
  /// In en, this message translates to:
  /// **'This platform does not support code browsing'**
  String get repoDetailCodeUnsupported;

  /// No description provided for @repoDetailCodeBranchesHeader.
  ///
  /// In en, this message translates to:
  /// **'Branches ({count})'**
  String repoDetailCodeBranchesHeader(Object count);

  /// No description provided for @repoDetailCodeCommitsHeader.
  ///
  /// In en, this message translates to:
  /// **'Commits ({count})'**
  String repoDetailCodeCommitsHeader(Object count);

  /// No description provided for @repoDetailTabContributors.
  ///
  /// In en, this message translates to:
  /// **'Contributors'**
  String get repoDetailTabContributors;

  /// No description provided for @repoDetailNoContributors.
  ///
  /// In en, this message translates to:
  /// **'No contributors'**
  String get repoDetailNoContributors;

  /// No description provided for @repoDetailNoContributorsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{repo} has no contributors yet.'**
  String repoDetailNoContributorsSubtitle(Object repo);

  /// No description provided for @repoDetailContributions.
  ///
  /// In en, this message translates to:
  /// **'{count} contributions'**
  String repoDetailContributions(Object count);

  /// No description provided for @repoDetailNoOpenIssues.
  ///
  /// In en, this message translates to:
  /// **'No open issues'**
  String get repoDetailNoOpenIssues;

  /// No description provided for @repoDetailNoOpenIssuesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{repo} has no open issues.'**
  String repoDetailNoOpenIssuesSubtitle(Object repo);

  /// No description provided for @repoDetailStarTooltip.
  ///
  /// In en, this message translates to:
  /// **'Star'**
  String get repoDetailStarTooltip;

  /// No description provided for @repoDetailUnstarTooltip.
  ///
  /// In en, this message translates to:
  /// **'Unstar'**
  String get repoDetailUnstarTooltip;

  /// No description provided for @repoDetailStarFailed.
  ///
  /// In en, this message translates to:
  /// **'Action failed, please retry'**
  String get repoDetailStarFailed;

  /// No description provided for @issueStateOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get issueStateOpen;

  /// No description provided for @issueStateClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get issueStateClosed;

  /// No description provided for @issueDetailMetaLine.
  ///
  /// In en, this message translates to:
  /// **'{author} opened on {date}'**
  String issueDetailMetaLine(String author, String date);

  /// No description provided for @issueDetailAssignees.
  ///
  /// In en, this message translates to:
  /// **'Assignees: {logins}'**
  String issueDetailAssignees(String logins);

  /// No description provided for @issueDetailCommentsHeader.
  ///
  /// In en, this message translates to:
  /// **'Comments ({count})'**
  String issueDetailCommentsHeader(int count);

  /// No description provided for @issueDetailNoComments.
  ///
  /// In en, this message translates to:
  /// **'No comments yet.'**
  String get issueDetailNoComments;

  /// No description provided for @prDetailBranchLine.
  ///
  /// In en, this message translates to:
  /// **'{author}  {source} → {target}'**
  String prDetailBranchLine(String author, String source, String target);

  /// No description provided for @prDetailChipCi.
  ///
  /// In en, this message translates to:
  /// **'CI {status}'**
  String prDetailChipCi(String status);

  /// No description provided for @prDetailChipNotMergeable.
  ///
  /// In en, this message translates to:
  /// **'not mergeable'**
  String get prDetailChipNotMergeable;

  /// No description provided for @prDetailFilesHeader.
  ///
  /// In en, this message translates to:
  /// **'Files ({count})'**
  String prDetailFilesHeader(int count);

  /// No description provided for @prDetailNoFiles.
  ///
  /// In en, this message translates to:
  /// **'No file list. Open in browser for the full diff.'**
  String get prDetailNoFiles;

  /// No description provided for @prDetailFileStat.
  ///
  /// In en, this message translates to:
  /// **'+{additions}  −{deletions}  {status}'**
  String prDetailFileStat(int additions, int deletions, String status);

  /// No description provided for @prDetailCommentsHeader.
  ///
  /// In en, this message translates to:
  /// **'Comments ({count})'**
  String prDetailCommentsHeader(int count);

  /// No description provided for @prDetailNoComments.
  ///
  /// In en, this message translates to:
  /// **'No comments yet.'**
  String get prDetailNoComments;

  /// No description provided for @prDetailCommentPath.
  ///
  /// In en, this message translates to:
  /// **'{path}:{line}'**
  String prDetailCommentPath(String path, int line);

  /// No description provided for @prDetailReviewApproved.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get prDetailReviewApproved;

  /// No description provided for @prDetailReviewRequestedChanges.
  ///
  /// In en, this message translates to:
  /// **'Requested changes'**
  String get prDetailReviewRequestedChanges;

  /// No description provided for @prDetailReviewCommentPosted.
  ///
  /// In en, this message translates to:
  /// **'Comment posted'**
  String get prDetailReviewCommentPosted;

  /// No description provided for @prDetailReviewMerged.
  ///
  /// In en, this message translates to:
  /// **'Merged'**
  String get prDetailReviewMerged;

  /// No description provided for @prDetailReviewFailed.
  ///
  /// In en, this message translates to:
  /// **'Review failed'**
  String get prDetailReviewFailed;

  /// No description provided for @prDetailReviewButton.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get prDetailReviewButton;

  /// No description provided for @prDetailMergeButton.
  ///
  /// In en, this message translates to:
  /// **'Merge'**
  String get prDetailMergeButton;

  /// No description provided for @prDetailReviewSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get prDetailReviewSheetTitle;

  /// No description provided for @prDetailReviewSheetCommentHint.
  ///
  /// In en, this message translates to:
  /// **'Optional comment'**
  String get prDetailReviewSheetCommentHint;

  /// No description provided for @prDetailReviewSheetComment.
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get prDetailReviewSheetComment;

  /// No description provided for @prDetailReviewSheetApprove.
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get prDetailReviewSheetApprove;

  /// No description provided for @prDetailReviewSheetRequestChanges.
  ///
  /// In en, this message translates to:
  /// **'Request changes'**
  String get prDetailReviewSheetRequestChanges;

  /// No description provided for @prDetailMergeDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Merge this pull request?'**
  String get prDetailMergeDialogTitle;

  /// No description provided for @prDetailMergeDialogContent.
  ///
  /// In en, this message translates to:
  /// **'{repo} #{number} will be merged on the remote.'**
  String prDetailMergeDialogContent(String repo, int number);

  /// No description provided for @prDetailCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get prDetailCancel;

  /// No description provided for @diffOpenInBrowser.
  ///
  /// In en, this message translates to:
  /// **'Open in browser'**
  String get diffOpenInBrowser;

  /// No description provided for @diffBinary.
  ///
  /// In en, this message translates to:
  /// **'This file is binary or the forge did not return a text diff.'**
  String get diffBinary;

  /// No description provided for @diffTruncated.
  ///
  /// In en, this message translates to:
  /// **'Showing a truncated diff.'**
  String get diffTruncated;

  /// No description provided for @diffTapHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a green or unchanged line to comment on it.'**
  String get diffTapHint;

  /// No description provided for @diffLineComment.
  ///
  /// In en, this message translates to:
  /// **'Line comment'**
  String get diffLineComment;

  /// No description provided for @diffCommentOnLine.
  ///
  /// In en, this message translates to:
  /// **'Comment on line {line}'**
  String diffCommentOnLine(int line);

  /// No description provided for @diffLineNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Line number'**
  String get diffLineNumberLabel;

  /// No description provided for @diffCommentHint.
  ///
  /// In en, this message translates to:
  /// **'Comment on this file'**
  String get diffCommentHint;

  /// No description provided for @diffPostComment.
  ///
  /// In en, this message translates to:
  /// **'Post comment'**
  String get diffPostComment;

  /// No description provided for @diffCommentPosted.
  ///
  /// In en, this message translates to:
  /// **'Comment posted'**
  String get diffCommentPosted;

  /// No description provided for @diffCommentFailed.
  ///
  /// In en, this message translates to:
  /// **'Comment failed'**
  String get diffCommentFailed;

  /// No description provided for @diffOmittedLines.
  ///
  /// In en, this message translates to:
  /// **'… remaining lines omitted'**
  String get diffOmittedLines;

  /// No description provided for @accountsTitle.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get accountsTitle;

  /// No description provided for @accountsAddGithub.
  ///
  /// In en, this message translates to:
  /// **'Add GitHub'**
  String get accountsAddGithub;

  /// No description provided for @accountsAddGitee.
  ///
  /// In en, this message translates to:
  /// **'Add Gitee'**
  String get accountsAddGitee;

  /// No description provided for @accountsAddGitlab.
  ///
  /// In en, this message translates to:
  /// **'Add GitLab'**
  String get accountsAddGitlab;

  /// No description provided for @accountsAddCodeup.
  ///
  /// In en, this message translates to:
  /// **'Add Codeup'**
  String get accountsAddCodeup;

  /// No description provided for @accountsAddGongfeng.
  ///
  /// In en, this message translates to:
  /// **'Add Gongfeng'**
  String get accountsAddGongfeng;

  /// No description provided for @accountsAddCoding.
  ///
  /// In en, this message translates to:
  /// **'Add CODING'**
  String get accountsAddCoding;

  /// No description provided for @accountsRevokeGithub.
  ///
  /// In en, this message translates to:
  /// **'Revoke a GitHub token on the website'**
  String get accountsRevokeGithub;

  /// No description provided for @accountsRevokeGitee.
  ///
  /// In en, this message translates to:
  /// **'Revoke a Gitee token on the website'**
  String get accountsRevokeGitee;

  /// No description provided for @accountsRevokeGitlab.
  ///
  /// In en, this message translates to:
  /// **'Revoke a GitLab token on the website'**
  String get accountsRevokeGitlab;

  /// No description provided for @accountsRevokeCodeup.
  ///
  /// In en, this message translates to:
  /// **'Revoke a Codeup token on the website'**
  String get accountsRevokeCodeup;

  /// No description provided for @accountsRevokeGongfeng.
  ///
  /// In en, this message translates to:
  /// **'Revoke a Gongfeng token on the website'**
  String get accountsRevokeGongfeng;

  /// No description provided for @accountsRevokeCoding.
  ///
  /// In en, this message translates to:
  /// **'Revoke a CODING token on the website'**
  String get accountsRevokeCoding;

  /// No description provided for @accountsRemoveDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove account?'**
  String get accountsRemoveDialogTitle;

  /// No description provided for @accountsRemoveDialogContent.
  ///
  /// In en, this message translates to:
  /// **'Deletes the local token for {name}. Revoke it on the platform website too.'**
  String accountsRemoveDialogContent(String name);

  /// No description provided for @accountsRemoveCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get accountsRemoveCancel;

  /// No description provided for @accountsRemoveConfirm.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get accountsRemoveConfirm;

  /// No description provided for @accountDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Account details'**
  String get accountDetailTitle;

  /// No description provided for @accountDetailDisplayName.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get accountDetailDisplayName;

  /// No description provided for @accountDetailLogin.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get accountDetailLogin;

  /// No description provided for @accountDetailPlatform.
  ///
  /// In en, this message translates to:
  /// **'Platform'**
  String get accountDetailPlatform;

  /// No description provided for @accountDetailBaseUrl.
  ///
  /// In en, this message translates to:
  /// **'Server URL'**
  String get accountDetailBaseUrl;

  /// No description provided for @accountDetailOrgId.
  ///
  /// In en, this message translates to:
  /// **'Organization ID'**
  String get accountDetailOrgId;

  /// No description provided for @accountDetailAuthType.
  ///
  /// In en, this message translates to:
  /// **'Auth type'**
  String get accountDetailAuthType;

  /// No description provided for @accountDetailAccountId.
  ///
  /// In en, this message translates to:
  /// **'Account ID'**
  String get accountDetailAccountId;

  /// No description provided for @accountDetailCreatedAt.
  ///
  /// In en, this message translates to:
  /// **'Added at'**
  String get accountDetailCreatedAt;

  /// No description provided for @addAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Add {platform}'**
  String addAccountTitle(String platform);

  /// No description provided for @addAccountBaseUrl.
  ///
  /// In en, this message translates to:
  /// **'Base URL'**
  String get addAccountBaseUrl;

  /// No description provided for @addAccountApiDomain.
  ///
  /// In en, this message translates to:
  /// **'API domain'**
  String get addAccountApiDomain;

  /// No description provided for @addAccountOrgId.
  ///
  /// In en, this message translates to:
  /// **'Organization ID'**
  String get addAccountOrgId;

  /// No description provided for @addAccountOrgIdHint.
  ///
  /// In en, this message translates to:
  /// **'Required for 中心版'**
  String get addAccountOrgIdHint;

  /// No description provided for @addAccountOpenTokenPage.
  ///
  /// In en, this message translates to:
  /// **'Open {platform} token page'**
  String addAccountOpenTokenPage(String platform);

  /// No description provided for @addAccountPat.
  ///
  /// In en, this message translates to:
  /// **'Personal access token'**
  String get addAccountPat;

  /// No description provided for @addAccountDisplayName.
  ///
  /// In en, this message translates to:
  /// **'Display name (optional)'**
  String get addAccountDisplayName;

  /// No description provided for @addAccountVerifySave.
  ///
  /// In en, this message translates to:
  /// **'Verify & save'**
  String get addAccountVerifySave;

  /// No description provided for @addAccountErrorNoToken.
  ///
  /// In en, this message translates to:
  /// **'Paste a token first.'**
  String get addAccountErrorNoToken;

  /// No description provided for @addAccountErrorNoTeam.
  ///
  /// In en, this message translates to:
  /// **'Set your team URL ({url}).'**
  String addAccountErrorNoTeam(String url);

  /// No description provided for @addAccountErrorVerifyFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not verify token'**
  String get addAccountErrorVerifyFailed;

  /// No description provided for @addAccountHelpGithub.
  ///
  /// In en, this message translates to:
  /// **'Create a classic Personal Access Token with repo, notifications, and read:user. Fine-grained tokens cannot read notifications reliably.'**
  String get addAccountHelpGithub;

  /// No description provided for @addAccountHelpGitee.
  ///
  /// In en, this message translates to:
  /// **'Create a private token with user_info, projects, pull requests, and notifications.'**
  String get addAccountHelpGitee;

  /// No description provided for @addAccountHelpGitlab.
  ///
  /// In en, this message translates to:
  /// **'Create a personal access token with the api scope. For self-hosted GitLab, set the Base URL first (https://gitlab.example.com).'**
  String get addAccountHelpGitlab;

  /// No description provided for @addAccountHelpCodeup.
  ///
  /// In en, this message translates to:
  /// **'Create a Yunxiao personal access token with 代码管理 · 合并请求 and 代码仓库. 中心版 needs Organization ID; Region 版 uses the instance API domain and can leave Organization ID empty.'**
  String get addAccountHelpCodeup;

  /// No description provided for @addAccountHelpGongfeng.
  ///
  /// In en, this message translates to:
  /// **'Create a private token at Profile → Account. For a self-hosted 工蜂 instance, set the Base URL first (https://git.example.com).'**
  String get addAccountHelpGongfeng;

  /// No description provided for @addAccountHelpCoding.
  ///
  /// In en, this message translates to:
  /// **'Set your team URL ({url}). Create a personal access token with vcs:repository and vcs:merge (rw to comment/merge).'**
  String addAccountHelpCoding(String url);

  /// No description provided for @mineTitle.
  ///
  /// In en, this message translates to:
  /// **'Me'**
  String get mineTitle;

  /// No description provided for @mineAccounts.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get mineAccounts;

  /// No description provided for @mineAccountsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'{count} connected'**
  String mineAccountsSubtitle(int count);

  /// No description provided for @mineAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get mineAppearance;

  /// No description provided for @mineAppearanceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Follows system'**
  String get mineAppearanceSubtitle;

  /// No description provided for @mineAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get mineAbout;

  /// No description provided for @mineAboutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'CodeInbox {version}'**
  String mineAboutSubtitle(String version);

  /// No description provided for @mineTokensExplanation.
  ///
  /// In en, this message translates to:
  /// **'Tokens stay on this device in the system secret store. There is no CodeInbox backend in this version.'**
  String get mineTokensExplanation;

  /// No description provided for @mineNoAccountsTitle.
  ///
  /// In en, this message translates to:
  /// **'No accounts'**
  String get mineNoAccountsTitle;

  /// No description provided for @mineNoAccountsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add GitHub or Gitee from Accounts.'**
  String get mineNoAccountsSubtitle;

  /// No description provided for @imageAlt.
  ///
  /// In en, this message translates to:
  /// **'[image]'**
  String get imageAlt;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @openInBrowser.
  ///
  /// In en, this message translates to:
  /// **'Open in browser'**
  String get openInBrowser;

  /// No description provided for @platformGithub.
  ///
  /// In en, this message translates to:
  /// **'GitHub'**
  String get platformGithub;

  /// No description provided for @platformGitee.
  ///
  /// In en, this message translates to:
  /// **'Gitee'**
  String get platformGitee;

  /// No description provided for @platformGitlab.
  ///
  /// In en, this message translates to:
  /// **'GitLab'**
  String get platformGitlab;

  /// No description provided for @platformCodeup.
  ///
  /// In en, this message translates to:
  /// **'Codeup'**
  String get platformCodeup;

  /// No description provided for @platformGongfeng.
  ///
  /// In en, this message translates to:
  /// **'Gongfeng'**
  String get platformGongfeng;

  /// No description provided for @platformCoding.
  ///
  /// In en, this message translates to:
  /// **'CODING'**
  String get platformCoding;

  /// No description provided for @crStateOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get crStateOpen;

  /// No description provided for @crStateMerged.
  ///
  /// In en, this message translates to:
  /// **'Merged'**
  String get crStateMerged;

  /// No description provided for @crStateClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get crStateClosed;

  /// No description provided for @repoVisibilityPublic.
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get repoVisibilityPublic;

  /// No description provided for @repoVisibilityInternal.
  ///
  /// In en, this message translates to:
  /// **'Internal'**
  String get repoVisibilityInternal;

  /// No description provided for @repoVisibilityPrivate.
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get repoVisibilityPrivate;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.countryCode) {
          case 'CN':
            return AppLocalizationsZhCn();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
