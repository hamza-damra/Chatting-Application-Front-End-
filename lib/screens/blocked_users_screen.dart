import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../presentation/blocs/user_blocking/user_blocking_bloc.dart';
import '../domain/models/blocked_user_model.dart';
import '../core/di/service_locator.dart';
import '../widgets/profile_image_widget.dart';

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocProvider(
      create:
          (context) =>
              serviceLocator<UserBlockingBloc>()..add(LoadBlockedUsers()),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Blocked Users',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          backgroundColor: theme.colorScheme.surface,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
            onPressed: () => Navigator.of(context).pop(),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(
              height: 1,
              color: theme.colorScheme.outline.withValues(alpha: 0.1),
            ),
          ),
        ),
        body: Container(
          color: theme.colorScheme.surface,
          child: BlocConsumer<UserBlockingBloc, UserBlockingState>(
            listener: (context, state) {
              if (state is UserBlockingFailure) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: ${state.message}'),
                    backgroundColor: theme.colorScheme.error,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              } else if (state is UserUnblocked) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('User unblocked successfully'),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              }
            },
            builder: (context, state) {
              if (state is UserBlockingLoading) {
                return _buildCenteredLoadingState(theme);
              }

              if (state is UserBlockingFailure) {
                return _buildErrorState(theme, state.message, () {
                  context.read<UserBlockingBloc>().add(LoadBlockedUsers());
                });
              }

              if (state is BlockedUsersLoaded) {
                final blockedUsers = state.blockedUsers;
                final filteredUsers = _filterUsers(blockedUsers);

                // Handle empty state with proper centering
                if (blockedUsers.isEmpty) {
                  return _buildEmptyState(theme);
                }

                // Handle no results state with search bar at top and centered content
                if (filteredUsers.isEmpty) {
                  return Column(
                    children: [
                      // Search bar at top
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: _buildModernSearchBar(theme),
                      ),
                      // Centered no results state
                      Expanded(child: _buildNoResultsState(theme)),
                    ],
                  );
                }

                // Normal list view with search bar and users
                return Column(
                  children: [
                    // Search bar
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: _buildModernSearchBar(theme),
                    ),

                    // Users list
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () async {
                          context.read<UserBlockingBloc>().add(
                            RefreshBlockedUsers(),
                          );
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          itemCount: filteredUsers.length,
                          itemBuilder: (context, index) {
                            return _buildModernUserCard(
                              context,
                              filteredUsers[index],
                              theme,
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                );
              }

              return _buildCenteredLoadingState(theme);
            },
          ),
        ),
      ),
    );
  }

  List<BlockedUserModel> _filterUsers(List<BlockedUserModel> users) {
    if (_searchQuery.isEmpty) return users;

    return users.where((blockedUser) {
      final user = blockedUser.blockedUser;
      return user.fullName.toLowerCase().contains(_searchQuery) ||
          user.username.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  Widget _buildErrorState(
    ThemeData theme,
    String message,
    VoidCallback onRetry,
  ) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Error loading blocked users',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenteredLoadingState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: theme.colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            'Loading blocked users...',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.block,
                size: 48,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Blocked Users',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Users you block will appear here',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsState(ThemeData theme) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off,
                size: 48,
                color: theme.colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Results Found',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No users found matching "$_searchQuery"',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernSearchBar(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: TextField(
        controller: _searchController,
        style: theme.textTheme.bodyLarge,
        decoration: InputDecoration(
          hintText: 'Search blocked users...',
          hintStyle: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          prefixIcon: Icon(
            Icons.search,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          suffixIcon:
              _searchQuery.isNotEmpty
                  ? IconButton(
                    icon: Icon(
                      Icons.clear,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    onPressed: () {
                      _searchController.clear();
                    },
                  )
                  : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildModernUserCard(
    BuildContext context,
    BlockedUserModel blockedUser,
    ThemeData theme,
  ) {
    final user = blockedUser.blockedUser;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Modern Avatar using ProfileImageWidget
          ProfileImageWidget(
            userId: user.id,
            userName: user.fullName,
            size: 56,
            backgroundColor: theme.colorScheme.primary,
            textColor: theme.colorScheme.onPrimary,
          ),
          const SizedBox(width: 16),

          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '@${user.username}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Blocked on ${_formatDate(blockedUser.blockedAt)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                if (blockedUser.reason != null &&
                    blockedUser.reason!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Reason: ${blockedUser.reason}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.secondary,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Modern Unblock button
          BlocBuilder<UserBlockingBloc, UserBlockingState>(
            builder: (context, state) {
              final isUnblocking =
                  state is UserBlockingActionLoading &&
                  state.action == 'unblocking' &&
                  state.userId == user.id;

              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.shadow.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed:
                      isUnblocking
                          ? null
                          : () => _showUnblockDialog(
                            context,
                            user.id,
                            user.fullName,
                          ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.secondary,
                    foregroundColor: theme.colorScheme.onSecondary,
                    disabledBackgroundColor: theme.colorScheme.onSurface
                        .withValues(alpha: 0.12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  child:
                      isUnblocking
                          ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                theme.colorScheme.onSecondary,
                              ),
                            ),
                          )
                          : const Text('Unblock'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showUnblockDialog(BuildContext context, int userId, String userName) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            backgroundColor: theme.colorScheme.surfaceContainerLowest,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              'Unblock User',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            content: Text(
              'Are you sure you want to unblock $userName?',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.onSurface.withValues(
                    alpha: 0.6,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  context.read<UserBlockingBloc>().add(UnblockUser(userId));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Unblock'),
              ),
            ],
          ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
