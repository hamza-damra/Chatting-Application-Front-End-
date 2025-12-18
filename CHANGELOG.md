# Changelog

All notable changes to the Vector messaging application will be documented in this file.

## [2.0.0] - 2024-12-18

### UI and Loading States Overhaul

This release introduces a comprehensive design system overhaul with consistent loading states, empty states, error handling, and accessibility improvements across all screens.

---

## What Changed

### Design System Foundation

A new centralized design system has been added at `lib/design_system/` with the following structure:

```
lib/design_system/
├── tokens/           # Color, spacing, and typography tokens
├── components/       # Reusable UI components
├── states/           # State management components
└── theme/            # Theme configuration
```

#### New Design Tokens
- **Colors** (`app_colors.dart`): Light and dark theme color tokens including background, surface, text, brand, semantic, and shimmer colors
- **Spacing** (`app_spacing.dart`): 4px-based spacing system with semantic spacing constants and responsive breakpoints
- **Typography** (`app_typography.dart`): Complete typography scale from displayLarge to caption

#### New State Components
- **AsyncState**: Sealed class for consistent async state management (Loading, Loaded, Error, Empty)
- **AsyncStateBuilder**: Widget that handles all async states with sensible defaults
- **EmptyStateView**: Displays icon, title, description, and optional action button
- **ErrorStateView**: Displays error icon, message, retry button, and expandable details
- **SkeletonTile**: Shimmer-animated placeholders for different content types
- **OfflineBanner**: Animated connectivity status banner

#### New UI Components
- **AppButton**: Enhanced button with loading state, variants (filled, outlined, text), and destructive styling
- **AppTextField**: Enhanced text field with visual states, validation feedback, and password toggle
- **AppCard**: Consistent card component with elevation and tap interaction
- **AppListTile**: List tile with leading/trailing widgets, chevrons, and switches
- **AppAvatar**: Avatar with image, initials fallback, and online status indicator
- **AppBadge**: Count badge with 99+ truncation
- **AppSpeedDial**: Floating action button with smooth animations and backdrop
- **SearchBarWidget**: Search input with loading indicator and clear button
- **ResponsiveContainer**: Responsive layout wrapper

### Screen Updates

All major screens have been updated to use the new design system:

- **Login Screen**: New form components, loading states, inline validation
- **Chats Screen**: Skeleton loading, empty state with "Start a new chat" action, error handling
- **Groups Screen**: Skeleton loading, empty state with "Create Group" action, error handling
- **Profile Screen**: Skeleton loading, success/error feedback, organized sections
- **Settings Screen**: Section headers, consistent trailing widgets, logout confirmation

### Accessibility Improvements

- Semantic labels on all interactive elements
- Minimum 44x44 touch targets
- Text scaling support up to 200%
- WCAG AA color contrast compliance
- Keyboard navigation support on web

### Performance Optimizations

- `const` constructors throughout design system
- `ListView.builder` for efficient list rendering
- Optimized shimmer animations
- Cached network images with placeholders

---

## How to Customize Theme Tokens

### Colors

Edit `lib/design_system/tokens/app_colors.dart`:

```dart
// Light theme colors
class LightAppColors implements AppColors {
  @override
  Color get primary => const Color(0xFF4A6FE5);  // Change brand color
  
  @override
  Color get background => const Color(0xFFF8F9FC);  // Change background
  
  // ... other color overrides
}

// Dark theme colors
class DarkAppColors implements AppColors {
  @override
  Color get primary => const Color(0xFF4A6FE5);
  
  @override
  Color get background => const Color(0xFF121212);  // Layered, not pure black
  
  // ... other color overrides
}
```

### Spacing

Edit `lib/design_system/tokens/app_spacing.dart`:

```dart
abstract class AppSpacing {
  // Base spacing (multiples of 4)
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  // ...
  
  // Semantic spacing
  static const double cardPadding = lg;
  static const double screenPadding = xl;
  
  // Responsive breakpoints
  static const double breakpointMobile = 600.0;
  static const double breakpointTablet = 900.0;
}
```

### Typography

Edit `lib/design_system/tokens/app_typography.dart`:

```dart
class DefaultAppTypography implements AppTypography {
  @override
  TextStyle get titleLarge => GoogleFonts.poppins(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: textColor,
  );
  
  // ... other text style overrides
}
```

---

## How to Add New Screens with Same Patterns

### 1. Use AsyncStateBuilder for Data Loading

```dart
import 'package:vector/design_system/states/async_state.dart';
import 'package:vector/design_system/states/async_state_builder.dart';

class MyScreen extends StatelessWidget {
  final AsyncState<MyData> state;
  
  @override
  Widget build(BuildContext context) {
    return AsyncStateBuilder<MyData>(
      state: state,
      onLoading: () => _buildSkeletonList(),
      onLoaded: (data) => _buildContent(data),
      onError: (message, onRetry) => ErrorStateView(
        message: message,
        onRetry: onRetry ?? () {},
      ),
      onEmpty: (message, onAction) => EmptyStateView(
        icon: Icons.inbox_outlined,
        title: 'No items yet',
        description: message,
        actionLabel: 'Add Item',
        onAction: onAction,
      ),
    );
  }
}
```

### 2. Use SkeletonTile for Loading States

```dart
import 'package:vector/design_system/states/skeleton_tile.dart';

Widget _buildSkeletonList() {
  return ListView.builder(
    itemCount: 5,
    itemBuilder: (context, index) => const SkeletonTile(
      type: SkeletonTileType.chatItem,
    ),
  );
}
```

### 3. Use Design System Components

```dart
import 'package:vector/design_system/components/app_button.dart';
import 'package:vector/design_system/components/app_text_field.dart';
import 'package:vector/design_system/components/app_card.dart';

// Button with loading state
AppButton(
  label: 'Submit',
  onPressed: _handleSubmit,
  isLoading: _isSubmitting,
  variant: AppButtonVariant.filled,
)

// Text field with validation
AppTextField(
  controller: _emailController,
  label: 'Email',
  errorText: _emailError,
  keyboardType: TextInputType.emailAddress,
)

// Card component
AppCard(
  onTap: () => _navigateToDetail(),
  child: ListTile(
    title: Text('Item Title'),
    subtitle: Text('Item description'),
  ),
)
```

### 4. Use Design Tokens for Styling

```dart
import 'package:vector/design_system/tokens/app_colors.dart';
import 'package:vector/design_system/tokens/app_spacing.dart';

Widget build(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final colors = isDark ? const DarkAppColors() : const LightAppColors();
  
  return Container(
    padding: const EdgeInsets.all(AppSpacing.lg),
    decoration: BoxDecoration(
      color: colors.surface,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      border: Border.all(color: colors.outline),
    ),
    child: Text(
      'Hello',
      style: TextStyle(color: colors.textPrimary),
    ),
  );
}
```

### 5. Handle Offline State

```dart
import 'package:vector/design_system/states/offline_banner.dart';

Widget build(BuildContext context) {
  return Column(
    children: [
      OfflineBanner(
        isOffline: !_isConnected,
        onRetry: _checkConnectivity,
      ),
      Expanded(child: _buildContent()),
    ],
  );
}
```

### 6. Ensure Accessibility

```dart
// Add semantic labels
Semantics(
  button: true,
  label: 'Send message',
  child: IconButton(
    icon: Icon(Icons.send),
    onPressed: _sendMessage,
  ),
)

// Ensure minimum touch targets
SizedBox(
  height: AppSpacing.minTouchTarget,  // 44.0
  width: AppSpacing.minTouchTarget,
  child: IconButton(...),
)
```

### 7. Support Responsive Layouts

```dart
import 'package:vector/design_system/tokens/app_spacing.dart';

Widget build(BuildContext context) {
  final deviceSize = ResponsiveLayout.getDeviceSize(context);
  
  return Padding(
    padding: ResponsiveLayout.getScreenPadding(context),
    child: deviceSize == DeviceSize.mobile
        ? _buildMobileLayout()
        : _buildTabletDesktopLayout(),
  );
}
```

---

## Component Reference

| Component | Location | Purpose |
|-----------|----------|---------|
| `AppColors` | `tokens/app_colors.dart` | Color tokens for light/dark themes |
| `AppSpacing` | `tokens/app_spacing.dart` | Spacing, radius, and breakpoint constants |
| `AppTypography` | `tokens/app_typography.dart` | Typography scale |
| `AsyncState` | `states/async_state.dart` | Sealed class for async states |
| `AsyncStateBuilder` | `states/async_state_builder.dart` | Widget for handling async states |
| `EmptyStateView` | `states/empty_state_view.dart` | Empty state display |
| `ErrorStateView` | `states/error_state_view.dart` | Error state with retry |
| `SkeletonTile` | `states/skeleton_tile.dart` | Loading placeholders |
| `OfflineBanner` | `states/offline_banner.dart` | Connectivity status banner |
| `AppButton` | `components/app_button.dart` | Enhanced button component |
| `AppTextField` | `components/app_text_field.dart` | Enhanced text field |
| `AppCard` | `components/app_card.dart` | Card component |
| `AppListTile` | `components/app_list_tile.dart` | List tile component |
| `AppAvatar` | `components/app_avatar.dart` | Avatar with status |
| `AppBadge` | `components/app_badge.dart` | Count badge |
| `AppSpeedDial` | `components/app_speed_dial.dart` | FAB with actions |
| `SearchBarWidget` | `components/search_bar_widget.dart` | Search input |
| `ResponsiveContainer` | `components/responsive_container.dart` | Responsive wrapper |

---

## Migration Notes

### From Old Components

| Old Component | New Component |
|---------------|---------------|
| `CustomButton` | `AppButton` |
| `CustomTextField` | `AppTextField` |
| `ShimmerWidgets` | `SkeletonTile` |
| Manual loading states | `AsyncStateBuilder` |

### Breaking Changes

- Theme configuration now uses `AppThemeConfig` instead of direct `ThemeData`
- Color access should use `LightAppColors`/`DarkAppColors` instead of `Theme.of(context).colorScheme`
- Spacing should use `AppSpacing` constants instead of hardcoded values

---

## Testing

Property-based tests are included for all design system components:

```bash
flutter test test/design_system/
```

Test files:
- `test/design_system/tokens/design_system_properties_test.dart`
- `test/design_system/states/state_components_properties_test.dart`
- `test/design_system/components/form_components_properties_test.dart`
- `test/design_system/accessibility/accessibility_properties_test.dart`
- `test/design_system/responsive/responsive_layout_properties_test.dart`
