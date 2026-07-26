class ApiResponse<T> {
  const ApiResponse({this.data, this.errorMessage});

  final T? data;
  final String? errorMessage;

  bool get isSuccess => errorMessage == null;
}
