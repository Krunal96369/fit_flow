import 'package:flutter/foundation.dart';

import '../../../../data/services/cloud_functions_service.dart';
import '../../domain/food_item.dart';

class FoodRepository {
  final CloudFunctionsService _cloudFunctionsService;

  FoodRepository(this._cloudFunctionsService);

  Future<List<FoodItem>> searchFoods(String query) async {
    try {
      debugPrint('Repository: Starting food search for query: $query');
      final response = await _cloudFunctionsService.searchFoods(query);
      debugPrint(
          'Repository: Received response from service: ${response.toString()}');

      // The response is already a List<FoodItem> from CloudFunctionsService
      return response;
    } catch (e) {
      debugPrint('Repository: Error in searchFoods: $e');
      rethrow;
    }
  }
}
