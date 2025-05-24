# Token Refresh Image Loading Fix

## Problem
The Flutter chat application was experiencing HTTP 401 (Unauthorized) errors when loading images. The issue occurred because:

1. **Expired Tokens**: Authentication tokens were expiring but image URLs were still using the old expired tokens
2. **No Token Refresh for Images**: The `CachedNetworkImage` widget doesn't automatically handle token refresh like the Dio HTTP client does
3. **Stale Token in UrlUtils**: The `UrlUtils.setAuthToken()` was not being updated when tokens were refreshed

## Error Logs
```
I/flutter ( 6897): ERROR: ChatImageThumbnail - Failed to load image: http://abusaker.zapto.org:8080/api/files/download/20250524-130448-scaled_40.jpg-15b998d5.jpg?token=eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJzYWZpbmFmaSIsImlhdCI6MTc0ODA3Nzc3NiwiZXhwIjoxNzQ4MTY0MTc2fQ._O6Nbq5e79PdG2BRfon9VpYc7ppxlMeDA4ideQd0N9E, Error: HttpException: Invalid statusCode: 401
```

## Solution Implemented

### 1. Enhanced UrlUtils with Token Update Notifications
**File**: `lib/utils/url_utils.dart`
- Added token update callback mechanism
- Added getter for current auth token
- Enhanced logging for token updates

### 2. Created AuthenticatedImageProvider
**File**: `lib/widgets/authenticated_image_provider.dart`
- Custom `ImageProvider` that handles authentication
- Automatically refreshes tokens on 401 errors
- Retries image requests with new tokens
- Integrates with the existing `TokenService`

### 3. Created AuthenticatedImage Widget
**File**: `lib/widgets/authenticated_image_provider.dart`
- Wrapper widget that uses `AuthenticatedImageProvider`
- Provides consistent error handling and loading states
- Easy drop-in replacement for `CachedNetworkImage`

### 4. Updated TokenService
**File**: `lib/core/services/token_service.dart`
- Added automatic UrlUtils token updates in `saveTokens()`
- Added token clearing in `clearTokens()`
- Ensures UrlUtils always has the latest token

### 5. Updated Image Widgets
**Files**:
- `lib/widgets/chat_image_thumbnail.dart`
- `lib/widgets/image_viewer.dart`

- Replaced `CachedNetworkImage` with `AuthenticatedImage`
- Added `TokenService` integration via Provider
- Maintained existing functionality while adding authentication

### 6. Enhanced ApiAuthProvider
**File**: `lib/providers/api_auth_provider.dart`
- Added logging for token updates
- Ensures UrlUtils is updated during login/logout

## Key Features of the Fix

### Automatic Token Refresh
- When an image request returns 401, the system automatically:
  1. Attempts to refresh the access token
  2. Updates UrlUtils with the new token
  3. Retries the image request with the new token

### Seamless Integration
- Drop-in replacement for existing image widgets
- No changes needed to existing image URLs or logic
- Maintains all existing features (caching, error handling, etc.)

### Robust Error Handling
- Graceful fallback when token refresh fails
- Detailed error messages for debugging
- Retry functionality for failed image loads

### Performance Optimized
- Only refreshes tokens when necessary (on 401 errors)
- Maintains image caching for performance
- Minimal overhead for successful requests

## Usage

### For Chat Image Thumbnails
```dart
ChatImageThumbnail(
  imageUrl: 'http://server.com/image.jpg',
  heroTag: 'image-1',
  width: 200,
  height: 150,
)
```

### For Full Image Viewer
```dart
ImageViewer(
  imageUrl: 'http://server.com/image.jpg',
  heroTag: 'image-1',
)
```

### For Custom Image Display
```dart
AuthenticatedImage(
  imageUrl: 'http://server.com/image.jpg',
  tokenService: tokenService,
  width: 200,
  height: 150,
  fit: BoxFit.cover,
)
```

## Testing the Fix

1. **Login to the app** - Ensure you have valid tokens
2. **Wait for token expiration** - Or manually expire tokens
3. **Try to view images** - Images should load successfully after automatic token refresh
4. **Check logs** - Look for token refresh messages in the console

## Expected Log Output
```
I/flutter: UrlUtils: Token updated
I/flutter: ApiAuthProvider: Updated UrlUtils with new token
I/flutter: AuthenticatedImageProvider: Received 401, attempting token refresh
I/flutter: TokenService: Token refreshed successfully
I/flutter: AuthenticatedImageProvider: Image loaded successfully after token refresh
```

## Benefits

1. **Eliminates 401 Image Errors**: Images will load successfully even with expired tokens
2. **Improved User Experience**: No more broken image placeholders due to authentication issues
3. **Automatic Recovery**: System self-heals without user intervention
4. **Maintainable Code**: Clean separation of concerns with reusable components
5. **Future-Proof**: Easy to extend for additional authentication requirements

## Provider Setup Fix

### Issue Resolved
The initial implementation failed with:
```
ProviderNotFoundException: Could not find the correct Provider<TokenService> above this ChatImageThumbnail Widget
```

### Solution
1. **Added TokenService to Provider Tree** (`lib/main.dart`)
   - Added `Provider<TokenService>.value(value: tokenService)` to the MultiProvider
   - Ensures TokenService is available throughout the widget tree

2. **Added Backward Compatibility**
   - Both `ChatImageThumbnail` and `ImageViewer` now gracefully handle missing TokenService
   - Falls back to `CachedNetworkImage` and `NetworkImage` respectively when TokenService is unavailable
   - Prevents crashes in environments where TokenService isn't provided

### Fallback Behavior
- **With TokenService**: Uses `AuthenticatedImage` with automatic token refresh
- **Without TokenService**: Falls back to standard image widgets (maintains existing functionality)

## Token Refresh Endpoint Fix

### Issue Discovered
After fixing the Provider issue, token refresh was still failing with:
```
ERROR: TokenService - Error refreshing token: DioException [bad response]: This exception was thrown because the response has a status code of 404
```

### Root Cause
The `TokenService` was using the wrong refresh token endpoint:
- **TokenService** was using: `/api/auth/refresh-token` (404 error)
- **Other services** were using: `/api/auth/refresh` (working correctly)

### Solution
Updated `TokenService.refreshAccessToken()` method to use the correct endpoint:
```dart
// Changed from:
'/api/auth/refresh-token'
// To:
'/api/auth/refresh'
```

This aligns with the endpoint used by `ApiAuthService` and other working services.

## Token Replacement in Retry URLs Fix

### Issue Discovered
After fixing the endpoint, token refresh was working but retry requests were still failing with 401 errors:
```
I/flutter: INFO: TokenService - Token refreshed successfully
I/flutter: INFO: AuthenticatedImageProvider - Token refreshed, retrying image request
I/flutter: ERROR: AuthenticatedImageProvider - Error fetching image bytes: HttpException: Failed to load image after token refresh: 401
```

### Root Cause
The retry logic was using the original URL which still contained the **expired token**. The `normalizeImageUrl` function was not replacing existing tokens, only adding tokens to URLs that didn't have them.

### Solution
1. **Enhanced UrlUtils.normalizeImageUrl()** - Now removes existing tokens before adding fresh ones
2. **Added _removeTokenFromUrl() helper** - Safely removes token parameters from URLs
3. **Updated retry logic** - Uses original imageUrl to ensure fresh token is applied

### Technical Details
```dart
// Before: Would keep old token if URL already had one
if (_authToken != null && !url.contains('token=')) {
  normalizedUrl += '?token=$_authToken';
}

// After: Always removes old token and adds fresh one
String normalizedUrl = _removeTokenFromUrl(url);
if (_authToken != null) {
  normalizedUrl += normalizedUrl.contains('?') ? '&token=$_authToken' : '?token=$_authToken';
}
```

## Bearer Token Authentication Fix

### Issue Discovered
After implementing the token refresh system, we discovered that the authentication method was inconsistent:
- **UrlUtils** was adding tokens as query parameters (`?token=...`)
- **Backend** expects Bearer token authentication in Authorization headers

### Root Cause
The system was mixing two authentication methods:
1. Query parameter tokens: `http://localhost:8080/api/files/download/file?token=jwt_token`
2. Bearer header tokens: `Authorization: Bearer jwt_token`

### Solution
1. **Updated AuthenticatedImageProvider** - Now adds `Authorization: Bearer {token}` header
2. **Updated UrlUtils** - Removed query parameter token logic since we use Bearer auth
3. **Clean URLs** - URLs now match the expected pattern: `http://localhost:8080/api/files/download/{fileId}`

### Technical Details
```dart
// Before: Query parameter authentication
final url = 'http://localhost:8080/api/files/download/file?token=jwt_token';

// After: Bearer token in Authorization header
final headers = {
  'Authorization': 'Bearer jwt_token',
  'User-Agent': 'Flutter App',
};
final url = 'http://localhost:8080/api/files/download/file';
```

### Expected URL Pattern
```
http://localhost:8080/api/files/download/202502-14-135954-scaled_3Rqjp-e6Nz8h3Jqp
```
With Authorization header: `Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`

## Files Modified

- `lib/main.dart` - Added TokenService to Provider tree
- `lib/utils/url_utils.dart` - Enhanced token management
- `lib/core/services/token_service.dart` - Added UrlUtils integration
- `lib/providers/api_auth_provider.dart` - Enhanced logging
- `lib/widgets/chat_image_thumbnail.dart` - Updated with authenticated image loading and fallback
- `lib/widgets/image_viewer.dart` - Updated with authenticated image provider and fallback

## Files Created

- `lib/widgets/authenticated_image_provider.dart` - New authenticated image provider and widget
- `TOKEN_REFRESH_IMAGE_FIX.md` - This documentation file
