# Implementation Plan

- [-] 1. Set up responsive infrastructure enhancements




  - [x] 1.1 Add ResponsiveMaxWidths constants to design system

    - Create constants in `lib/design_system/tokens/app_spacing.dart`
    - Define max widths: chatList (800), authForm (400), profileSettings (600), userList (600), dialog (400), createGroup (500), mediaGallery (1200), textViewer (800)
    - _Requirements: 1.3, 3.1, 4.1, 5.1, 6.3, 7.1, 7.5_

  - [x] 1.2 Create ResponsiveScaffold helper widget



    - Create `lib/design_system/components/responsive_scaffold.dart`
    - Implement scaffold wrapper that auto-applies ResponsiveContainer to body
    - Support custom maxContentWidth override
    - _Requirements: 1.1, 1.2_

  - [x] 1.3 Write property test for desktop content centering






    - **Property 1: Desktop content centering and max-width constraint**
    - **Validates: Requirements 1.3, 3.1, 3.2, 3.3, 4.1, 4.2, 5.1, 5.2**

  - [ ]* 1.4 Write property test for tablet padding adaptation
    - **Property 2: Tablet padding adaptation**
    - **Validates: Requirements 1.4, 5.5**

- [x] 2. Update ChatScreen for responsiveness





  - [x] 2.1 Wrap ChatScreen message list with ResponsiveContainer


    - Add ResponsiveContainer with maxWidth: 800px around message list
    - Center content on tablet/desktop
    - _Requirements: 2.1_

  - [x] 2.2 Center message input area on desktop

    - Wrap input area with responsive constraints
    - Maintain full-width on mobile
    - _Requirements: 2.2_


  - [x] 2.3 Increase message bubble padding on larger screens
    - Use ResponsiveLayout.value() for padding values
    - Mobile: current padding, Tablet/Desktop: increased padding
    - _Requirements: 2.3_

  - [x] 2.4 Write property test for message bubble width adaptation



    - **Property 10: Message bubble width adaptation**
    - **Validates: Requirements 2.3, 8.2**


- [x] 3. Update authentication screens for consistency





  - [x] 3.1 Verify LoginScreen responsive constraints

    - Ensure max-width is 400px on tablet/desktop (already partially implemented)
    - Verify centering behavior
    - _Requirements: 3.1_

  - [x] 3.2 Update RegisterScreen with responsive constraints


    - Apply same pattern as LoginScreen
    - Max-width 400px, centered on tablet/desktop
    - _Requirements: 3.2_


  - [x] 3.3 Update ForgotPasswordScreen with responsive constraints

    - Apply same pattern as LoginScreen
    - Max-width 400px, centered on tablet/desktop
    - _Requirements: 3.3_

  - [x] 3.4 Write property test for touch target sizes



    - **Property 8: Bottom navigation spacing adaptation (includes touch targets)**
    - **Validates: Requirements 3.5, 8.5**


- [x] 4. Checkpoint - Ensure all tests pass




  - Ensure all tests pass, ask the user if questions arise.


- [x] 5. Update Profile and Settings screens





  - [x] 5.1 Update ProfileScreen with ResponsiveContainer

    - Wrap content with maxWidth: 600px
    - Use card-based layout on tablet/desktop
    - _Requirements: 4.1, 4.3_


  - [x] 5.2 Update SettingsScreen with ResponsiveContainer

    - Wrap content with maxWidth: 600px
    - Ensure section grouping is visually clear on larger screens
    - _Requirements: 4.2, 4.4_

  - [x] 5.3 Write property test for spacing consistency



    - Verify spacing ratios are maintained across screen sizes
    - _Requirements: 4.5_

- [x] 6. Update list screens for responsiveness





  - [x] 6.1 Update PrivateChatList responsive constraints


    - Change maxWidth from 700px to 800px for consistency
    - Use ResponsiveContainer instead of manual ConstrainedBox
    - _Requirements: 5.1_

  - [x] 6.2 Update GroupChatList responsive constraints


    - Apply same pattern as PrivateChatList
    - MaxWidth: 800px, centered on desktop
    - _Requirements: 5.2_

  - [x] 6.3 Update CreatePrivateChatScreen with responsive constraints


    - Wrap user list with ResponsiveContainer maxWidth: 600px
    - _Requirements: 5.3_

  - [x] 6.4 Update AddParticipantsScreen with responsive constraints


    - Wrap user list with ResponsiveContainer maxWidth: 600px
    - _Requirements: 5.4_

  - [x] 6.5 Update BlockedUsersScreen with responsive constraints


    - Wrap list with ResponsiveContainer maxWidth: 600px
    - _Requirements: 5.6_

  - [x] 6.6 Increase list item padding on desktop


    - Use ResponsiveLayout.value() for horizontal padding
    - _Requirements: 5.5_

- [x] 7. Update media and file screens

  - [x] 7.1 Update MediaGalleryScreen grid columns
    - Use ResponsiveLayout.value() for column count
    - 2 columns mobile, 3 tablet, 4+ desktop
    - _Requirements: 6.1_

  - [x] 7.2 Write property test for grid column adaptation

    - **Property 4: Media gallery grid column adaptation**
    - **Validates: Requirements 6.1**

  - [x] 7.3 Update MediaPreviewScreen with max dimensions
    - Constrain media size on large screens
    - Add appropriate margins on desktop
    - _Requirements: 6.2, 6.5_

  - [x] 7.4 Update TextFileViewerScreen with responsive constraints
    - Wrap content with ResponsiveContainer maxWidth: 800px
    - _Requirements: 6.3_

  - [x] 7.5 Update StorageStatsScreen with responsive grid
    - Use responsive grid layout for statistics cards
    - _Requirements: 6.4_


- [x] 8. Checkpoint - Ensure all tests pass




  - Ensure all tests pass, ask the user if questions arise.


- [x] 9. Update dialogs and modals




  - [x] 9.1 Create responsive dialog helper


    - Create utility function for showing responsive dialogs
    - Constrain width to 400px on tablet/desktop
    - _Requirements: 7.1_

  - [x] 9.2 Write property test for dialog max-width



    - **Property 5: Dialog max-width constraint on large screens**
    - **Validates: Requirements 7.1**


  - [x] 9.3 Update bottom sheets to use dialogs on desktop






    - Create helper that shows bottom sheet on mobile, dialog on desktop
    - _Requirements: 7.3_



  - [x] 9.4 Update GroupSettingsScreen modal actions
    - Adapt action layout based on screen width
    - _Requirements: 7.4_



  - [x] 9.5 Update CreateGroupScreen with responsive constraints
    - Wrap form with ResponsiveContainer maxWidth: 500px
    - _Requirements: 7.5_


- [x] 10. Update flexible widgets




  - [x] 10.1 Audit and fix ModernChatListItem flexibility


    - Ensure Flexible/Expanded widgets prevent overflow
    - Test at various widths from 280px to 1920px
    - _Requirements: 8.1_

  - [x] 10.2 Write property test for widget flexibility



    - **Property 6: Widget flexibility - no text overflow**
    - **Validates: Requirements 8.1**

  - [x] 10.3 Update ModernMessageBubble width constraints


    - Adapt max-width percentage based on screen size
    - 75% on mobile, 60% on tablet/desktop
    - _Requirements: 8.2_

  - [x] 10.4 Update SearchBarWidget expansion behavior


    - Ensure proper expansion with max-width constraints
    - _Requirements: 8.4_

  - [x] 10.5 Write property test for search bar expansion



    - **Property 7: Search bar expansion with constraints**
    - **Validates: Requirements 8.4**

  - [x] 10.6 Update ModernBottomNavigation spacing


    - Adapt item spacing based on screen width
    - Maintain minimum 44px touch targets
    - _Requirements: 8.5_

  - [x] 10.7 Update FileAttachmentWidget preview size


    - Adapt preview size based on available width
    - _Requirements: 8.6_


- [-] 11. Implement orientation support




  - [x] 11.1 Add state preservation for orientation changes

    - Use AutomaticKeepAliveClientMixin where needed
    - Preserve scroll positions and input state
    - _Requirements: 9.1, 9.2_

  - [ ] 11.2 Write property test for breakpoint recalculation

    - **Property 3: Responsive breakpoint recalculation on orientation change**
    - **Validates: Requirements 1.5, 9.5**

  - [ ] 11.3 Write property test for state preservation

    - **Property 9: Orientation state preservation**
    - **Validates: Requirements 9.2**


- [x] 12. Final Checkpoint - Ensure all tests pass




  - Ensure all tests pass, ask the user if questions arise.
