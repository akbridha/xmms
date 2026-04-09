class ValidationDetail {
  final String scheduleId;
  final List<ValidationResultData> data;

  ValidationDetail({
    required this.scheduleId,
    required this.data,
  });

  factory ValidationDetail.fromJson(Map<String, dynamic> json) {
    final dataList = json['data'] as List<dynamic>? ?? [];
    
    return ValidationDetail(
      scheduleId: json['schedule_id']?.toString() ?? '',
      data: dataList.map((e) => ValidationResultData.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'schedule_id': scheduleId,
      'data': data.map((e) => e.toJson()).toList(),
    };
  }
}

class ValidationResultData {
  final int scheduleId;
  final List<int> resultIds;
  final String section;
  final String codeUnit;
  final String poc;
  final String? hmKm;
  final String nrpName;
  final String startTime;
  final String endTime;
  final String status;
  final Map<String, List<ValidationCategory>> data;

  ValidationResultData({
    required this.scheduleId,
    required this.resultIds,
    required this.section,
    required this.codeUnit,
    required this.poc,
    this.hmKm,
    required this.nrpName,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.data,
  });

  factory ValidationResultData.fromJson(Map<String, dynamic> json) {
    final resultIdsRaw = json['result_ids'] as List<dynamic>? ?? [];
    final dataRaw = json['data'] as Map<String, dynamic>? ?? {};
    
    final resultIds = resultIdsRaw.map((e) => e as int).toList();
    final dataMap = <String, List<ValidationCategory>>{};

    dataRaw.forEach((pocKey, pocValue) {
      if (pocValue is List<dynamic>) {
        final categories = <ValidationCategory>[];
        for (final categoryData in pocValue) {
          if (categoryData is List<dynamic> && categoryData.length >= 2) {
            final categoryName = categoryData[0] as String? ?? '';
            final items = categoryData[1] as List<dynamic>? ?? [];
            categories.add(ValidationCategory(
              name: categoryName,
              items: items.map((item) {
                if (item is List<dynamic> && item.length >= 4) {
                  return DetailValidationItem(
                    id: item[0]?.toString() ?? '',
                    details: item.length > 1 && item[1] is Map<String, dynamic>
                        ? ValidationItemDetails.fromJson(item[1] as Map<String, dynamic>)
                        : ValidationItemDetails(detailsItems: '', activity: '', value: ''),
                    inputValue: item[2]?.toString() ?? '',
                    flag: item[3] as int? ?? 0,
                  );
                }
                return DetailValidationItem(
                  id: '',
                  details: ValidationItemDetails(detailsItems: '', activity: '', value: ''),
                  inputValue: '',
                  flag: 0,
                );
              }).toList(),
            ));
          }
        }
        dataMap[pocKey] = categories;
      }
    });

    return ValidationResultData(
      scheduleId: json['schedule_id'] as int? ?? 0,
      resultIds: resultIds,
      section: json['section'] as String? ?? '',
      codeUnit: json['code_unit'] as String? ?? '',
      poc: json['poc'] as String? ?? '',
      hmKm: json['hm_km'] as String?,
      nrpName: json['nrp_name'] as String? ?? '',
      startTime: json['start_time'] as String? ?? '',
      endTime: json['end_time'] as String? ?? '',
      status: json['status'] as String? ?? '',
      data: dataMap,
    );
  }

  Map<String, dynamic> toJson() {
    final dataJson = <String, dynamic>{};
    data.forEach((key, categories) {
      dataJson[key] = categories.map((category) => [
        category.name,
        category.items.map((item) => [
          item.id,
          item.details.toJson(),
          item.inputValue,
          item.flag,
        ]).toList(),
      ]).toList();
    });

    return {
      'schedule_id': scheduleId,
      'result_ids': resultIds,
      'section': section,
      'code_unit': codeUnit,
      'poc': poc,
      'hm_km': hmKm,
      'nrp_name': nrpName,
      'start_time': startTime,
      'end_time': endTime,
      'status': status,
      'data': dataJson,
    };
  }
}

class ValidationCategory {
  final String name;
  final List<DetailValidationItem> items;

  ValidationCategory({
    required this.name,
    required this.items,
  });
}

class DetailValidationItem {
  final String id;
  final ValidationItemDetails details;
  final String inputValue;
  final int flag;

  DetailValidationItem({
    required this.id,
    required this.details,
    required this.inputValue,
    required this.flag,
  });
}

class ValidationItemDetails {
  final String detailsItems;
  final String activity;
  final String value;

  ValidationItemDetails({
    required this.detailsItems,
    required this.activity,
    required this.value,
  });

  factory ValidationItemDetails.fromJson(Map<String, dynamic> json) {
    return ValidationItemDetails(
      detailsItems: json['details_items'] as String? ?? '',
      activity: json['activity'] as String? ?? '',
      value: json['value'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'details_items': detailsItems,
      'activity': activity,
      'value': value,
    };
  }
}
