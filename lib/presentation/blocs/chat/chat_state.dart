import 'package:equatable/equatable.dart';
import '../../../domain/models/chat_room_model.dart';

abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

// Initial state
class ChatInitial extends ChatState {}

// Loading chat rooms
class ChatRoomsLoading extends ChatState {}

// Chat rooms loaded successfully
class ChatRoomsLoaded extends ChatState {
  final List<ChatRoomModel> chatRooms;
  final String currentUserId;

  const ChatRoomsLoaded({
    required this.chatRooms,
    required this.currentUserId,
  });

  ChatRoomsLoaded copyWith({
    List<ChatRoomModel>? chatRooms,
    String? currentUserId,
  }) {
    return ChatRoomsLoaded(
      chatRooms: chatRooms ?? this.chatRooms,
      currentUserId: currentUserId ?? this.currentUserId,
    );
  }

  @override
  List<Object?> get props => [chatRooms, currentUserId];
}

// Chat room operation in progress
class ChatRoomOperationInProgress extends ChatState {
  final String message;

  const ChatRoomOperationInProgress(this.message);

  @override
  List<Object?> get props => [message];
}

// Chat room operation completed successfully
class ChatRoomOperationSuccess extends ChatState {
  final String message;
  final ChatRoomModel? chatRoom;

  const ChatRoomOperationSuccess(this.message, {this.chatRoom});

  @override
  List<Object?> get props => [message, chatRoom];
}

// Chat operation failed
class ChatFailure extends ChatState {
  final String error;

  const ChatFailure(this.error);

  @override
  List<Object?> get props => [error];
}
