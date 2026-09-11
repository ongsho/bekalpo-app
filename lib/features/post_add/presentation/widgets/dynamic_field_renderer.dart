import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/post_field.dart';

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
                subtitle: item.nameBn != null
                    ? Text(
                        item.nameBn!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    : null,
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
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
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
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
            value: selectedValue,
            hint: Text(
              widget.field.placeholder ?? 'Select ${widget.field.title}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            isDense: true,
            items: widget.field.items.map((item) {
              return DropdownMenuItem<String>(
                value: item.id.toString(),
                child: SizedBox(
                  height: 32,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.nameEn,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14),
                      ),
                      if (item.nameBn != null)
                        Text(
                          item.nameBn!,
                          style: TextStyle(
                            fontSize: 10,
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
            onChanged: (value) {
              // Select should store as array
              widget.onChanged([value]);
            },
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
                  currentList = (widget.value as List).map((e) => e.toString()).toList();
                }
                
                final isSelected = currentList.contains(item.id.toString());
                
                return CheckboxListTile(
                  title: Text(
                    item.nameEn,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: item.nameBn != null
                      ? Text(
                          item.nameBn!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      : null,
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
