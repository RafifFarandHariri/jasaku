import 'package:flutter/foundation.dart';
import 'package:jasaku_app/services/api_service.dart';

class ServicesProvider with ChangeNotifier {
  List<dynamic> _services = [];
  bool _isLoading = false;

  List<dynamic> get services => _services;
  bool get isLoading => _isLoading;

  void setServices(List<dynamic> list) {
    _services = List.from(list);
    notifyListeners();
  }

  void addService(Map<String, dynamic> svc) {
    // insert at top
    _services.insert(0, svc);
    notifyListeners();
  }

  Future<void> fetchServices() async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await ApiService.get('services');
      if (res is List) {
        _services = List.from(res);
      }
    } catch (_) {}
    _isLoading = false;
    notifyListeners();
  }
}
