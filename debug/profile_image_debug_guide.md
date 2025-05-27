# 🔍 Profile Image Upload Debug Guide

## 🎯 **ISSUE ANALYSIS**

Based on the Postman screenshot, the backend endpoint is **working correctly** (200 OK response). The issue is likely in the **Flutter request formatting** or **authentication headers**.

## 🔧 **DEBUGGING STEPS**

### **Step 1: Compare Postman vs Flutter Request**

#### **Postman Request (Working)**
```
POST http://abusaker.zapto.org:8080/api/users/me/profile-image
Content-Type: multipart/form-data
Authorization: Bearer {token}
Body: form-data with "file" parameter
```

#### **Flutter Request (Check These)**
1. **URL Format**: Ensure exact URL match
2. **Content-Type**: Should be `multipart/form-data` (auto-set by http package)
3. **File Parameter Name**: Must be exactly "file"
4. **Authorization Header**: Must include "Bearer " prefix

### **Step 2: Add Detailed Request Logging**

Add this debug code to your Flutter app to capture the exact request being sent:

```dart
// In ApiAuthService.uploadProfileImage method
AppLogger.i('DEBUG', '=== PROFILE IMAGE UPLOAD DEBUG ===');
AppLogger.i('DEBUG', 'URL: $uploadUrl');
AppLogger.i('DEBUG', 'Method: POST');
AppLogger.i('DEBUG', 'Headers: ${request.headers}');
AppLogger.i('DEBUG', 'File path: ${imageFile.path}');
AppLogger.i('DEBUG', 'File exists: ${await imageFile.exists()}');
AppLogger.i('DEBUG', 'File size: ${await imageFile.length()} bytes');

// After getting response
AppLogger.i('DEBUG', 'Response status: ${response.statusCode}');
AppLogger.i('DEBUG', 'Response headers: ${response.headers}');
AppLogger.i('DEBUG', 'Response body: ${response.body}');
```

### **Step 3: Verify Authentication Token**

Check if the token being sent is valid:

```dart
// Add this before making the request
final token = _tokenService.accessToken;
AppLogger.i('DEBUG', 'Token length: ${token?.length ?? 0}');
AppLogger.i('DEBUG', 'Token starts with: ${token?.substring(0, 20) ?? 'null'}...');
AppLogger.i('DEBUG', 'Token expired: ${_tokenService.isTokenExpired}');
```

### **Step 4: Test with Minimal Request**

Create a simplified test method:

```dart
Future<void> testProfileImageUpload(File imageFile) async {
  try {
    final url = 'http://abusaker.zapto.org:8080/api/users/me/profile-image';
    final request = http.MultipartRequest('POST', Uri.parse(url));
    
    // Add headers exactly like Postman
    request.headers.addAll({
      'Authorization': 'Bearer ${_tokenService.accessToken}',
      'Accept': 'application/json',
    });
    
    // Add file exactly like Postman
    request.files.add(
      await http.MultipartFile.fromPath('file', imageFile.path),
    );
    
    print('Sending test request...');
    final response = await request.send();
    final responseBody = await response.stream.bytesToString();
    
    print('Test Response Status: ${response.statusCode}');
    print('Test Response Body: $responseBody');
    
  } catch (e) {
    print('Test Error: $e');
  }
}
```

## 🚨 **COMMON ISSUES & FIXES**

### **Issue 1: Wrong Content-Type Header**
**Problem**: Manually setting Content-Type header
**Fix**: Let http package auto-set multipart/form-data

```dart
// ❌ DON'T DO THIS
request.headers['Content-Type'] = 'multipart/form-data';

// ✅ DO THIS (let it auto-set)
request.headers.addAll({
  'Authorization': 'Bearer ${token}',
  'Accept': 'application/json',
});
```

### **Issue 2: File Parameter Name Mismatch**
**Problem**: Using wrong parameter name
**Fix**: Must be exactly "file"

```dart
// ✅ CORRECT
request.files.add(
  await http.MultipartFile.fromPath('file', imageFile.path),
);
```

### **Issue 3: Token Format Issues**
**Problem**: Missing "Bearer " prefix or malformed token
**Fix**: Verify token format

```dart
// ✅ CORRECT FORMAT
'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...'
```

### **Issue 4: File Path Issues**
**Problem**: File doesn't exist or wrong path
**Fix**: Verify file before upload

```dart
if (!await imageFile.exists()) {
  throw Exception('Image file does not exist at path: ${imageFile.path}');
}
```

## 🧪 **TESTING CHECKLIST**

- [ ] **URL matches Postman exactly**
- [ ] **Authorization header includes "Bearer " prefix**
- [ ] **File parameter named "file"**
- [ ] **No manual Content-Type header set**
- [ ] **File exists and is readable**
- [ ] **Token is valid and not expired**
- [ ] **Request headers logged and compared**
- [ ] **Response body logged for error details**

## 🔍 **NEXT STEPS**

1. **Add the debug logging code above**
2. **Run the Flutter app and attempt upload**
3. **Compare the logged request with Postman**
4. **Check for differences in headers, URL, or file handling**
5. **Test with the simplified test method**

The backend is working (proven by Postman), so the issue is in the Flutter request formatting. The debug logs will reveal the exact difference.
