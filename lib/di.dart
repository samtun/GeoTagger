import 'package:geo_tagger/repositories/position_repository.dart';
import 'package:get_it/get_it.dart';

final getIt = GetIt.instance;

void setupDependencies() {
  getIt.registerSingleton<PositionRepository>(PositionRepository());
}