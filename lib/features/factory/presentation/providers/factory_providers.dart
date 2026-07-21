import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/factory_repository.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/factory.dart';

final factoryRepositoryProvider = Provider<FactoryRepository>((ref) {
  return FactoryRepository();
});

final allFactoriesProvider = FutureProvider<List<Factory>>((ref) async {
  final repository = ref.watch(factoryRepositoryProvider);
  return await repository.getAllFactories();
});

final currentFactoryProvider = FutureProvider<Factory?>((ref) async {
  final authState = ref.watch(authStateProvider);
  final factoryId = authState.factoryId;
  
  if (factoryId == null) return null;
  
  final repository = ref.watch(factoryRepositoryProvider);
  return await repository.getFactory(factoryId);
});

final currentFactoryStreamProvider = StreamProvider<Factory?>((ref) {
  final authState = ref.watch(authStateProvider);
  final factoryId = authState.factoryId;
  
  if (factoryId == null) {
    return Stream.value(null);
  }
  
  final repository = ref.watch(factoryRepositoryProvider);
  return repository.watchFactory(factoryId);
});
