package com.example.chatapp.controller;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import lombok.extern.slf4j.Slf4j;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.HashMap;
import java.util.Map;

/**
 * Debug controller to help diagnose profile image upload issues
 * Add this temporarily to your backend to test various components
 */
@RestController
@RequestMapping("/api/debug")
@Slf4j
public class DebugController {

    @Value("${file.upload-dir:/uploads/profile-images}")
    private String uploadDir;

    /**
     * Test file system access and permissions
     */
    @GetMapping("/file-system")
    public ResponseEntity<Map<String, Object>> testFileSystem() {
        Map<String, Object> result = new HashMap<>();
        
        try {
            Path uploadPath = Paths.get(uploadDir);
            
            // Test directory existence
            result.put("uploadDir", uploadDir);
            result.put("directoryExists", Files.exists(uploadPath));
            result.put("isDirectory", Files.isDirectory(uploadPath));
            result.put("isWritable", Files.isWritable(uploadPath));
            
            // Test directory creation
            if (!Files.exists(uploadPath)) {
                Files.createDirectories(uploadPath);
                result.put("directoryCreated", true);
            }
            
            // Test file write
            Path testFile = uploadPath.resolve("test_" + System.currentTimeMillis() + ".txt");
            Files.write(testFile, "test content".getBytes());
            result.put("fileWriteTest", "SUCCESS");
            
            // Test file read
            String content = new String(Files.readAllBytes(testFile));
            result.put("fileReadTest", content.equals("test content") ? "SUCCESS" : "FAILED");
            
            // Cleanup test file
            Files.delete(testFile);
            result.put("fileDeleteTest", "SUCCESS");
            
            result.put("status", "OK");
            return ResponseEntity.ok(result);
            
        } catch (Exception e) {
            log.error("File system test failed", e);
            result.put("status", "ERROR");
            result.put("error", e.getMessage());
            result.put("errorType", e.getClass().getSimpleName());
            return ResponseEntity.status(500).body(result);
        }
    }

    /**
     * Test multipart file upload without database operations
     */
    @PostMapping("/multipart-test")
    public ResponseEntity<Map<String, Object>> testMultipartUpload(
            @RequestParam("file") MultipartFile file,
            Authentication authentication) {
        
        Map<String, Object> result = new HashMap<>();
        
        try {
            log.info("=== MULTIPART UPLOAD TEST ===");
            log.info("File name: {}", file.getOriginalFilename());
            log.info("File size: {} bytes", file.getSize());
            log.info("Content type: {}", file.getContentType());
            log.info("User: {}", authentication != null ? authentication.getName() : "null");
            
            // Basic file validation
            result.put("fileName", file.getOriginalFilename());
            result.put("fileSize", file.getSize());
            result.put("contentType", file.getContentType());
            result.put("isEmpty", file.isEmpty());
            result.put("user", authentication != null ? authentication.getName() : "null");
            
            if (file.isEmpty()) {
                result.put("status", "ERROR");
                result.put("error", "File is empty");
                return ResponseEntity.badRequest().body(result);
            }
            
            // Test file content access
            byte[] bytes = file.getBytes();
            result.put("bytesRead", bytes.length);
            result.put("firstByte", bytes.length > 0 ? bytes[0] : "none");
            
            // Test file save (without database)
            Path uploadPath = Paths.get(uploadDir);
            if (!Files.exists(uploadPath)) {
                Files.createDirectories(uploadPath);
            }
            
            String filename = "test_" + System.currentTimeMillis() + "_" + file.getOriginalFilename();
            Path filePath = uploadPath.resolve(filename);
            
            Files.copy(file.getInputStream(), filePath);
            result.put("fileSaved", true);
            result.put("savedPath", filePath.toString());
            result.put("savedFileExists", Files.exists(filePath));
            result.put("savedFileSize", Files.size(filePath));
            
            // Cleanup test file
            Files.delete(filePath);
            result.put("testFileDeleted", true);
            
            result.put("status", "SUCCESS");
            return ResponseEntity.ok(result);
            
        } catch (Exception e) {
            log.error("Multipart upload test failed", e);
            result.put("status", "ERROR");
            result.put("error", e.getMessage());
            result.put("errorType", e.getClass().getSimpleName());
            result.put("stackTrace", getStackTrace(e));
            return ResponseEntity.status(500).body(result);
        }
    }

    /**
     * Test authentication and user access
     */
    @GetMapping("/auth-test")
    public ResponseEntity<Map<String, Object>> testAuthentication(Authentication authentication) {
        Map<String, Object> result = new HashMap<>();
        
        try {
            result.put("authenticated", authentication != null);
            
            if (authentication != null) {
                result.put("username", authentication.getName());
                result.put("authorities", authentication.getAuthorities().toString());
                result.put("principal", authentication.getPrincipal().getClass().getSimpleName());
                result.put("isAuthenticated", authentication.isAuthenticated());
            }
            
            result.put("status", "OK");
            return ResponseEntity.ok(result);
            
        } catch (Exception e) {
            log.error("Auth test failed", e);
            result.put("status", "ERROR");
            result.put("error", e.getMessage());
            return ResponseEntity.status(500).body(result);
        }
    }

    /**
     * Test the exact same endpoint as the failing one, but with detailed logging
     */
    @PostMapping("/profile-image-debug")
    public ResponseEntity<Map<String, Object>> debugProfileImageUpload(
            @RequestParam("file") MultipartFile file,
            Authentication authentication) {
        
        Map<String, Object> result = new HashMap<>();
        
        try {
            log.info("=== PROFILE IMAGE DEBUG UPLOAD ===");
            log.info("Upload directory: {}", uploadDir);
            log.info("File: {} ({} bytes, {})", file.getOriginalFilename(), file.getSize(), file.getContentType());
            log.info("User: {}", authentication != null ? authentication.getName() : "null");
            
            // Step 1: Validate authentication
            if (authentication == null || !authentication.isAuthenticated()) {
                result.put("step", "authentication");
                result.put("status", "ERROR");
                result.put("error", "Not authenticated");
                return ResponseEntity.status(401).body(result);
            }
            result.put("authenticationOK", true);
            
            // Step 2: Validate file
            if (file.isEmpty()) {
                result.put("step", "file_validation");
                result.put("status", "ERROR");
                result.put("error", "File is empty");
                return ResponseEntity.badRequest().body(result);
            }
            result.put("fileValidationOK", true);
            
            // Step 3: Test directory access
            Path uploadPath = Paths.get(uploadDir);
            if (!Files.exists(uploadPath)) {
                Files.createDirectories(uploadPath);
                log.info("Created upload directory: {}", uploadPath);
            }
            result.put("directoryOK", true);
            
            // Step 4: Test file save
            String filename = System.currentTimeMillis() + "_debug_" + file.getOriginalFilename();
            Path filePath = uploadPath.resolve(filename);
            Files.copy(file.getInputStream(), filePath);
            result.put("fileSaveOK", true);
            result.put("savedPath", filePath.toString());
            
            // Step 5: Simulate database operation (without actual DB call)
            String imageUrl = "/api/files/download/" + filename;
            result.put("imageUrl", imageUrl);
            result.put("databaseSimulationOK", true);
            
            // Cleanup
            Files.delete(filePath);
            result.put("cleanupOK", true);
            
            result.put("status", "SUCCESS");
            result.put("message", "All steps completed successfully");
            
            return ResponseEntity.ok(result);
            
        } catch (Exception e) {
            log.error("Profile image debug upload failed", e);
            result.put("status", "ERROR");
            result.put("error", e.getMessage());
            result.put("errorType", e.getClass().getSimpleName());
            result.put("stackTrace", getStackTrace(e));
            return ResponseEntity.status(500).body(result);
        }
    }

    private String getStackTrace(Exception e) {
        StringBuilder sb = new StringBuilder();
        for (StackTraceElement element : e.getStackTrace()) {
            sb.append(element.toString()).append("\n");
            if (sb.length() > 1000) break; // Limit stack trace length
        }
        return sb.toString();
    }
}
