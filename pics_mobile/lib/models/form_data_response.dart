import 'form_item.dart';

class FormDataResponse {
  final String message;
  final FormDataDetail data;

  FormDataResponse({
    required this.message,
    required this.data,
  });

  factory FormDataResponse.fromJson(Map<String, dynamic> json) {
    return FormDataResponse(
      message: json['message'] as String? ?? '',
      data: FormDataDetail.fromJson(json['data'] as Map<String, dynamic>? ?? {}),
    );
  }
}

class FormDataDetail {
  final String codeUnit;
  final String poc;
  final String mode;
  final String unitSection;
  final String scheduleDate;
  final int scheduleId;
  final int totalItems;
  final int totalCategories;
  final List<FormItem> items;

  FormDataDetail({
    required this.codeUnit,
    required this.poc,
    required this.mode,
    required this.unitSection,
    required this.scheduleDate,
    required this.scheduleId,
    required this.totalItems,
    required this.totalCategories,
    required this.items,
  });

  factory FormDataDetail.fromJson(Map<String, dynamic> json) {
    // Parse the nested categories_with_items structure
    final categoriesWithItems = json['categories_with_items'] as List<dynamic>? ?? [];
    
    // Flatten all items from all categories into a single list
    final List<FormItem> allItems = [];
    for (final category in categoriesWithItems) {
      final categoryMap = category as Map<String, dynamic>;
      final itemsList = categoryMap['items'] as List<dynamic>? ?? [];
      
      for (final item in itemsList) {
        allItems.add(FormItem.fromJson(item as Map<String, dynamic>));
      }
    }

    return FormDataDetail(
      codeUnit: json['code_unit'] as String? ?? '',
      poc: json['poc'] as String? ?? '',
      mode: json['mode'] as String? ?? '',
      unitSection: json['unit_section'] as String? ?? '',
      scheduleDate: json['schedule_date'] as String? ?? '',
      scheduleId: json['schedule_id'] as int? ?? 0,
      totalItems: json['total_items'] as int? ?? 0,
      totalCategories: json['total_categories'] as int? ?? 0,
      items: allItems,
    );
  }

  // Helper method to check if this schedule has already been claimed
  // by comparing schedule date with any history entry dates
  bool get isAlreadyClaimed {
    try {
      final scheduleDateObj = DateTime.parse(scheduleDate);
      
      // Check if any item has a history entry matching the schedule date
      for (final item in items) {
        for (final historyEntry in item.history) {
          if (_isSameDate(historyEntry.date, scheduleDateObj)) {
            return true;
          }
        }
      }
      return false;
    } catch (e) {
      // If date parsing fails, assume not claimed to be safe
      return false;
    }
  }

  bool _isSameDate(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }
}
