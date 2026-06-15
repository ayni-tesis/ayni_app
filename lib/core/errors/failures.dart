abstract class Failure {
  final String message;
  const Failure(this.message);

  @override
  String toString() => message;
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Error del servidor, intente más tarde.']);
}

class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Error de almacenamiento local.']);
}

class ConnectionFailure extends Failure {
  const ConnectionFailure([super.message = 'Sin conexión a internet.']);
}

class ProcessingFailure extends Failure {
  const ProcessingFailure([super.message = 'Error al procesar la imagen.']);
}

abstract class Either<L, R> {
  const Either();
  T fold<T>(T Function(L left) onLeft, T Function(R right) onRight);
}

class Left<L, R> extends Either<L, R> {
  final L value;
  const Left(this.value);
  @override
  T fold<T>(T Function(L left) onLeft, T Function(R right) onRight) => onLeft(value);
}

class Right<L, R> extends Either<L, R> {
  final R value;
  const Right(this.value);
  @override
  T fold<T>(T Function(L left) onLeft, T Function(R right) onRight) => onRight(value);
}
