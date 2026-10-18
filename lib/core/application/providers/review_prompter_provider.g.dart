// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review_prompter_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$reviewPrompterHash() => r'e2b608fe7ad99d7f15cfabf737a467d6720f0f66';

/// Asks for a store rating at a payoff moment, under a deliberately quiet
/// policy (see [ReviewPrompter]). The whole portfolio had zero ratings on both
/// stores as of 6 Sep 2026 because no app had ever asked.
///
/// Copied from [reviewPrompter].
@ProviderFor(reviewPrompter)
final reviewPrompterProvider = Provider<ReviewPrompter>.internal(
  reviewPrompter,
  name: r'reviewPrompterProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$reviewPrompterHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ReviewPrompterRef = ProviderRef<ReviewPrompter>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
