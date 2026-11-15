import 'dart:math';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import '../../data/datasources/local_database.dart';

class MockNetworkInterceptor extends Interceptor {
  final AppDatabase database;

  MockNetworkInterceptor({required this.database});

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final customLatency = prefs.getInt(AppConstants.prefSimulatedLatency);
    final force503 = prefs.getBool(AppConstants.prefForce503) ?? false;

    // Configurable latency: default 400ms-850ms
    final delayMs = customLatency ?? (400 + Random().nextInt(450));
    await Future.delayed(Duration(milliseconds: delayMs));

    final path = options.path;

    // Check if force 503 checkout retry simulation is triggered
    if (force503 && path.contains('/api/checkout')) {
      handler.reject(
        DioException(
          requestOptions: options,
          response: Response(
            requestOptions: options,
            statusCode: 503,
            statusMessage: 'Service Unavailable - Dark-Store Cluster Overload (Recruiter Debug Mode)',
            data: {
              'error': 'Dark-Store Cluster Overload',
              'retryAfterSeconds': 5,
              'code': 'HTTP_503_STORE_CAPACITY',
            },
          ),
          type: DioExceptionType.badResponse,
        ),
      );
      return;
    }

    if (path == '/api/catalog') {
      final products = await database.getProducts();
      final data = products
          .map(
            (p) => {
              'id': p.id,
              'name': p.name,
              'price_usd': p.priceUsd,
              'stock': p.darkStoreStock,
              'upc': p.upcBarcode,
            },
          )
          .toList();

      handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: {'status': 'ok', 'count': data.length, 'results': data},
        ),
      );
      return;
    }

    if (path == '/api/orders') {
      final orders = await database.getOrders();
      final data = orders
          .map(
            (o) => {
              'id': o.id,
              'total': o.totalUsd,
              'status': o.status.name,
              'items_count': o.items.length,
            },
          )
          .toList();

      handler.resolve(
        Response(
          requestOptions: options,
          statusCode: 200,
          data: {'status': 'ok', 'results': data},
        ),
      );
      return;
    }

    // Default pass-through
    handler.next(options);
  }
}

Dio createMockDio(AppDatabase database) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://api.omnicart.enterprise',
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
    ),
  );
  dio.interceptors.add(MockNetworkInterceptor(database: database));
  return dio;
}
