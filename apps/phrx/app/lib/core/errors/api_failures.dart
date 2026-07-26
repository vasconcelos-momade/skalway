import 'failures.dart';

class ApiFailure extends Failure {
  const ApiFailure(super.message, {this.statusCode});

  final int? statusCode;
}
