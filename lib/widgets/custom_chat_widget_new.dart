import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../models/message.dart';
import '../services/improved_file_upload_service.dart';
import '../providers/message_pagination_provider.dart';
import '../providers/chat_provider.dart';
import '../presentation/widgets/chat/professional_chat_input.dart';
import '../presentation/widgets/chat/professional_attachment_menu.dart';
import '../presentation/widgets/chat/professional_file_upload_handler.dart';
import '../services/api_file_service.dart';
import '../services/websocket_service.dart';
import '../utils/logger.dart';
import '../utils/url_utils.dart';
import '../utils/file_type_helper.dart';
import '../screens/file_viewers/text_file_viewer_screen.dart';
import '../widgets/blocking_aware_chat_input.dart';
import 'chat_image_thumbnail.dart';
import 'video_player_widget.dart';

import '../custom_routes.dart';

class CustomChatWidgetNew extends StatefulWidget {
  final Function(String) onSendMessage;
  final Function(String, String) onSendAttachment;
  final int currentUserId;
  final bool showUserAvatars;
  final ImprovedFileUploadService webSocketService;
  final int roomId;
  final int? otherUserId;
  final String? otherUserName;
  final int pageSize;

  const CustomChatWidgetNew({
    super.key,
    required this.onSendMessage,
    required this.onSendAttachment,
    required this.currentUserId,
    required this.webSocketService,
    required this.roomId,
    this.showUserAvatars = true,
    this.otherUserId,
    this.otherUserName,
    this.pageSize = 20,
  });

  @override
  State<CustomChatWidgetNew> createState() => _CustomChatWidgetNewState();
}

class _CustomChatWidgetNewState extends State<CustomChatWidgetNew> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isAttachmentMenuOpen = false;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String _currentFileName = '';
  ProfessionalFileUploadHandler? _fileUploadHandler;
  MessagePaginationProvider? _paginationProvider;

  @override
  void initState() {
    super.initState();

    // Add scroll listener for pagination
    _scrollController.addListener(_onScroll);

    // Initialize pagination provider and load initial messages
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializePagination();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize the professional file upload handler with services from context
    if (_fileUploadHandler == null) {
      final apiFileService = context.read<ApiFileService>();
      final webSocketService = context.read<WebSocketService>();

      _fileUploadHandler = ProfessionalFileUploadHandler(
        chatRoomId: widget.roomId,
        apiFileService: apiFileService,
        webSocketService: webSocketService,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);

    // Remove ChatProvider listener
    try {
      final chatProvider = context.read<ChatProvider>();
      chatProvider.removeListener(_onChatProviderUpdate);
    } catch (e) {
      // Context might be disposed, ignore error
      AppLogger.w(
        'CustomChatWidgetNew',
        'Error removing ChatProvider listener: $e',
      );
    }

    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Initialize pagination provider and load initial messages
  void _initializePagination() {
    _paginationProvider = context.read<MessagePaginationProvider>();

    // Load initial messages
    _paginationProvider!
        .loadMessages(widget.roomId, size: widget.pageSize)
        .then((_) {
          // Scroll to bottom after loading initial messages
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
          });
        });

    // Set up WebSocket integration for real-time messages
    _setupWebSocketIntegration();
  }

  /// Set up WebSocket integration for real-time messages
  void _setupWebSocketIntegration() {
    final chatProvider = context.read<ChatProvider>();

    // Listen to new messages from ChatProvider and add them to pagination provider
    chatProvider.addListener(_onChatProviderUpdate);
  }

  /// Handle updates from ChatProvider (WebSocket messages)
  void _onChatProviderUpdate() {
    if (_paginationProvider == null) return;

    final chatProvider = context.read<ChatProvider>();
    final providerMessages = chatProvider.getMessages(widget.roomId.toString());

    // Check if there are new messages that aren't in our pagination provider
    bool hasNewMessages = false;
    for (final typesMsg in providerMessages) {
      final convertedMessage = _convertTypesMessageToMessage(typesMsg);

      // Only add if it's not already in our pagination provider
      if (!_paginationProvider!.messages.any(
        (m) => m.id == convertedMessage.id,
      )) {
        AppLogger.i(
          'CustomChatWidgetNew',
          'Adding new real-time message ${convertedMessage.id} to pagination provider',
        );
        _paginationProvider!.addMessage(convertedMessage);
        hasNewMessages = true;
      }
    }

    // Only scroll to bottom if we actually added new messages
    if (hasNewMessages) {
      AppLogger.i(
        'CustomChatWidgetNew',
        'New messages added, scrolling to bottom',
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }
  }

  /// Convert types.Message to Message for pagination provider
  Message _convertTypesMessageToMessage(dynamic typesMsg) {
    String? attachmentUrl;
    String? contentType;
    String? content = typesMsg.id; // Default content

    if (typesMsg.runtimeType.toString().contains('TextMessage')) {
      content = typesMsg.text;
      contentType = 'text/plain';
    } else if (typesMsg.runtimeType.toString().contains('ImageMessage')) {
      attachmentUrl = typesMsg.uri;
      contentType = 'image/jpeg';
      content = typesMsg.name;
    } else if (typesMsg.runtimeType.toString().contains('FileMessage')) {
      content = typesMsg.uri;
      attachmentUrl = typesMsg.uri;
      contentType = typesMsg.mimeType ?? 'application/octet-stream';
    } else if (typesMsg.runtimeType.toString().contains('CustomMessage')) {
      final metadata = typesMsg.metadata;
      if (metadata != null) {
        attachmentUrl = metadata['attachmentUrl'] as String?;
        contentType = metadata['contentType'] as String?;
        content = metadata['fileName'] as String? ?? 'File';
      }
    }

    return Message(
      id: int.tryParse(typesMsg.id) ?? 0,
      roomId: widget.roomId,
      senderId: int.tryParse(typesMsg.author.id) ?? 0,
      senderName:
          '${typesMsg.author.firstName ?? ''} ${typesMsg.author.lastName ?? ''}'
              .trim(),
      content: content,
      contentType: contentType,
      attachmentUrl: attachmentUrl,
      sentAt:
          typesMsg.createdAt != null
              ? DateTime.fromMillisecondsSinceEpoch(typesMsg.createdAt!)
              : DateTime.now(),
    );
  }

  /// Handle scroll events for pagination
  void _onScroll() {
    if (!_scrollController.hasClients || _paginationProvider == null) return;

    // Check if we've scrolled to the top (for loading older messages)
    // In a reversed ListView, scrolling up means reaching maxScrollExtent
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // Load more messages if available
      if (_paginationProvider!.canLoadMore) {
        AppLogger.i(
          'CustomChatWidgetNew',
          'Loading more messages due to scroll position',
        );
        _paginationProvider!.loadMoreMessages(size: widget.pageSize);
      }
    }
  }

  @override
  void didUpdateWidget(CustomChatWidgetNew oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If room ID changed, reset pagination and load new messages
    if (widget.roomId != oldWidget.roomId) {
      AppLogger.i(
        'CustomChatWidgetNew',
        'Room ID changed from ${oldWidget.roomId} to ${widget.roomId}',
      );

      if (_paginationProvider != null) {
        _paginationProvider!.reset();
        _paginationProvider!.loadMessages(widget.roomId, size: widget.pageSize);
      }
    }
  }

  void _scrollToBottom() {
    // In a reversed ListView, the "bottom" (most recent messages) is actually at position 0
    if (_scrollController.hasClients) {
      try {
        _scrollController.animateTo(
          0.0, // Scroll to position 0 in a reversed ListView
          duration: const Duration(
            milliseconds: 450,
          ), // Slightly longer for smoother animation
          curve: Curves.easeOutCubic, // More polished curve for smoother motion
        );
      } catch (e) {
        // If there's an error, try again with a delay
        Future.delayed(const Duration(milliseconds: 200), () {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              0.0,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOut,
            );
          }
        });
      }
    }
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isNotEmpty) {
      // Send message through the original handler
      widget.onSendMessage(message);
      _messageController.clear();

      // The message will be added to pagination provider through WebSocket integration
      // Just scroll to bottom
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }
  }

  void _toggleAttachmentMenu() {
    setState(() {
      _isAttachmentMenuOpen = !_isAttachmentMenuOpen;
    });
  }

  void _handleProgress(double progress) {
    setState(() {
      _uploadProgress = progress;
    });
  }

  void _handleUploadError(String error) {
    setState(() {
      _isUploading = false;
      _uploadProgress = 0.0;
    });

    // Create a more user-friendly error message
    String userFriendlyError = error;

    // Handle common file upload errors with better messages
    if (error.contains('Content type not allowed') ||
        error.contains('file type is not supported')) {
      userFriendlyError =
          'This file type is not supported. Try using JPEG, PNG, PDF, or TXT format.';
    } else if (error.contains('File size exceeds')) {
      userFriendlyError = 'File is too large. Please select a file under 1GB.';
    } else if (error.contains('timed out')) {
      userFriendlyError =
          'Upload timed out. Check your connection and try again with a smaller file.';
    } else if (error.contains('not a participant') ||
        error.contains('ChatRoomAccessDeniedException') ||
        error.contains('You are not a participant')) {
      userFriendlyError =
          'You don\'t have permission to upload files to this chat room.';
    } else if (error.contains('Access denied') || error.contains('403')) {
      userFriendlyError =
          'Access denied. You may not have permission for this action.';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(userFriendlyError),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'DISMISS',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  Future<void> _pickAndUploadImage() async {
    if (_fileUploadHandler == null) return;

    setState(() {
      _isUploading = true;
      _currentFileName = 'image';
      _isAttachmentMenuOpen = false;
    });

    try {
      await _fileUploadHandler!.pickAndUploadImage(
        onProgress: _handleProgress,
        onComplete: () {
          setState(() {
            _isUploading = false;
            _uploadProgress = 0.0;
          });
          // The file upload handler already sends the message via WebSocket
          _scrollToBottom();
        },
        onError: _handleUploadError,
      );
    } catch (e) {
      AppLogger.e('CustomChatWidgetNew', 'Error uploading image: $e');
      _handleUploadError(e.toString());
    }
  }

  Future<void> _pickAndUploadVideo() async {
    if (_fileUploadHandler == null) return;

    setState(() {
      _isUploading = true;
      _currentFileName = 'video';
      _isAttachmentMenuOpen = false;
    });

    try {
      await _fileUploadHandler!.pickAndUploadVideo(
        onProgress: _handleProgress,
        onComplete: () {
          setState(() {
            _isUploading = false;
            _uploadProgress = 0.0;
          });
          _scrollToBottom();
        },
        onError: _handleUploadError,
      );
    } catch (e) {
      AppLogger.e('CustomChatWidgetNew', 'Error uploading video: $e');
      _handleUploadError(e.toString());
    }
  }

  Future<void> _pickAndUploadDocument() async {
    if (_fileUploadHandler == null) return;

    setState(() {
      _isUploading = true;
      _currentFileName = 'document';
      _isAttachmentMenuOpen = false;
    });

    try {
      await _fileUploadHandler!.pickAndUploadDocument(
        onProgress: _handleProgress,
        onComplete: () {
          setState(() {
            _isUploading = false;
            _uploadProgress = 0.0;
          });
          _scrollToBottom();
        },
        onError: _handleUploadError,
      );
    } catch (e) {
      AppLogger.e('CustomChatWidgetNew', 'Error uploading document: $e');
      _handleUploadError(e.toString());
    }
  }

  Future<void> _captureAndUploadImage() async {
    if (_fileUploadHandler == null) return;

    setState(() {
      _isUploading = true;
      _currentFileName = 'camera';
      _isAttachmentMenuOpen = false;
    });

    try {
      await _fileUploadHandler!.captureAndUploadImage(
        onProgress: _handleProgress,
        onComplete: () {
          setState(() {
            _isUploading = false;
            _uploadProgress = 0.0;
          });
          _scrollToBottom();
        },
        onError: _handleUploadError,
      );
    } catch (e) {
      AppLogger.e('CustomChatWidgetNew', 'Error uploading camera image: $e');
      _handleUploadError(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MessagePaginationProvider>(
      builder: (context, paginationProvider, child) {
        return Column(
          children: [
            Expanded(child: _buildMessagesList(paginationProvider)),
            if (_isUploading) _buildProgressIndicator(),
            if (_isAttachmentMenuOpen) _buildProfessionalAttachmentMenu(),
            _buildChatInput(),
          ],
        );
      },
    );
  }

  Widget _buildMessagesList(MessagePaginationProvider paginationProvider) {
    // Show loading indicator for initial load
    if (paginationProvider.isLoading && paginationProvider.messages.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading messages...'),
          ],
        ),
      );
    }

    // Show error state
    if (paginationProvider.hasError && paginationProvider.messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              'Error loading messages',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              paginationProvider.errorMessage,
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed:
                  () => paginationProvider.refresh(size: widget.pageSize),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Show empty state
    if (paginationProvider.messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.chat_bubble_outline, color: Colors.grey, size: 48),
            const SizedBox(height: 16),
            Text(
              'No messages yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Text(
              'Start the conversation!',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // Show messages list with pagination
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount:
          paginationProvider.messages.length +
          (paginationProvider.isLoadingMore ? 1 : 0),
      reverse: true,
      itemBuilder: (context, index) {
        // Show loading indicator at the top when loading more
        if (index == paginationProvider.messages.length) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 8),
                  Text('Loading older messages...'),
                ],
              ),
            ),
          );
        }

        // When reversed, we need to access items in reverse order
        final message =
            paginationProvider.messages[paginationProvider.messages.length -
                1 -
                index];
        final isCurrentUser = message.senderId == widget.currentUserId;

        return _buildMessageItem(message, isCurrentUser);
      },
    );
  }

  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Uploading $_currentFileName',
                  style: const TextStyle(fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${(_uploadProgress * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: _uploadProgress,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                widget.webSocketService.cancelUpload();
                setState(() {
                  _isUploading = false;
                });
              },
              child: const Text('Cancel'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfessionalAttachmentMenu() {
    return ProfessionalAttachmentMenu(
      onPhotoPressed: _pickAndUploadImage,
      onCameraPressed: _captureAndUploadImage,
      onVideoPressed: _pickAndUploadVideo,
      onFilePressed: _pickAndUploadDocument,
      isEnabled: !_isUploading,
      isUploading: _isUploading,
    );
  }

  Widget _buildChatInput() {
    // Check if this is a private chat (has other user info)
    final isPrivateChat =
        widget.otherUserId != null && widget.otherUserName != null;

    if (isPrivateChat) {
      // Use blocking-aware input for private chats
      return BlockingAwareChatInput(
        controller: _messageController,
        onSendMessage: _sendMessage,
        onAttachmentPressed: _toggleAttachmentMenu,
        otherUserId: widget.otherUserId!,
        otherUserName: widget.otherUserName!,
        hintText: 'Type a message...',
      );
    } else {
      // Use regular input for group chats
      return ProfessionalChatInput(
        controller: _messageController,
        onSendMessage: _sendMessage,
        onAttachmentPressed: _toggleAttachmentMenu,
        isAttachmentUploading: _isUploading,
        hintText: 'Type a message...',
      );
    }
  }

  Widget _buildMessageItem(Message message, bool isCurrentUser) {
    // Filter out problematic timestamp-only messages
    if (_isTimestampOnlyMessage(message)) {
      AppLogger.w(
        'CustomChatWidgetNew',
        'Filtering out timestamp-only message: id=${message.id}, content=${message.content}',
      );
      return const SizedBox.shrink(); // Return empty widget
    }

    // Add detailed logging for message structure
    AppLogger.i(
      'CustomChatWidgetNew',
      'MESSAGE DATA: id=${message.id}, senderId=${message.senderId}, '
          'contentType=${message.contentType}, '
          'content=${message.content?.substring(0, message.content?.length.clamp(0, 100) ?? 0)}, '
          'attachmentUrl=${message.attachmentUrl}',
    );

    // Check for image URL in content field using improved utility method
    bool isImageInContent = false;
    bool isVideoInContent = false;
    bool isTextFileInContent = false;
    if (message.content != null && message.content!.isNotEmpty) {
      isImageInContent = UrlUtils.isImageUrl(message.content);
      isVideoInContent = _isVideoUrl(message.content!);
      isTextFileInContent =
          message.content!.startsWith('http') &&
          _isTextFile(message.content!, message.contentType);
      AppLogger.i(
        'CustomChatWidgetNew',
        'Content field URL detection: isImage=$isImageInContent, isVideo=$isVideoInContent, isTextFile=$isTextFileInContent for ${message.content}',
      );
    }

    // Determine the message type for better logging
    String messageType = "unknown";
    if (message.attachmentUrl != null) {
      messageType = "attachment";
    } else if (isImageInContent) {
      messageType = "image-in-content";
    } else if (isVideoInContent) {
      messageType = "video-in-content";
    } else if (isTextFileInContent) {
      messageType = "text-file-in-content";
    } else if (message.content != null && message.content!.isNotEmpty) {
      messageType = "text";
    } else {
      messageType = "empty";
      AppLogger.w(
        'CustomChatWidgetNew',
        'EMPTY MESSAGE: id=${message.id}, no content or attachmentUrl',
      );
    }

    // Log which rendering path we're taking
    AppLogger.i(
      'CustomChatWidgetNew',
      'Rendering message type: $messageType, id=${message.id}',
    );

    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
          minWidth: _getMinWidthForMessage(message),
        ),
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: _getPaddingForMessage(message),
        decoration: BoxDecoration(
          color:
              isCurrentUser
                  ? Theme.of(context).colorScheme.primary
                  : (Theme.of(context).brightness == Brightness.dark
                      ? Theme.of(context).colorScheme.surfaceContainerHigh
                      : Theme.of(context).colorScheme.surfaceContainerLowest),
          borderRadius: _getBorderRadiusForMessage(message, isCurrentUser),
          border: Border.all(
            color:
                isCurrentUser
                    ? Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.3)
                    : Theme.of(
                      context,
                    ).colorScheme.outline.withValues(alpha: 0.2),
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(
                context,
              ).colorScheme.shadow.withValues(alpha: 0.1),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: IntrinsicWidth(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isCurrentUser && widget.showUserAvatars)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    message.senderName ?? 'Unknown',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color:
                          isCurrentUser
                              ? Theme.of(context).colorScheme.onPrimary
                              : Theme.of(context).colorScheme.onSurface,
                      fontSize: 12,
                    ),
                  ),
                ),
              // Handle case where image URL is in attachmentUrl
              if (message.attachmentUrl != null)
                _buildAttachment(
                  message.attachmentUrl!,
                  message.contentType,
                  message: message,
                  isCurrentUser: isCurrentUser,
                )
              // Handle case where image URL might be in content field with an image content type
              else if (isImageInContent)
                _buildAttachment(
                  message.content!,
                  message.contentType ?? 'image/jpeg',
                  message: message,
                  isCurrentUser: isCurrentUser,
                )
              // Handle case where video URL might be in content field with a video content type
              else if (isVideoInContent)
                _buildAttachment(
                  message.content!,
                  message.contentType ?? 'video/mp4',
                  message: message,
                  isCurrentUser: isCurrentUser,
                )
              // Handle case where text file URL might be in content field with a text content type
              else if (isTextFileInContent)
                _buildAttachment(
                  message.content!,
                  message.contentType ?? 'text/plain',
                  message: message,
                  isCurrentUser: isCurrentUser,
                )
              // Handle video messages that show as "File" text - check content type
              else if (message.contentType != null &&
                  message.contentType!.startsWith('video/') &&
                  message.content != null &&
                  message.content!.isNotEmpty)
                _buildVideoMessageWithLoading(message, isCurrentUser)
              // Handle image messages that might show as text
              else if (message.contentType != null &&
                  message.contentType!.startsWith('image/') &&
                  message.content != null &&
                  message.content!.isNotEmpty)
                _buildImageMessageWithLoading(message, isCurrentUser)
              // Only show text content if it's not an image/video/text file URL in the content field
              else if (message.content != null && message.content!.isNotEmpty)
                _buildTextContent(message.content!, isCurrentUser)
              // Fallback for empty or unsupported messages
              else
                _buildUnsupportedMessageWidget(message, isCurrentUser),
              Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _formatTime(message.sentAt),
                    style: TextStyle(
                      fontSize: 10,
                      color:
                          isCurrentUser
                              ? Theme.of(
                                context,
                              ).colorScheme.onPrimary.withValues(alpha: 0.7)
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // New method to display unsupported message types with debugging info
  Widget _buildUnsupportedMessageWidget(Message message, bool isCurrentUser) {
    AppLogger.e(
      'CustomChatWidgetNew',
      'UNSUPPORTED MESSAGE: id=${message.id}, '
          'contentType=${message.contentType}, '
          'content=${message.content}, '
          'attachmentUrl=${message.attachmentUrl}',
    );

    // Dump the full message for debugging
    AppLogger.e('CustomChatWidgetNew', 'Full message: ${message.toJson()}');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.withAlpha(
              51,
            ), // Use neutral color instead of red
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Unsupported message type',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800], // Use neutral color instead of red
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Message ID: ${message.id}',
                style: TextStyle(
                  fontSize: 12,
                  color: isCurrentUser ? Colors.white70 : Colors.black54,
                ),
              ),
              Text(
                'Content Type: ${message.contentType ?? "none"}',
                style: TextStyle(
                  fontSize: 12,
                  color: isCurrentUser ? Colors.white70 : Colors.black54,
                ),
              ),
              if (kDebugMode && message.content != null)
                Text(
                  'Content: ${message.content?.substring(0, message.content!.length.clamp(0, 30))}${message.content!.length > 30 ? "..." : ""}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isCurrentUser ? Colors.white70 : Colors.black54,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // Handle video messages that might show as "File" text
  Widget _buildVideoMessageWithLoading(Message message, bool isCurrentUser) {
    AppLogger.i(
      'CustomChatWidgetNew',
      'Building video message with loading: id=${message.id}, contentType=${message.contentType}',
    );

    final String heroTagId =
        message.id?.toString() ??
        DateTime.now().microsecondsSinceEpoch.toString();

    // If content looks like a URL, use it as video URL
    if (message.content != null &&
        (message.content!.startsWith('http') ||
            _isVideoUrl(message.content!))) {
      return SizedBox(
        width: 240,
        child: VideoThumbnail(
          videoUrl: message.content!,
          heroTag: 'video-$heroTagId',
          isCurrentUser: isCurrentUser,
        ),
      );
    }

    // If attachmentUrl is available, use it
    if (message.attachmentUrl != null && message.attachmentUrl!.isNotEmpty) {
      String videoUrl = message.attachmentUrl!;
      if (!videoUrl.startsWith('http')) {
        videoUrl = 'http://abusaker.zapto.org:8080${message.attachmentUrl!}';
      }
      return SizedBox(
        width: 240,
        child: VideoThumbnail(
          videoUrl: videoUrl,
          heroTag: 'video-$heroTagId',
          isCurrentUser: isCurrentUser,
        ),
      );
    }

    // Try to construct URL from message ID (fallback for old messages)
    if (message.id != null) {
      return _buildVideoWithFallbackUrl(message, isCurrentUser, heroTagId);
    }

    // Otherwise, show a loading placeholder for video
    return _buildVideoLoadingPlaceholder(message, isCurrentUser);
  }

  // Build video widget with fallback URL construction
  Widget _buildVideoWithFallbackUrl(
    Message message,
    bool isCurrentUser,
    String heroTagId,
  ) {
    // Try to get video URL from backend using message ID
    return FutureBuilder<String?>(
      future: _getVideoUrlFromMessage(message),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildVideoLoadingPlaceholder(message, isCurrentUser);
        }

        if (snapshot.hasData && snapshot.data != null) {
          return SizedBox(
            width: 240,
            child: VideoThumbnail(
              videoUrl: snapshot.data!,
              heroTag: 'video-$heroTagId',
              isCurrentUser: isCurrentUser,
            ),
          );
        }

        // If we can't get the URL, show an error placeholder
        return _buildVideoErrorPlaceholder(message, isCurrentUser);
      },
    );
  }

  // Get video URL from message (try different approaches)
  Future<String?> _getVideoUrlFromMessage(Message message) async {
    try {
      AppLogger.i(
        'CustomChatWidgetNew',
        'Attempting to get video URL for message: id=${message.id}, content=${message.content}, attachmentUrl=${message.attachmentUrl}, downloadUrl=${message.downloadUrl}',
      );

      // Method 1: Use downloadUrl if available (new backend feature)
      if (message.downloadUrl != null && message.downloadUrl!.isNotEmpty) {
        String fullUrl =
            'http://abusaker.zapto.org:8080${message.downloadUrl!}';
        AppLogger.i(
          'CustomChatWidgetNew',
          'Using downloadUrl from message: $fullUrl',
        );
        return fullUrl;
      }

      // Method 2: Check if content contains a URL (sometimes backend stores URLs in content)
      if (message.content != null && message.content!.contains('http')) {
        // Extract URL from content if it's mixed with other text
        final urlRegex = RegExp(r'https?://[^\s]+');
        final match = urlRegex.firstMatch(message.content!);
        if (match != null) {
          String extractedUrl = match.group(0)!;
          AppLogger.i(
            'CustomChatWidgetNew',
            'Extracted URL from content: $extractedUrl',
          );
          return extractedUrl;
        }
      }

      // Method 3: Check if attachmentUrl is available and construct proper download URL
      if (message.attachmentUrl != null && message.attachmentUrl!.isNotEmpty) {
        String attachmentUrl = message.attachmentUrl!;

        // If it's already a full URL, return it
        if (attachmentUrl.startsWith('http')) {
          AppLogger.i(
            'CustomChatWidgetNew',
            'Using full attachmentUrl: $attachmentUrl',
          );
          return attachmentUrl;
        }

        // If it's a relative path, construct the full URL
        String fullUrl = 'http://abusaker.zapto.org:8080$attachmentUrl';
        AppLogger.i(
          'CustomChatWidgetNew',
          'Constructed URL from attachmentUrl: $fullUrl',
        );
        return fullUrl;
      }

      // Method 4: Try to get video URL from chat room data (where correct URLs are stored)
      if (message.id != null && message.roomId != null) {
        try {
          String? roomVideoUrl = await _getVideoUrlFromChatRoomData(message);
          if (roomVideoUrl != null) {
            AppLogger.i(
              'CustomChatWidgetNew',
              'Found video URL from chat room data: $roomVideoUrl',
            );
            return roomVideoUrl;
          }
        } catch (e) {
          AppLogger.w(
            'CustomChatWidgetNew',
            'Failed to get video URL from chat room data: $e',
          );
        }
      }

      // Method 5: Try to get video metadata from backend using message ID (fallback)
      if (message.id != null) {
        try {
          String? videoUrl = await _fetchVideoUrlFromBackend(message.id!);
          if (videoUrl != null) {
            AppLogger.i(
              'CustomChatWidgetNew',
              'Fetched video URL from backend: $videoUrl',
            );
            return videoUrl;
          }
        } catch (e) {
          AppLogger.w(
            'CustomChatWidgetNew',
            'Failed to fetch video URL from backend: $e',
          );
        }
      }

      AppLogger.w(
        'CustomChatWidgetNew',
        'Could not determine video URL for message ${message.id}',
      );
      return null;
    } catch (e) {
      AppLogger.e('CustomChatWidgetNew', 'Error getting video URL: $e');
      return null;
    }
  }

  // Try to get video URL from chat room data (where correct URLs are stored)
  Future<String?> _getVideoUrlFromChatRoomData(Message message) async {
    try {
      // Access the ChatProvider to get room data
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      final rooms = chatProvider.rooms;

      // Find the room that contains this message
      final room = rooms.firstWhere(
        (room) => room.id == message.roomId.toString(),
        orElse: () => throw Exception('Room not found'),
      );

      // Check if the room's last message is this video message and has the correct URL
      final lastMessageData = room.metadata?['lastMessage'];
      if (lastMessageData != null && lastMessageData is Map) {
        final lastMessageId = lastMessageData['id'];
        final lastMessageContent = lastMessageData['content'];

        // If this is the last message and it has a video URL in content
        if (lastMessageId == message.id &&
            lastMessageContent != null &&
            lastMessageContent.toString().contains('http') &&
            lastMessageContent.toString().contains('.mp4')) {
          AppLogger.i(
            'CustomChatWidgetNew',
            'Found video URL in room last message data: $lastMessageContent',
          );
          return lastMessageContent.toString();
        }
      }

      return null;
    } catch (e) {
      AppLogger.w(
        'CustomChatWidgetNew',
        'Error getting video URL from chat room data: $e',
      );
      return null;
    }
  }

  // Fetch video URL from backend using message ID
  Future<String?> _fetchVideoUrlFromBackend(int messageId) async {
    try {
      // Use the new message-based download endpoint from the backend
      String downloadUrl =
          'http://abusaker.zapto.org:8080/api/files/message/$messageId';
      AppLogger.i(
        'CustomChatWidgetNew',
        'Fetched video URL from backend: $downloadUrl',
      );
      return downloadUrl;
    } catch (e) {
      AppLogger.e(
        'CustomChatWidgetNew',
        'Error constructing video URL from backend: $e',
      );
      return null;
    }
  }

  // Build video error placeholder
  Widget _buildVideoErrorPlaceholder(Message message, bool isCurrentUser) {
    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Video icon
          Icon(Icons.videocam_off, size: 64, color: Colors.grey[500]),

          // Error indicator
          Positioned(
            bottom: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withAlpha(180),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, size: 16, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    'Video unavailable',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Handle image messages that might show as text
  Widget _buildImageMessageWithLoading(Message message, bool isCurrentUser) {
    AppLogger.i(
      'CustomChatWidgetNew',
      'Building image message with loading: id=${message.id}, contentType=${message.contentType}',
    );

    final String heroTagId =
        message.id?.toString() ??
        DateTime.now().microsecondsSinceEpoch.toString();

    // If content looks like a URL, use it as image URL
    if (message.content != null &&
        (message.content!.startsWith('http') ||
            _isImageUrl(message.content!))) {
      return ChatImageThumbnail(
        imageUrl: message.content!,
        height: 180,
        width: null,
        fit: BoxFit.cover,
        heroTag: 'image-$heroTagId',
        isCurrentUser: isCurrentUser,
      );
    }

    // Otherwise, show a loading placeholder for image
    return _buildImageLoadingPlaceholder(message, isCurrentUser);
  }

  // Build video loading placeholder
  Widget _buildVideoLoadingPlaceholder(Message message, bool isCurrentUser) {
    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Shimmer effect
          _buildShimmerEffect(),

          // Video icon
          Icon(Icons.videocam, size: 64, color: Colors.grey[500]),

          // Loading indicator
          Positioned(
            bottom: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isCurrentUser
                            ? Colors.white
                            : Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Loading video...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build image loading placeholder
  Widget _buildImageLoadingPlaceholder(Message message, bool isCurrentUser) {
    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Shimmer effect
          _buildShimmerEffect(),

          // Image icon
          Icon(Icons.image, size: 64, color: Colors.grey[500]),

          // Loading indicator
          Positioned(
            bottom: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isCurrentUser
                            ? Colors.white
                            : Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Loading image...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Build shimmer effect for loading placeholders
  Widget _buildShimmerEffect() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1500),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.grey[400]!,
                Colors.grey[300]!,
                Colors.grey[200]!,
                Colors.grey[300]!,
                Colors.grey[400]!,
              ],
              stops: [
                0.0,
                0.25 + value * 0.25,
                0.5 + value * 0.25,
                0.75 + value * 0.25,
                1.0,
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
        );
      },
    );
  }

  // Check if URL is an image
  bool _isImageUrl(String url) {
    final imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp'];
    final lowerUrl = url.toLowerCase();
    return imageExtensions.any((ext) => lowerUrl.contains(ext));
  }

  Widget _buildAttachment(
    String url,
    String? contentType, {
    Message? message,
    bool isCurrentUser = false,
  }) {
    // Add detailed logging for attachment rendering
    AppLogger.i(
      'CustomChatWidgetNew',
      'ATTACHMENT: url=$url, contentType=$contentType, '
          'isImage=${contentType != null && contentType.startsWith("image/")}',
    );

    final String heroTagId =
        message?.id?.toString() ??
        DateTime.now().microsecondsSinceEpoch.toString();

    try {
      if (contentType != null && contentType.startsWith('image/')) {
        AppLogger.i('CustomChatWidgetNew', 'Attempting to render image: $url');
        // Use the ChatImageThumbnail for images with hero animation
        return ChatImageThumbnail(
          imageUrl: url,
          height: 180,
          width: null, // Let the widget determine its own width
          fit: BoxFit.cover,
          heroTag: 'image-$heroTagId',
          isCurrentUser: isCurrentUser,
        );
      } else if (contentType != null && contentType.startsWith('video/')) {
        AppLogger.i('CustomChatWidgetNew', 'Attempting to render video: $url');
        // Use the VideoThumbnail for videos with hero animation
        return SizedBox(
          width: 240,
          child: VideoThumbnail(
            videoUrl: url,
            heroTag: 'video-$heroTagId',
            isCurrentUser: isCurrentUser,
          ),
        );
      } else {
        // For non-image files - improved design
        final fileName = _getFileNameFromUrl(url);
        final fileIcon = _getIconForContentType(contentType);
        final fileSize = _getFileSizeFromUrl(url);

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                // Open file based on content type
                if (contentType != null && contentType.startsWith('video/')) {
                  Navigator.pushNamed(
                    context,
                    CustomRoutes.videoPreview,
                    arguments: {
                      'url': url,
                      'contentType': contentType,
                      'fileName': fileName,
                    },
                  );
                } else if (_isTextFile(url, contentType)) {
                  // Open text file viewer
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => TextFileViewerScreen(
                            fileUrl: url,
                            fileName: fileName,
                            contentType: contentType,
                          ),
                    ),
                  );
                } else {
                  // For other file types
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Opening file...'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color:
                      isCurrentUser
                          ? Colors.white.withValues(alpha: 0.15)
                          : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        isCurrentUser
                            ? Colors.white.withValues(alpha: 0.3)
                            : Colors.grey.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color:
                                isCurrentUser
                                    ? Colors.white.withValues(alpha: 0.2)
                                    : Theme.of(
                                      context,
                                    ).primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            fileIcon,
                            size: 24,
                            color:
                                isCurrentUser
                                    ? Colors.white
                                    : Theme.of(context).primaryColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                fileName,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color:
                                      isCurrentUser
                                          ? Colors.white
                                          : Colors.black87,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (fileSize.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  fileSize,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color:
                                        isCurrentUser
                                            ? Colors.white.withValues(
                                              alpha: 0.8,
                                            )
                                            : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Icon(
                          Icons.open_in_new,
                          size: 18,
                          color:
                              isCurrentUser
                                  ? Colors.white.withValues(alpha: 0.8)
                                  : Colors.grey[600],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isCurrentUser
                                ? Colors.white.withValues(alpha: 0.2)
                                : Theme.of(
                                  context,
                                ).primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.touch_app,
                            size: 14,
                            color:
                                isCurrentUser
                                    ? Colors.white.withValues(alpha: 0.9)
                                    : Theme.of(context).primaryColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Tap to open',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color:
                                  isCurrentUser
                                      ? Colors.white.withValues(alpha: 0.9)
                                      : Theme.of(context).primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }
    } catch (e) {
      AppLogger.e('CustomChatWidgetNew', 'Error rendering attachment: $e');
      return Container(
        height: 180,
        width: double.infinity,
        color: Colors.grey[300],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image, size: 48, color: Colors.grey[600]),
              const SizedBox(height: 8),
              Text(
                'Error: ${e.toString().substring(0, e.toString().length.clamp(0, 50))}',
                style: TextStyle(color: Colors.grey[800]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
  }

  IconData _getIconForContentType(String? contentType) {
    if (contentType == null) return Icons.insert_drive_file;

    if (contentType.startsWith('image/')) {
      return Icons.image;
    } else if (contentType.startsWith('video/')) {
      return Icons.videocam;
    } else if (contentType.startsWith('audio/')) {
      return Icons.audiotrack;
    } else if (contentType.contains('pdf')) {
      return Icons.picture_as_pdf;
    } else if (contentType.contains('word') ||
        contentType.contains('document')) {
      return Icons.description;
    } else if (contentType.contains('excel') || contentType.contains('sheet')) {
      return Icons.table_chart;
    } else if (contentType.contains('presentation') ||
        contentType.contains('powerpoint')) {
      return Icons.slideshow;
    } else if (contentType.startsWith('text/') ||
        contentType == 'application/json' ||
        contentType == 'application/xml') {
      return Icons.article;
    } else {
      return Icons.insert_drive_file;
    }
  }

  bool _isVideoUrl(String url) {
    // Check if the URL has a video file extension
    final videoExtensions = [
      '.mp4',
      '.avi',
      '.mov',
      '.wmv',
      '.flv',
      '.webm',
      '.mkv',
    ];
    final lowerUrl = url.toLowerCase();
    return videoExtensions.any((ext) => lowerUrl.endsWith(ext));
  }

  String _getFileNameFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      if (pathSegments.isNotEmpty) {
        String fileName = pathSegments.last;
        return _cleanFileName(fileName);
      }
    } catch (e) {
      // Ignore parsing errors
    }
    return 'File';
  }

  /// Clean up server-generated filenames to show user-friendly names
  String _cleanFileName(String fileName) {
    // Handle server-generated filenames like "20250524-150243-sample3 (1).txt-a1b2c3d4.txt"
    // Pattern: YYYYMMDD-HHMMSS-originalname-hash.extension

    // First, try to extract the original filename from server pattern
    final serverPattern = RegExp(r'^\d{8}-\d{6}-(.+?)-[a-f0-9]+\.(.+)$');
    final match = serverPattern.firstMatch(fileName);

    if (match != null) {
      final originalName = match.group(1)!;
      final extension = match.group(2)!;

      // Clean up the original name
      String cleanName = originalName;

      // Remove duplicate extensions (like "sample.txt" becoming "sample.txt.txt")
      if (cleanName.toLowerCase().endsWith('.${extension.toLowerCase()}')) {
        cleanName = cleanName.substring(
          0,
          cleanName.length - extension.length - 1,
        );
      }

      // Remove parentheses with numbers like " (1)", " (2)", etc.
      cleanName = cleanName.replaceAll(RegExp(r'\s*\(\d+\)\s*'), '');

      // Ensure we have a clean extension
      return '$cleanName.$extension';
    }

    // If it doesn't match the server pattern, try other cleanup
    String cleanName = fileName;

    // Remove hash-like suffixes (like "-a1b2c3d4" before extension)
    cleanName = cleanName.replaceAll(RegExp(r'-[a-f0-9]{8,}(?=\.[^.]+$)'), '');

    // Remove timestamp prefixes (like "20250524-150243-")
    cleanName = cleanName.replaceAll(RegExp(r'^\d{8}-\d{6}-'), '');

    // Remove parentheses with numbers
    cleanName = cleanName.replaceAll(RegExp(r'\s*\(\d+\)\s*'), '');

    // Remove duplicate extensions
    final parts = cleanName.split('.');
    if (parts.length > 2) {
      final extension = parts.last;
      final nameWithoutExt = parts.sublist(0, parts.length - 1).join('.');
      if (nameWithoutExt.toLowerCase().endsWith(
        '.${extension.toLowerCase()}',
      )) {
        final nameWithoutDuplicateExt = nameWithoutExt.substring(
          0,
          nameWithoutExt.length - extension.length - 1,
        );
        cleanName = '$nameWithoutDuplicateExt.$extension';
      }
    }

    // Ensure the name is not empty
    if (cleanName.isEmpty || cleanName == '.') {
      return 'Document';
    }

    return cleanName;
  }

  /// Get file size information from URL (placeholder for now)
  String _getFileSizeFromUrl(String url) {
    // For now, return empty string since we don't have size info in the URL
    // This could be enhanced to make a HEAD request to get file size
    return '';
  }

  /// Calculate minimum width for message based on content
  double _getMinWidthForMessage(Message message) {
    // For attachments, use a larger minimum width
    if (message.attachmentUrl != null) {
      return 200.0;
    }

    // For text messages, calculate based on content length
    final content = message.content ?? '';
    final contentLength = content.length;

    if (contentLength <= 5) {
      // Very short messages (1-5 characters) - minimal width
      return 60.0;
    } else if (contentLength <= 15) {
      // Short messages (6-15 characters) - small width
      return 80.0;
    } else if (contentLength <= 30) {
      // Medium messages (16-30 characters) - medium width
      return 120.0;
    } else {
      // Long messages - no minimum constraint, let it flow naturally
      return 0.0;
    }
  }

  /// Get padding for message based on content type and size
  EdgeInsets _getPaddingForMessage(Message message) {
    // For attachments, use consistent padding
    if (message.attachmentUrl != null) {
      return const EdgeInsets.all(8);
    }

    final content = message.content ?? '';
    final contentLength = content.length;

    if (contentLength <= 5) {
      // Very short messages - compact padding
      return const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
    } else if (contentLength <= 15) {
      // Short messages - slightly more padding
      return const EdgeInsets.symmetric(horizontal: 14, vertical: 9);
    } else if (contentLength <= 50) {
      // Medium messages - standard padding
      return const EdgeInsets.symmetric(horizontal: 16, vertical: 10);
    } else {
      // Long messages - generous padding for readability
      return const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
    }
  }

  /// Get border radius for message based on content and user
  BorderRadius _getBorderRadiusForMessage(Message message, bool isCurrentUser) {
    final content = message.content ?? '';
    final contentLength = content.length;

    // For very short messages, use more rounded corners
    if (contentLength <= 5) {
      return BorderRadius.circular(20);
    } else if (contentLength <= 15) {
      return BorderRadius.circular(18);
    } else {
      // Standard border radius for longer messages
      if (isCurrentUser) {
        return const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(4),
        );
      } else {
        return const BorderRadius.only(
          topLeft: Radius.circular(4),
          topRight: Radius.circular(16),
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        );
      }
    }
  }

  /// Build text content with appropriate styling based on content length
  Widget _buildTextContent(String content, bool isCurrentUser) {
    final contentLength = content.length;

    // Determine font size based on content length
    double fontSize;
    FontWeight fontWeight;

    if (contentLength <= 3) {
      // Very short content (like "OK", "Hi") - larger, bolder
      fontSize = 16;
      fontWeight = FontWeight.w600;
    } else if (contentLength <= 10) {
      // Short content - slightly larger
      fontSize = 15;
      fontWeight = FontWeight.w500;
    } else if (contentLength <= 50) {
      // Medium content - standard size
      fontSize = 14;
      fontWeight = FontWeight.w400;
    } else {
      // Long content - slightly smaller for better readability
      fontSize = 13;
      fontWeight = FontWeight.w400;
    }

    return Text(
      content,
      style: TextStyle(
        color:
            isCurrentUser
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.onSurface,
        fontSize: fontSize,
        fontWeight: fontWeight,
        height:
            contentLength > 50 ? 1.4 : 1.2, // Better line height for long text
      ),
      textAlign: contentLength <= 10 ? TextAlign.center : TextAlign.left,
    );
  }

  String _formatTime(DateTime? dateTime) {
    if (dateTime == null) return '';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (messageDate == yesterday) {
      return 'Yesterday ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  bool _isTextFile(String url, String? contentType) {
    // Check by content type first
    if (FileTypeHelper.isTextFileByContentType(contentType)) {
      return true;
    }
    // Check by file extension
    final fileName = _getFileNameFromUrl(url);
    return FileTypeHelper.isTextFile(fileName);
  }

  /// Check if a message is a problematic timestamp-only message that should be filtered out
  bool _isTimestampOnlyMessage(Message message) {
    // Check if the message content is just a timestamp number
    if (message.content == null || message.content!.isEmpty) {
      return false;
    }

    // Check if content is a numeric timestamp (13 digits for milliseconds since epoch)
    final content = message.content!.trim();
    if (RegExp(r'^\d{13}$').hasMatch(content)) {
      // Additional checks to confirm this is a problematic message:
      // 1. senderId is 0 (system/invalid user)
      // 2. contentType is null
      // 3. no attachmentUrl
      // 4. message ID matches the content (both are the same timestamp)
      if (message.senderId == 0 &&
          message.contentType == null &&
          message.attachmentUrl == null &&
          message.id.toString() == content) {
        return true;
      }
    }

    return false;
  }
}
