import 'package:freezed_annotation/freezed_annotation.dart';

part 'session.freezed.dart';
part 'session.g.dart';

@freezed
sealed class Session with _$Session {
  const factory Session({
    required String userId,
    required String displayName,
    required DateTime signedInAt,
  }) = _Session;

  factory Session.fromJson(Map<String, dynamic> json) =>
      _$SessionFromJson(json);
}
