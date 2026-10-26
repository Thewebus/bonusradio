import 'package:myBonus/model/liveeventmodel.dart' as video;
import 'package:myBonus/model/sectionlistmodel.dart' as section;

// get_category_content — everything filed under one rubrique (category):
// songs and podcasts in the home-section item shape (section.Datum, so the
// existing playback works as is), videos/series as catalog rows.
class CategoryContentModel {
  int? status;
  String? message;
  CategoryContent? result;

  CategoryContentModel({this.status, this.message, this.result});

  factory CategoryContentModel.fromJson(Map<String, dynamic> json) =>
      CategoryContentModel(
        status: json["status"],
        message: json["message"],
        result: json["result"] is Map<String, dynamic>
            ? CategoryContent.fromJson(json["result"])
            : null,
      );
}

class CategoryContent {
  int? id;
  String? name;
  String? image;
  int songCount;
  int podcastCount;
  int videoCount;
  List<section.Datum> songs;
  List<section.Datum> podcasts;
  List<video.Result> videos;

  CategoryContent({
    this.id,
    this.name,
    this.image,
    this.songCount = 0,
    this.podcastCount = 0,
    this.videoCount = 0,
    this.songs = const [],
    this.podcasts = const [],
    this.videos = const [],
  });

  factory CategoryContent.fromJson(Map<String, dynamic> json) =>
      CategoryContent(
        id: json["id"],
        name: json["name"],
        image: json["image"],
        songCount: json["song_count"] ?? 0,
        podcastCount: json["podcast_count"] ?? 0,
        videoCount: json["video_count"] ?? 0,
        songs: List<section.Datum>.from(
            (json["songs"] ?? []).map((x) => section.Datum.fromJson(x))),
        podcasts: List<section.Datum>.from(
            (json["podcasts"] ?? []).map((x) => section.Datum.fromJson(x))),
        videos: List<video.Result>.from(
            (json["videos"] ?? []).map((x) => video.Result.fromJson(x))),
      );
}
