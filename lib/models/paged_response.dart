class PagedResponse<T> {
  final List<T> content;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;
  final bool last;

  PagedResponse({
    required this.content,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
    required this.last,
  });

  factory PagedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    return PagedResponse<T>(
      content: (json['content'] as List)
          .map((item) => fromJsonT(item as Map<String, dynamic>))
          .toList(),
      page: json['page'] as int,
      size: json['size'] as int,
      totalElements: json['totalElements'] as int,
      totalPages: json['totalPages'] as int,
      last: json['last'] as bool,
    );
  }

  Map<String, dynamic> toJson(Map<String, dynamic> Function(T) toJsonT) {
    return {
      'content': content.map((item) => toJsonT(item)).toList(),
      'page': page,
      'size': size,
      'totalElements': totalElements,
      'totalPages': totalPages,
      'last': last,
    };
  }

  bool get hasNextPage => !last;
  bool get hasPreviousPage => page > 0;
  bool get isEmpty => content.isEmpty;
  bool get isNotEmpty => content.isNotEmpty;

  PagedResponse<T> copyWith({
    List<T>? content,
    int? page,
    int? size,
    int? totalElements,
    int? totalPages,
    bool? last,
  }) {
    return PagedResponse<T>(
      content: content ?? this.content,
      page: page ?? this.page,
      size: size ?? this.size,
      totalElements: totalElements ?? this.totalElements,
      totalPages: totalPages ?? this.totalPages,
      last: last ?? this.last,
    );
  }

  @override
  String toString() {
    return 'PagedResponse{page: $page, size: $size, totalElements: $totalElements, totalPages: $totalPages, last: $last, contentLength: ${content.length}}';
  }
}
