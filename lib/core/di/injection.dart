import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

import '../network/mock_network_interceptor.dart';
import '../platform/pos_hardware_bridge.dart';
import '../../data/datasources/local_database.dart';
import '../../data/repositories/cart_repository_impl.dart';
import '../../data/repositories/catalog_repository_impl.dart';
import '../../data/repositories/cold_chain_repository_impl.dart';
import '../../data/repositories/fx_repository_impl.dart';
import '../../data/repositories/order_repository_impl.dart';
import '../../domain/repositories/cart_repository.dart';
import '../../domain/repositories/catalog_repository.dart';
import '../../domain/repositories/cold_chain_repository.dart';
import '../../domain/repositories/fx_repository.dart';
import '../../domain/repositories/order_repository.dart';

final sl = GetIt.instance;

void setupDependencyInjection() {
  if (sl.isRegistered<AppDatabase>()) return;

  // Database
  final database = AppDatabase.instance;
  sl.registerSingleton<AppDatabase>(database);

  // Platform hardware bridge
  final posBridge = PosHardwareBridge();
  sl.registerSingleton<PosHardwareBridge>(posBridge);

  // Mock Dio client
  final dio = createMockDio(database);
  sl.registerSingleton<Dio>(dio);

  // Repositories
  final catalogRepo = CatalogRepositoryImpl(database: database);
  sl.registerSingleton<CatalogRepository>(catalogRepo);

  final cartRepo = CartRepositoryImpl(database: database);
  sl.registerSingleton<CartRepository>(cartRepo);

  final orderRepo = OrderRepositoryImpl(database: database);
  sl.registerSingleton<OrderRepository>(orderRepo);

  final coldChainRepo = ColdChainRepositoryImpl();
  sl.registerSingleton<ColdChainRepository>(coldChainRepo);

  final fxRepo = FxRepositoryImpl();
  sl.registerSingleton<FxRepository>(fxRepo);
}
