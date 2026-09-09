import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/division.dart';
import '../../../../core/models/district.dart';
import '../../../../core/models/thana.dart';
import '../../../../core/models/category.dart';
import '../../../../core/models/post_field.dart';
import '../../../../core/models/brand.dart';
import '../../../../core/models/model.dart';
import '../../../../core/providers/post_fields_provider.dart';
import '../../../../core/providers/draft_post_provider.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/brand_provider.dart';
import '../../../../core/providers/model_provider.dart';
import '../../../home/presentation/widgets/location_selector_bottom_sheet.dart';
import '../../../home/presentation/widgets/category_selector_bottom_sheet.dart';
import '../widgets/dynamic_field_renderer.dart';
import '../../../auth/presentation/screens/auth_entry_screen.dart';
import '../../../auth/presentation/screens/phone_add_screen.dart';
import '../../../bottom_nav/presentation/providers/nav_provider.dart';

class PostAddScreen extends ConsumerStatefulWidget {
  const PostAddScreen({super.key});

  @override
  ConsumerState<PostAddScreen> createState() => _PostAddScreenState();
}

class _PostAddScreenState extends ConsumerState<PostAddScreen> {
  // Location selection state
  Division? _selectedDivision;
  District? _selectedDistrict;
  Thana? _selectedArea;
  String? _locationDisplayName;

  // Category selection state
  String? _selectedCategoryId;
  String? _selectedCategoryName;

  // Brand selection state
  Brand? _selectedBrand;
  String? _selectedBrandName;

  // Model selection state
  ProductModel? _selectedModel;
  String? _selectedModelName;

  // Form field values
  final Map<String, dynamic> _fieldValues = {};
  final Map<String, String?> _fieldErrors = {};

  // Validation state
  bool _isFormValid = false;

  // Draft ID tracking
  String? _currentPostId;

  // Track if auth check has been done
  bool _hasCheckedAuth = false;

  @override
  void initState() {
    super.initState();
    // Don't initialize draft in initState to avoid blocking app startup
    // Initialize draft lazily when user interacts with the screen
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final postFieldsState = ref.watch(postFieldsProvider);
    final currentIndex = ref.watch(navIndexProvider);
    final authState = ref.watch(authProvider);

    // Check auth when post-add tab becomes visible (index 2)
    if (currentIndex == 2 && !_hasCheckedAuth) {
      _hasCheckedAuth = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkAuth();
      });
    }

    // Check phone availability
    final hasVerifiedPhone = authState.userPhone != null;
    final hasContacts =
        authState.userContacts != null && authState.userContacts!.isNotEmpty;
    final hasPhone = hasVerifiedPhone || hasContacts;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Ad'),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Phone selector (always show with red alert if missing)
            _buildPhoneSelector(theme, hasPhone),
            const SizedBox(height: 16),

            // Location selector (show when phone exists)
            if (hasPhone) ...[
              _buildLocationSelector(theme),
              const SizedBox(height: 16),

              // Category selector (show when phone exists)
              _buildCategorySelector(theme),
              const SizedBox(height: 16),

              // Brand selector (show when category selected)
              if (_selectedCategoryId != null) ...[
                _buildBrandSelector(theme),
                const SizedBox(height: 16),

                // Model selector (show when brand selected)
                if (_selectedBrand != null) ...[
                  _buildModelSelector(theme),
                  const SizedBox(height: 16),
                ],
              ],
            ],

            // Helper text
            _buildHelperText(theme),
            const SizedBox(height: 24),

            // Dynamic form fields (only show when location, category, brand, and model are selected)
            if (_selectedArea != null &&
                _selectedCategoryId != null &&
                _selectedBrand != null &&
                _selectedModel != null) ...[
              if (postFieldsState.isLoading)
                const Center(child: CircularProgressIndicator())
              else if (postFieldsState.error != null)
                _buildErrorState(postFieldsState.error!, theme)
              else
                _buildDynamicFields(postFieldsState.fields, theme),

              const SizedBox(height: 24),

              // Submit button
              _buildSubmitButton(theme),
            ],
          ],
        ),
      ),
    );
  }

  void _checkAuth() {
    final authState = ref.read(authProvider);

    // Only check if logged in
    if (!authState.isLoggedIn) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (context) => const AuthEntryScreen()));
    }
    // Phone check is now handled by the UI with red alert
  }

  @override
  void dispose() {
    // Don't clear draft on dispose - let it persist for resuming
    super.dispose();
  }

  Future<void> _initializeDraft() async {
    if (_currentPostId != null) {
      print(
        'PostAddScreen: Draft already initialized with ID: $_currentPostId',
      );
      return;
    }

    print('PostAddScreen: Initializing draft...');
    try {
      final postId = await ref
          .read(draftPostProvider.notifier)
          .initializeDraft();
      setState(() {
        _currentPostId = postId;
      });
      print('PostAddScreen: Draft initialized with ID: $postId');
    } catch (e) {
      print('PostAddScreen: Error initializing draft: $e');
      // Continue even if draft initialization fails
    }
  }

  Future<void> _saveDraft() async {
    if (_currentPostId == null) {
      print('PostAddScreen: No draft ID, skipping save');
      return;
    }

    print('PostAddScreen: Saving draft with ID: $_currentPostId');
    try {
      await ref.read(draftPostProvider.notifier).updateDraft({
        'location': _locationDisplayName,
        'category_id': _selectedCategoryId,
        'category_name': _selectedCategoryName,
        'brand_id': _selectedBrand?.id,
        'brand_name': _selectedBrandName,
        'model_id': _selectedModel?.id,
        'model_name': _selectedModelName,
        'field_values': _fieldValues,
      });
      print('PostAddScreen: Draft saved successfully');
    } catch (e) {
      print('PostAddScreen: Error saving draft: $e');
    }
  }

  void _validateForm() {
    // Validate all required fields
    bool isValid = true;

    // Check location
    if (_selectedArea == null) {
      isValid = false;
    }

    // Check category
    if (_selectedCategoryId == null) {
      isValid = false;
    }

    // Check brand
    if (_selectedBrand == null) {
      isValid = false;
    }

    // Check model
    if (_selectedModel == null) {
      isValid = false;
    }

    // Check dynamic fields (skip brand and model since they have dedicated selectors)
    final postFieldsState = ref.read(postFieldsProvider);
    for (final field in postFieldsState.fields) {
      // Skip brand and model fields
      if (field.slug == 'brand' || field.slug == 'model') continue;

      if (field.pivot.isRequired == true &&
          (_fieldValues[field.slug] == null ||
              _fieldValues[field.slug].toString().isEmpty)) {
        isValid = false;
        _fieldErrors[field.slug] = '${field.title} is required';
      }
    }

    setState(() {
      _isFormValid = isValid;
    });
  }

  void _handleSubmit() {
    if (!_isFormValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    // TODO: Implement actual post submission
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Post submission coming soon!')),
    );
  }

  Widget _buildPhoneSelector(ThemeData theme, bool hasPhone) {
    if (hasPhone) {
      final authState = ref.watch(authProvider);
      final userPhone = authState.userPhone;
      final contacts = authState.userContacts;

      // If user has phone in main field
      if (userPhone != null) {
        return InkWell(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: theme.dividerColor),
              borderRadius: BorderRadius.circular(12),
              color: theme.colorScheme.surface,
            ),
            child: Row(
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.phone_outlined,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),

                // Label and value
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Contact Number',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        userPhone,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),

                // Status indicator
                Icon(Icons.check_circle, color: Colors.green, size: 24),
              ],
            ),
          ),
        );
      }

      // If user has multiple contacts, show dropdown
      if (contacts != null && contacts.isNotEmpty) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: theme.dividerColor),
            borderRadius: BorderRadius.circular(12),
            color: theme.colorScheme.surface,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.phone_outlined,
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Label
                  Expanded(
                    child: Text(
                      'Select Contact Number',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ),

                  // Status indicator
                  Icon(Icons.check_circle, color: Colors.green, size: 24),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  hintText: 'Select a phone number',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                items: contacts.map((contact) {
                  final phone = contact.value;
                  final isPrimary = contact.isPrimary == true;
                  return DropdownMenuItem<String>(
                    value: phone,
                    child: Row(
                      children: [
                        Text(phone ?? ''),
                        if (isPrimary) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Primary',
                              style: TextStyle(
                                fontSize: 10,
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    // Store selected phone
                  });
                },
              ),
            ],
          ),
        );
      }
    }

    // No phone available - show gentle warning
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
        color: Colors.orange.withOpacity(0.05),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.phone_outlined, color: Colors.orange, size: 24),
          ),
          const SizedBox(width: 16),

          // Label and message
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add Phone Number',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Required to post ads',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.orange.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          // Add phone button - more subtle
          TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const PhoneAddScreen()),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSelector(ThemeData theme) {
    final isSelected = _selectedArea != null;

    return InkWell(
      onTap: () => _showLocationSelector(),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: theme.dividerColor),
          borderRadius: BorderRadius.circular(12),
          color: theme.colorScheme.surface,
        ),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.location_on_outlined,
                color: theme.colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),

            // Label and value
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Location',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isSelected ? _locationDisplayName! : 'Select Location',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurface.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
            ),

            // Status indicator
            if (!isSelected)
              _buildPulsingDot(theme)
            else
              Icon(Icons.check_circle, color: Colors.green, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySelector(ThemeData theme) {
    final isSelected = _selectedCategoryId != null;

    return InkWell(
      onTap: () => _showCategorySelector(),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: theme.dividerColor),
          borderRadius: BorderRadius.circular(12),
          color: theme.colorScheme.surface,
        ),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.category_outlined,
                color: theme.colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),

            // Label and value
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Advertisement Type',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isSelected ? _selectedCategoryName! : 'Select Category',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurface.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
            ),

            // Status indicator
            if (!isSelected)
              _buildPulsingDot(theme)
            else
              Icon(Icons.check_circle, color: Colors.green, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildBrandSelector(ThemeData theme) {
    final brandState = ref.watch(brandProvider);
    final isSelected = _selectedBrand != null;

    return InkWell(
      onTap: () => _showBrandSelector(),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: theme.dividerColor),
          borderRadius: BorderRadius.circular(12),
          color: theme.colorScheme.surface,
        ),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.business_outlined,
                color: theme.colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),

            // Label and value
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Brand',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isSelected ? _selectedBrandName! : 'Select Brand',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurface.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
            ),

            // Status indicator
            if (!isSelected)
              _buildPulsingDot(theme)
            else
              Icon(Icons.check_circle, color: Colors.green, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildModelSelector(ThemeData theme) {
    final modelState = ref.watch(modelProvider);
    final isSelected = _selectedModel != null;

    return InkWell(
      onTap: () => _showModelSelector(),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: theme.dividerColor),
          borderRadius: BorderRadius.circular(12),
          color: theme.colorScheme.surface,
        ),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.devices_outlined,
                color: theme.colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),

            // Label and value
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Model',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isSelected ? _selectedModelName! : 'Select Model',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurface.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
            ),

            // Status indicator
            if (!isSelected)
              _buildPulsingDot(theme)
            else
              Icon(Icons.check_circle, color: Colors.green, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHelperText(ThemeData theme) {
    return Center(
      child: Text(
        'বিজ্ঞাপন দিতে ফোন নম্বর, লোকেশন ও ক্যাটাগরি বেছে নিন',
        style: TextStyle(
          fontSize: 14,
          color: theme.colorScheme.onSurface.withOpacity(0.6),
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildPulsingDot(ThemeData theme) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.red,
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.4),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicFields(List<PostField> fields, ThemeData theme) {
    if (fields.isEmpty) {
      return Center(
        child: Text(
          'No fields available for this category',
          style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: fields
          .where((field) {
            // Skip brand and model fields since they have dedicated selectors
            return field.slug != 'brand' && field.slug != 'model';
          })
          .map((field) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: DynamicFieldRenderer(
                field: field,
                value: _fieldValues[field.slug],
                onChanged: (value) {
                  _initializeDraft(); // Lazy initialization
                  setState(() {
                    _fieldValues[field.slug] = value;
                    _fieldErrors.remove(field.slug);
                    _validateForm();
                  });
                  _saveDraft();
                },
                errorText: _fieldErrors[field.slug],
              ),
            );
          })
          .toList(),
    );
  }

  Widget _buildErrorState(String error, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: theme.colorScheme.onErrorContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error,
              style: TextStyle(color: theme.colorScheme.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(ThemeData theme) {
    return Material(
      color: _isFormValid
          ? theme.colorScheme.primary
          : theme.colorScheme.primary.withOpacity(0.5),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: _isFormValid ? _handleSubmit : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          alignment: Alignment.center,
          child: const Text(
            'Submit',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  void _showLocationSelector() {
    _initializeDraft(); // Lazy initialization
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LocationSelectorBottomSheet(
        onLocationSelected: (division, district, area) {
          setState(() {
            _selectedDivision = division;
            _selectedDistrict = district;
            _selectedArea = area;
            _locationDisplayName = '${area.nameEn}, ${district.nameEn}';
          });
          _saveDraft();
        },
      ),
    );
  }

  void _showCategorySelector() {
    _initializeDraft(); // Lazy initialization
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CategorySelectorBottomSheet(
        onCategorySelected: (categoryId, categoryName) {
          setState(() {
            _selectedCategoryId = categoryId;
            _selectedCategoryName = categoryName;
            // Clear brand and model when category changes
            _selectedBrand = null;
            _selectedBrandName = null;
            _selectedModel = null;
            _selectedModelName = null;
            // Clear previous field values when category changes
            _fieldValues.clear();
            _fieldErrors.clear();
            // Fetch fields for the new category
            ref
                .read(postFieldsProvider.notifier)
                .fetchFields(int.parse(categoryId));
            // Fetch brands for the new category
            ref.read(brandProvider.notifier).fetchBrands(int.parse(categoryId));
          });
          _saveDraft();
        },
      ),
    );
  }

  void _showBrandSelector() {
    final brandState = ref.read(brandProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Select Brand',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: brandState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : brandState.brands.isEmpty
                  ? const Center(child: Text('No brands available'))
                  : ListView.builder(
                      itemCount: brandState.brands.length,
                      itemBuilder: (context, index) {
                        final brand = brandState.brands[index];
                        return ListTile(
                          title: Text(brand.displayName),
                          onTap: () {
                            setState(() {
                              _selectedBrand = brand;
                              _selectedBrandName = brand.displayName;
                              // Clear model when brand changes
                              _selectedModel = null;
                              _selectedModelName = null;
                              // Fetch models for the new brand
                              if (brand.id != null) {
                                ref
                                    .read(modelProvider.notifier)
                                    .fetchModels(brand.id!);
                              }
                            });
                            _saveDraft();
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showModelSelector() {
    final modelState = ref.read(modelProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Select Model',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: modelState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : modelState.models.isEmpty
                  ? const Center(child: Text('No models available'))
                  : ListView.builder(
                      itemCount: modelState.models.length,
                      itemBuilder: (context, index) {
                        final model = modelState.models[index];
                        return ListTile(
                          title: Text(model.displayName),
                          onTap: () {
                            setState(() {
                              _selectedModel = model;
                              _selectedModelName = model.displayName;
                            });
                            _saveDraft();
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
