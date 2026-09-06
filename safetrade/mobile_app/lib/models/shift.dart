class Shift {
  final String id;
  final String status; // active | closed
  final String clockIn;
  final String? clockOut;
  final Map<String, dynamic>? summary;

  Shift({
    required this.id, required this.status, required this.clockIn,
    this.clockOut, this.summary,
  });

  factory Shift.fromJson(Map<String, dynamic> json) => Shift(
        id: json["id"], status: json["status"], clockIn: json["clock_in"] ?? "",
        clockOut: json["clock_out"],
        summary: json["summary_json"] == null
            ? null
            : Map<String, dynamic>.from(json["summary_json"]),
      );
}
