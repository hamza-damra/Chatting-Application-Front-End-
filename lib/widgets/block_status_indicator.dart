import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../presentation/blocs/user_blocking/user_blocking_bloc.dart';
import '../core/di/service_locator.dart';

class BlockStatusIndicator extends StatefulWidget {
  final int userId;
  final bool showText;
  final TextStyle? textStyle;
  final double iconSize;
  final Color? iconColor;
  final EdgeInsetsGeometry? padding;

  const BlockStatusIndicator({
    super.key,
    required this.userId,
    this.showText = false,
    this.textStyle,
    this.iconSize = 16,
    this.iconColor,
    this.padding,
  });

  @override
  State<BlockStatusIndicator> createState() => _BlockStatusIndicatorState();
}

class _BlockStatusIndicatorState extends State<BlockStatusIndicator> {
  bool? _isBlocked;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkBlockStatus();
  }

  @override
  void didUpdateWidget(BlockStatusIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.userId != oldWidget.userId) {
      _checkBlockStatus();
    }
  }

  void _checkBlockStatus() {
    setState(() {
      _isLoading = true;
    });
    
    serviceLocator<UserBlockingBloc>().add(CheckUserBlockStatus(widget.userId));
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: serviceLocator<UserBlockingBloc>(),
      child: BlocListener<UserBlockingBloc, UserBlockingState>(
        listener: (context, state) {
          if (state is UserBlockStatusChecked && state.userId == widget.userId) {
            setState(() {
              _isBlocked = state.isBlocked;
              _isLoading = false;
            });
          } else if (state is UserBlocked && state.blockedUser.blockedUser.id == widget.userId) {
            setState(() {
              _isBlocked = true;
              _isLoading = false;
            });
          } else if (state is UserUnblocked && state.userId == widget.userId) {
            setState(() {
              _isBlocked = false;
              _isLoading = false;
            });
          }
        },
        child: _buildIndicator(context),
      ),
    );
  }

  Widget _buildIndicator(BuildContext context) {
    if (_isLoading) {
      return widget.showText
          ? Padding(
              padding: widget.padding ?? EdgeInsets.zero,
              child: Text(
                'Checking...',
                style: widget.textStyle ?? Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            )
          : Padding(
              padding: widget.padding ?? EdgeInsets.zero,
              child: SizedBox(
                width: widget.iconSize,
                height: widget.iconSize,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    widget.iconColor ?? Colors.grey[400]!,
                  ),
                ),
              ),
            );
    }

    // Don't show anything if user is not blocked
    if (_isBlocked != true) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: widget.padding ?? EdgeInsets.zero,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.block,
            size: widget.iconSize,
            color: widget.iconColor ?? Colors.red[600],
          ),
          if (widget.showText) ...[
            const SizedBox(width: 4),
            Text(
              'Blocked',
              style: widget.textStyle ?? Theme.of(context).textTheme.bodySmall?.copyWith(
                color: widget.iconColor ?? Colors.red[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class BlockStatusChip extends StatelessWidget {
  final int userId;
  final VoidCallback? onTap;

  const BlockStatusChip({
    super.key,
    required this.userId,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: serviceLocator<UserBlockingBloc>(),
      child: BlocBuilder<UserBlockingBloc, UserBlockingState>(
        builder: (context, state) {
          bool? isBlocked;
          bool isLoading = false;

          if (state is UserBlockStatusChecked && state.userId == userId) {
            isBlocked = state.isBlocked;
          } else if (state is UserBlocked && state.blockedUser.blockedUser.id == userId) {
            isBlocked = true;
          } else if (state is UserUnblocked && state.userId == userId) {
            isBlocked = false;
          } else if (state is UserBlockingActionLoading && state.userId == userId) {
            isLoading = true;
          }

          // Don't show chip if user is not blocked
          if (isBlocked != true && !isLoading) {
            return const SizedBox.shrink();
          }

          return GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red[300]!),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isLoading)
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                      ),
                    )
                  else
                    Icon(
                      Icons.block,
                      size: 12,
                      color: Colors.red[700],
                    ),
                  const SizedBox(width: 4),
                  Text(
                    isLoading ? 'Checking...' : 'Blocked',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.red[700],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
