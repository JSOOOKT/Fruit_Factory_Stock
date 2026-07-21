import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/tank_repository.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/tank.dart';

final tankRepositoryProvider = Provider<TankRepository>((ref) {
  return TankRepository();
});

final tankListProvider = FutureProvider<List<Tank>>((ref) async {
  final repository = ref.watch(tankRepositoryProvider);
  final factoryId = ref.watch(currentFactoryIdProvider);
  
  if (factoryId == null) return [];
  return await repository.getTanksByFactory(factoryId);
});

final tankListStreamProvider = StreamProvider<List<Tank>>((ref) {
  final repository = ref.watch(tankRepositoryProvider);
  final factoryId = ref.watch(currentFactoryIdProvider);
  
  if (factoryId == null) return Stream.value([]);
  return repository.watchTanks(factoryId);
});
