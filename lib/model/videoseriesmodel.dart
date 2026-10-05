// To parse this JSON data, do
//
//     final videoSeriesModel = videoSeriesModelFromJson(jsonString);
//     final videoSeriesDetailModel = videoSeriesDetailModelFromJson(jsonString);

import 'dart:convert';
import 'package:myBonus/model/liveeventmodel.dart' as liveevent;

VideoSeriesModel videoSeriesModelFromJson(String str) =>
    VideoSeriesModel.fromJson(json.decode(str));

class VideoSeriesModel {
  VideoSeriesModel({
    this.status,
    this.message,
    this.result,
  });

  int? status;
  String? message;
  List<Result>? result;

  factory VideoSeriesModel.fromJson(Map<String, dynamic> json) =>
      VideoSeriesModel(
        status: json["status"],
        message: json["message"],
        result: json["result"] == null
            ? []
            : List<Result>.from(
                json["result"]?.map((x) => Result.fromJson(x)) ?? []),
      );
}

class Result {
  Result({
    this.id,
    this.title,
    this.description,
    this.portraitImg,
    this.landscapeImg,
    this.categoryId,
    this.categoryName,
    this.episodeCount,
    this.status,
  });

  int? id;
  String? title;
  String? description;
  String? portraitImg;
  String? landscapeImg;
  int? categoryId;
  String? categoryName;
  int? episodeCount;
  int? status;

  factory Result.fromJson(Map<String, dynamic> json) => Result(
        id: json["id"],
        title: json["title"],
        description: json["description"],
        portraitImg: json["portrait_img"],
        landscapeImg: json["landscape_img"],
        categoryId: json["category_id"],
        categoryName: json["category_name"],
        episodeCount: json["episode_count"],
        status: json["status"],
      );
}

VideoSeriesDetailModel videoSeriesDetailModelFromJson(String str) =>
    VideoSeriesDetailModel.fromJson(json.decode(str));

class VideoSeriesDetailModel {
  VideoSeriesDetailModel({
    this.status,
    this.message,
    this.result,
  });

  int? status;
  String? message;
  DetailResult? result;

  factory VideoSeriesDetailModel.fromJson(Map<String, dynamic> json) =>
      VideoSeriesDetailModel(
        status: json["status"],
        message: json["message"],
        result: json["result"] == null
            ? null
            : DetailResult.fromJson(json["result"]),
      );
}

// Episodes reuse liveeventmodel's Result as-is — get_video_series_detail
// returns them in the exact same shape as get_video's rows.
class DetailResult {
  DetailResult({
    this.id,
    this.title,
    this.description,
    this.portraitImg,
    this.landscapeImg,
    this.categoryId,
    this.categoryName,
    this.episodes,
  });

  int? id;
  String? title;
  String? description;
  String? portraitImg;
  String? landscapeImg;
  int? categoryId;
  String? categoryName;
  List<liveevent.Result>? episodes;

  factory DetailResult.fromJson(Map<String, dynamic> json) => DetailResult(
        id: json["id"],
        title: json["title"],
        description: json["description"],
        portraitImg: json["portrait_img"],
        landscapeImg: json["landscape_img"],
        categoryId: json["category_id"],
        categoryName: json["category_name"],
        episodes: json["episodes"] == null
            ? []
            : List<liveevent.Result>.from(json["episodes"]
                    ?.map((x) => liveevent.Result.fromJson(x)) ??
                []),
      );
}
