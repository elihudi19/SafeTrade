class PredictiveAlert {
  final String id;
  final String? product; // null kwa alerts za kibiashara (loss_warning/profit_trend)
  final String alertType; // fast_moving | slow_moving | loss_warning | profit_trend
  final Map<String, dynamic> detail;

  PredictiveAlert({
    required this.id, this.product, required this.alertType,
    required this.detail,
  });

  factory PredictiveAlert.fromJson(Map<String, dynamic> json) => PredictiveAlert(
        id: json["id"], product: json["product"], alertType: json["alert_type"],
        detail: Map<String, dynamic>.from(json["detail_json"] ?? {}),
      );

  bool get isBusinessLevel => alertType == "loss_warning" || alertType == "profit_trend";
}
