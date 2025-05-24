import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/chat_room_repository.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../../domain/models/chat_room_model.dart';
import '../../../domain/models/user_model.dart';
import '../../../utils/logger.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRoomRepository _chatRoomRepository;
  final AuthRepository _authRepository;

  ChatBloc(this._chatRoomRepository, this._authRepository)
    : super(ChatInitial()) {
    on<LoadChatRooms>(_onLoadChatRooms);
    on<CreatePrivateChat>(_onCreatePrivateChat);
    on<CreateGroupChat>(_onCreateGroupChat);
    on<UpdateChatRoom>(_onUpdateChatRoom);
    on<DeleteChatRoom>(_onDeleteChatRoom);
    on<AddParticipant>(_onAddParticipant);
    on<RemoveParticipant>(_onRemoveParticipant);
    on<ChatRoomUpdated>(_onChatRoomUpdated);
    on<UserStatusUpdated>(_onUserStatusUpdated);
  }

  Future<void> _onLoadChatRooms(
    LoadChatRooms event,
    Emitter<ChatState> emit,
  ) async {
    try {
      emit(ChatRoomsLoading());

      // Get current user
      final currentUser = await _authRepository.getCurrentUser();
      if (currentUser == null) {
        emit(const ChatFailure('User not authenticated'));
        return;
      }

      // Get chat rooms
      final chatRooms = await _chatRoomRepository.getUserChatRooms();

      // Sort chat rooms by last message time (newest first)
      chatRooms.sort((a, b) {
        if (a.lastMessageTime == null && b.lastMessageTime == null) {
          return 0;
        } else if (a.lastMessageTime == null) {
          return 1;
        } else if (b.lastMessageTime == null) {
          return -1;
        }
        return b.lastMessageTime!.compareTo(a.lastMessageTime!);
      });

      emit(
        ChatRoomsLoaded(
          chatRooms: chatRooms,
          currentUserId: currentUser.id.toString(),
        ),
      );
    } catch (e) {
      AppLogger.e('ChatBloc', 'Error loading chat rooms: $e');
      emit(ChatFailure(e.toString()));
    }
  }

  Future<void> _onCreatePrivateChat(
    CreatePrivateChat event,
    Emitter<ChatState> emit,
  ) async {
    try {
      emit(const ChatRoomOperationInProgress('Creating private chat...'));

      final chatRoom = await _chatRoomRepository.createPrivateChat(
        event.userId,
      );

      emit(
        ChatRoomOperationSuccess(
          'Private chat created successfully',
          chatRoom: chatRoom,
        ),
      );

      // Reload chat rooms
      add(LoadChatRooms());
    } catch (e) {
      AppLogger.e('ChatBloc', 'Error creating private chat: $e');
      emit(ChatFailure(e.toString()));
    }
  }

  Future<void> _onCreateGroupChat(
    CreateGroupChat event,
    Emitter<ChatState> emit,
  ) async {
    try {
      emit(const ChatRoomOperationInProgress('Creating group chat...'));

      final chatRoom = await _chatRoomRepository.createChatRoom(
        event.name,
        false, // isPrivate = false for group chats
        event.participantIds,
      );

      emit(
        ChatRoomOperationSuccess(
          'Group chat created successfully',
          chatRoom: chatRoom,
        ),
      );

      // Reload chat rooms
      add(LoadChatRooms());
    } catch (e) {
      AppLogger.e('ChatBloc', 'Error creating group chat: $e');
      emit(ChatFailure(e.toString()));
    }
  }

  Future<void> _onUpdateChatRoom(
    UpdateChatRoom event,
    Emitter<ChatState> emit,
  ) async {
    try {
      emit(const ChatRoomOperationInProgress('Updating chat room...'));

      final chatRoom = await _chatRoomRepository.updateChatRoom(
        event.id,
        event.name,
        event.isPrivate,
      );

      emit(
        ChatRoomOperationSuccess(
          'Chat room updated successfully',
          chatRoom: chatRoom,
        ),
      );

      // Reload chat rooms
      add(LoadChatRooms());
    } catch (e) {
      AppLogger.e('ChatBloc', 'Error updating chat room: $e');
      emit(ChatFailure(e.toString()));
    }
  }

  Future<void> _onDeleteChatRoom(
    DeleteChatRoom event,
    Emitter<ChatState> emit,
  ) async {
    try {
      emit(const ChatRoomOperationInProgress('Deleting chat room...'));

      await _chatRoomRepository.deleteChatRoom(event.id);

      emit(const ChatRoomOperationSuccess('Chat room deleted successfully'));

      // Reload chat rooms
      add(LoadChatRooms());
    } catch (e) {
      AppLogger.e('ChatBloc', 'Error deleting chat room: $e');
      emit(ChatFailure(e.toString()));
    }
  }

  Future<void> _onAddParticipant(
    AddParticipant event,
    Emitter<ChatState> emit,
  ) async {
    try {
      emit(const ChatRoomOperationInProgress('Adding participant...'));

      await _chatRoomRepository.addParticipant(event.chatRoomId, event.userId);

      emit(const ChatRoomOperationSuccess('Participant added successfully'));

      // Reload chat rooms
      add(LoadChatRooms());
    } catch (e) {
      AppLogger.e('ChatBloc', 'Error adding participant: $e');
      emit(ChatFailure(e.toString()));
    }
  }

  Future<void> _onRemoveParticipant(
    RemoveParticipant event,
    Emitter<ChatState> emit,
  ) async {
    try {
      emit(const ChatRoomOperationInProgress('Removing participant...'));

      await _chatRoomRepository.removeParticipant(
        event.chatRoomId,
        event.userId,
      );

      emit(const ChatRoomOperationSuccess('Participant removed successfully'));

      // Reload chat rooms
      add(LoadChatRooms());
    } catch (e) {
      AppLogger.e('ChatBloc', 'Error removing participant: $e');
      emit(ChatFailure(e.toString()));
    }
  }

  void _onChatRoomUpdated(ChatRoomUpdated event, Emitter<ChatState> emit) {
    final currentState = state;
    if (currentState is ChatRoomsLoaded) {
      // Find the chat room in the list
      final index = currentState.chatRooms.indexWhere(
        (room) => room.id == event.chatRoom.id,
      );

      if (index != -1) {
        // Update the chat room
        final updatedChatRooms = List<ChatRoomModel>.from(
          currentState.chatRooms,
        );
        updatedChatRooms[index] = event.chatRoom;

        // Sort chat rooms by last message time (newest first)
        updatedChatRooms.sort((a, b) {
          if (a.lastMessageTime == null && b.lastMessageTime == null) {
            return 0;
          } else if (a.lastMessageTime == null) {
            return 1;
          } else if (b.lastMessageTime == null) {
            return -1;
          }
          return b.lastMessageTime!.compareTo(a.lastMessageTime!);
        });

        emit(currentState.copyWith(chatRooms: updatedChatRooms));
      }
    }
  }

  void _onUserStatusUpdated(UserStatusUpdated event, Emitter<ChatState> emit) {
    final currentState = state;
    if (currentState is ChatRoomsLoaded) {
      // Update user status in all chat rooms
      final updatedChatRooms =
          currentState.chatRooms.map((chatRoom) {
            // Check if the user is a participant in this chat room
            final participantIndex = chatRoom.participants.indexWhere(
              (participant) => participant.id == event.user.id,
            );

            if (participantIndex != -1) {
              // Update the participant
              final updatedParticipants = List<UserModel>.from(
                chatRoom.participants,
              );
              updatedParticipants[participantIndex] = event.user;

              // Return updated chat room
              return chatRoom.copyWith(participants: updatedParticipants);
            }

            return chatRoom;
          }).toList();

      emit(currentState.copyWith(chatRooms: updatedChatRooms));
    }
  }
}
