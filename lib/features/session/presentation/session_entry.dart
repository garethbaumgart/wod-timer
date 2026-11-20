import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:wod_timer/core/presentation/router/app_routes.dart';
import 'package:wod_timer/features/session/application/session_draft.dart';
import 'package:wod_timer/features/session/application/session_store.dart';
import 'package:wod_timer/features/session/domain/session_block.dart';
import 'package:wod_timer/features/timer/application/providers/timer_providers.dart';
import 'package:wod_timer/features/timer/presentation/widgets/setup_scaffold.dart';

/// "+ THEN" on a setup screen (2.6.0): a new Today's WOD whose first block
/// is [first], the values on screen, in the builder with the add sheet up.
/// The values are remembered as that mode's last, as START would, without
/// making it the tablet's last mode started.
SetupCapsule thenCapsule({
  required BuildContext context,
  required WidgetRef ref,
  required SessionBlock Function() first,
}) => SetupCapsule(
  label: '+ THEN',
  semanticsLabel: "Then: start Today's WOD with this as its first block",
  onTap: () {
    final block = first();
    ref.read(hapticServiceProvider).lightImpact();
    unawaited(ref.read(sessionStoreProvider).rememberBlock(block));
    ref.read(sessionDraftProvider.notifier).open([block], BuilderSource.then);
    context.go(AppRoutes.todaysWodPath(addBlock: true));
  },
);
