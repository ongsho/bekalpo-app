import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/division.dart';
import '../models/district.dart';
import '../models/thana.dart';
import '../repositories/location_repository.dart';

class LocationState {
  final List<Division> allDivisions;
  final Division? selectedDivision;
  final District? selectedDistrict;
  final Thana? selectedArea;
  final String? areaSlug;
  final String? locationDisplayName;
  final bool isLoading;
  final String? error;

  const LocationState({
    this.allDivisions = const [],
    this.selectedDivision,
    this.selectedDistrict,
    this.selectedArea,
    this.areaSlug,
    this.locationDisplayName,
    this.isLoading = false,
    this.error,
  });

  LocationState copyWith({
    List<Division>? allDivisions,
    Division? selectedDivision,
    District? selectedDistrict,
    Thana? selectedArea,
    String? areaSlug,
    String? locationDisplayName,
    bool? isLoading,
    String? error,
  }) {
    return LocationState(
      allDivisions: allDivisions ?? this.allDivisions,
      selectedDivision: selectedDivision ?? this.selectedDivision,
      selectedDistrict: selectedDistrict ?? this.selectedDistrict,
      selectedArea: selectedArea ?? this.selectedArea,
      areaSlug: areaSlug ?? this.areaSlug,
      locationDisplayName: locationDisplayName ?? this.locationDisplayName,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class LocationNotifier extends StateNotifier<LocationState> {
  final LocationRepository _repository;
  static const String _storageKey = 'selected_location';

  LocationNotifier(this._repository) : super(const LocationState()) {
    _loadPersistedLocation();
    _loadLocations();
  }

  Future<void> _loadPersistedLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final locationData = prefs.getString(_storageKey);

      if (locationData != null) {
        // Parse saved location data
        final parts = locationData.split('|');
        if (parts.length >= 2) {
          state = state.copyWith(
            areaSlug: parts[0],
            locationDisplayName: parts[1],
          );
        }
      }
    } catch (e) {
      // If loading fails, just use default state
      print('Error loading persisted location: $e');
    }
  }

  Future<void> _loadLocations() async {
    state = state.copyWith(isLoading: true);
    try {
      final divisions = await _repository.getLocations();
      state = state.copyWith(allDivisions: divisions, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load locations: $e',
      );
    }
  }

  Future<void> refreshLocations() async {
    await _loadLocations();
  }

  Future<void> saveLocation({
    required Division division,
    required District district,
    required Thana area,
  }) async {
    try {
      final areaSlug = _generateSlug(area.nameEn ?? '');
      final locationDisplayName =
          '${area.nameEn ?? ''}, ${district.nameEn ?? ''}';

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, '$areaSlug|$locationDisplayName');

      state = state.copyWith(
        selectedDivision: division,
        selectedDistrict: district,
        selectedArea: area,
        areaSlug: areaSlug,
        locationDisplayName: locationDisplayName,
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to save location: $e');
    }
  }

  Future<void> clearLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);

      state = const LocationState();
      _loadLocations();
    } catch (e) {
      state = state.copyWith(error: 'Failed to clear location: $e');
    }
  }

  String _generateSlug(String name) {
    return name
        .toLowerCase()
        .replaceAll(' ', '-')
        .replaceAll(RegExp(r'[^\w-]'), '');
  }
}

final locationRepositoryProvider = Provider<LocationRepository>((ref) {
  return LocationRepository();
});

final locationProvider = StateNotifierProvider<LocationNotifier, LocationState>(
  (ref) {
    final repository = ref.watch(locationRepositoryProvider);
    return LocationNotifier(repository);
  },
);
