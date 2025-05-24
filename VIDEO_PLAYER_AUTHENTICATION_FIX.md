# Video Player Authentication Fix

## Issues Identified

### 1. Video Player ExoPlayer Error
```
I/flutter ( 6897): ERROR: VideoPlayerWidget - Error initializing video player: PlatformException(VideoError, Video player had error androidx.media3.exoplayer.ExoPlaybackException: Source error, null, null)
```

**Root Cause**: `VideoPlayerController.networkUrl()` doesn't support authentication headers, so it can't access protected video files on the server.

### 2. Image 404 Errors
```
I/flutter ( 6897): ERROR: AuthenticatedImage - Error displaying image: HttpException: Failed to load image: 404
```

**Root Cause**: URL normalization was using `/api/images/` endpoint instead of the correct `/api/files/download/` endpoint.

## Solution Overview

### 1. Created AuthenticatedVideoPlayer
- **Downloads video with Bearer token authentication**
- **Saves to temporary file** for local playback
- **Automatic token refresh** when tokens expire
- **Proper error handling** with user-friendly messages

### 2. Updated VideoPlayerWidget
- **Smart routing**: Uses authenticated player for server videos, legacy player for public videos
- **Seamless integration** with existing code
- **Backward compatibility** maintained

### 3. Fixed URL Normalization
- **Correct endpoint**: Now uses `/api/files/download/{fileId}` for all files
- **Handles bare filenames**: Converts server filenames to proper URLs
- **Bearer authentication**: Removed query parameter tokens

## Technical Implementation

### AuthenticatedVideoPlayer Flow
```dart
1. Normalize video URL → /api/files/download/{fileId}
2. Download video with Bearer token → Authorization: Bearer {token}
3. Save to temporary file → /temp/video_{timestamp}.mp4
4. Initialize VideoPlayerController.file() → Local playback
5. Clean up temp file on dispose
```

### Smart Video Player Routing
```dart
// VideoPlayerWidget automatically chooses the right player
if (needsAuth && tokenService != null) {
  return AuthenticatedVideoPlayer(); // For server videos
} else {
  return _LegacyVideoPlayer(); // For public videos
}
```

### URL Normalization Examples
```dart
// Before (Incorrect)
"video_file.mp4" → "http://server/api/images/video_file.mp4"

// After (Correct)
"video_file.mp4" → "http://server/api/files/download/video_file.mp4"
"202502-14-135954-scaled_3Rqjp-e6Nz8h3Jqp" → "http://server/api/files/download/202502-14-135954-scaled_3Rqjp-e6Nz8h3Jqp"
```

## Expected Behavior

### Video Loading Success Log
```
I/flutter: AuthenticatedVideoPlayer: Normalized video URL: http://server/api/files/download/video_file.mp4
I/flutter: AuthenticatedVideoPlayer: Downloading video: http://server/api/files/download/video_file.mp4
I/flutter: AuthenticatedVideoPlayer: Added Authorization header with Bearer token
I/flutter: AuthenticatedVideoPlayer: Video downloaded successfully
I/flutter: AuthenticatedVideoPlayer: Video saved to temp file: /temp/video_1234567890.mp4
```

### Image Loading Success Log
```
I/flutter: AuthenticatedImageProvider: Normalized URL: http://server/api/files/download/image_file.jpg
I/flutter: AuthenticatedImageProvider: Added Authorization header with Bearer token
I/flutter: AuthenticatedImageProvider: Image loaded successfully
```

## Files Modified

### Core Files
- **`lib/widgets/authenticated_video_player.dart`** - NEW: Authenticated video player with Bearer token support
- **`lib/widgets/video_player_widget.dart`** - Updated to use smart routing between authenticated and legacy players
- **`lib/utils/url_utils.dart`** - Fixed URL normalization to use correct `/api/files/download/` endpoint

### Dependencies
- **`path_provider`** - Already included for temporary file storage
- **`video_player`** - Already included for video playback
- **`chewie`** - Already included for video controls

## Key Features

### 1. Automatic Authentication
- ✅ **Bearer Token Headers**: `Authorization: Bearer {token}`
- ✅ **Token Refresh**: Automatic retry with fresh tokens
- ✅ **Error Handling**: User-friendly error messages

### 2. Performance Optimized
- ✅ **Local Playback**: Downloads once, plays locally
- ✅ **Temp File Cleanup**: Automatic cleanup on dispose
- ✅ **Smart Caching**: Reuses downloaded files when possible

### 3. User Experience
- ✅ **Loading Indicators**: Shows download progress
- ✅ **Error Recovery**: Retry buttons for failed loads
- ✅ **Seamless Integration**: Works with existing chat UI

### 4. Security
- ✅ **Protected Content**: Only authenticated users can access videos
- ✅ **Token Security**: No tokens in URLs, only in headers
- ✅ **Automatic Refresh**: Handles expired tokens gracefully

## Testing

### Test Video Loading
1. **Send a video message** in chat
2. **Tap to play** - should show loading indicator
3. **Video should play** with controls
4. **Check logs** for successful authentication

### Test Image Loading
1. **Send an image message** in chat
2. **Image should display** without 404 errors
3. **Tap to view full screen** - should work
4. **Check logs** for successful authentication

### Test Error Handling
1. **Disconnect network** during video load
2. **Should show retry button**
3. **Reconnect and retry** - should work
4. **Token expiry** should auto-refresh

## Troubleshooting

### Video Still Not Playing
- Check server endpoint: `/api/files/download/{fileId}`
- Verify Bearer token in request headers
- Check file permissions on server
- Ensure video file format is supported (MP4 recommended)

### Images Still 404
- Verify URL normalization in logs
- Check if filename matches server file
- Ensure Bearer token authentication is working
- Test with direct server URL

### Performance Issues
- Large videos may take time to download
- Consider implementing progressive download
- Monitor temp file storage usage
- Clean up old temp files periodically

## Success Criteria
- ✅ Videos play without ExoPlayer errors
- ✅ Images load without 404 errors  
- ✅ Authentication works with Bearer tokens
- ✅ Automatic token refresh functions
- ✅ User-friendly error messages
- ✅ Proper cleanup of temporary files
