# 🔧 Backend Profile Image Upload Fix Guide

## 🎯 **ISSUE ANALYSIS**

The Flutter request is **perfectly formatted** and matches Postman exactly:
- ✅ Correct URL: `http://abusaker.zapto.org:8080/api/users/me/profile-image`
- ✅ Correct Method: POST
- ✅ Correct Headers: `Authorization: Bearer {token}`, `Accept: application/json`
- ✅ Correct File Parameter: "file"
- ✅ Valid Token: 131 characters, not expired
- ✅ Valid File: 19,126 bytes, JPG format

**The 500 Internal Server Error is definitely a backend issue.**

## 🚨 **COMMON BACKEND CAUSES & FIXES**

### **1. File Storage Directory Issues**

**Problem**: Backend can't write to the file storage directory

**Check**:
```bash
# Check if upload directory exists and has write permissions
ls -la /path/to/upload/directory
```

**Fix**:
```java
// In your application.properties or application.yml
file.upload-dir=/uploads/profile-images
spring.servlet.multipart.max-file-size=5MB
spring.servlet.multipart.max-request-size=5MB

// Ensure directory creation in your service
@PostConstruct
public void init() {
    try {
        Files.createDirectories(Paths.get(uploadDir));
    } catch (IOException e) {
        throw new RuntimeException("Could not create upload directory!", e);
    }
}
```

### **2. Missing Multipart Configuration**

**Problem**: Spring Boot not configured for multipart requests

**Fix**:
```java
// Add to application.properties
spring.servlet.multipart.enabled=true
spring.servlet.multipart.max-file-size=5MB
spring.servlet.multipart.max-request-size=5MB
spring.servlet.multipart.file-size-threshold=2KB
```

### **3. Controller Method Issues**

**Problem**: Incorrect parameter binding or missing annotations

**Fix**:
```java
@PostMapping("/api/users/me/profile-image")
public ResponseEntity<UserResponse> uploadProfileImage(
    @RequestParam("file") MultipartFile file,
    Authentication authentication) {
    
    try {
        // Validate file
        if (file.isEmpty()) {
            return ResponseEntity.badRequest()
                .body(new ErrorResponse("File is empty"));
        }
        
        // Get current user
        String username = authentication.getName();
        User user = userService.findByUsername(username);
        
        // Upload and save
        String imageUrl = userService.addProfileImage(user.getId(), file);
        
        // Return updated user
        UserResponse response = userMapper.toResponse(user);
        return ResponseEntity.ok(response);
        
    } catch (Exception e) {
        log.error("Profile image upload failed", e);
        return ResponseEntity.status(500)
            .body(new ErrorResponse("Upload failed: " + e.getMessage()));
    }
}
```

### **4. Service Method Issues**

**Problem**: File processing or database update errors

**Fix**:
```java
@Service
@Transactional
public class UserService {
    
    @Value("${file.upload-dir:/uploads/profile-images}")
    private String uploadDir;
    
    public String addProfileImage(Long userId, MultipartFile file) {
        try {
            // Validate file type
            String contentType = file.getContentType();
            if (!isValidImageType(contentType)) {
                throw new IllegalArgumentException("Invalid file type: " + contentType);
            }
            
            // Generate unique filename
            String originalFilename = file.getOriginalFilename();
            String extension = getFileExtension(originalFilename);
            String filename = System.currentTimeMillis() + "_" + userId + extension;
            
            // Ensure upload directory exists
            Path uploadPath = Paths.get(uploadDir);
            if (!Files.exists(uploadPath)) {
                Files.createDirectories(uploadPath);
            }
            
            // Save file
            Path filePath = uploadPath.resolve(filename);
            Files.copy(file.getInputStream(), filePath, StandardCopyOption.REPLACE_EXISTING);
            
            // Update user in database
            User user = userRepository.findById(userId)
                .orElseThrow(() -> new EntityNotFoundException("User not found"));
            
            String imageUrl = "/api/files/download/" + filename;
            user.setProfilePicture(imageUrl);
            userRepository.save(user);
            
            return imageUrl;
            
        } catch (IOException e) {
            throw new RuntimeException("Failed to store file", e);
        }
    }
    
    private boolean isValidImageType(String contentType) {
        return contentType != null && (
            contentType.equals("image/jpeg") ||
            contentType.equals("image/png") ||
            contentType.equals("image/gif") ||
            contentType.equals("image/webp")
        );
    }
    
    private String getFileExtension(String filename) {
        if (filename == null || !filename.contains(".")) {
            return ".jpg"; // default
        }
        return filename.substring(filename.lastIndexOf("."));
    }
}
```

### **5. Database Issues**

**Problem**: Database connection or constraint violations

**Check**:
```sql
-- Check if user exists
SELECT * FROM users WHERE username = 'user3';

-- Check profile_picture column constraints
DESCRIBE users;

-- Check for any database locks
SHOW PROCESSLIST;
```

**Fix**:
```java
// Ensure proper transaction handling
@Transactional(rollbackFor = Exception.class)
public String addProfileImage(Long userId, MultipartFile file) {
    // ... implementation
}
```

### **6. Security Configuration Issues**

**Problem**: Security blocking multipart requests

**Fix**:
```java
@Configuration
@EnableWebSecurity
public class SecurityConfig {
    
    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            .csrf(csrf -> csrf.disable()) // For file uploads
            .authorizeHttpRequests(auth -> auth
                .requestMatchers("/api/users/me/profile-image").authenticated()
                .anyRequest().permitAll()
            );
        return http.build();
    }
}
```

## 🔍 **DEBUGGING STEPS**

### **Step 1: Check Backend Logs**
Look for the actual exception in your backend logs:
```bash
# Check application logs
tail -f /path/to/your/app.log

# Or if using Docker
docker logs your-container-name -f
```

### **Step 2: Add Debug Logging**
```java
@PostMapping("/api/users/me/profile-image")
public ResponseEntity<UserResponse> uploadProfileImage(
    @RequestParam("file") MultipartFile file,
    Authentication authentication) {
    
    log.info("=== PROFILE IMAGE UPLOAD DEBUG ===");
    log.info("File name: {}", file.getOriginalFilename());
    log.info("File size: {} bytes", file.getSize());
    log.info("Content type: {}", file.getContentType());
    log.info("User: {}", authentication.getName());
    log.info("Upload directory: {}", uploadDir);
    
    try {
        // ... rest of implementation
    } catch (Exception e) {
        log.error("PROFILE IMAGE UPLOAD ERROR:", e);
        throw e;
    }
}
```

### **Step 3: Test File System Access**
```java
@GetMapping("/api/test/file-system")
public ResponseEntity<String> testFileSystem() {
    try {
        Path uploadPath = Paths.get(uploadDir);
        
        // Test directory creation
        if (!Files.exists(uploadPath)) {
            Files.createDirectories(uploadPath);
        }
        
        // Test file write
        Path testFile = uploadPath.resolve("test.txt");
        Files.write(testFile, "test".getBytes());
        Files.delete(testFile);
        
        return ResponseEntity.ok("File system access OK");
    } catch (Exception e) {
        return ResponseEntity.status(500).body("File system error: " + e.getMessage());
    }
}
```

## 🎯 **IMMEDIATE ACTION PLAN**

1. **Check backend logs** for the actual exception
2. **Verify upload directory** exists and has write permissions
3. **Add debug logging** to the controller method
4. **Test the `/api/test/file-system` endpoint** (add it temporarily)
5. **Check database connectivity** and user existence
6. **Verify multipart configuration** in application.properties

The Flutter code is perfect - focus on the backend file handling and database operations!
