import '../domain/forge_adapter.dart';
import '../domain/models.dart';
import 'adapters/codeup_adapter.dart';
import 'adapters/gitee_adapter.dart';
import 'adapters/github_adapter.dart';
import 'adapters/gitlab_adapter.dart';
import 'adapters/coding_adapter.dart';
import 'adapters/gongfeng_adapter.dart';

class AdapterRegistry {
  AdapterRegistry({Map<ForgePlatform, ForgeAdapter>? adapters})
      : _adapters = adapters ??
            {
              ForgePlatform.github: GithubAdapter(),
              ForgePlatform.gitee: GiteeAdapter(),
              ForgePlatform.gitlab: GitlabAdapter(),
              ForgePlatform.codeup: CodeupAdapter(),
              ForgePlatform.gongfeng: GongfengAdapter(),
              ForgePlatform.coding: CodingAdapter(),
            };

  final Map<ForgePlatform, ForgeAdapter> _adapters;

  ForgeAdapter forPlatform(ForgePlatform platform) {
    final adapter = _adapters[platform];
    if (adapter == null) {
      throw AdapterException.unsupported('No adapter for ${platform.name}');
    }
    return adapter;
  }
}
