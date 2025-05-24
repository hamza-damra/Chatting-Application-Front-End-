import 'package:equatable/equatable.dart';
import '../../../domain/models/chat_room_model.dart';
import '../../../domain/models/user_model.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

// Load all chat rooms for the current user
class LoadChatRooms extends ChatEvent {}

// Create a new private chat with another user
class CreatePrivateChat extends ChatEvent {
  final String userId;

  const CreatePrivateChat({required this.userId});

  @override
  List<Object?> get props => [userId];
}

// Create a new group chat
class CreateGroupChat extends ChatEvent {
  final String name;
  final List<String> participantIds;

  const CreateGroupChat({
    required this.name,
    required this.participantIds,
  });

  @override
  List<Object?> get props => [name, participantIds];
}

// Update a chat room
class UpdateChatRoom extends ChatEvent {
  final String id;
  final String name;
  final bool isPrivate;

  const UpdateChatRoom({
    required this.id,
    required this.name,
    required this.isPrivate,
  });

  @override
  List<Object?> get props => [id, name, isPrivate];
}

// Delete a chat room
class DeleteChatRoom extends ChatEvent {
  final String id;

  const DeleteChatRoom({required this.id});

  @override
  List<Object?> get props => [id];
}

// Add a participant to a chat room
class AddParticipant extends ChatEvent {
  final String chatRoomId;
  final String userId;

  const AddParticipant({
    required this.chatRoomId,
    required this.userId,
  });

  @override
  List<Object?> get props => [chatRoomId, userId];
}

// Remove a participant from a chat room
class RemoveParticipant extends ChatEvent {
  final String chatRoomId;
  final String userId;

  const RemoveParticipant({
    required this.chatRoomId,
    required this.userId,
  });

  @override
  List<Object?> get props => [chatRoomId, userId];
}

// Chat room updated (e.g., new message received)
class ChatRoomUpdated extends ChatEvent {
  final ChatRoomModel chatRoom;

  const ChatRoomUpdated({required this.chatRoom});

  @override
  List<Object?> get props => [chatRoom];
}

// User status updated (online/offline)
class UserStatusUpdated extends ChatEvent {
  final UserModel user;

  const UserStatusUpdated({required this.user});

  @override
  List<Object?> get props => [user];
}
