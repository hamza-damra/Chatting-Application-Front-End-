# Flutter Chat Application

A modern, professional real-time messaging application built with Flutter and Spring Boot backend.

![Flutter Version](https://img.shields.io/badge/Flutter-3.24-blue)
![License](https://img.shields.io/badge/License-MIT-green)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web%20%7C%20Desktop-lightgrey)

## Overview

This chat application provides a comprehensive messaging experience with real-time communication, advanced file sharing, user blocking system, and a modern professional UI. Built with Flutter and Spring Boot, it works seamlessly across multiple platforms with enterprise-grade features.

## ✨ Features

### 🚀 Core Features
- **Real-time Messaging**: Instant message delivery using WebSocket and STOMP
- **File Sharing**: Support for images, videos, documents, and audio files with chunked upload
- **User Authentication**: Secure JWT-based login and registration system
- **Message Status**: Read receipts and delivery status indicators
- **Responsive UI**: Works seamlessly on mobile, tablet, and desktop
- **Theme Support**: Beautiful light and dark mode options

### 💬 Chat Features
- **Private Chats**: One-on-one conversations with online status indicators
- **Group Chats**: Multi-user group conversations with member management
- **Modern Chat UI**: Professional, pretty, and modern chat room items with gradients and shadows
- **Unread Message Notifications**: Real-time unread count badges with smart presence tracking
- **Message Types**: Text, images, videos, documents, and audio support
- **File Attachments**: Drag-and-drop file uploads with progress indicators

### 🔒 Security & Privacy
- **User Blocking System**: Comprehensive blocking/unblocking functionality with confirmation dialogs
- **Blocked User Indicators**: Visual indicators for blocked users in chat lists
- **Secure File Access**: Protected file uploads and downloads with access control
- **JWT Authentication**: Secure token-based authentication with refresh tokens

### 🎨 UI/UX Improvements
- **Modern Design**: Professional chat list items with enhanced styling
- **Smooth Animations**: Elegant transitions and loading states with shimmer effects
- **Enhanced Avatars**: Gradient avatars with online status indicators
- **Smart Notifications**: Context-aware push notifications that respect user presence
- **Responsive Layout**: Adaptive UI that works across all screen sizes

## Screenshots

[Add screenshots here]

## 🛠️ Technology Stack

- **Frontend**: Flutter 3.24+ with Material Design 3
- **Backend**: Spring Boot with WebSocket support
- **State Management**: Provider and Bloc patterns
- **Networking**: HTTP, WebSockets, STOMP
- **UI Components**: Custom widgets with Material Design 3
- **Authentication**: JWT tokens with secure storage
- **File Storage**: Chunked upload with progress tracking
- **Notifications**: Local and push notifications

## 📦 Key Dependencies

- **HTTP & WebSocket**: http, dio, web_socket_channel, stomp_dart_client
- **Chat UI**: flutter_chat_ui, flutter_chat_types, flutter_chat_core
- **State Management**: provider, flutter_bloc, bloc, equatable
- **Utilities**: image_picker, shared_preferences, path_provider, intl
- **UI**: google_fonts, flutter_svg, cached_network_image, shimmer
- **Notifications**: flutter_local_notifications
- **Media**: video_player, photo_view, file_picker

## Getting Started

### Prerequisites

- Flutter SDK 3.24 or higher
- Dart SDK 3.1 or higher
- Android Studio / VS Code with Flutter extensions

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/hamza-damra/Chatting-Application-Front-End-.git
   ```

2. Navigate to the project directory:
   ```bash
   cd chatting_application
   ```

3. Install dependencies:
   ```bash
   flutter pub get
   ```

4. Run the application:
   ```bash
   flutter run
   ```

## 🆕 Recent Improvements

### Modern Chat UI Redesign
- **Professional Chat List Items**: Completely redesigned chat room items with modern styling
- **Enhanced Avatars**: Beautiful gradient avatars with improved online status indicators
- **Better Shadows & Elevation**: Professional depth and visual hierarchy
- **Improved Typography**: Better font weights, spacing, and readability
- **Smart Unread Badges**: Modern gradient badges with 99+ overflow handling

### User Blocking System
- **Comprehensive Blocking**: Full user blocking/unblocking functionality
- **Visual Indicators**: Clear blocked user indicators in chat lists
- **Confirmation Dialogs**: User-friendly confirmation dialogs for blocking actions
- **Blocked Users Management**: Dedicated screen for managing blocked users
- **Chat Input Freezing**: Automatic chat input disabling for blocked users

### Enhanced File Upload
- **Chunked Upload**: Improved file upload with chunked processing
- **Progress Tracking**: Real-time upload progress indicators
- **Multiple File Types**: Support for various file formats
- **Error Handling**: Comprehensive error handling and retry mechanisms

### Performance & UX
- **Shimmer Loading**: Beautiful shimmer effects instead of basic loading indicators
- **Smooth Animations**: Enhanced transitions and micro-interactions
- **Better Error Handling**: Professional error messages and recovery options
- **Responsive Design**: Improved layout adaptation across different screen sizes

## Configuration

The application can be configured by modifying the `lib/config/api_config.dart` file:

- Set the API base URL
- Configure WebSocket endpoints
- Adjust timeout settings

## Architecture

This project follows a clean architecture approach with:

- **Presentation Layer**: UI components and Bloc/Provider state management
- **Domain Layer**: Business logic and use cases
- **Data Layer**: API services and local storage

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Flutter team for the amazing framework
- All the package authors that made this project possible
