# Chat Application

A modern real-time messaging application built with Flutter.

![Flutter Version](https://img.shields.io/badge/Flutter-3.24-blue)
![License](https://img.shields.io/badge/License-MIT-green)

## Overview

This chat application provides a feature-rich messaging experience with real-time communication, file sharing, and a modern UI. Built with Flutter, it works seamlessly across multiple platforms.

## Features

- **Real-time Messaging**: Instant message delivery using WebSocket and STOMP
- **File Sharing**: Support for images, videos, documents, and audio files
- **User Authentication**: Secure login and registration system
- **Message Status**: Read receipts and delivery status
- **Responsive UI**: Works on mobile, tablet, and desktop
- **Theme Support**: Light and dark mode options

## Screenshots

[Add screenshots here]

## Technology Stack

- **Frontend**: Flutter 3.24+
- **State Management**: Provider and Bloc patterns
- **Networking**: HTTP, WebSockets, STOMP
- **UI Components**: flutter_chat_ui, Material Design 3

## Dependencies

- **HTTP & WebSocket**: http, dio, web_socket_channel, stomp_dart_client
- **Chat UI**: flutter_chat_ui, flutter_chat_types, flutter_chat_core
- **State Management**: provider, flutter_bloc, bloc
- **Utilities**: image_picker, shared_preferences, path_provider
- **UI**: google_fonts, flutter_svg, cached_network_image

## Getting Started

### Prerequisites

- Flutter SDK 3.24 or higher
- Dart SDK 3.1 or higher
- Android Studio / VS Code with Flutter extensions

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/chatting_application.git
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
