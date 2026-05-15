import '../cubits/auth_cubit.dart';

class AppRoutes {
  static const String splash = '/splash';
  static const String auth = '/';
  static const String profile = '/profile';

  static const String farmerHome = '/farmer';
  static const String producerHome = '/producer';
  static const String slaughterhouseHome = '/slaughterhouse';

  static const String collectorHome = '/collector';
  static const String depotHome = '/depot';
  static const String laveryHome = '/lavery';
  static const String transformationHome = '/transformation';

  static String supplierRoute(SupplierRole role) {
    switch (role) {
      case SupplierRole.farmer:
        return farmerHome;
      case SupplierRole.producer:
        return producerHome;
      case SupplierRole.slaughterhouse:
        return slaughterhouseHome;
    }
  }

  static String workerRoute(WorkerRole role) {
    switch (role) {
      case WorkerRole.collector:
        return collectorHome;
      case WorkerRole.depot:
        return depotHome;
      case WorkerRole.lavery:
        return laveryHome;
      case WorkerRole.transformation:
        return transformationHome;
    }
  }
}
