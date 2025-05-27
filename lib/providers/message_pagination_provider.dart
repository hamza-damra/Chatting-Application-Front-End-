import 'package:flutter/foundation.dart';
import '../models/message.dart';
import '../services/message_pagination_service.dart';
import '../utils/logger.dart';

class MessagePaginationProvider extends ChangeNotifier {
  final MessagePaginationService _messageService;

  MessagePaginationProvider(this._messageService);

  List<Message> _messages = [];
  int _currentPage = 0;
  int _totalPages = 0;
  int _totalElements = 0;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasError = false;
  String _errorMessage = '';
  bool _hasNextPage = false;
  bool _hasPreviousPage = false;
  int? _currentChatRoomId;

  // Getters
  List<Message> get messages => _messages;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get totalElements => _totalElements;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasError => _hasError;
  String get errorMessage => _errorMessage;
  bool get hasNextPage => _hasNextPage;
  bool get hasPreviousPage => _hasPreviousPage;
  int? get currentChatRoomId => _currentChatRoomId;

  /// Load initial messages for a chat room
  Future<void> loadMessages(
    int chatRoomId, {
    int page = 0,
    int size = 20,
  }) async {
    AppLogger.i(
      'MessagePaginationProvider',
      'Loading messages for room $chatRoomId, page: $page, size: $size',
    );

    _isLoading = true;
    _hasError = false;
    _currentChatRoomId = chatRoomId;
    notifyListeners();

    try {
      final response = await _messageService.getMessages(
        chatRoomId: chatRoomId,
        page: page,
        size: size,
      );

      // Sort messages by timestamp to ensure correct order (oldest first, newest last)
      final sortedMessages = response.content.toList();
      sortedMessages.sort((a, b) {
        if (a.sentAt == null && b.sentAt == null) return 0;
        if (a.sentAt == null) return -1;
        if (b.sentAt == null) return 1;
        return a.sentAt!.compareTo(b.sentAt!);
      });

      _messages = sortedMessages;
      _currentPage = response.page;
      _totalPages = response.totalPages;
      _totalElements = response.totalElements;
      _hasNextPage = response.hasNextPage;
      _hasPreviousPage = response.hasPreviousPage;
      _hasError = false;

      AppLogger.i(
        'MessagePaginationProvider',
        'Successfully loaded ${_messages.length} messages for room $chatRoomId. '
            'Page: $_currentPage, Total Pages: $_totalPages, Has Next: $_hasNextPage',
      );
    } catch (e) {
      AppLogger.e('MessagePaginationProvider', 'Error loading messages: $e');
      _hasError = true;
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load more messages (pagination) when scrolling up
  Future<void> loadMoreMessages({int size = 20}) async {
    if (_currentChatRoomId == null || _isLoadingMore) {
      AppLogger.w(
        'MessagePaginationProvider',
        'Cannot load more messages: chatRoomId=$_currentChatRoomId, isLoadingMore=$_isLoadingMore',
      );
      return;
    }

    // If backend doesn't support pagination (hasNextPage is false but we haven't tried loading more)
    if (!_hasNextPage && _currentPage == 0) {
      AppLogger.i(
        'MessagePaginationProvider',
        'Backend appears to return all messages in one response, no more pages available',
      );
      return;
    }

    if (!_hasNextPage) {
      AppLogger.w(
        'MessagePaginationProvider',
        'No more pages available: hasNextPage=$_hasNextPage',
      );
      return;
    }

    AppLogger.i(
      'MessagePaginationProvider',
      'Loading more messages for room $_currentChatRoomId, next page: ${_currentPage + 1}',
    );

    _isLoadingMore = true;
    notifyListeners();

    try {
      final response = await _messageService.getOlderMessages(
        chatRoomId: _currentChatRoomId!,
        currentPage: _currentPage,
        size: size,
      );

      // Combine older messages with existing messages
      final allMessages = [..._messages, ...response.content];

      // Remove duplicates based on message ID
      final uniqueMessages = <Message>[];
      final seenIds = <int>{};

      for (final message in allMessages) {
        if (message.id != null && !seenIds.contains(message.id)) {
          seenIds.add(message.id!);
          uniqueMessages.add(message);
        }
      }

      // Sort all messages by timestamp (oldest first, newest last)
      uniqueMessages.sort((a, b) {
        if (a.sentAt == null && b.sentAt == null) return 0;
        if (a.sentAt == null) return -1;
        if (b.sentAt == null) return 1;
        return a.sentAt!.compareTo(b.sentAt!);
      });

      _messages = uniqueMessages;
      _currentPage = response.page;
      _totalPages = response.totalPages;
      _totalElements = response.totalElements;
      _hasNextPage = response.hasNextPage;
      _hasPreviousPage = response.hasPreviousPage;

      AppLogger.i(
        'MessagePaginationProvider',
        'Successfully loaded ${response.content.length} more messages. Total: ${_messages.length}',
      );
    } catch (e) {
      AppLogger.e(
        'MessagePaginationProvider',
        'Error loading more messages: $e',
      );
      _hasError = true;
      _errorMessage = e.toString();
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Add a new message (from WebSocket or sending)
  void addMessage(Message message) {
    // Check if message already exists
    if (_messages.any((m) => m.id == message.id)) {
      AppLogger.w(
        'MessagePaginationProvider',
        'Message ${message.id} already exists, skipping',
      );
      return;
    }

    // Only add message if it belongs to the current chat room
    if (_currentChatRoomId != null && message.roomId != _currentChatRoomId) {
      AppLogger.w(
        'MessagePaginationProvider',
        'Message ${message.id} is for room ${message.roomId}, but current room is $_currentChatRoomId, skipping',
      );
      return;
    }

    // Add new message and maintain chronological order
    _messages.add(message);

    // Sort messages to ensure correct order (oldest first, newest last)
    _messages.sort((a, b) {
      if (a.sentAt == null && b.sentAt == null) return 0;
      if (a.sentAt == null) return -1;
      if (b.sentAt == null) return 1;
      return a.sentAt!.compareTo(b.sentAt!);
    });

    _totalElements++;

    AppLogger.i(
      'MessagePaginationProvider',
      'Added new message ${message.id}. Total messages: ${_messages.length}',
    );

    notifyListeners();
  }

  /// Add a new message and scroll to bottom (for sent messages)
  void addMessageAndScrollToBottom(Message message) {
    addMessage(message);
    // The widget will handle scrolling to bottom when new messages are added
  }

  /// Update an existing message
  void updateMessage(Message updatedMessage) {
    final index = _messages.indexWhere((m) => m.id == updatedMessage.id);
    if (index != -1) {
      _messages[index] = updatedMessage;
      AppLogger.i(
        'MessagePaginationProvider',
        'Updated message ${updatedMessage.id}',
      );
      notifyListeners();
    }
  }

  /// Remove a message
  void removeMessage(int messageId) {
    _messages.removeWhere((m) => m.id == messageId);
    _totalElements = _totalElements > 0 ? _totalElements - 1 : 0;
    AppLogger.i(
      'MessagePaginationProvider',
      'Removed message $messageId. Total messages: ${_messages.length}',
    );
    notifyListeners();
  }

  /// Reset the provider state
  void reset() {
    _messages = [];
    _currentPage = 0;
    _totalPages = 0;
    _totalElements = 0;
    _hasNextPage = false;
    _hasPreviousPage = false;
    _hasError = false;
    _errorMessage = '';
    _currentChatRoomId = null;
    AppLogger.i('MessagePaginationProvider', 'Provider state reset');
    notifyListeners();
  }

  /// Refresh messages (reload first page)
  Future<void> refresh({int size = 20}) async {
    if (_currentChatRoomId == null) return;

    AppLogger.i(
      'MessagePaginationProvider',
      'Refreshing messages for room $_currentChatRoomId',
    );

    await loadMessages(_currentChatRoomId!, page: 0, size: size);
  }

  /// Check if we can load more messages
  bool get canLoadMore {
    // Can't load if already loading
    if (_isLoadingMore || _isLoading) return false;

    // Can't load if no next page available
    if (!_hasNextPage) return false;

    // Special case: if backend doesn't support pagination and we're on page 0,
    // we might have all messages already
    if (_currentPage == 0 && _totalPages == 1) return false;

    return true;
  }
}
