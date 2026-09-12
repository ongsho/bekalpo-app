import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/post_field.dart';
import '../../../home/presentation/widgets/generic_selector_bottom_sheet.dart';

class DynamicFieldRenderer extends ConsumerStatefulWidget {
  final PostField field;
  final dynamic value;
  final Function(dynamic) onChanged;
  final String? errorText;
  final bool showValidationError;

  const DynamicFieldRenderer({
    super.key,
    required this.field,
    required this.value,
    required this.onChanged,
    this.errorText,
    this.showValidationError = false,
  });

  @override
  ConsumerState<DynamicFieldRenderer> createState() =>
      _DynamicFieldRendererState();
}

class _DynamicFieldRendererState extends ConsumerState<DynamicFieldRenderer> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Special handling for price field
    if (widget.field.slug == 'price') {
      return _buildPriceField(theme);
    }

    switch (widget.field.type) {
      case 'text':
        return _buildTextField(theme);
      case 'radio':
        return _buildRadioField(theme);
      case 'select':
        return _buildSelectField(theme);
      case 'checkbox':
        return _buildCheckboxField(theme);
      case 'image':
        return _buildImageField(theme);
      default:
        return _buildUnsupportedField(theme);
    }
  }

  Widget _buildPriceField(ThemeData theme) {
    final showError = widget.showValidationError;

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
                  Icons.account_balance_wallet_outlined,
                  color: showError ? Colors.red : Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Row(
                  children: [
                    Text(
                      widget.field.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: showError
                            ? Colors.red
                            : theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    if (widget.field.pivot.required)
                      Text(
                        ' *',
                        style: TextStyle(
                          color: showError
                              ? Colors.red
                              : theme.colorScheme.error,
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
            initialValue: widget.value?.toString(),
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: widget.field.placeholder ?? 'Enter price',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              errorText: widget.errorText,
              prefixText: '৳ ',
            ),
            onChanged: widget.onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(ThemeData theme) {
    final showError = widget.showValidationError;

    return TextFormField(
      initialValue: widget.value?.toString(),
      decoration: InputDecoration(
        labelText:
            widget.field.title + (widget.field.pivot.required ? ' *' : ''),
        hintText: widget.field.placeholder,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: showError ? Colors.red : theme.dividerColor,
            width: showError ? 2 : 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: showError ? Colors.red : theme.dividerColor,
            width: showError ? 2 : 1,
          ),
        ),
        errorText: widget.errorText,
      ),
      onChanged: widget.onChanged,
    );
  }

  Widget _buildRadioField(ThemeData theme) {
    final showError = widget.showValidationError;

    // Handle radio value - extract from array if needed
    String? selectedValue;
    if (widget.value is List) {
      final listValue = widget.value as List;
      if (listValue.isNotEmpty) {
        selectedValue = listValue.first.toString();
      }
    } else if (widget.value != null) {
      selectedValue = widget.value.toString();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              widget.field.title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: showError ? Colors.red : theme.colorScheme.onSurface,
              ),
            ),
            if (widget.field.pivot.required)
              Text(
                '*',
                style: TextStyle(
                  color: showError ? Colors.red : theme.colorScheme.error,
                  fontSize: 16,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (widget.field.items.isEmpty)
          Text(
            'No options available',
            style: TextStyle(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          )
        else
          Column(
            children: widget.field.items.map((item) {
              return RadioListTile<String>(
                title: Text(
                  item.nameEn,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                value: item.id.toString(),
                groupValue: selectedValue,
                onChanged: (value) {
                  // Radio should store as array
                  widget.onChanged([value]);
                },
                activeColor: theme.colorScheme.primary,
              );
            }).toList(),
          ),
        if (widget.errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              widget.errorText!,
              style: TextStyle(color: theme.colorScheme.error, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildSelectField(ThemeData theme) {
    final showError = widget.showValidationError;

    // Handle select value - extract from array if needed
    String? selectedValue;
    if (widget.value is List) {
      final listValue = widget.value as List;
      if (listValue.isNotEmpty) {
        selectedValue = listValue.first.toString();
      }
    } else if (widget.value != null) {
      selectedValue = widget.value.toString();
    }

    // Find the selected item label
    String? selectedLabel;
    if (selectedValue != null) {
      try {
        final fieldItem = widget.field.items.firstWhere(
          (i) => i.id.toString() == selectedValue,
        );
        selectedLabel = fieldItem.nameEn;
      } catch (e) {
        // Item not found, ignore
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              widget.field.title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: showError ? Colors.red : theme.colorScheme.onSurface,
              ),
            ),
            if (widget.field.pivot.required)
              Text(
                '*',
                style: TextStyle(
                  color: showError ? Colors.red : theme.colorScheme.error,
                  fontSize: 16,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (widget.field.items.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(
                color: showError ? Colors.red : theme.dividerColor,
                width: showError ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'No options available',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          )
        else
          InkWell(
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => GenericSelectorBottomSheet(
                  field: widget.field,
                  initialValue: selectedValue,
                  onItemSelected: (value) {
                    // Select should store as array
                    widget.onChanged([value]);
                  },
                ),
              );
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              decoration: BoxDecoration(
                border: Border.all(
                  color: showError ? Colors.red : theme.dividerColor,
                  width: showError ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(8),
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
                      Icons.arrow_drop_down,
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
                          widget.field.title,
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
                          selectedLabel ??
                              (widget.field.placeholder ??
                                  'Select ${widget.field.title}'),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: selectedLabel != null
                                ? theme.colorScheme.onSurface
                                : theme.colorScheme.onSurface.withOpacity(0.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Status indicator
                  if (selectedLabel != null)
                    Icon(Icons.check_circle, color: Colors.green, size: 24)
                  else
                    Icon(
                      Icons.arrow_drop_down,
                      color: theme.colorScheme.onSurface.withOpacity(0.4),
                      size: 24,
                    ),
                ],
              ),
            ),
          ),
        if (widget.errorText != null)
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 4),
            child: Text(
              widget.errorText!,
              style: TextStyle(color: theme.colorScheme.error, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildCheckboxField(ThemeData theme) {
    final showError = widget.showValidationError;

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
              Text(
                widget.field.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: showError ? Colors.red : theme.colorScheme.onSurface,
                ),
              ),
              if (widget.field.pivot.required)
                Text(
                  '*',
                  style: TextStyle(
                    color: showError ? Colors.red : theme.colorScheme.error,
                    fontSize: 16,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (widget.field.items.isEmpty)
            Text(
              'No options available',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            )
          else
            Column(
              children: widget.field.items.map((item) {
                // Handle checkbox value - convert to List<String> if needed
                List<String> currentList = [];
                if (widget.value is List) {
                  currentList = (widget.value as List)
                      .map((e) => e.toString())
                      .toList();
                }

                final isSelected = currentList.contains(item.id.toString());

                return CheckboxListTile(
                  title: Text(
                    item.nameEn,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  value: isSelected,
                  onChanged: (checked) {
                    if (checked == true) {
                      currentList.add(item.id.toString());
                    } else {
                      currentList.remove(item.id.toString());
                    }
                    widget.onChanged(currentList);
                  },
                  activeColor: theme.colorScheme.primary,
                );
              }).toList(),
            ),
          if (widget.errorText != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                widget.errorText!,
                style: TextStyle(color: theme.colorScheme.error, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImageField(ThemeData theme) {
    // Image field is handled separately in the parent screen
    // This is a placeholder to avoid unsupported field error
    return const SizedBox.shrink();
  }

  Widget _buildUnsupportedField(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Unsupported field type: ${widget.field.type}',
        style: TextStyle(color: theme.colorScheme.onErrorContainer),
      ),
    );
  }
}
