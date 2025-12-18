import 'package:flutter/material.dart';

/// Sealed class representing the different states of an asynchronous operation.
/// Used for consistent state management across the application.
sealed class AsyncState<T> {
  const AsyncState();
}

/// Represents a loading state while data is being fetched.
class AsyncLoading<T> extends AsyncState<T> {
  const AsyncLoading();
}

/// Represents a successful state with loaded data.
class AsyncLoaded<T> extends AsyncState<T> {
  final T data;
  const AsyncLoaded(this.data);
}

/// Represents an error state with error information and optional retry callback.
class AsyncError<T> extends AsyncState<T> {
  final String message;
  final Object? error;
  final VoidCallback? onRetry;
  
  const AsyncError(
    this.message, {
    this.error,
    this.onRetry,
  });
}

/// Represents an empty state when no data is available.
class AsyncEmpty<T> extends AsyncState<T> {
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  
  const AsyncEmpty({
    this.message,
    this.actionLabel,
    this.onAction,
  });
}
