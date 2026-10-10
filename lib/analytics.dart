import 'dart:developer' as developer;

void track(String name, [Map<String, Object?> props = const {}]) {
  developer.log('$name $props', name: 'codeinbox.analytics');
}
