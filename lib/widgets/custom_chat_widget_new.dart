import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../models/message.dart';
import '../services/improved_file_upload_service.dart';
import '../presentation/widgets/chat/professional_chat_input.dart';
import '../presentation/widgets/chat/professional_attachment_menu.dart';
import '../presentation/widgets/chat/professional_file_upload_handler.dart';
import '../services/api_file_service.dart';
import '../services/websocket_service.dart';
import '../utils/logger.dart';
import '../utils/url_utils.dart';
import '../utils/file_type_helper.dart';
import '../screens/file_viewers/text_file_viewer_screen.dart';
import 'chat_image_thumbnail.dart';
import 'video_player_widget.dart';

import '../custom_routes.dart';

class CustomChatWidgetNew extends StatefulWidget {
  final List<Message> messages;
  final Function(String) onSendMessage;
  final Function(String, String) onSendAttachment;
  final int currentUserId;
  final bool showUserAvatars;
  final ImprovedFileUploadService webSocketService;
  final int roomId;

  const CustomChatWidgetNew({
    super.key,
    required this.messages,
    required this.onSendMessage,
    required this.onSendAttachment,
    required this.currentUserId,
    required this.webSocketService,
    required this.roomId,
    this.showUserAvatars = true,
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
  int _previousMessageCount = 0;
  ProfessionalFileUploadHandler? _fileUploadHandler;

  @override
  void initState() {
    super.initState();
    _previousMessageCount = widget.messages.length;

    // Schedule a scroll to bottom on initial load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
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
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(CustomChatWidgetNew oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If messages changed, ensure we update the UI properly
    if (widget.messages != oldWidget.messages) {
      // If new messages were added, scroll to bottom
      if (widget.messages.length > _previousMessageCount) {
        AppLogger.i(
          'CustomChatWidgetNew',
          'New messages detected. Auto-scrolling to bottom.',
        );

        // For reversed ListView, we need to scroll to position 0 for newest messages
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      }

      _previousMessageCount = widget.messages.length;
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
      widget.onSendMessage(message);
      _messageController.clear();
      // No need to call _scrollToBottom here as didUpdateWidget will handle it
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

  void _handleUploadComplete(String url, String contentType) {
    setState(() {
      _isUploading = false;
      _uploadProgress = 0.0;
    });
    widget.onSendAttachment(url, contentType);

    // Use a small delay to ensure the message is added to the list before scrolling
    Future.delayed(const Duration(milliseconds: 50), () {
      _scrollToBottom();
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
      userFriendlyError = 'File is too large. Please select a file under 10MB.';
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

  Future<void> _pickAndUploadAudio() async {
    setState(() {
      _isUploading = true;
      _currentFileName = 'audio';
      _isAttachmentMenuOpen = false;
    });

    try {
      final result = await widget.webSocketService.pickAndUploadAudio(
        roomId: widget.roomId,
        onProgress: _handleProgress,
      );

      _handleUploadComplete(result.url, result.contentType);
    } catch (e) {
      AppLogger.e('CustomChatWidgetNew', 'Error uploading audio: $e');
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
    return Column(
      children: [
        Expanded(
          child:
              widget.messages.isEmpty
                  ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.chat_bubble_outline,
                          color: Colors.grey,
                          size: 48,
                        ),
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
                  )
                  : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: widget.messages.length,
                    // Reverse the ListView so newest messages are at the bottom
                    reverse: true,
                    itemBuilder: (context, index) {
                      // When reversed, we need to access items in reverse order
                      final message =
                          widget.messages[widget.messages.length - 1 - index];
                      final isCurrentUser =
                          message.senderId == widget.currentUserId;

                      return _buildMessageItem(message, isCurrentUser);
                    },
                  ),
        ),
        if (_isUploading) _buildProgressIndicator(),
        if (_isAttachmentMenuOpen) _buildProfessionalAttachmentMenu(),
        ProfessionalChatInput(
          controller: _messageController,
          onSendMessage: _sendMessage,
          onAttachmentPressed: _toggleAttachmentMenu,
          isAttachmentUploading: _isUploading,
          hintText: 'Type a message...',
        ),
      ],
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

  Widget _buildAttachmentMenu() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildAttachmentButton(
            icon: Icons.camera_alt,
            label: 'Camera',
            onTap: _captureAndUploadImage,
          ),
          _buildAttachmentButton(
            icon: Icons.image,
            label: 'Image',
            onTap: _pickAndUploadImage,
          ),
          _buildAttachmentButton(
            icon: Icons.videocam,
            label: 'Video',
            onTap: _pickAndUploadVideo,
          ),
          _buildAttachmentButton(
            icon: Icons.audiotrack,
            label: 'Audio',
            onTap: _pickAndUploadAudio,
          ),
          _buildAttachmentButton(
            icon: Icons.insert_drive_file,
            label: 'Document',
            onTap: _pickAndUploadDocument,
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: _isUploading ? null : onTap,
          borderRadius: BorderRadius.circular(30),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.black87),
        ),
      ],
    );
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
              isCurrentUser ? Theme.of(context).primaryColor : Colors.grey[300],
          borderRadius: _getBorderRadiusForMessage(message, isCurrentUser),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
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
                      color: isCurrentUser ? Colors.white : Colors.black87,
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
                              ? const Color.fromARGB(255, 200, 171, 171)
                              : Colors.black54,
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
        return VideoThumbnail(
          videoUrl: url,
          heroTag: 'video-$heroTagId',
          isCurrentUser: isCurrentUser,
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
                          ? Colors.white.withOpacity(0.15)
                          : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        isCurrentUser
                            ? Colors.white.withOpacity(0.3)
                            : Colors.grey.withOpacity(0.3),
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
                                    ? Colors.white.withOpacity(0.2)
                                    : Theme.of(
                                      context,
                                    ).primaryColor.withOpacity(0.1),
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
                                            ? Colors.white.withOpacity(0.8)
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
                                  ? Colors.white.withOpacity(0.8)
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
                                ? Colors.white.withOpacity(0.2)
                                : Theme.of(
                                  context,
                                ).primaryColor.withOpacity(0.1),
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
                                    ? Colors.white.withOpacity(0.9)
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
                                      ? Colors.white.withOpacity(0.9)
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
        color: isCurrentUser ? Colors.white : Colors.black87,
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
