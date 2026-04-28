import 'package:testmyapp/core/directories/directories_provider.dart';
import 'package:testmyapp/core/notification/in_app_notification_controller.dart';
import 'package:testmyapp/core/preferences/general_preferences.dart';
import 'package:testmyapp/hiddifycore/hiddify_core_service.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
part 'init_signal.g.dart';

@riverpod
class CoreRestartSignal extends _$CoreRestartSignal {
  @override
  int build() => 0;

  void restart() => state++;
}
