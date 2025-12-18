# Implementation Plan

- [x] 1. Set up design system foundation






  - [x] 1.1 Create design system directory structure and token files

    - Create `lib/design_system/tokens/` directory
    - Create `app_colors.dart` with LightAppColors and DarkAppColors classes
    - Create `app_spacing.dart` with spacing constants
    - Create `app_typography.dart` with typography scale
    - _Requirements: 1.1, 1.2, 1.3_


  - [ ] 1.2 Write property tests for design system tokens
    - **Property 1: Design system color tokens completeness**
    - **Property 2: Typography scale completeness**
    - **Property 3: Spacing system consistency**


    - **Property 4: Dark theme surface differentiation**
    - **Validates: Requirements 1.1, 1.2, 1.3, 1.5**
  - [-] 1.3 Create unified theme configuration

    - Create `lib/design_system/theme/app_theme_data.dart`


    - Implement AppThemeConfig class with light/dark factory constructors
    - Implement toThemeData() conversion method
    - Update ThemeProvider to use new AppThemeConfig
    - _Requirements: 1.4, 1.5, 1.6_

- [x] 2. Implement state management components



  - [x] 2.1 Create AsyncState sealed class and AsyncStateBuilder

    - Create `lib/design_system/states/async_state.dart` with AsyncState types
    - Create `lib/design_system/states/async_state_builder.dart` widget
    - _Requirements: 2.5, 2.6_

  - [x] 2.2 Create EmptyStateView component

    - Create `lib/design_system/states/empty_state_view.dart`
    - Implement with icon, title, description, and optional action button
    - Use design system tokens for styling
    - _Requirements: 2.1_

  - [x] 2.3 Write property test for EmptyStateView

    - **Property 5: State component rendering**
    - **Property 12: Empty state action button**
    - **Validates: Requirements 2.1, 4.4, 5.1**
  - [x] 2.4 Create ErrorStateView component


    - Create `lib/design_system/states/error_state_view.dart`
    - Implement with error icon, message, retry button, and expandable details
    - Use design system tokens for styling
    - _Requirements: 2.2_
  - [x] 2.5 Write property test for ErrorStateView

    - **Property 6: Error state retry functionality**
    - **Validates: Requirements 2.2, 2.6**
  - [x] 2.6 Create SkeletonTile component


    - Create `lib/design_system/states/skeleton_tile.dart`
    - Implement SkeletonTileType enum (chatItem, groupItem, profileHeader, settingsItem)
    - Create shimmer-animated placeholders for each type
    - _Requirements: 2.3_
  - [x] 2.7 Write property test for SkeletonTile

    - **Property 7: Skeleton tile layout matching**
    - **Validates: Requirements 2.3**

  - [x] 2.8 Create OfflineBanner component

    - Create `lib/design_system/states/offline_banner.dart`
    - Implement animated banner with connectivity status
    - Integrate with ConnectivityService
    - _Requirements: 2.4, 2.7_
  - [x] 2.9 Write property test for OfflineBanner

    - **Property 8: Offline banner visibility**
    - **Validates: Requirements 2.4, 2.7**


- [x] 3. Checkpoint - Ensure all tests pass




  - Ensure all tests pass, ask the user if questions arise.

- [x] 4. Create reusable UI components





  - [x] 4.1 Create enhanced AppButton component


    - Create `lib/design_system/components/app_button.dart`
    - Support loading state with spinner inside button
    - Support outlined, filled, and text variants
    - Support destructive styling for logout/delete actions
    - _Requirements: 3.6, 7.4_

  - [x] 4.2 Create enhanced AppTextField component

    - Create `lib/design_system/components/app_text_field.dart`
    - Implement visual states: default, focused, error, disabled
    - Support inline validation error display
    - Support password visibility toggle with accessibility label
    - _Requirements: 3.2, 3.3, 3.4_


  - [ ] 4.3 Write property tests for form components
    - **Property 10: Form validation feedback**


    - **Property 11: Form submission loading state**
    - **Validates: Requirements 3.3, 3.5, 3.6**
  - [x] 4.4 Create AppCard component


    - Create `lib/design_system/components/app_card.dart`
    - Implement with consistent elevation, border radius, and padding
    - Support tap interaction with ripple effect


    - _Requirements: 1.4_
  - [ ] 4.5 Create AppListTile component
    - Create `lib/design_system/components/app_list_tile.dart`


    - Support leading icon/avatar, title, subtitle, trailing widget
    - Support chevron for navigation items, switch for toggles
    - _Requirements: 7.2_


  - [ ] 4.6 Create AppAvatar component
    - Create `lib/design_system/components/app_avatar.dart`

    - Support image, initials fallback, and online status indicator

    - Support multiple sizes (small, medium, large)
    - _Requirements: 4.1, 6.1_
  - [ ] 4.7 Create AppBadge component
    - Create `lib/design_system/components/app_badge.dart`
    - Support count display with 99+ truncation
    - Support different colors for different badge types
    - _Requirements: 4.1_
  - [ ] 4.8 Create SearchBarWidget component
    - Create `lib/design_system/components/search_bar_widget.dart`
    - Implement with loading indicator during search
    - Support clear button and search icon
    - _Requirements: 4.2_

- [x] 5. Update Login Screen





  - [x] 5.1 Refactor LoginScreen to use new design system components


    - Replace CustomTextField with AppTextField
    - Replace CustomButton with AppButton
    - Update styling to use design system tokens
    - _Requirements: 3.1, 3.2_
  - [x] 5.2 Implement form loading state behavior

    - Disable all inputs during authentication
    - Show loading spinner in submit button
    - _Requirements: 3.5, 3.6_
  - [x] 5.3 Implement error feedback

    - Show error snackbar or inline banner on authentication failure
    - Clear error state on retry
    - _Requirements: 3.7_
  - [x] 5.4 Ensure responsive layout

    - Test and fix layout at mobile, tablet, and web sizes
    - _Requirements: 3.8_

- [x] 6. Update Chats Screen (Private Chat List)

  - [x] 6.1 Enhance ModernChatListItem component
    - Update to use design system components (AppAvatar, AppBadge)
    - Ensure all required information is displayed
    - _Requirements: 4.1_

  - [ ] 6.2 Write property test for chat list item
    - **Property 13: Chat list item information completeness**
    - **Validates: Requirements 4.1, 5.3**
    - Note: Requires GetIt service locator setup for BlockedUserIndicator dependency

  - [x] 6.3 Implement loading state with skeleton tiles
    - Use SkeletonTile with chatItem type during loading
    - Show appropriate number of skeleton items
    - _Requirements: 4.3_

  - [x] 6.4 Write property test for loading state

    - **Property 9: Loading state skeleton display**
    - **Validates: Requirements 2.5, 4.3**
    - Note: Requires GetIt service locator setup for BlockedUserIndicator dependency

  - [x] 6.5 Implement empty state with EmptyStateView
    - Show EmptyStateView with "Start a new chat" action
    - Use appropriate icon and messaging
    - _Requirements: 4.4_

  - [x] 6.6 Implement error state with ErrorStateView
    - Show ErrorStateView with retry functionality
    - _Requirements: 4.7_

  - [x] 6.7 Add search bar with loading indicator
    - Integrate SearchBarWidget at top of list
    - Show loading indicator during search
    - _Requirements: 4.2_

  - [x] 6.8 Ensure pull-to-refresh works correctly
    - Verify RefreshIndicator is properly configured
    - _Requirements: 4.5_

- [x] 7. Update Groups Screen
  - [x] 7.1 Implement loading state with skeleton tiles
    - Use SkeletonTile with groupItem type during loading
    - _Requirements: 5.2_
  - [x] 7.2 Implement empty state with EmptyStateView
    - Show EmptyStateView with "Create Group" action
    - Use appropriate icon and messaging
    - _Requirements: 5.1_
  - [x] 7.3 Implement error state with ErrorStateView
    - Show ErrorStateView with retry functionality
    - _Requirements: 5.5_
  - [x] 7.4 Ensure pull-to-refresh works correctly
    - Verify RefreshIndicator is properly configured
    - _Requirements: 5.4_

- [x] 8. Checkpoint - Ensure all tests pass





  - Ensure all tests pass, ask the user if questions arise.

- [x] 9. Update Profile Screen



  - [x] 9.1 Refactor profile header card


    - Use AppAvatar with online status indicator
    - Use design system tokens for styling
    - Improve layout and spacing
    - _Requirements: 6.1_


  - [x] 9.2 Improve edit button affordance
    - Make edit button more visually prominent
    - Use consistent icon and styling

    - _Requirements: 6.2_
  - [x] 9.3 Implement loading state with skeleton

    - Use SkeletonTile with profileHeader type
    - Show skeleton for info fields
    - _Requirements: 6.3_
  - [x] 9.4 Implement success/error feedback


    - Show success snackbar on profile update
    - Show error message with retry on failure
    - _Requirements: 6.4, 6.5_

  - [x] 9.5 Organize information in labeled sections


    - Use consistent section headers and spacing
    - _Requirements: 6.6_

- [x] 10. Update Settings Screen



  - [x] 10.1 Organize settings into sections with headers


    - Add section headers for Account, Privacy, Notifications, Chat, Media, About
    - Use consistent styling for headers
    - _Requirements: 7.1_
  - [x] 10.2 Write property test for settings sections


    - **Property 14: Settings section organization**
    - **Validates: Requirements 7.1**

  - [x] 10.3 Update list tiles with consistent trailing widgets
    - Use chevrons for navigation items
    - Use switches for toggle items
    - _Requirements: 7.2_

  - [x] 10.4 Implement loading state for remote settings
    - Use SkeletonTile with settingsItem type

    - _Requirements: 7.3_
  - [x] 10.5 Style logout button as destructive action
    - Use red/destructive color styling

    - _Requirements: 7.4_
  - [x] 10.6 Implement logout confirmation dialog
    - Show confirmation before logout
    - Cancel should not execute logout
    - _Requirements: 7.5_
  - [x] 10.7 Write property test for logout confirmation



    - **Property 15: Logout confirmation dialog**
    - **Validates: Requirements 7.5**


- [x] 11. Enhance Speed Dial FAB


  - [x] 11.1 Update FAB styling and animations


    - Use theme-consistent colors
    - Ensure smooth open/close animations
    - _Requirements: 8.1, 8.5_
  - [x] 11.2 Add backdrop effect when open


    - Implement dim or blur effect behind action items
    - _Requirements: 8.2_


  - [x] 11.3 Add tooltips and labels to action items
    - Ensure "New Chat" and "New Group" labels are visible

    - _Requirements: 8.3_

  - [x] 11.4 Write property test for FAB labels
    - **Property 16: FAB action labels**
    - **Validates: Requirements 8.3**

  - [x] 11.5 Ensure FAB respects safe areas


    - Position FAB to avoid overlapping important UI
    - _Requirements: 8.4_


- [x] 12. Implement accessibility improvements

  - [x] 12.1 Add semantic labels to interactive elements
    - Audit all buttons, text fields, and toggles
    - Add appropriate semantic labels
    - _Requirements: 9.2_

  - [x] 12.2 Write property test for semantic labels
    - **Property 18: Interactive element semantics**
    - **Validates: Requirements 9.2**

  - [x] 12.3 Ensure minimum touch target sizes
    - Audit all tappable widgets
    - Ensure 44x44 minimum touch targets
    - _Requirements: 9.6_

  - [x] 12.4 Write property test for touch targets
    - **Property 19: Touch target minimum size**
    - **Validates: Requirements 9.6**

  - [x] 12.5 Test and fix text scaling
    - Test all screens at 200% text scale
    - Fix any overflow or layout issues
    - _Requirements: 9.1_

  - [x] 12.6 Write property test for text scaling
    - **Property 17: Text scaling layout integrity**
    - **Validates: Requirements 9.1**

  - [x] 12.7 Verify color contrast ratios

    - Check foreground/background contrast meets WCAG AA
    - Fix any contrast issues
    - _Requirements: 9.3_


- [x] 13. Implement responsive layouts



  - [x] 13.1 Test and fix mobile layouts (< 600px)
    - Verify all screens work on small screens
    - Fixed AppButton text overflow on mobile by adding Flexible wrapper
    - _Requirements: 9.5_
  - [x] 13.2 Test and fix tablet layouts (600-900px)

    - Verify all screens adapt appropriately
    - _Requirements: 9.5_

  - [x] 13.3 Test and fix desktop/web layouts (> 900px)

    - Verify all screens work on large screens
    - _Requirements: 9.5_
  - [x] 13.4 Write property test for responsive layouts


    - **Property 20: Responsive layout adaptation**
    - **Validates: Requirements 9.5**


- [x] 14. Performance optimization




  - [x] 14.1 Audit and optimize widget rebuilds


    - Add const constructors where possible
    - Use selective state management
    - _Requirements: 10.2_
  - [x] 14.2 Ensure efficient list rendering


    - Verify ListView.builder is used for all lists
    - _Requirements: 10.1_
  - [x] 14.3 Optimize shimmer animations

    - Ensure shimmer doesn't cause frame drops
    - _Requirements: 10.3_
  - [x] 14.4 Implement image caching with placeholders

    - Use cached network images
    - Show shimmer placeholders during load
    - _Requirements: 10.5_


- [x] 15. Final Checkpoint - Ensure all tests pass




  - Ensure all tests pass, ask the user if questions arise.


- [x] 16. Create documentation






  - [ ] 16.1 Create CHANGELOG.md with UI overhaul summary
    - Document what changed
    - Document where to customize theme tokens
    - Document how to add new screens with same patterns
    - _Requirements: All_
