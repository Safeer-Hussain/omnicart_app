import '../../domain/entities/cold_chain_log.dart';
import '../../domain/repositories/cold_chain_repository.dart';
import '../datasources/local_database.dart';

class ColdChainRepositoryImpl implements ColdChainRepository {
  final AppDatabase _db = AppDatabase.instance;

  @override
  Future<void> recordLog(ColdChainLog log) async {
    await _db.insertColdChainLog(log);
  }

  @override
  Future<List<ColdChainLog>> getRecentLogs({int limit = 20}) async {
    return await _db.getColdChainLogs(limit: limit);
  }

  @override
  Future<List<ColdChainLog>> getDeviations() async {
    return await _db.getColdChainDeviations();
  }
}
