import 'package:flutter/material.dart';
import 'package:grocery_app/services/app_wide_refresh.dart';

/// Allows [RefreshIndicator] to react to nested vertical scrollables (not only depth == 0).
bool appWideRefreshNotificationPredicate(ScrollNotification notification) {
  final ScrollMetrics m = notification.metrics;
  if (m.axis != Axis.vertical) return false;

  if (notification is OverscrollNotification && notification.overscroll < 0) {
    return true;
  }

  if (notification is ScrollUpdateNotification &&
      notification.dragDetails != null &&
      m.extentBefore == 0) {
    return true;
  }

  return false;
}

/// Wraps the navigator subtree so pull-down refreshes shared app data on every route.
///
/// Routes whose root is fully non-scrollable (e.g. a splash [Stack]) will not show
/// overscroll; most screens use a [ListView]/[GridView]/[SingleChildScrollView] and work.
class GlobalPullToRefreshHost extends StatelessWidget {
  const GlobalPullToRefreshHost({super.key, required this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final Widget body = child ?? const SizedBox.shrink();

    return RefreshIndicator.adaptive(
      edgeOffset: MediaQuery.paddingOf(context).top,
      notificationPredicate: appWideRefreshNotificationPredicate,
      onRefresh: () => AppWideRefresh.refresh(context),
      child: body,
    );
  }
}
