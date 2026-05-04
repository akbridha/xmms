class HistoryPrintModel {
  final int? idResult;
  final int? scheduleId;
  final List<int>? resultIds;
  final String? section;
  final String? codeUnit;
  final String? actualEndTime;
  final String? poc;
  final dynamic hmKm;
  final String? nrpName;
  final String? startTime;
  final String? endTime;
  final String? status;
  final Map<String, dynamic>? data;
  final String? validationBy;
  final String? validatorName;
  final String? validationTime;

  HistoryPrintModel({
    this.idResult,
    this.scheduleId,
    this.resultIds,
    this.section,
    this.codeUnit,
    this.actualEndTime,
    this.poc,
    this.hmKm,
    this.nrpName,
    this.startTime,
    this.endTime,
    this.status,
    this.data,
    this.validationBy,
    this.validatorName,
    this.validationTime,
  });

  factory HistoryPrintModel.fromJson(Map<String, dynamic> json) {
    return HistoryPrintModel(
      idResult: json['id_result'],
      scheduleId: json['schedule_id'],
      resultIds: json['result_ids'] != null 
        ? List<int>.from(json['result_ids']) 
        : null,
      section: json['section'],
      codeUnit: json['code_unit'],
      actualEndTime: json['actual_end_time'],
      poc: json['poc'],
      hmKm: json['hm_km'],
      nrpName: json['nrp_name'],
      startTime: json['start_time'],
      endTime: json['end_time'],
      status: json['status'],
      data: json['data'],
      validationBy: json['validation_by'],
      validatorName: json['validator_name'],
      validationTime: json['validation_time'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_result': idResult,
      'schedule_id': scheduleId,
      'result_ids': resultIds,
      'section': section,
      'code_unit': codeUnit,
      'actual_end_time': actualEndTime,
      'poc': poc,
      'hm_km': hmKm,
      'nrp_name': nrpName,
      'start_time': startTime,
      'end_time': endTime,
      'status': status,
      'data': data,
      'validation_by': validationBy,
      'validator_name': validatorName,
      'validation_time': validationTime,
    };
  }
}