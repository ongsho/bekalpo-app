import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/division.dart';
import '../../../../core/models/district.dart';
import '../../../../core/models/thana.dart';
import '../../../../core/providers/location_provider.dart';

class LocationSelectorBottomSheet extends ConsumerStatefulWidget {
  const LocationSelectorBottomSheet({super.key});

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

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildContent(locationState)),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Select Location',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSelectionSteps(),
        ],
      ),
    );
  }

  Widget _buildSelectionSteps() {
    return Row(
      children: [
        _buildStepIndicator(1, _selectedDivision != null, 'Division'),
        _buildStepConnector(_selectedDivision != null),
        _buildStepIndicator(2, _selectedDistrict != null, 'District'),
        _buildStepConnector(_selectedDistrict != null),
        _buildStepIndicator(3, _selectedArea != null, 'Area'),
      ],
    );
  }

  Widget _buildStepIndicator(int step, bool isCompleted, String label) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted ? Colors.blue : Colors.grey.shade300,
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 18)
                : Text(
                    step.toString(),
                    style: const TextStyle(
                      color: Colors.white,
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
            color: isCompleted ? Colors.blue : Colors.grey.shade600,
            fontWeight: isCompleted ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStepConnector(bool isConnected) {
    return Container(
      width: 30,
      height: 2,
      margin: const EdgeInsets.only(bottom: 20),
      color: isConnected ? Colors.blue : Colors.grey.shade300,
    );
  }

  Widget _buildContent(LocationState locationState) {
    if (locationState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (locationState.error != null) {
      return _buildErrorState(locationState.error!, () {
        ref.read(locationProvider.notifier).refreshLocations();
      });
    }

    if (_selectedDivision == null) {
      return _buildDivisionList(locationState.allDivisions);
    } else if (_selectedDistrict == null) {
      return _buildDistrictList();
    } else {
      return _buildAreaList();
    }
  }

  Widget _buildDivisionList(List<Division> divisions) {
    if (divisions.isEmpty) {
      return _buildEmptyState('No divisions available');
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: divisions.length,
      itemBuilder: (context, index) {
        final division = divisions[index];
        return _buildDivisionTile(division);
      },
    );
  }

  Widget _buildDivisionTile(Division division) {
    return ListTile(
      title: Text(
        division.nameEn ?? '',
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: division.nameBn != null ? Text(division.nameBn!) : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        setState(() {
          _selectedDivision = division;
          _selectedDistrict = null;
          _selectedArea = null;
        });
      },
    );
  }

  Widget _buildDistrictList() {
    if (_selectedDivision?.districts == null ||
        _selectedDivision!.districts!.isEmpty) {
      return _buildEmptyState('No districts available');
    }
    return Column(
      children: [
        _buildBackButton(() {
          setState(() {
            _selectedDivision = null;
            _selectedDistrict = null;
            _selectedArea = null;
          });
        }, _selectedDivision?.nameEn ?? ''),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: _selectedDivision!.districts!.length,
            itemBuilder: (context, index) {
              final district = _selectedDivision!.districts![index];
              return _buildDistrictTile(district);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDistrictTile(District district) {
    return ListTile(
      title: Text(
        district.nameEn ?? '',
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: district.nameBn != null ? Text(district.nameBn!) : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        setState(() {
          _selectedDistrict = district;
          _selectedArea = null;
        });
      },
    );
  }

  Widget _buildAreaList() {
    if (_selectedDistrict?.thanas == null ||
        _selectedDistrict!.thanas!.isEmpty) {
      return _buildEmptyState('No areas available');
    }
    return Column(
      children: [
        _buildBackButton(() {
          setState(() {
            _selectedDistrict = null;
            _selectedArea = null;
          });
        }, _selectedDistrict?.nameEn ?? ''),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: _selectedDistrict!.thanas!.length,
            itemBuilder: (context, index) {
              final area = _selectedDistrict!.thanas![index];
              return _buildAreaTile(area);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAreaTile(Thana area) {
    return ListTile(
      title: Text(
        area.nameEn ?? '',
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: area.nameBn != null ? Text(area.nameBn!) : null,
      trailing: const Icon(Icons.check_circle, color: Colors.green),
      onTap: () async {
        if (_selectedDivision != null && _selectedDistrict != null) {
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
      },
    );
  }

  Widget _buildBackButton(VoidCallback onTap, String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            const Icon(Icons.arrow_back, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
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

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
