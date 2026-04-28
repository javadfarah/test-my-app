import 'package:fpdart/fpdart.dart';
import 'package:testmyapp/core/utils/exception_handler.dart';
import 'package:testmyapp/features/stats/model/stats_failure.dart';
import 'package:testmyapp/hiddifycore/generated/v2/hcore/hcore.pb.dart';
import 'package:testmyapp/hiddifycore/hiddify_core_service.dart';
import 'package:testmyapp/utils/custom_loggers.dart';

abstract interface class StatsRepository {
  Stream<Either<StatsFailure, SystemInfo>> watchStats();
}

class StatsRepositoryImpl with ExceptionHandler, InfraLogger implements StatsRepository {
  StatsRepositoryImpl({required this.singbox});

  final HiddifyCoreService singbox;

  @override
  Stream<Either<StatsFailure, SystemInfo>> watchStats() {
    return singbox.watchStats().handleExceptions(StatsUnexpectedFailure.new);
  }
}
