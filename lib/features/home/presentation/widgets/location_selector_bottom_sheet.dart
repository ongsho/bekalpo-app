import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../../../../core/models/division.dart';
import '../../../../core/models/district.dart';
import '../../../../core/models/thana.dart';
import '../../../../core/providers/location_provider.dart';

class LocationSelectorBottomSheet extends ConsumerStatefulWidget {
  final Function(Division division, District district, Thana area)?
  onLocationSelected;

  const LocationSelectorBottomSheet({super.key, this.onLocationSelected});

  @override
  ConsumerState<LocationSelectorBottomSheet> createState() =>
      _LocationSelectorBottomSheetState();
}

class _LocationSelectorBottomSheetState
    extends ConsumerState<LocationSelectorBottomSheet> {
  Division? _selectedDivision;
  District? _selectedDistrict;
  Thana? _selectedArea;

  @override
  Widget build(BuildContext context) {
    final locationState = ref.watch(locationProvider);
    final theme = Theme.of(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildHeader(theme),
          Expanded(child: _buildContent(locationState, theme)),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Select Location',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.pop(context),
                  splashColor: theme.colorScheme.primary.withOpacity(0.15),
                  highlightColor: theme.colorScheme.primary.withOpacity(0.1),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: theme.colorScheme.primary),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSelectionSteps(theme),
        ],
      ),
    );
  }

  Widget _buildSelectionSteps(ThemeData theme) {
    return Row(
      children: [
        _buildStepIndicator(1, _selectedDivision != null, 'Division', theme),
        _buildStepConnector(_selectedDivision != null, theme),
        _buildStepIndicator(2, _selectedDistrict != null, 'District', theme),
        _buildStepConnector(_selectedDistrict != null, theme),
        _buildStepIndicator(3, _selectedArea != null, 'Area', theme),
      ],
    );
  }

  Widget _buildStepIndicator(
    int step,
    bool isCompleted,
    String label,
    ThemeData theme,
  ) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted ? theme.colorScheme.primary : theme.dividerColor,
          ),
          child: Center(
            child: isCompleted
                ? Icon(Icons.check, color: theme.colorScheme.surface, size: 18)
                : Text(
                    step.toString(),
                    style: TextStyle(
                      color: theme.colorScheme.surface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isCompleted
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withOpacity(0.6),
            fontWeight: isCompleted ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStepConnector(bool isConnected, ThemeData theme) {
    return Container(
      width: 30,
      height: 2,
      margin: const EdgeInsets.only(bottom: 20),
      color: isConnected ? theme.colorScheme.primary : theme.dividerColor,
    );
  }

  Widget _buildContent(LocationState locationState, ThemeData theme) {
    if (locationState.isLoading) {
      return Center(
        child: CircularProgressIndicator(color: theme.colorScheme.primary),
      );
    }

    if (locationState.error != null) {
      return _buildErrorState(locationState.error!, () {
        ref.read(locationProvider.notifier).refreshLocations();
      }, theme);
    }

    if (_selectedDivision == null) {
      return _buildDivisionList(locationState.allDivisions, theme);
    } else if (_selectedDistrict == null) {
      return _buildDistrictList(theme);
    } else {
      return _buildAreaList(theme);
    }
  }

  Widget _buildDivisionList(List<Division> divisions, ThemeData theme) {
    if (divisions.isEmpty) {
      return _buildEmptyState('No divisions available', theme);
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: divisions.length,
      itemBuilder: (context, index) {
        final division = divisions[index];
        return _buildDivisionTile(division, theme);
      },
    );
  }

  Widget _buildDivisionTile(Division division, ThemeData theme) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() {
            _selectedDivision = division;
            _selectedDistrict = null;
            _selectedArea = null;
          });
        },
        splashColor: theme.colorScheme.primary.withOpacity(0.15),
        highlightColor: theme.colorScheme.primary.withOpacity(0.1),
        child: ListTile(
          title: Text(
            division.nameEn ?? '',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface,
            ),
          ),
          subtitle: division.nameBn != null
              ? Text(
                  division.nameBn!,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                )
              : null,
          trailing: Icon(
            Icons.chevron_right,
            color: theme.colorScheme.onSurface.withOpacity(0.4),
          ),
        ),
      ),
    );
  }

  Widget _buildDistrictList(ThemeData theme) {
    if (_selectedDivision?.districts == null ||
        _selectedDivision!.districts!.isEmpty) {
      return _buildEmptyState('No districts available', theme);
    }
    return Column(
      children: [
        _buildBackButton(
          () {
            setState(() {
              _selectedDivision = null;
              _selectedDistrict = null;
              _selectedArea = null;
            });
          },
          _selectedDivision?.nameEn ?? '',
          theme,
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: _selectedDivision!.districts!.length,
            itemBuilder: (context, index) {
              final district = _selectedDivision!.districts![index];
              return _buildDistrictTile(district, theme);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDistrictTile(District district, ThemeData theme) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() {
            _selectedDistrict = district;
            _selectedArea = null;
          });
        },
        splashColor: theme.colorScheme.primary.withOpacity(0.15),
        highlightColor: theme.colorScheme.primary.withOpacity(0.1),
        child: ListTile(
          title: Text(
            district.nameEn ?? '',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface,
            ),
          ),
          subtitle: district.nameBn != null
              ? Text(
                  district.nameBn!,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                )
              : null,
          trailing: Icon(
            Icons.chevron_right,
            color: theme.colorScheme.onSurface.withOpacity(0.4),
          ),
        ),
      ),
    );
  }

  Widget _buildAreaList(ThemeData theme) {
    if (_selectedDistrict?.thanas == null ||
        _selectedDistrict!.thanas!.isEmpty) {
      return _buildEmptyState('No areas available', theme);
    }
    return Column(
      children: [
        _buildBackButton(
          () {
            setState(() {
              _selectedDistrict = null;
              _selectedArea = null;
            });
          },
          _selectedDistrict?.nameEn ?? '',
          theme,
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: _selectedDistrict!.thanas!.length,
            itemBuilder: (context, index) {
              final area = _selectedDistrict!.thanas![index];
              return _buildAreaTile(area, theme);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAreaTile(Thana area, ThemeData theme) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          HapticFeedback.mediumImpact();
          if (_selectedDivision != null && _selectedDistrict != null) {
            if (widget.onLocationSelected != null) {
              // Callback mode - just return the selection
              widget.onLocationSelected!(
                _selectedDivision!,
                _selectedDistrict!,
                area,
              );
              if (mounted) {
                Navigator.pop(context);
              }
            } else {
              // Original mode - save to provider
              await ref
                  .read(locationProvider.notifier)
                  .saveLocation(
                    division: _selectedDivision!,
                    district: _selectedDistrict!,
                    area: area,
                  );
              if (mounted) {
                Navigator.pop(context, true);
              }
            }
          }
        },
        splashColor: theme.colorScheme.primary.withOpacity(0.15),
        highlightColor: theme.colorScheme.primary.withOpacity(0.1),
        child: ListTile(
          title: Text(
            area.nameEn ?? '',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface,
            ),
          ),
          subtitle: area.nameBn != null
              ? Text(
                  area.nameBn!,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                )
              : null,
          trailing: Icon(Icons.check_circle, color: theme.colorScheme.primary),
        ),
      ),
    );
  }

  Widget _buildBackButton(VoidCallback onTap, String title, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          splashColor: theme.colorScheme.primary.withOpacity(0.15),
          highlightColor: theme.colorScheme.primary.withOpacity(0.1),
          child: Row(
            children: [
              Icon(
                Icons.arrow_back,
                size: 20,
                color: theme.colorScheme.onSurface,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(
    String message,
    VoidCallback onRetry,
    ThemeData theme,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: theme.colorScheme.onSurface.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 48,
              color: theme.colorScheme.onSurface.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
