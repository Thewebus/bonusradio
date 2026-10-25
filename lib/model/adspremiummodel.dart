// To parse this JSON data, do
//
//     final adsPremiumModel = adsPremiumModelFromJson(jsonString);

import 'dart:convert';

AdsPremiumModel adsPremiumModelFromJson(String str) =>
    AdsPremiumModel.fromJson(json.decode(str));

String adsPremiumModelToJson(AdsPremiumModel data) =>
    json.encode(data.toJson());

// get_ads_premium — the posters of the radio screen's "zone pub" slideshow,
// managed in the admin (Ads Premium).
class AdsPremiumModel {
  int? status;
  String? message;
  List<Result>? result;

  AdsPremiumModel({this.status, this.message, this.result});

  factory AdsPremiumModel.fromJson(Map<String, dynamic> json) =>
      AdsPremiumModel(
        status: json["status"],
        message: json["message"],
        result: json["result"] == null
            ? []
            : List<Result>.from(json["result"].map((x) => Result.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "status": status,
        "message": message,
        "result": result == null
            ? []
            : List<dynamic>.from(result!.map((x) => x.toJson())),
      };
}

class Result {
  int? id;
  String? creaName;
  // Full URL of the poster (uploaded file or external image).
  String? imageUrl;
  // Opened on tap when set (site, WhatsApp, Facebook…).
  String? linkUrl;
  // Seconds this poster stays on screen before the next one.
  int? displayDuration;

  Result({
    this.id,
    this.creaName,
    this.imageUrl,
    this.linkUrl,
    this.displayDuration,
  });

  factory Result.fromJson(Map<String, dynamic> json) => Result(
        id: json["id"],
        creaName: json["crea_name"],
        imageUrl: json["image_url"],
        linkUrl: json["link_url"],
        displayDuration: json["display_duration"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "crea_name": creaName,
        "image_url": imageUrl,
        "link_url": linkUrl,
        "display_duration": displayDuration,
      };
}
