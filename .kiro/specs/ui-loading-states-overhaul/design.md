# Design Document: UI and Loading States Overhaul

## Overview

This design document outlines the architecture and implementation approach for overhauling the Vector messaging application's UI and loading states. The overhaul focuses on creating a unified design system, implementing consistent state management patterns, and ensuring accessibility and responsiveness across all screens.

The existing codebase uses:
- **State Management**: Provider + flutter_bloc (hybrid approach)
- **Theme**: Custom AppTheme with light/dark mode support via ThemeProvider
- **Existing Components**: ShimmerWidgets, ModernBottomNavigation, CustomButton, CustomTextField
- **Architecture**: Clean architecture with presentation/domain/data layers

This design builds upon the existing foundation while introducing new reusable components and standardizing patterns across all screens.

## Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Presentation Layer                        │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐             │
│  │   Screens   │  │   Widgets   │  │    Blocs    │             │
│  │  (Updated)  │  │  (New/Upd)  │  │  (Existing) │             │
│  └─────────────┘  └─────────────┘  └─────────────┘             │
├─────────────────────────────────────────────────────────────────┤
│                      Design System Layer                         │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐             │
│  │   Tokens    │  │ Components  │  │   Themes    │             │
│  │ (Colors,    │  │ (Buttons,   │  │ (Light/Dark)│             │
│  │  Spacing,   │  │  Cards,     │  │             │             │
│  │  Typography)│  │  States)    │  │             │             │
│  └─────────────┘  └─────────────┘  └─────────────┘             │
├─────────────────────────────────────────────────────────────────┤
│                      State Management                            │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────────────────────────┐│
│  │  AsyncState<T> = Loading | Loaded<T> | Error | Empty        ││
│  │  ConnectivityState = Online | Offline                       ││
│  └─────────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────┘
```

### File Structure

```
lib/
├── design_system/
│   ├── tokens/
│   │   ├── app_colors.dart          # Color tokens
│   │   ├── app_spacing.dart         # Spacing constants
│   │   └── app_typography.dart      # Typography scale
│   ├── components/
│   │   ├── app_button.dart          # Enhanced button
│   │   ├── app_text_field.dart      # Enhanced text field
│   │   ├── app_card.dart            # Card component
│   │   ├── app_list_tile.dart       # List tile component
│   │   ├── app_avatar.dart          # Avatar component
│   │   ├── app_badge.dart           # Badge component
│   │   └── app_chip.dart            # Chip component
│   ├── states/
│   │   ├── empty_state_view.dart    # Empty state component
│   │   ├── error_state_view.dart    # Error state component
│   │   ├── skeleton_tile.dart       # Skeleton loading tile
│   │   ├── offline_banner.dart      # Offline indicator
│   │   └── async_state_builder.dart # State builder widget
│   └── theme/
│       └── app_theme_data.dart      # Unified theme configuration
├── widgets/
│   └── ... (existing + updated)
└── screens/
    └── ... (updated screens)
```

## Components and Interfaces

### Design System Tokens

#### AppColors

```dart
abstract class AppColors {
  // Background colors
  Color get background;
  Color get surface;
  Color get surfaceElevated;
  Color get surfaceHighest;
  
  // Text colors
  Color get textPrimary;
  Color get textSecondary;
  Color get textTertiary;
  Color get textOnPrimary;
  
  // Brand colors
  Color get primary;
  Color get primaryLight;
  Color get secondary;
  
  // Semantic colors
  Color get success;
  Color get warning;
  Color get error;
  Color get info;
  
  // Border/Outline colors
  Color get outline;
  Color get outlineVariant;
  Color get divider;
  
  // Shimmer colors
  Color get shimmerBase;
  Color get shimmerHighlight;
}

class LightAppColors implements AppColors { ... }
class DarkAppColors implements AppColors { ... }
```

#### AppSpacing

```dart
abstract class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;
  static const double huge = 48.0;
  
  // Semantic spacing
  static const double cardPadding = lg;
  static const double listItemPadding = lg;
  static const double sectionSpacing = xxl;
  static const double screenPadding = xl;
}
```

#### AppTypography

```dart
abstract class AppTypography {
  TextStyle get displayLarge;   // 28px, bold
  TextStyle get displayMedium;  // 24px, bold
  TextStyle get titleLarge;     // 20px, semibold
  TextStyle get titleMedium;    // 18px, semibold
  TextStyle get titleSmall;     // 16px, semibold
  TextStyle get bodyLarge;      // 16px, regular
  TextStyle get bodyMedium;     // 14px, regular
  TextStyle get bodySmall;      // 12px, regular
  TextStyle get labelLarge;     // 14px, medium
  TextStyle get labelMedium;    // 12px, medium
  TextStyle get labelSmall;     // 10px, medium
  TextStyle get caption;        // 11px, regular
}
```

### State Components

#### AsyncState Generic Type

```dart
sealed class AsyncState<T> {
  const AsyncState();
}

class AsyncLoading<T> extends AsyncState<T> {
  const AsyncLoading();
}

class AsyncLoaded<T> extends AsyncState<T> {
  final T data;
  const AsyncLoaded(this.data);
}

class AsyncError<T> extends AsyncState<T> {
  final String message;
  final Object? error;
  final VoidCallback? onRetry;
  const AsyncError(this.message, {this.error, this.onRetry});
}

class AsyncEmpty<T> extends AsyncState<T> {
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  const AsyncEmpty({this.message, this.actionLabel, this.onAction});
}
```

#### EmptyStateView

```dart
class EmptyStateView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? description;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? customIcon;
  
  // Renders centered column with icon, title, description, and optional action button
}
```

#### ErrorStateView

```dart
class ErrorStateView extends StatelessWidget {
  final String message;
  final String? details;
  final VoidCallback onRetry;
  final bool showDetails;
  final IconData? icon;
  
  // Renders error icon, message, retry button, and expandable details
}
```

#### SkeletonTile

```dart
class SkeletonTile extends StatelessWidget {
  final SkeletonTileType type;
  final bool animate;
  
  // Types: chatItem, groupItem, profileHeader, settingsItem, messageItem
  // Renders shimmer-animated placeholder matching the specified type
}

enum SkeletonTileType {
  chatItem,
  groupItem,
  profileHeader,
  settingsItem,
  messageItem,
}
```

#### OfflineBanner

```dart
class OfflineBanner extends StatelessWidget {
  final bool isOffline;
  final VoidCallback? onRetry;
  
  // Renders animated banner at top of screen when offline
  // Shows "You're offline" with optional retry button
}
```

#### AsyncStateBuilder

```dart
class AsyncStateBuilder<T> extends StatelessWidget {
  final AsyncState<T> state;
  final Widget Function(T data) onLoaded;
  final Widget Function()? onLoading;
  final Widget Function(String message, VoidCallback? onRetry)? onError;
  final Widget Function(String? message, VoidCallback? onAction)? onEmpty;
  
  // Convenience widget that handles all async states with sensible defaults
}
```

### Screen-Specific Components

#### ModernChatListItem (Enhanced)

```dart
class ModernChatListItem extends StatelessWidget {
  final ChatRoom chatRoom;
  final int currentUserId;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  
  // Enhanced to include:
  // - Avatar with online indicator
  // - Name with verified badge support
  // - Last message preview (truncated)
  // - Timestamp (relative formatting)
  // - Unread badge with count
  // - Mute indicator icon
  // - Typing indicator support
}
```

#### SearchBarWidget

```dart
class SearchBarWidget extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool isLoading;
  final VoidCallback? onClear;
  final ValueChanged<String>? onChanged;
  
  // Renders search input with loading indicator and clear button
}
```

## Data Models

### Theme Configuration Model

```dart
class AppThemeConfig {
  final AppColors colors;
  final AppTypography typography;
  final AppSpacing spacing;
  final BorderRadius defaultBorderRadius;
  final Duration defaultAnimationDuration;
  
  // Factory constructors for light and dark themes
  factory AppThemeConfig.light();
  factory AppThemeConfig.dark();
  
  // Convert to Flutter ThemeData
  ThemeData toThemeData();
}
```

### Screen State Models

```dart
class ChatListState {
  final AsyncState<List<ChatRoom>> chats;
  final bool isRefreshing;
  final String? searchQuery;
  final bool isSearching;
}

class ProfileState {
  final AsyncState<UserModel> profile;
  final bool isEditing;
  final bool isSaving;
  final String? saveError;
}

class SettingsState {
  final AsyncState<SettingsData> settings;
  final Map<String, bool> toggleStates;
}
```

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system-essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

Based on the prework analysis, the following correctness properties have been identified:

### Property 1: Design system color tokens completeness
*For any* theme mode (light or dark), the AppColors implementation SHALL provide non-null Color values for all required tokens (background, surface, surfaceElevated, primary, secondary, success, warning, error, textPrimary, textSecondary, outline, shimmerBase, shimmerHighlight).
**Validates: Requirements 1.1**

### Property 2: Typography scale completeness
*For any* AppTypography implementation, all text styles (displayLarge, displayMedium, titleLarge, titleMedium, titleSmall, bodyLarge, bodyMedium, bodySmall, labelLarge, labelMedium, labelSmall, caption) SHALL have defined fontSize and fontWeight properties.
**Validates: Requirements 1.2**

### Property 3: Spacing system consistency
*For any* spacing value in AppSpacing, the value SHALL be a multiple of 4.0 (the base unit).
**Validates: Requirements 1.3**

### Property 4: Dark theme surface differentiation
*For any* dark theme configuration, the surface colors (background, surface, surfaceElevated, surfaceHighest) SHALL NOT be pure black (#000000) and SHALL have distinct luminance values creating visual hierarchy.
**Validates: Requirements 1.5**

### Property 5: State component rendering
*For any* EmptyStateView with required parameters (icon, title), the widget SHALL render without errors and contain the specified icon and title text.
**Validates: Requirements 2.1**

### Property 6: Error state retry functionality
*For any* ErrorStateView with an onRetry callback, tapping the retry button SHALL invoke the callback exactly once.
**Validates: Requirements 2.2, 2.6**

### Property 7: Skeleton tile layout matching
*For any* SkeletonTile of type chatItem, the rendered widget SHALL contain placeholder elements for avatar (circular), title text (rectangular), and subtitle text (rectangular).
**Validates: Requirements 2.3**

### Property 8: Offline banner visibility
*For any* OfflineBanner with isOffline=true, the banner SHALL be visible; with isOffline=false, the banner SHALL be hidden or have zero height.
**Validates: Requirements 2.4, 2.7**

### Property 9: Loading state skeleton display
*For any* screen using AsyncStateBuilder with AsyncLoading state, the builder SHALL render the skeleton/loading UI (not empty content or error view).
**Validates: Requirements 2.5, 4.3, 5.2, 6.3, 7.3**

### Property 10: Form validation feedback
*For any* text field with a validator function, when the validator returns a non-null error string, the field SHALL display that error message visibly below the input.
**Validates: Requirements 3.3**

### Property 11: Form submission loading state
*For any* form with isLoading=true, all input fields SHALL be disabled (not accepting input) AND the submit button SHALL display a loading indicator.
**Validates: Requirements 3.5, 3.6**

### Property 12: Empty state action button
*For any* EmptyStateView with actionLabel and onAction provided, the widget SHALL render a tappable button with the specified label that invokes onAction when tapped.
**Validates: Requirements 4.4, 5.1**

### Property 13: Chat list item information completeness
*For any* ModernChatListItem with a valid ChatRoom, the rendered widget SHALL contain elements displaying: avatar, display name, last message preview, and timestamp.
**Validates: Requirements 4.1, 5.3**

### Property 14: Settings section organization
*For any* SettingsScreen, the widget tree SHALL contain section headers for Account, Notifications, Chat, Media, and About sections in a scrollable layout.
**Validates: Requirements 7.1**

### Property 15: Logout confirmation dialog
*For any* logout action trigger, the system SHALL display a confirmation dialog before executing the logout; canceling the dialog SHALL NOT execute logout.
**Validates: Requirements 7.5**

### Property 16: FAB action labels
*For any* SpeedDial FAB in open state, each child action SHALL have a visible label or tooltip text.
**Validates: Requirements 8.3**

### Property 17: Text scaling layout integrity
*For any* screen rendered with textScaleFactor up to 2.0, the layout SHALL NOT have overflow errors and all text SHALL remain readable.
**Validates: Requirements 9.1**

### Property 18: Interactive element semantics
*For any* interactive widget (button, text field, toggle), the widget SHALL have a non-empty semantic label for accessibility.
**Validates: Requirements 9.2**

### Property 19: Touch target minimum size
*For any* tappable widget, the effective touch target area SHALL be at least 44x44 logical pixels.
**Validates: Requirements 9.6**

### Property 20: Responsive layout adaptation
*For any* screen rendered at width < 600px (mobile), 600-900px (tablet), and > 900px (desktop), the layout SHALL adapt without horizontal overflow.
**Validates: Requirements 9.5**

## Error Handling

### Error Categories

```dart
enum AppErrorType {
  network,      // No internet, timeout, DNS failure
  server,       // 5xx errors, service unavailable
  auth,         // 401, 403, token expired
  validation,   // 400, invalid input
  notFound,     // 404, resource not found
  unknown,      // Unexpected errors
}

class AppError {
  final AppErrorType type;
  final String userMessage;
  final String? technicalDetails;
  final Object? originalError;
  
  // Factory constructors for common error types
  factory AppError.fromDioError(DioException e);
  factory AppError.fromException(Object e);
}
```

### Error Display Strategy

| Error Type | Display Method | User Action |
|------------|----------------|-------------|
| Network | OfflineBanner + ErrorStateView | Retry button |
| Server | ErrorStateView | Retry button |
| Auth | Snackbar + Redirect to login | Re-authenticate |
| Validation | Inline field errors | Fix input |
| NotFound | ErrorStateView | Go back |
| Unknown | ErrorStateView with details | Retry or report |

### Centralized Error Service

```dart
class ErrorService {
  static AppError mapError(Object error);
  static void showError(BuildContext context, AppError error);
  static void showSnackbar(BuildContext context, String message, {bool isError = true});
  static void showRetrySnackbar(BuildContext context, String message, VoidCallback onRetry);
}
```

## Testing Strategy

### Dual Testing Approach

This implementation uses both unit tests and property-based tests:

1. **Unit Tests**: Verify specific examples, edge cases, and integration points
2. **Property-Based Tests**: Verify universal properties that should hold across all inputs

### Property-Based Testing Framework

The project will use the `glados` package for property-based testing in Dart/Flutter:

```yaml
dev_dependencies:
  glados: ^1.1.1
```

### Test Organization

```
test/
├── design_system/
│   ├── tokens/
│   │   ├── app_colors_test.dart
│   │   ├── app_spacing_test.dart
│   │   └── app_typography_test.dart
│   ├── components/
│   │   ├── empty_state_view_test.dart
│   │   ├── error_state_view_test.dart
│   │   ├── skeleton_tile_test.dart
│   │   └── offline_banner_test.dart
│   └── theme/
│       └── app_theme_data_test.dart
├── screens/
│   ├── login_screen_test.dart
│   ├── chats_screen_test.dart
│   ├── groups_screen_test.dart
│   ├── profile_screen_test.dart
│   └── settings_screen_test.dart
├── widgets/
│   ├── modern_chat_list_item_test.dart
│   └── search_bar_widget_test.dart
└── property_tests/
    ├── design_system_properties_test.dart
    ├── state_components_properties_test.dart
    ├── accessibility_properties_test.dart
    └── responsive_layout_properties_test.dart
```

### Key Test Scenarios

#### Design System Tests
- Color token completeness for light/dark themes
- Typography scale consistency
- Spacing value validation
- Theme switching behavior

#### State Component Tests
- EmptyStateView renders with all configurations
- ErrorStateView retry callback invocation
- SkeletonTile layout for each type
- OfflineBanner visibility states
- AsyncStateBuilder state transitions

#### Screen Tests
- Loading state shows skeletons
- Empty state shows EmptyStateView with action
- Error state shows ErrorStateView with retry
- Form validation displays errors
- Form submission disables inputs

#### Accessibility Tests
- Semantic labels on interactive elements
- Touch target sizes
- Text scaling up to 200%
- Color contrast ratios

#### Responsive Tests
- Mobile layout (< 600px)
- Tablet layout (600-900px)
- Desktop layout (> 900px)
