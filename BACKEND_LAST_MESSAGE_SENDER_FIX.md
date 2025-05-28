# Backend Fix: Last Message Sender Field

## Issue Description

The Flutter chat application is experiencing a type casting error when receiving chat room data from the backend:

```
ERROR: ChatProvider - Error getting private chat rooms: type '_Map<String, dynamic>' is not a subtype of type 'String?' in type cast
```

## Root Cause

The backend is currently returning `lastMessageSender` as a **user object** (Map) instead of a **string** containing the sender's name. This causes type casting errors in the Flutter application.

### Current Backend Response (Problematic)
```json
{
  "id": 1,
  "name": "Chat Room Name",
  "type": "PRIVATE",
  "lastMessage": "Hello, how are you?",
  "lastMessageSender": {
    "id": 123,
    "fullName": "John Doe",
    "username": "john.doe",
    "email": "john@example.com"
  },
  "lastMessageTime": "2024-01-15T10:30:00Z",
  "participants": [...],
  "unreadCount": 2
}
```

### Expected Backend Response (Fixed)
```json
{
  "id": 1,
  "name": "Chat Room Name",
  "type": "PRIVATE",
  "lastMessage": "Hello, how are you?",
  "lastMessageSender": "John Doe",
  "lastMessageTime": "2024-01-15T10:30:00Z",
  "participants": [...],
  "unreadCount": 2
}
```

## Required Backend Changes

### 1. Update Chat Room Entity/DTO

Modify your chat room response DTO to include `lastMessageSender` as a string field:

```java
public class ChatRoomResponseDTO {
    private Long id;
    private String name;
    private String type;
    private String lastMessage;
    private String lastMessageSender;  // Should be String, not User object
    private LocalDateTime lastMessageTime;
    private List<UserDTO> participants;
    private Integer unreadCount;
    
    // getters and setters
}
```

### 2. Update Repository/Service Layer

When fetching chat rooms, ensure the `lastMessageSender` field contains the sender's display name:

```java
@Service
public class ChatRoomService {
    
    public List<ChatRoomResponseDTO> getUserChatRooms(Long userId) {
        List<ChatRoom> chatRooms = chatRoomRepository.findByUserId(userId);
        
        return chatRooms.stream()
            .map(this::mapToChatRoomResponseDTO)
            .collect(Collectors.toList());
    }
    
    private ChatRoomResponseDTO mapToChatRoomResponseDTO(ChatRoom chatRoom) {
        ChatRoomResponseDTO dto = new ChatRoomResponseDTO();
        dto.setId(chatRoom.getId());
        dto.setName(chatRoom.getName());
        dto.setType(chatRoom.getType().toString());
        dto.setLastMessage(chatRoom.getLastMessage());
        
        // Fix: Extract sender name instead of returning user object
        if (chatRoom.getLastMessageSender() != null) {
            dto.setLastMessageSender(chatRoom.getLastMessageSender().getFullName());
        }
        
        dto.setLastMessageTime(chatRoom.getLastMessageTime());
        dto.setParticipants(mapParticipants(chatRoom.getParticipants()));
        dto.setUnreadCount(chatRoom.getUnreadCount());
        
        return dto;
    }
}
```

### 3. Update Database Schema (if needed)

If your database stores the last message sender as a foreign key, you may need to update your queries to join with the users table:

```sql
-- Example query to get chat rooms with sender names
SELECT 
    cr.id,
    cr.name,
    cr.type,
    cr.last_message,
    u.full_name as last_message_sender,  -- Get sender name, not ID
    cr.last_message_time,
    cr.unread_count
FROM chat_rooms cr
LEFT JOIN users u ON cr.last_message_sender_id = u.id
WHERE cr.id IN (
    SELECT DISTINCT cp.chat_room_id 
    FROM chat_participants cp 
    WHERE cp.user_id = ?
);
```

### 4. Update Message Creation Logic

When a new message is sent, update the chat room's `lastMessageSender` field with the sender's name:

```java
@Service
public class MessageService {
    
    public void sendMessage(SendMessageRequest request) {
        // Create and save message
        Message message = createMessage(request);
        messageRepository.save(message);
        
        // Update chat room's last message info
        ChatRoom chatRoom = chatRoomRepository.findById(request.getChatRoomId())
            .orElseThrow(() -> new ChatRoomNotFoundException());
            
        chatRoom.setLastMessage(message.getContent());
        chatRoom.setLastMessageSender(message.getSender().getFullName()); // Use name, not object
        chatRoom.setLastMessageTime(message.getSentAt());
        
        chatRoomRepository.save(chatRoom);
        
        // Send WebSocket notification with correct format
        sendWebSocketNotification(chatRoom);
    }
}
```

### 5. Update WebSocket Notifications

Ensure WebSocket notifications also send the sender name as a string:

```java
@Component
public class WebSocketNotificationService {
    
    public void notifyNewMessage(ChatRoom chatRoom, Message message) {
        Map<String, Object> notification = new HashMap<>();
        notification.put("type", "NEW_MESSAGE");
        notification.put("chatRoomId", chatRoom.getId());
        notification.put("latestMessageContent", message.getContent());
        notification.put("latestMessageSender", message.getSender().getFullName()); // String, not object
        notification.put("timestamp", message.getSentAt().toString());
        notification.put("unreadCount", chatRoom.getUnreadCount());
        
        // Send to all participants
        chatRoom.getParticipants().forEach(participant -> {
            messagingTemplate.convertAndSendToUser(
                participant.getId().toString(),
                "/queue/chat/updates",
                notification
            );
        });
    }
}
```

## Testing

After implementing these changes, test the API endpoints:

### 1. Test Chat Rooms Endpoint
```bash
GET /api/chatrooms
Authorization: Bearer <token>
```

Expected response should have `lastMessageSender` as a string:
```json
[
  {
    "id": 1,
    "name": "John Doe",
    "type": "PRIVATE",
    "lastMessage": "Hello there!",
    "lastMessageSender": "John Doe",
    "lastMessageTime": "2024-01-15T10:30:00Z",
    "unreadCount": 1
  }
]
```

### 2. Test WebSocket Notifications

Send a message and verify the WebSocket notification format:
```json
{
  "type": "NEW_MESSAGE",
  "chatRoomId": 1,
  "latestMessageContent": "New message content",
  "latestMessageSender": "Jane Smith",
  "timestamp": "2024-01-15T10:35:00Z",
  "unreadCount": 2
}
```

## Migration Notes

If you have existing data where `lastMessageSender` is stored as user IDs, you may need a data migration script:

```sql
-- Update existing chat rooms to use sender names instead of IDs
UPDATE chat_rooms cr
SET last_message_sender = (
    SELECT u.full_name 
    FROM users u 
    WHERE u.id = CAST(cr.last_message_sender AS INTEGER)
)
WHERE cr.last_message_sender IS NOT NULL 
AND cr.last_message_sender ~ '^[0-9]+$';  -- Only update if it's a numeric ID
```

## Verification

After implementing these changes:

1. ✅ Chat rooms API should return `lastMessageSender` as string
2. ✅ WebSocket notifications should send sender names as strings
3. ✅ Flutter app should no longer throw type casting errors
4. ✅ Chat lists should display "SenderName: message" for group chats
5. ✅ Chat lists should display just the message content for private chats

## Alternative Solution (Temporary)

If backend changes cannot be implemented immediately, the Flutter app has been updated with a temporary workaround that can handle both formats:
- String format: `"lastMessageSender": "John Doe"`
- Object format: `"lastMessageSender": {"fullName": "John Doe", ...}`

However, the recommended approach is to fix the backend to return the correct string format for consistency and performance.
