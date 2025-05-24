import 'package:flutter/material.dart';
import '../models/message.dart';
import '../services/improved_file_upload_service.dart';
import '../utils/logger.dart';
import 'shimmer_widgets.dart';

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

  // Define theme colors for consistency
  late Color _primaryColor;
  late Color _lightGrey;
  late Color _darkGrey;

  @override
  void initState() {
    super.initState();

    // Scroll to bottom when widget is first built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && widget.messages.isNotEmpty) {
        _scrollToBottom();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize theme colors based on context
    _primaryColor = Theme.of(context).primaryColor;
    _lightGrey = Colors.grey.shade200;
    _darkGrey = Colors.grey.shade600;
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isNotEmpty) {
      widget.onSendMessage(message);
      _messageController.clear();
      // Scroll to bottom after sending
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
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
  }

  void _handleUploadError(String error) {
    setState(() {
      _isUploading = false;
      _uploadProgress = 0.0;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Upload failed: $error'),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Future<void> _pickAndUploadImage() async {
    setState(() {
      _isUploading = true;
      _currentFileName = 'image';
      _isAttachmentMenuOpen = false;
    });

    try {
      final result = await widget.webSocketService.pickAndUploadImage(
        roomId: widget.roomId,
        onProgress: _handleProgress,
      );

      _handleUploadComplete(result.url, result.contentType);
    } catch (e) {
      AppLogger.e('CustomChatWidgetNew', 'Error uploading image: $e');
      _handleUploadError(e.toString());
    }
  }

  Future<void> _pickAndUploadVideo() async {
    setState(() {
      _isUploading = true;
      _currentFileName = 'video';
      _isAttachmentMenuOpen = false;
    });

    try {
      final result = await widget.webSocketService.pickAndUploadVideo(
        roomId: widget.roomId,
        onProgress: _handleProgress,
      );

      _handleUploadComplete(result.url, result.contentType);
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
    setState(() {
      _isUploading = true;
      _currentFileName = 'document';
      _isAttachmentMenuOpen = false;
    });

    try {
      final result = await widget.webSocketService.pickAndUploadDocument(
        roomId: widget.roomId,
        onProgress: _handleProgress,
      );

      _handleUploadComplete(result.url, result.contentType);
    } catch (e) {
      AppLogger.e('CustomChatWidgetNew', 'Error uploading document: $e');
      _handleUploadError(e.toString());
    }
  }

  Future<void> _captureAndUploadImage() async {
    setState(() {
      _isUploading = true;
      _currentFileName = 'camera';
      _isAttachmentMenuOpen = false;
    });

    try {
      final result = await widget.webSocketService.captureAndUploadImage(
        roomId: widget.roomId,
        onProgress: _handleProgress,
      );

      _handleUploadComplete(result.url, result.contentType);
    } catch (e) {
      AppLogger.e('CustomChatWidgetNew', 'Error capturing image: $e');
      _handleUploadError(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        // A subtle gradient background for the chat area
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.grey.shade50, Colors.grey.shade100],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child:
                  widget.messages.isEmpty
                      ? _buildEmptyState()
                      : _buildMessagesList(),
            ),
            if (_isUploading) _buildProgressIndicator(),
            if (_isAttachmentMenuOpen) _buildAttachmentMenu(),
            _buildInputField(),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: _darkGrey.withAlpha(128),
          ),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 18,
              color: _darkGrey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start the conversation by sending a message',
            style: TextStyle(fontSize: 14, color: _darkGrey.withAlpha(179)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      itemCount: widget.messages.length,
      itemBuilder: (context, index) {
        final message = widget.messages[index];
        final isCurrentUser = message.senderId == widget.currentUserId;

        // Group messages by sender (show sender name only once per group)
        final bool showSenderInfo =
            index == 0 ||
            widget.messages[index - 1].senderId != message.senderId;

        // Reduce padding between messages from same sender
        final bool sameAsPrevious =
            index > 0 &&
            widget.messages[index - 1].senderId == message.senderId;

        return Padding(
          padding: EdgeInsets.only(top: sameAsPrevious ? 2 : 12, bottom: 2),
          child: _buildMessageItem(
            message,
            isCurrentUser,
            showSenderInfo && !isCurrentUser && widget.showUserAvatars,
          ),
        );
      },
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(51),
            blurRadius: 4,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getIconForContentType(_currentFileName),
                size: 20,
                color: _primaryColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Uploading $_currentFileName...',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${(_uploadProgress * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _uploadProgress,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                widget.webSocketService.cancelUpload();
                setState(() {
                  _isUploading = false;
                });
              },
              icon: const Icon(Icons.close, size: 16),
              label: const Text('Cancel'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red.shade700,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            decoration: BoxDecoration(
              color: _primaryColor.withAlpha(26),
              borderRadius: BorderRadius.circular(30),
            ),
            child: IconButton(
              icon: Icon(
                _isAttachmentMenuOpen ? Icons.close : Icons.add,
                color: _isAttachmentMenuOpen ? Colors.red : _primaryColor,
              ),
              onPressed: _isUploading ? null : _toggleAttachmentMenu,
              splashRadius: 24,
              tooltip: _isAttachmentMenuOpen ? 'Close menu' : 'Attachments',
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: _lightGrey,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              style: const TextStyle(fontSize: 16),
              textCapitalization: TextCapitalization.sentences,
              minLines: 1,
              maxLines: 5,
              onSubmitted: (_) => _sendMessage(),
              textInputAction: TextInputAction.send,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: _primaryColor,
              borderRadius: BorderRadius.circular(30),
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: _sendMessage,
              tooltip: 'Send message',
              splashRadius: 24,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentMenu() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.grey.withAlpha(26), blurRadius: 4)],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildAttachmentButton(
              icon: Icons.camera_alt,
              label: 'Camera',
              color: Colors.blue.shade700,
              onTap: _captureAndUploadImage,
            ),
            const SizedBox(width: 8),
            _buildAttachmentButton(
              icon: Icons.image,
              label: 'Gallery',
              color: Colors.green.shade600,
              onTap: _pickAndUploadImage,
            ),
            const SizedBox(width: 8),
            _buildAttachmentButton(
              icon: Icons.videocam,
              label: 'Video',
              color: Colors.red.shade600,
              onTap: _pickAndUploadVideo,
            ),
            const SizedBox(width: 8),
            _buildAttachmentButton(
              icon: Icons.audiotrack,
              label: 'Audio',
              color: Colors.orange.shade600,
              onTap: _pickAndUploadAudio,
            ),
            const SizedBox(width: 8),
            _buildAttachmentButton(
              icon: Icons.insert_drive_file,
              label: 'Document',
              color: Colors.purple.shade600,
              onTap: _pickAndUploadDocument,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: _isUploading ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isUploading ? color.withAlpha(128) : color,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: color.withAlpha(77),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: _isUploading ? Colors.grey : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageItem(
    Message message,
    bool isCurrentUser,
    bool showSenderInfo,
  ) {
    final maxWidth = MediaQuery.of(context).size.width * 0.75;
    final bubbleColor = isCurrentUser ? _primaryColor : Colors.white;
    final textColor = isCurrentUser ? Colors.white : Colors.black87;

    return Column(
      crossAxisAlignment:
          isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        if (showSenderInfo)
          Padding(
            padding: const EdgeInsets.only(left: 12, bottom: 4),
            child: Text(
              message.senderName ?? 'Unknown',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _darkGrey,
                fontSize: 13,
              ),
            ),
          ),
        Align(
          alignment:
              isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            constraints: BoxConstraints(maxWidth: maxWidth),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft:
                    isCurrentUser
                        ? const Radius.circular(16)
                        : const Radius.circular(4),
                bottomRight:
                    isCurrentUser
                        ? const Radius.circular(4)
                        : const Radius.circular(16),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(13),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            margin: EdgeInsets.only(
              left: isCurrentUser ? 64 : 0,
              right: isCurrentUser ? 0 : 64,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Attachment (if any)
                  if (message.attachmentUrl != null)
                    _buildAttachment(
                      message.attachmentUrl!,
                      message.contentType,
                      isCurrentUser,
                    ),

                  // Message content
                  if (message.content != null && message.content!.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(
                        left: 12,
                        right: 12,
                        top: message.attachmentUrl != null ? 8 : 12,
                        bottom: 4,
                      ),
                      child: Text(
                        message.content!,
                        style: TextStyle(color: textColor, fontSize: 15),
                      ),
                    ),

                  // Timestamp
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 12,
                      right: 12,
                      bottom: 6,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Expanded(child: Container()),
                        Text(
                          _formatTime(message.sentAt),
                          style: TextStyle(
                            fontSize: 11,
                            color:
                                isCurrentUser
                                    ? Colors.white.withAlpha(179)
                                    : Colors.black54,
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
      ],
    );
  }

  Widget _buildAttachment(String url, String? contentType, bool isCurrentUser) {
    final bool isImage =
        contentType != null && contentType.startsWith('image/');
    final textColor = isCurrentUser ? Colors.white : Colors.black87;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isImage)
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            child: Image.network(
              url,
              fit: BoxFit.cover,
              width: double.infinity,
              height: 180,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return ShimmerWidgets.chatImageShimmer(
                  width: double.infinity,
                  height: 180,
                  isCurrentUser: isCurrentUser,
                  primaryColor: _primaryColor,
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 120,
                  color:
                      isCurrentUser
                          ? _primaryColor.withAlpha(204)
                          : Colors.grey[300],
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.broken_image,
                          color:
                              isCurrentUser ? Colors.white : Colors.grey[600],
                          size: 40,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Image not available',
                          style: TextStyle(
                            color:
                                isCurrentUser ? Colors.white : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color:
                        isCurrentUser
                            ? Colors.white.withAlpha(51)
                            : _primaryColor.withAlpha(26),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getIconForContentType(contentType),
                    size: 28,
                    color: isCurrentUser ? Colors.white : _primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getFileNameFromUrl(url),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: textColor.withAlpha(179),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  isCurrentUser
                                      ? Colors.white.withAlpha(51)
                                      : _primaryColor.withAlpha(26),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _getFileExtension(url).toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: textColor.withAlpha(179),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.file_download_outlined,
                            size: 14,
                            color: textColor.withAlpha(179),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Tap to open',
                            style: TextStyle(
                              fontSize: 12,
                              color: textColor.withAlpha(179),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
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
    } else {
      return Icons.insert_drive_file;
    }
  }

  String _getFileNameFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      if (pathSegments.isNotEmpty) {
        return pathSegments.last;
      }
    } catch (e) {
      // Ignore parsing errors
    }
    return 'File';
  }

  String _getFileExtension(String url) {
    try {
      final fileName = _getFileNameFromUrl(url);
      final parts = fileName.split('.');
      if (parts.length > 1) {
        return parts.last.substring(0, 3); // Limit to 3 chars
      }
    } catch (e) {
      // Ignore parsing errors
    }
    return 'file';
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
      return '${dateTime.day}/${dateTime.month}, ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}
