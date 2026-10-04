// To parse this JSON data, do
//
//     final videoCategoryModel = videoCategoryModelFromJson(jsonString);

import 'dart:convert';

VideoCategoryModel videoCategoryModelFromJson(String str) =>
    VideoCategoryModel.fromJson(json.decode(str));

String videoCategoryModelToJson(VideoCategoryModel data) =>
    json.encode(data.toJson());

class VideoCategoryModel {
  VideoCategoryModel({
    this.status,
    this.message,
    this.result,
  });

  int? status;
  String? message;
  List<Result>? result;

  factory VideoCategoryModel.fromJson(Map<String, dynamic> json) =>
      VideoCategoryModel(
        status: json["status"],
        message: json["message"],
        result: json["result"] == null
            ? []
            : List<Result>.from(
                json["result"]?.map((x) => Result.fromJson(x)) ?? []),
      );

  Map<String, dynamic> toJson() => {
        "status": status,
        "message": message,
        "result": result == null
            ? []
            : List<dynamic>.from(result?.map((x) => x.toJson()) ?? []),
      };
}

class Result {
  Result({
    this.id,
    this.name,
    this.status,
    this.createdAt,
    this.updatedAt,
  });

  int? id;
  String? name;
  int? status;
  String? createdAt;
  String? updatedAt;

  factory Result.fromJson(Map<String, dynamic> json) => Result(
        id: json["id"],
        name: json["name"],
        status: json["status"],
        createdAt: json["created_at"],
        updatedAt: json["updated_at"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "status": status,
        "created_at": createdAt,
        "updated_at": updatedAt,
      };
}
