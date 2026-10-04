import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/division.dart';
import '../../../../core/models/district.dart';
import '../../../../core/models/thana.dart';

import '../../../../core/models/post_field.dart';
import 'dart:io';
import '../../../../core/models/brand.dart';
import '../../../../core/models/model.dart';
import '../../../../core/models/contact.dart';
import '../../../../core/providers/post_fields_provider.dart';
import '../../../../core/providers/draft_post_provider.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/brand_provider.dart';
import '../../../../core/providers/model_provider.dart';
import '../../../../core/providers/location_provider.dart';
import '../../../../core/network/api_client.dart';
import '../../../home/presentation/widgets/location_selector_bottom_sheet.dart';
import '../../../home/presentation/widgets/category_selector_bottom_sheet.dart';
import '../../../home/presentation/widgets/brand_selector_bottom_sheet.dart';
import '../../../home/presentation/widgets/model_selector_bottom_sheet.dart';
import '../widgets/dynamic_field_renderer.dart';
import '../widgets/image_upload_widget.dart';
import '../../../auth/presentation/screens/auth_entry_screen.dart';
import '../../../auth/presentation/screens/phone_add_screen.dart';
import '../../../bottom_nav/presentation/providers/nav_provider.dart';
import '../../../../app/router/app_routes.dart';

class PostAddScreen extends ConsumerStatefulWidget {
  final String? postId; // Optional: if provided, edit mode
  final Map<String, dynamic>? initialData; // Optional: initial data for edit

  const PostAddScreen({super.key, this.postId, this.initialData});

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
  bool _hasBrandField = false; // Track if brand field exists in dynamic fields

  // Model selection state
  ProductModel? _selectedModel;
  String? _selectedModelName;

  // Form field values
  final Map<String, dynamic> _fieldValues = {};
  final Map<String, String?> _fieldErrors = {};

  // Contact number selection state
  String? _selectedContactNumber;

  // Validation state
  bool _isFormValid = false;
  bool _hasAttemptedSubmit = false;

  // Draft ID tracking
  String? _currentPostId;

  // Track if auth check has been done
  bool _hasCheckedAuth = false;

  // Edit mode tracking
  bool _isEditMode = false;

  // Image upload state
  final List<String> _uploadedImages = [];
  bool _isUploadingImages = false;

  // Submit state
  bool _isSubmitting = false;

  // Loading state for API calls
  bool _isLoading = false;

  // Edit data storage
  dynamic _editData;

  @override
  void initState() {
    super.initState();

    // Check if this is edit mode
    _isEditMode = widget.postId != null;

    if (_isEditMode) {
      // Load existing post data for editing from API
      _currentPostId = widget.postId;
      _loadPostFromAPI();
    }
    // Don't initialize draft in initState to avoid blocking app startup
    // Initialize draft lazily when user interacts with the screen
  }

  Future<void> _loadPostFromAPI() async {
    if (_currentPostId == null) return;

    try {
      setState(() {
        _isLoading = true;
      });

      final apiClient = ApiClient();
      final response = await apiClient.getPostForEdit(_currentPostId!);

      if (response.statusCode == 200) {
        final responseMap = response.data as Map<String, dynamic>;
        final data = responseMap['data'];
        _populateFormDataFromAPI(data);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load post: ${response.statusCode}'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading post: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _populateFormDataFromAPI(dynamic data) {
    if (data == null) return;

    setState(() {
      // Load category
      if (data['category_id'] != null &&
          data['category'] != null &&
          data['category'] is Map) {
        final categoryData = data['category'] as Map<String, dynamic>;
        _selectedCategoryId = data['category_id'].toString();
        _selectedCategoryName = categoryData['name_en']?.toString();

        // Trigger post fields provider reload with new category
        ref
            .read(postFieldsProvider.notifier)
            .fetchFields(int.parse(_selectedCategoryId!));

        // Trigger brand provider reload with new category
        ref
            .read(brandProvider.notifier)
            .fetchBrands(int.parse(_selectedCategoryId!));
      }

      // Load location (Thana)
      if (data['thana_id'] != null) {
        if (data['thana'] != null && data['thana'] is Map) {
          final thanaData = data['thana'] as Map<String, dynamic>;
          _selectedArea = Thana(
            id: data['thana_id'],
            nameEn: thanaData['name_en']?.toString(),
            nameBn: thanaData['name_bn']?.toString(),
          );
          _locationDisplayName = _selectedArea?.nameEn;
        } else if (data['thana'] is List && data['thana'].isNotEmpty) {
          // Handle case where thana is an array
          final thanaData = data['thana'][0] as Map<String, dynamic>;
          _selectedArea = Thana(
            id: data['thana_id'],
            nameEn: thanaData['name_en']?.toString(),
            nameBn: thanaData['name_bn']?.toString(),
          );
          _locationDisplayName = _selectedArea?.nameEn;
        } else {
          // If thana object is not available, fetch it by ID
          _loadThanaById(data['thana_id']);
        }
      }

      // Load brand if available
      if (data['brand_id'] != null) {
        if (data['brand'] != null && data['brand'] is Map) {
          final brandData = data['brand'] as Map<String, dynamic>;
          _selectedBrand = Brand(
            id: data['brand_id'],
            nameEn: brandData['name_en']?.toString(),
            nameBn: brandData['name_bn']?.toString(),
          );
          _selectedBrandName = _selectedBrand?.nameEn;

          // Trigger model provider reload with new brand
          ref.read(modelProvider.notifier).fetchModels(data['brand_id']);
        } else if (data['brand'] is List && data['brand'].isNotEmpty) {
          // Handle case where brand is an array
          final brandData = data['brand'][0] as Map<String, dynamic>;
          _selectedBrand = Brand(
            id: data['brand_id'],
            nameEn: brandData['name_en']?.toString(),
            nameBn: brandData['name_bn']?.toString(),
          );
          _selectedBrandName = _selectedBrand?.nameEn;

          // Trigger model provider reload with new brand
          ref.read(modelProvider.notifier).fetchModels(data['brand_id']);
        } else {
          _loadBrandById(data['brand_id']);
        }
      }

      // Load model if available
      if (data['model_id'] != null) {
        if (data['model'] != null && data['model'] is Map) {
          final modelData = data['model'] as Map<String, dynamic>;
          _selectedModel = ProductModel(
            id: data['model_id'],
            nameEn: modelData['name_en']?.toString(),
            nameBn: modelData['name_bn']?.toString(),
          );
          _selectedModelName = _selectedModel?.nameEn;
        } else if (data['model'] is List && data['model'].isNotEmpty) {
          // Handle case where model is an array
          final modelData = data['model'][0] as Map<String, dynamic>;
          _selectedModel = ProductModel(
            id: data['model_id'],
            nameEn: modelData['name_en']?.toString(),
            nameBn: modelData['name_bn']?.toString(),
          );
          _selectedModelName = _selectedModel?.nameEn;
        } else {
          _loadModelById(data['model_id']);
        }
      }

      // Load field values from field_values array
      if (data['field_values'] != null) {
        final fieldValues = data['field_values'] as List<dynamic>;
        for (var fv in fieldValues) {
          if (fv['field_slug'] != null) {
            final slug = fv['field_slug'];
            final value = fv['value'];
            if (value != null) {
              _fieldValues[slug] = value;
            }
            // Handle value_ids for select fields
            if (fv['value_ids'] != null) {
              _fieldValues[slug] = fv['value_ids'];
            }
          }
        }
      }

      // Load direct fields from post object
      if (data['title'] != null) {
        _fieldValues['title'] = data['title'];
      }
      if (data['description'] != null) {
        _fieldValues['description'] = data['description'];
      }

      // Load images
      if (data['image'] != null) {
        final images = data['image'] as List<dynamic>;
        _uploadedImages.addAll(images.cast<String>());
      }

      // Validate form
      _validateForm();

      // Store the data for later use when dynamic fields are loaded
      _editData = data;

      // Debug print after setState
    });
  }

  // Helper function to convert field values to correct types for payload
  dynamic _convertFieldValueForPayload(
    String slug,
    dynamic value,
    postFieldsState,
  ) {
    // Find the field definition
    PostField? field;
    try {
      field = postFieldsState.fields.firstWhere((f) => f.slug == slug);
    } catch (e) {
      // Field not found in current category
      return null;
    }

    if (field == null) return null;

    // Radio and select fields: convert List to int
    if (field.type == 'radio' || field.type == 'select') {
      if (value is List && value.isNotEmpty) {
        final firstValue = value.first;
        if (firstValue is String) {
          final intValue = int.tryParse(firstValue);
          return intValue;
        }
        if (firstValue is int) return firstValue;
        return firstValue;
      }
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      return value;
    }

    // Checkbox fields: convert List to List<int>
    if (field.type == 'checkbox') {
      if (value is List) {
        final intList = value
            .map((e) {
              if (e is int) return e;
              if (e is String) return int.tryParse(e);
              return null;
            })
            .whereType<int>()
            .toList();
        return intList;
      }
      return value;
    }

    // Text fields: keep as is
    return value;
  }

  // Method to apply field values after dynamic fields are loaded
  void _applyFieldValuesAfterFieldsLoaded() {
    if (_editData == null) return;

    // Fix #11: If category changed from original, apply nothing at all
    if (_editData['category_id'].toString() != _selectedCategoryId) {
      return;
    }

    setState(() {
      // Re-apply field values after dynamic fields are loaded
      if (_editData['field_values'] != null) {
        final fieldValues = _editData['field_values'] as List<dynamic>;
        for (var fv in fieldValues) {
          if (fv['field_slug'] != null) {
            final slug = fv['field_slug'];
            final value = fv['value'];
            // Skip brand and model since they are handled by dedicated selectors
            if (slug == 'brand' || slug == 'model') {
              continue;
            }
            if (value != null) {
              _fieldValues[slug] = value;
            }
            if (fv['value_ids'] != null) {
              _fieldValues[slug] = fv['value_ids'];
            }
          }
        }
      }
      if (_editData['title'] != null)
        _fieldValues['title'] = _editData['title'];
      if (_editData['description'] != null)
        _fieldValues['description'] = _editData['description'];

      // Convert loaded values to correct types
      final postFieldsState = ref.read(postFieldsProvider);
      _fieldValues.forEach((key, value) {
        if (key == 'brand' || key == 'model' || key == 'description') return;
        final converted = _convertFieldValueForPayload(
          key,
          value,
          postFieldsState,
        );
        if (converted != value) {
          _fieldValues[key] = converted;
        }
      });
    });
  }

  Future<void> _loadBrandById(dynamic brandId) async {
    try {
      // Use brand provider to find the brand by ID
      final brandState = ref.read(brandProvider);

      // Search for brand in the provider
      final brand = brandState.brands.firstWhere(
        (b) => b.id == brandId,
        orElse: () => throw Exception('Brand not found'),
      );

      setState(() {
        _selectedBrand = brand;
        _selectedBrandName = brand.nameEn;
      });
    } catch (e) {
      // Set placeholder on error
      setState(() {
        _selectedBrand = Brand(
          id: brandId,
          nameEn: 'Brand $brandId',
          nameBn: 'ব্র্যান্ড $brandId',
        );
        _selectedBrandName = _selectedBrand?.nameEn;
      });
    }
  }

  Future<void> _loadModelById(dynamic modelId) async {
    try {
      // Use model provider to find the model by ID
      final modelState = ref.read(modelProvider);

      // Search for model in the provider
      final model = modelState.models.firstWhere(
        (m) => m.id == modelId,
        orElse: () => throw Exception('Model not found'),
      );

      setState(() {
        _selectedModel = model;
        _selectedModelName = model.nameEn;
      });
    } catch (e) {
      // Set placeholder on error
      setState(() {
        _selectedModel = ProductModel(
          id: modelId,
          nameEn: 'Model $modelId',
          nameBn: 'মডেল $modelId',
        );
        _selectedModelName = _selectedModel?.nameEn;
      });
    }
  }

  Future<void> _loadThanaById(dynamic thanaId) async {
    try {
      // Use location provider to find the thana by ID
      final locationState = ref.read(locationProvider);

      // Search for thana in all divisions
      Thana? foundThana;
      for (final division in locationState.allDivisions) {
        if (division.districts != null) {
          for (final district in division.districts!) {
            if (district.thanas != null) {
              try {
                final thana = district.thanas!.firstWhere(
                  (t) => t.id == thanaId,
                  orElse: () => throw Exception('Not found'),
                );
                foundThana = thana;
                break;
              } catch (e) {
                // Continue searching
              }
            }
          }
        }
        if (foundThana != null) break;
      }

      if (foundThana != null) {
        final thanaName = foundThana.nameEn ?? 'Area $thanaId';
        setState(() {
          _selectedArea = foundThana;
          _locationDisplayName = thanaName;
        });
      } else {
        // Set placeholder if not found
        setState(() {
          _selectedArea = Thana(
            id: thanaId,
            nameEn: 'Area $thanaId',
            nameBn: 'এলাক $thanaId',
          );
          _locationDisplayName = _selectedArea?.nameEn;
        });
      }
    } catch (e) {
      // Set placeholder on error
      setState(() {
        _selectedArea = Thana(
          id: thanaId,
          nameEn: 'Area $thanaId',
          nameBn: 'এলাক $thanaId',
        );
        _locationDisplayName = _selectedArea?.nameEn;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final postFieldsState = ref.watch(postFieldsProvider);
    final currentIndex = ref.watch(navIndexProvider);
    final authState = ref.watch(authProvider);

    // Listen for post fields loading completion
    ref.listen(postFieldsProvider, (previous, next) {
      if (previous?.isLoading == true &&
          !next.isLoading &&
          next.error == null) {
        _applyFieldValuesAfterFieldsLoaded();

        // Check if brand and model fields exist in dynamic fields
        setState(() {
          _hasBrandField = next.fields.any((field) => field.slug == 'brand');
        });

        // Re-run validation after fields load (fix for issue #10)
        _validateForm();
      }
    });

    // Listen for brand provider loading completion
    ref.listen(brandProvider, (previous, next) {
      // Note: _hasBrands is no longer used for validation - _hasBrandField controls that
    });

    // If brand field exists but no brand is selected, clear model
    if (_hasBrandField && _selectedBrand == null && _selectedModel != null) {
      setState(() {
        _selectedModel = null;
        _selectedModelName = null;
      });
    }

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
        title: Text(_isEditMode ? 'Edit Post' : 'Post Ad'),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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

                    // Brand selector (show when category selected AND brand field exists in dynamic fields OR brand is already selected in edit mode)
                    if (_selectedCategoryId != null &&
                        (_hasBrandField || _selectedBrand != null)) ...[
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

                  // Dynamic form fields (show when location and category are selected, and brand/model if brand field exists)
                  if (_selectedArea != null &&
                      _selectedCategoryId != null &&
                      (!_hasBrandField ||
                          (_selectedBrand != null &&
                              _selectedModel != null))) ...[
                    if (postFieldsState.isLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (postFieldsState.error != null)
                      _buildErrorState(postFieldsState.error!, theme)
                    else
                      _buildDynamicFields(postFieldsState.fields, theme),

                    const SizedBox(height: 24),

                    // Submit button
                    _buildSubmitButton(theme, _isEditMode),
                  ] else if (_selectedArea != null &&
                      _selectedCategoryId != null &&
                      _hasBrandField) ...[
                    // Show message when brand/model not selected
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Please select brand and model to continue',
                                style: TextStyle(
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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
      return;
    }

    try {
      final postId = await ref
          .read(draftPostProvider.notifier)
          .initializeDraft();
      setState(() {
        _currentPostId = postId;
      });
    } catch (e) {
      // Continue even if draft initialization fails
    }
  }

  Future<void> _saveDraft() async {
    if (_currentPostId == null) {
      return;
    }

    try {
      // Create a copy of field_values without brand and model
      final fieldValuesCopy = Map<String, dynamic>.from(_fieldValues);
      fieldValuesCopy.remove('brand');
      fieldValuesCopy.remove('model');

      await ref.read(draftPostProvider.notifier).updateDraft({
        'location': _locationDisplayName,
        'category_id': _selectedCategoryId,
        'category_name': _selectedCategoryName,
        'brand_id': _selectedBrand?.id,
        'brand_name': _selectedBrandName,
        'model_id': _selectedModel?.id,
        'model_name': _selectedModelName,
        'field_values': fieldValuesCopy,
        'images': _uploadedImages,
      });
    } catch (e) {}
  }

  Future<void> _handleImageSelection(List<File> imageFiles) async {
    if (_currentPostId == null) {
      await _initializeDraft();
    }

    if (_currentPostId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to initialize draft')),
      );
      return;
    }

    setState(() {
      _isUploadingImages = true;
    });

    // Upload in background without blocking UI
    _uploadImagesInBackground(imageFiles);
  }

  Future<void> _uploadImagesInBackground(List<File> imageFiles) async {
    try {
      final apiClient = ApiClient();

      final response = await apiClient.uploadImages(
        'posts/image/upload/$_currentPostId',
        files: imageFiles,
      );

      if (response.statusCode == 200) {
        final data = response.data;

        if (data != null && data['image'] != null) {
          final List<dynamic> newImages = data['image'];

          setState(() {
            _uploadedImages.addAll(newImages.cast<String>());
            _isUploadingImages = false;
          });

          _saveDraft();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Images uploaded successfully')),
            );
          }
        } else {
          // Try to get image from different possible response structures
          if (data != null) {
            if (data['images'] != null) {
              final List<dynamic> newImages = data['images'];
              setState(() {
                _uploadedImages.addAll(newImages.cast<String>());
                _isUploadingImages = false;
              });
            } else if (data['data'] != null && data['data']['image'] != null) {
              final List<dynamic> newImages = data['data']['image'];
              setState(() {
                _uploadedImages.addAll(newImages.cast<String>());
                _isUploadingImages = false;
              });
            }
          }
        }
      } else {
        setState(() {
          _isUploadingImages = false;
        });
      }
    } catch (e) {
      setState(() {
        _isUploadingImages = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error uploading images: $e')));
      }
    }
  }

  Future<void> _handleImageReorder(List<String> reorderedImages) async {
    if (_currentPostId == null) {
      return;
    }

    try {
      final apiClient = ApiClient();
      final response = await apiClient.reorderImages(
        'posts/image/upload/reorder/$_currentPostId',
        imageUrls: reorderedImages,
      );

      if (response.statusCode == 200) {
        setState(() {
          // Images are already updated in the widget
        });
        _saveDraft();
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error reordering images: $e')));
    }
  }

  void _handleImageRemoval(int index) {
    setState(() {
      _uploadedImages.removeAt(index);
    });
    _saveDraft();
  }

  void _validateForm() {
    // Validate all required fields
    bool isValid = true;

    // Check location
    if (_selectedArea == null) {
      isValid = false;
    } else {}

    // Check category
    if (_selectedCategoryId == null) {
      isValid = false;
    } else {}

    // Check brand and model only if brand field exists in dynamic fields
    if (_hasBrandField) {
      if (_selectedBrand == null) {
        isValid = false;
      } else {}

      if (_selectedModel == null) {
        isValid = false;
      } else {}
    }

    // Check dynamic fields (skip brand and model since they have dedicated selectors)
    // Only validate dynamic fields if brand and model are selected (when brand field exists)
    if (!_hasBrandField || (_selectedBrand != null && _selectedModel != null)) {
      final postFieldsState = ref.read(postFieldsProvider);
      for (final field in postFieldsState.fields) {
        // Skip brand and model fields
        if (field.slug == 'brand' || field.slug == 'model') continue;

        final value = _fieldValues[field.slug];
        final isEmpty =
            value == null ||
            (value is List && value.isEmpty) ||
            (value is String && value.isEmpty);

        if (field.pivot.required && isEmpty) {
          isValid = false;
          _fieldErrors[field.slug] = '${field.title} is required';
        } else {
          // Clear error if field is now valid
          _fieldErrors.remove(field.slug);
          if (field.pivot.required) {}
        }
      }

      // Check description field (always required when dynamic fields are shown)
      final descValue = _fieldValues['description'];
      final descEmpty = descValue == null || descValue.toString().isEmpty;

      if (descEmpty) {
        isValid = false;
        _fieldErrors['description'] = 'Description is required';
      } else {
        _fieldErrors.remove('description');
      }
    }

    setState(() {
      _isFormValid = isValid;
    });
  }

  Future<void> _handleSubmit() async {
    // Mark that user has attempted to submit
    setState(() {
      _hasAttemptedSubmit = true;
    });

    if (!_isFormValid) {
      return;
    }

    // Check if images are still uploading
    if (_isUploadingImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please wait for images to finish uploading'),
        ),
      );
      return;
    }

    // Initialize draft if not already done
    if (_currentPostId == null) {
      await _initializeDraft();
    }

    if (_currentPostId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to initialize draft')),
      );
      return;
    }

    // Show loading indicator
    setState(() {
      _isSubmitting = true;
    });

    try {
      // Get auth state for contact phones
      final authState = ref.read(authProvider);

      // Build contact phones array
      List<Map<String, dynamic>> contactPhones = [];
      if (authState.userPhone != null) {
        contactPhones.add({'phone': authState.userPhone, 'verified': true});
      }
      if (authState.userContacts != null &&
          authState.userContacts!.isNotEmpty) {
        for (var contact in authState.userContacts!) {
          // Handle both Contact objects and dynamic data
          if (contact is Contact) {
            contactPhones.add({
              'id': contact.id,
              'phone': contact.value,
              'verified': contact.verifiedAt != null,
            });
          } else if (contact is Map<String, dynamic>) {
            contactPhones.add({
              'id': contact['id'],
              'phone': contact['value'],
              'verified': contact['verified_at'] != null,
            });
          }
        }
      }

      // Build the info object with all field values directly
      Map<String, dynamic> info = {
        'contact_phones': contactPhones,
        '__initialized': true,
      };

      // Get currently loaded fields to filter which slugs to include
      final postFieldsState = ref.read(postFieldsProvider);
      final validSlugs = postFieldsState.fields.map((f) => f.slug).toSet();

      // Add all field values directly to info object, but only for currently loaded fields
      _fieldValues.forEach((key, value) {
        // Skip description as it's handled separately
        if (key == 'description') return;

        // Skip brand and model as they are handled separately below
        if (key == 'brand' || key == 'model') return;

        // Fix #12: Only include slugs that exist in currently loaded fields
        if (!validSlugs.contains(key)) {
          return;
        }

        // Convert value to correct type
        final convertedValue = _convertFieldValueForPayload(
          key,
          value,
          postFieldsState,
        );
        info[key] = convertedValue;
      });

      // Add brand and model to info object
      // Fix #12: Send null for brand/model if category doesn't have brand field
      if (_hasBrandField) {
        if (_selectedBrand != null) {
          info['brand'] = _selectedBrand!.id;
        } else {
          info['brand'] = null;
        }
        if (_selectedModel != null) {
          info['model'] = _selectedModel!.id;
        } else {
          info['model'] = null;
        }
      } else {
        info['brand'] = null;
        info['model'] = null;
      }

      // Add description if exists
      if (_fieldValues.containsKey('description')) {
        info['description'] = _fieldValues['description'];
      }

      // Build the payload
      // Fix #13: Convert category_id to int
      Map<String, dynamic> payload = {
        'info': info,
        'category_id': _selectedCategoryId != null
            ? int.parse(_selectedCategoryId!)
            : null,
        'thana_id': _selectedArea?.id,
        'status': 'published',
      };

      final apiClient = ApiClient();
      final response = await apiClient.submitPost(
        _currentPostId!,
        payload: payload,
      );

      if (response.statusCode == 200) {
        // Post submitted successfully
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post submitted successfully!')),
        );

        // Clear the form
        setState(() {
          _fieldValues.clear();
          _fieldErrors.clear();
          _uploadedImages.clear();
          _currentPostId = null;
          _selectedCategoryName = null;
          _selectedCategoryId = null;
          _selectedArea = null;
          _locationDisplayName = null;
          _selectedBrand = null;
          _selectedBrandName = null;
          _selectedModel = null;
          _selectedModelName = null;
          _isFormValid = false;
          _hasAttemptedSubmit = false;
        });

        // Navigate directly to My Posts screen
        if (mounted) {
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil(AppRoutes.myPosts, (route) => false);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit post: ${response.statusCode}'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error submitting post: $e')));
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Widget _buildPhoneSelector(ThemeData theme, bool hasPhone) {
    if (hasPhone) {
      final authState = ref.watch(authProvider);
      final userPhone = authState.userPhone;
      final contacts = authState.userContacts;

      // If user has phone in main field
      if (userPhone != null) {
        // Auto-select the single phone number
        if (_selectedContactNumber == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              _selectedContactNumber = userPhone;
            });
          });
        }

        return InkWell(
          onTap: () {
            // Allow changing contact by going to phone add screen
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const PhoneAddScreen()),
            );
          },
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
                    color: Colors.white,
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        userPhone,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),

                // Edit button
                Icon(Icons.edit, color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                // Status indicator
                Icon(Icons.check_circle, color: Colors.green, size: 24),
              ],
            ),
          ),
        );
      }

      // If user has multiple contacts, show dropdown
      if (contacts != null && contacts.isNotEmpty) {
        // If there's only one contact, show it as selected (like the main phone field)
        if (contacts.length == 1) {
          final singleContact = contacts.first;
          // Auto-select the single contact
          if (_selectedContactNumber == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              setState(() {
                _selectedContactNumber = singleContact.value;
              });
            });
          }

          return InkWell(
            onTap: () {
              // Allow changing contact by going to phone add screen
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const PhoneAddScreen()),
              );
            },
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
                      color: Colors.white,
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
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          singleContact.value ?? '',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Edit button
                  Icon(Icons.edit, color: theme.colorScheme.primary, size: 20),
                  const SizedBox(width: 8),
                  // Status indicator
                  Icon(Icons.check_circle, color: Colors.green, size: 24),
                ],
              ),
            ),
          );
        }

        // If multiple contacts, show dropdown
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
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Label
                  Expanded(
                    child: Text(
                      'Select Contact Number',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
                value: _selectedContactNumber,
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
                    _selectedContactNumber = value;
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
            child: Icon(Icons.phone_outlined, color: Colors.white, size: 24),
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
    final showError = _hasAttemptedSubmit && !isSelected;

    return InkWell(
      onTap: () => _showLocationSelector(),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: showError ? Colors.red : theme.dividerColor,
            width: showError ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: theme.colorScheme.surface,
        ),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: showError
                    ? Colors.red.withOpacity(0.1)
                    : theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.location_on_outlined,
                color: showError ? Colors.red : Colors.white,
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
                      color: showError
                          ? Colors.red
                          : theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isSelected
                        ? (_locationDisplayName ?? 'Select Location')
                        : 'Select Location',
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
              showError
                  ? Icon(Icons.error, color: Colors.red, size: 24)
                  : _buildPulsingDot(theme)
            else
              Icon(Icons.check_circle, color: Colors.green, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySelector(ThemeData theme) {
    final isSelected = _selectedCategoryId != null;
    final showError = _hasAttemptedSubmit && !isSelected;

    return InkWell(
      onTap: () => _showCategorySelector(),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: showError ? Colors.red : theme.dividerColor,
            width: showError ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: theme.colorScheme.surface,
        ),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: showError
                    ? Colors.red.withOpacity(0.1)
                    : theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.category_outlined,
                color: showError ? Colors.red : Colors.white,
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
                      color: showError
                          ? Colors.red
                          : theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isSelected
                        ? (_selectedCategoryName ?? 'Select Category')
                        : 'Select Category',
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
              showError
                  ? Icon(Icons.error, color: Colors.red, size: 24)
                  : _buildPulsingDot(theme)
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
    final showError = _hasAttemptedSubmit && !isSelected;

    return InkWell(
      onTap: () {
        // Check if brands are available before showing selector
        if (brandState.brands.isEmpty && !brandState.isLoading) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No brands available for this category'),
            ),
          );
          return;
        }
        _showBrandSelector();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: showError ? Colors.red : theme.dividerColor,
            width: showError ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: theme.colorScheme.surface,
        ),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: showError
                    ? Colors.red.withOpacity(0.1)
                    : theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.business_outlined,
                color: showError ? Colors.red : Colors.white,
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
                      color: showError
                          ? Colors.red
                          : theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isSelected
                        ? (_selectedBrandName ?? 'Select Brand')
                        : 'Select Brand',
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
              showError
                  ? Icon(Icons.error, color: Colors.red, size: 24)
                  : _buildPulsingDot(theme)
            else
              Icon(Icons.check_circle, color: Colors.green, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildModelSelector(ThemeData theme) {
    final isSelected = _selectedModel != null;
    final showError = _hasAttemptedSubmit && !isSelected;

    return InkWell(
      onTap: () => _showModelSelector(),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: showError ? Colors.red : theme.dividerColor,
            width: showError ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: theme.colorScheme.surface,
        ),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: showError
                    ? Colors.red.withOpacity(0.1)
                    : theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.devices_outlined,
                color: showError ? Colors.red : Colors.white,
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
                      color: showError
                          ? Colors.red
                          : theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isSelected
                        ? (_selectedModelName ?? 'Select Model')
                        : 'Select Model',
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
              showError
                  ? Icon(Icons.error, color: Colors.red, size: 24)
                  : _buildPulsingDot(theme)
            else
              Icon(Icons.check_circle, color: Colors.green, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHelperText(ThemeData theme) {
    List<String> missingItems = [];

    // Check phone
    final authState = ref.read(authProvider);
    final hasVerifiedPhone = authState.userPhone != null;
    final hasContacts =
        authState.userContacts != null && authState.userContacts!.isNotEmpty;
    final hasPhone = hasVerifiedPhone || hasContacts;
    if (!hasPhone) {
      missingItems.add('ফোন নম্বর');
    }

    // Check location
    if (_selectedArea == null) {
      missingItems.add('লোকেশন');
    }

    // Check category
    if (_selectedCategoryId == null) {
      missingItems.add('ক্যাটাগরি');
    }

    // Check brand and model only if brand field exists
    if (_hasBrandField) {
      if (_selectedBrand == null) {
        missingItems.add('ব্র্যান্ড');
      }
      if (_selectedModel == null) {
        missingItems.add('মডেল');
      }
    }

    String helperText;
    if (missingItems.isEmpty) {
      helperText = 'বিজ্ঞাপন দিতে অন্যান্য তথ্য পূরণ করুন';
    } else {
      helperText = 'বিজ্ঞাপন দিতে ${missingItems.join(', ')} বেছে নিন';
    }

    return Center(
      child: Text(
        helperText,
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

    // Check if description field exists in dynamic fields
    final hasDescriptionField = fields.any(
      (field) => field.slug == 'description',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...fields
            .where((field) {
              // Skip brand and model fields since they have dedicated selectors
              return field.slug != 'brand' && field.slug != 'model';
            })
            .map((field) {
              // Check if field should show validation error
              bool showFieldError = false;
              if (_hasAttemptedSubmit && field.pivot.required) {
                final fieldValue = _fieldValues[field.slug];
                if (fieldValue == null || fieldValue.toString().isEmpty) {
                  showFieldError = true;
                }
              }

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
                  showValidationError: showFieldError,
                ),
              );
            })
            .toList(),

        const SizedBox(height: 16),

        // Add manual description field if not present in dynamic fields
        if (!hasDescriptionField) ...[
          _buildDescriptionField(theme),
          const SizedBox(height: 16),
        ],

        // Image upload widget
        ImageUploadWidget(
          uploadedImages: _uploadedImages,
          onImagesSelected: _handleImageSelection,
          onImagesReordered: _handleImageReorder,
          onImageRemoved: _handleImageRemoval,
          isUploading: _isUploadingImages,
        ),
      ],
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

  Widget _buildDescriptionField(ThemeData theme) {
    bool showError = false;
    if (_hasAttemptedSubmit) {
      final descriptionValue = _fieldValues['description'];
      if (descriptionValue == null || descriptionValue.toString().isEmpty) {
        showError = true;
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: showError ? Colors.red : theme.dividerColor,
          width: showError ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
        color: theme.colorScheme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: showError
                      ? Colors.red.withOpacity(0.1)
                      : theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.description_outlined,
                  color: showError ? Colors.red : Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Row(
                  children: [
                    Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: showError
                            ? Colors.red
                            : theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    Text(
                      ' *',
                      style: TextStyle(
                        color: showError ? Colors.red : theme.colorScheme.error,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: _fieldValues['description']?.toString(),
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'Enter product description',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              errorText: showError ? 'Description is required' : null,
            ),
            onChanged: (value) {
              _initializeDraft(); // Lazy initialization
              setState(() {
                _fieldValues['description'] = value;
                _fieldErrors.remove('description');
                _validateForm();
              });
              _saveDraft();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(ThemeData theme, bool isEditMode) {
    // Only enable submit if form is valid AND brand/model are selected when brand field exists
    final canSubmit =
        _isFormValid &&
        (!_hasBrandField || (_selectedBrand != null && _selectedModel != null));

    return Material(
      color: canSubmit
          ? theme.colorScheme.primary
          : theme.colorScheme.primary.withOpacity(0.5),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: (_isSubmitting || !canSubmit)
            ? null
            : _handleSubmit, // Disable when submitting or can't submit
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          alignment: Alignment.center,
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  isEditMode ? 'Update' : 'Submit',
                  style: const TextStyle(
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
            // Also clear brand and model from field values if they exist
            _fieldValues.remove('brand');
            _fieldValues.remove('model');
            // Reset hasBrandField flag
            _hasBrandField = false;
            // Fetch fields for the new category
            ref
                .read(postFieldsProvider.notifier)
                .fetchFields(int.parse(categoryId));
            // Fetch brands for the new category
            ref.read(brandProvider.notifier).fetchBrands(int.parse(categoryId));
          });
          _saveDraft();
          // Validate form after category change
          _validateForm();
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
      builder: (context) => BrandSelectorBottomSheet(
        brands: brandState.brands,
        onBrandSelected: (brand) {
          setState(() {
            _selectedBrand = brand;
            _selectedBrandName = brand.displayName;
            // Clear model when brand changes
            _selectedModel = null;
            _selectedModelName = null;
            // Fetch models for the new brand
            if (brand.id != null) {
              ref.read(modelProvider.notifier).fetchModels(brand.id!);
            }
          });
          _saveDraft();
        },
      ),
    );
  }

  void _showModelSelector() {
    final modelState = ref.read(modelProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ModelSelectorBottomSheet(
        models: modelState.models,
        onModelSelected: (model) {
          setState(() {
            _selectedModel = model;
            _selectedModelName = model.displayName;
          });
          _saveDraft();
        },
      ),
    );
  }
}
