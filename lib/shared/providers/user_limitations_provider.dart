import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import '../../data/models/user_limitations.dart';
import '../../data/api_service.dart';
import '../../features/auth/auth_provider.dart';

final logger = Logger();

class UserLimitationsState {
  final UserLimitations? limitations;
  final bool isLoading;
  final String? error;

  UserLimitationsState({this.limitations, this.isLoading = false, this.error});

  UserLimitationsState copyWith({
    UserLimitations? limitations,
    bool? isLoading,
    String? error,
  }) {
    return UserLimitationsState(
      limitations: limitations ?? this.limitations,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class UserLimitationsNotifier extends StateNotifier<UserLimitationsState> {
  final ApiService _apiService;

  UserLimitationsNotifier(this._apiService) : super(UserLimitationsState()) {
    refreshLimitations();
  }

  Future<void> refreshLimitations() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final limitations = await _apiService.getUserLimitations();
      state = state.copyWith(limitations: limitations, isLoading: false);
    } catch (e, stackTrace) {
      logger.e(
        'Error loading user limitations',
        error: e,
        stackTrace: stackTrace,
      );
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load user limitations: ${e.toString()}',
      );
    }
  }

  // Helper method to check if user can make a request
  bool get canMakeRequest {
    return state.limitations?.canMakeRequest ?? false;
  }

  // Helper method to get limit message
  String? get limitMessage {
    return state.limitations?.limitMessage;
  }
}

// Provider for UserLimitationsNotifier
final userLimitationsProvider =
    StateNotifierProvider<UserLimitationsNotifier, UserLimitationsState>((ref) {
      return UserLimitationsNotifier(ref.watch(apiServiceProvider));
    });

// Convenience provider for just the limitations data
final limitationsDataProvider = Provider<UserLimitations?>((ref) {
  return ref.watch(userLimitationsProvider).limitations;
});

// Convenience provider for checking if user can make requests
final canMakeRequestProvider = Provider<bool>((ref) {
  return ref.watch(userLimitationsProvider).limitations?.canMakeRequest ??
      false;
});
