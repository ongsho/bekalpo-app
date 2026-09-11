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
import '../../../../core/network/api_client.dart';
import '../../../home/presentation/widgets/location_selector_bottom_sheet.dart';
import '../../../home/presentation/widgets/category_selector_bottom_sheet.dart';
import '../widgets/dynamic_field_renderer.dart';
import '../widgets/image_upload_widget.dart';
import '../../../auth/presentation/screens/auth_entry_screen.dart';
import '../../../auth/presentation/screens/phone_add_screen.dart';
import '../../../bottom_nav/presentation/providers/nav_provider.dart';
import '../../../../app/router/app_routes.dart';

class PostAddScreen extends ConsumerStatefulWidget {
  final String? postId; // Optional: if provided, edit mode
  final Map<String, dynamic>? initialData; // Optional: initial data for edit

  const PostAddScreen({
    super.key,
    this.postId,
    this.initialData,
  });

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
  bool _hasBrands = false;

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

  @override
  void initState() {
    super.initState();
    
    // Check if this is edit mode
    _isEditMode = widget.postId != null;
    
    if (_isEditMode) {
      // Load existing post data for editing
      _currentPostId = widget.postId;
      _loadExistingPostData();
    }
    // Don't initialize draft in initState to avoid blocking app startup
    // Initialize draft lazily when user interacts with the screen
  }

  void _loadExistingPostData() {
    if (widget.initialData == null) {
      // If no initial data provided, we could fetch from API
      // For now, we'll just set the draft ID
      return;
    }
    
    final data = widget.initialData!;
    
    setState(() {
      // Load category
      if (data['category_id'] != null) {
        _selectedCategoryId = data['category_id'].toString();
        _selectedCategoryName = data['category_name']?.toString();
      }
      
      // Load location
      if (data['thana_id'] != null) {
        // Note: You'll need to fetch the actual Thana object based on ID
        // For now, we'll just store the ID
        // _selectedArea = Thana with data['thana_id']
      }
      
      // Load brand and model if available
      if (data['brand_id'] != null) {
        // _selectedBrand = Brand with data['brand_id']
        _selectedBrandName = data['brand_name']?.toString();
      }
      
      if (data['model_id'] != null) {
        // _selectedModel = Model with data['model_id']
        _selectedModelName = data['model_name']?.toString();
      }
      
      // Load field values
      if (data['field_values'] != null) {
        final fieldValues = data['field_values'] as Map<String, dynamic>;
        fieldValues.forEach((key, value) {
          _fieldValues[key] = value;
        });
      }
      
      // Load images
      if (data['images'] != null) {
        final images = data['images'] as List<dynamic>;
        _uploadedImages.addAll(images.cast<String>());
      }
      
      // Validate form
      _validateForm();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final postFieldsState = ref.watch(postFieldsProvider);
    final currentIndex = ref.watch(navIndexProvider);
    final authState = ref.watch(authProvider);
    final brandState = ref.watch(brandProvider);

    // Update hasBrands state based on brand provider
    if (!brandState.isLoading && brandState.brands.isNotEmpty && !_hasBrands) {
      setState(() {
        _hasBrands = true;
      });
    } else if (!brandState.isLoading &&
        brandState.brands.isEmpty &&
        _hasBrands) {
      setState(() {
        _hasBrands = false;
      });
    }

    // If brands are available but no brand is selected, clear model
    if (_hasBrands && _selectedBrand == null && _selectedModel != null) {
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

              // Brand selector (show when category selected AND brands are available)
              if (_selectedCategoryId != null && _hasBrands) ...[
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

            // Dynamic form fields (show when location and category are selected, and brand/model if brands are available)
            if (_selectedArea != null &&
                _selectedCategoryId != null &&
                (!_hasBrands ||
                    (_selectedBrand != null && _selectedModel != null))) ...[
              if (postFieldsState.isLoading)
                const Center(child: CircularProgressIndicator())
              else if (postFieldsState.error != null)
                _buildErrorState(postFieldsState.error!, theme)
              else
                _buildDynamicFields(postFieldsState.fields, theme),

              const SizedBox(height: 24),

              // Submit button
              _buildSubmitButton(theme, _isEditMode),
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
        'images': _uploadedImages,
      });
      print('PostAddScreen: Draft saved successfully');
    } catch (e) {
      print('PostAddScreen: Error saving draft: $e');
    }
  }

  Future<void> _handleImageSelection(List<File> imageFiles) async {
    print(
      'PostAddScreen: _handleImageSelection called with ${imageFiles.length} files',
    );

    if (_currentPostId == null) {
      print('PostAddScreen: No draft ID, initializing draft');
      await _initializeDraft();
    }

    if (_currentPostId == null) {
      print('PostAddScreen: Draft initialization failed');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to initialize draft')),
      );
      return;
    }

    print(
      'PostAddScreen: Starting background image upload for post ID: $_currentPostId',
    );

    setState(() {
      _isUploadingImages = true;
    });

    // Upload in background without blocking UI
    _uploadImagesInBackground(imageFiles);
  }

  Future<void> _uploadImagesInBackground(List<File> imageFiles) async {
    try {
      final apiClient = ApiClient();
      print(
        'PostAddScreen: Calling API uploadImages with ${imageFiles.length} files',
      );

      final response = await apiClient.uploadImages(
        'posts/image/upload/$_currentPostId',
        files: imageFiles,
      );

      print('PostAddScreen: Upload response status: ${response.statusCode}');
      print('PostAddScreen: Upload response data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;
        print('PostAddScreen: Response data type: ${data.runtimeType}');
        print(
          'PostAddScreen: Response data keys: ${data is Map ? (data as Map).keys : 'not a map'}',
        );

        if (data != null && data['image'] != null) {
          final List<dynamic> newImages = data['image'];
          print(
            'PostAddScreen: Successfully uploaded ${newImages.length} images',
          );
          print('PostAddScreen: New images: $newImages');

          setState(() {
            _uploadedImages.addAll(newImages.cast<String>());
            _isUploadingImages = false;
          });

          print(
            'PostAddScreen: Total uploaded images: ${_uploadedImages.length}',
          );
          print('PostAddScreen: Current uploaded images: $_uploadedImages');

          _saveDraft();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Images uploaded successfully')),
            );
          }
        } else {
          print('PostAddScreen: Response data or image array is null');
          print('PostAddScreen: Full response: $data');

          // Try to get image from different possible response structures
          if (data != null) {
            if (data['images'] != null) {
              print('PostAddScreen: Found images in "images" key');
              final List<dynamic> newImages = data['images'];
              setState(() {
                _uploadedImages.addAll(newImages.cast<String>());
                _isUploadingImages = false;
              });
            } else if (data['data'] != null && data['data']['image'] != null) {
              print('PostAddScreen: Found images in data.image');
              final List<dynamic> newImages = data['data']['image'];
              setState(() {
                _uploadedImages.addAll(newImages.cast<String>());
                _isUploadingImages = false;
              });
            }
          }
        }
      } else {
        print(
          'PostAddScreen: Upload failed with status: ${response.statusCode}',
        );
        setState(() {
          _isUploadingImages = false;
        });
      }
    } catch (e) {
      print('PostAddScreen: Error uploading images: $e');
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
    }

    // Check category
    if (_selectedCategoryId == null) {
      isValid = false;
    }

    // Check brand and model only if brands are available for this category
    if (_hasBrands) {
      if (_selectedBrand == null) {
        isValid = false;
      }

      if (_selectedModel == null) {
        isValid = false;
      }
    }

    // Check dynamic fields (skip brand and model since they have dedicated selectors)
    final postFieldsState = ref.read(postFieldsProvider);
    for (final field in postFieldsState.fields) {
      // Skip brand and model fields
      if (field.slug == 'brand' || field.slug == 'model') continue;

      if (field.pivot.required &&
          (_fieldValues[field.slug] == null ||
              _fieldValues[field.slug].toString().isEmpty)) {
        isValid = false;
        _fieldErrors[field.slug] = '${field.title} is required';
      } else {
        // Clear error if field is now valid
        _fieldErrors.remove(field.slug);
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

      // Build the info object
      Map<String, dynamic> info = {
        'field_values': [],
        'contact_phones': contactPhones,
        '__initialized': true,
      };

      // Add field values to info (not inside field_values array, but as direct properties)
      _fieldValues.forEach((key, value) {
        info[key] = value;
      });

      // Add description if exists
      if (_fieldValues.containsKey('description')) {
        info['description'] = _fieldValues['description'];
      }

      // Build the payload
      Map<String, dynamic> payload = {
        'info': info,
        'category_id': _selectedCategoryId,
        'thana_id': _selectedArea?.id,
        'status': 'published',
      };

      // Add brand and model if available
      if (_selectedBrand != null) {
        payload['brand_id'] = _selectedBrand!.id;
      }
      if (_selectedModel != null) {
        payload['model_id'] = _selectedModel!.id;
      }

      print('PostAddScreen: Submitting post with ID: $_currentPostId');
      print('PostAddScreen: Payload: $payload');

      final apiClient = ApiClient();
      final response = await apiClient.submitPost(
        _currentPostId!,
        payload: payload,
      );

      print('PostAddScreen: Submit response status: ${response.statusCode}');
      print('PostAddScreen: Submit response data: ${response.data}');

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
          Navigator.of(context).pushNamedAndRemoveUntil(
            AppRoutes.myPosts,
            (route) => false,
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit post: ${response.statusCode}'),
          ),
        );
      }
    } catch (e) {
      print('PostAddScreen: Error submitting post: $e');
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
    return Center(
      child: Text(
        _hasBrands
            ? 'বিজ্ঞাপন দিতে ফোন নম্বর, লোকেশন, ক্যাটাগরি, ব্র্যান্ড ও মডেল বেছে নিন'
            : 'বিজ্ঞাপন দিতে ফোন নম্বর, লোকেশন ও ক্যাটাগরি বেছে নিন',
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

  Widget _buildSubmitButton(ThemeData theme, bool isEditMode) {
    return Material(
      color: _isFormValid
          ? theme.colorScheme.primary
          : theme.colorScheme.primary.withOpacity(0.5),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: _isSubmitting ? null : _handleSubmit, // Disable when submitting
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
                              _hasBrands = true;
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
