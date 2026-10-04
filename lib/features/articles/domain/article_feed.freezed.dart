// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'article_feed.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ArticleFeed {

 List<Article> get items; bool get hasMore; bool get isLoadingMore; Object? get loadMoreError;
/// Create a copy of ArticleFeed
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ArticleFeedCopyWith<ArticleFeed> get copyWith => _$ArticleFeedCopyWithImpl<ArticleFeed>(this as ArticleFeed, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ArticleFeed;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ArticleFeed&&const DeepCollectionEquality().equals(other.items, _this.items)&&(identical(other.hasMore, _this.hasMore) || other.hasMore == _this.hasMore)&&(identical(other.isLoadingMore, _this.isLoadingMore) || other.isLoadingMore == _this.isLoadingMore)&&const DeepCollectionEquality().equals(other.loadMoreError, _this.loadMoreError));
}


@override
int get hashCode {
  final _this = this as ArticleFeed;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.items),_this.hasMore,_this.isLoadingMore,const DeepCollectionEquality().hash(_this.loadMoreError));
}

@override
String toString() {
  final _this = this as ArticleFeed;
  return 'ArticleFeed(items: ${_this.items}, hasMore: ${_this.hasMore}, isLoadingMore: ${_this.isLoadingMore}, loadMoreError: ${_this.loadMoreError})';
}


}

/// @nodoc
abstract mixin class $ArticleFeedCopyWith<$Res>  {
  factory $ArticleFeedCopyWith(ArticleFeed value, $Res Function(ArticleFeed) _then) = _$ArticleFeedCopyWithImpl;
@useResult
$Res call({
 List<Article> items, bool hasMore, bool isLoadingMore, Object? loadMoreError
});




}
/// @nodoc
class _$ArticleFeedCopyWithImpl<$Res>
    implements $ArticleFeedCopyWith<$Res> {
  _$ArticleFeedCopyWithImpl(this._self, this._then);

  final ArticleFeed _self;
  final $Res Function(ArticleFeed) _then;

/// Create a copy of ArticleFeed
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? items = null,Object? hasMore = null,Object? isLoadingMore = null,Object? loadMoreError = freezed,}) {
  return _then(ArticleFeed(
items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<Article>,hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,isLoadingMore: null == isLoadingMore ? _self.isLoadingMore : isLoadingMore // ignore: cast_nullable_to_non_nullable
as bool,loadMoreError: freezed == loadMoreError ? _self.loadMoreError : loadMoreError ,
  ));
}

}


/// Adds pattern-matching-related methods to [ArticleFeed].
extension ArticleFeedPatterns on ArticleFeed {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ArticleFeed value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ArticleFeed() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ArticleFeed value)  $default,){
final _that = this;
switch (_that) {
case _ArticleFeed():
return $default(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ArticleFeed value)?  $default,){
final _that = this;
switch (_that) {
case _ArticleFeed() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<Article> items,  bool hasMore,  bool isLoadingMore,  Object? loadMoreError)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ArticleFeed() when $default != null:
return $default(_that.items,_that.hasMore,_that.isLoadingMore,_that.loadMoreError);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<Article> items,  bool hasMore,  bool isLoadingMore,  Object? loadMoreError)  $default,) {final _that = this;
switch (_that) {
case _ArticleFeed():
return $default(_that.items,_that.hasMore,_that.isLoadingMore,_that.loadMoreError);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<Article> items,  bool hasMore,  bool isLoadingMore,  Object? loadMoreError)?  $default,) {final _that = this;
switch (_that) {
case _ArticleFeed() when $default != null:
return $default(_that.items,_that.hasMore,_that.isLoadingMore,_that.loadMoreError);case _:
  return null;

}
}

}

/// @nodoc


class _ArticleFeed implements ArticleFeed {
  const _ArticleFeed({ List<Article> items = const <Article>[], this.hasMore = false, this.isLoadingMore = false, this.loadMoreError}): _items = items;
  

 final  List<Article> _items;
@override@JsonKey() List<Article> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

@override@JsonKey() final  bool hasMore;
@override@JsonKey() final  bool isLoadingMore;
@override final  Object? loadMoreError;

/// Create a copy of ArticleFeed
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ArticleFeedCopyWith<_ArticleFeed> get copyWith => __$ArticleFeedCopyWithImpl<_ArticleFeed>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ArticleFeed&&const DeepCollectionEquality().equals(other.items, _items)&&(identical(other.hasMore, hasMore) || other.hasMore == hasMore)&&(identical(other.isLoadingMore, isLoadingMore) || other.isLoadingMore == isLoadingMore)&&const DeepCollectionEquality().equals(other.loadMoreError, loadMoreError));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),hasMore,isLoadingMore,const DeepCollectionEquality().hash(loadMoreError));
}

@override
String toString() {
    return 'ArticleFeed(items: $items, hasMore: $hasMore, isLoadingMore: $isLoadingMore, loadMoreError: $loadMoreError)';
}


}

/// @nodoc
abstract mixin class _$ArticleFeedCopyWith<$Res> implements $ArticleFeedCopyWith<$Res> {
  factory _$ArticleFeedCopyWith(_ArticleFeed value, $Res Function(_ArticleFeed) _then) = __$ArticleFeedCopyWithImpl;
@override @useResult
$Res call({
 List<Article> items, bool hasMore, bool isLoadingMore, Object? loadMoreError
});




}
/// @nodoc
class __$ArticleFeedCopyWithImpl<$Res>
    implements _$ArticleFeedCopyWith<$Res> {
  __$ArticleFeedCopyWithImpl(this._self, this._then);

  final _ArticleFeed _self;
  final $Res Function(_ArticleFeed) _then;

/// Create a copy of ArticleFeed
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? items = null,Object? hasMore = null,Object? isLoadingMore = null,Object? loadMoreError = freezed,}) {
  return _then(_ArticleFeed(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<Article>,hasMore: null == hasMore ? _self.hasMore : hasMore // ignore: cast_nullable_to_non_nullable
as bool,isLoadingMore: null == isLoadingMore ? _self.isLoadingMore : isLoadingMore // ignore: cast_nullable_to_non_nullable
as bool,loadMoreError: freezed == loadMoreError ? _self.loadMoreError : loadMoreError ,
  ));
}


}

// dart format on
