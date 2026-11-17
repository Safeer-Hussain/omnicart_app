import '../entities/cold_chain_log.dart';

abstract class ColdChainRepository {
  Future<void> recordLog(ColdChainLog log);
  Future<List<ColdChainLog>> getRecentLogs({int limit = 20});
  Future<List<ColdChainLog>> getDeviations();
}
