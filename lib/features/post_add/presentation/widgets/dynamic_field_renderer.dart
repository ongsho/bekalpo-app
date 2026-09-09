import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/post_field.dart';

class DynamicFieldRenderer extends ConsumerStatefulWidget {
  final PostField field;
  final dynamic value;
  final Function(dynamic) onChanged;
  final String? errorText;

  const DynamicFieldRenderer({
    super.key,
    required this.field,
    required this.value,
    required this.onChanged,
    this.errorText,
  });

  @override
  ConsumerState<DynamicFieldRenderer> createState() =>
      _DynamicFieldRendererState();
}

class _DynamicFieldRendererState extends ConsumerState<DynamicFieldRenderer> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    switch (widget.field.type) {
      case 'text':
        return _buildTextField(theme);
      case 'radio':
        return _buildRadioField(theme);
      case 'select':
        return _buildSelectField(theme);
      case 'checkbox':
        return _buildCheckboxField(theme);
      default:
        return _buildUnsupportedField(theme);
    }
  }

  Widget _buildTextField(ThemeData theme) {
    return TextFormField(
      initialValue: widget.value as String?,
      decoration: InputDecoration(
        labelText:
            widget.field.title + (widget.field.pivot.required ? ' *' : ''),
        hintText: widget.field.placeholder,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        errorText: widget.errorText,
      ),
      onChanged: widget.onChanged,
    );
  }

  Widget _buildRadioField(ThemeData theme) {
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
                color: theme.colorScheme.onSurface,
              ),
            ),
            if (widget.field.pivot.required)
              Text(
                '*',
                style: TextStyle(color: theme.colorScheme.error, fontSize: 16),
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
                title: Text(item.nameEn),
                subtitle: item.nameBn != null ? Text(item.nameBn!) : null,
                value: item.id.toString(),
                groupValue: widget.value as String?,
                onChanged: (value) {
                  widget.onChanged(value);
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
                color: theme.colorScheme.onSurface,
              ),
            ),
            if (widget.field.pivot.required)
              Text(
                '*',
                style: TextStyle(color: theme.colorScheme.error, fontSize: 16),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (widget.field.items.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(color: theme.dividerColor),
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
              ),
              errorText: widget.errorText,
            ),
            value: widget.value as String?,
            hint: Text(
              widget.field.placeholder ?? 'Select ${widget.field.title}',
            ),
            items: widget.field.items.map((item) {
              return DropdownMenuItem<String>(
                value: item.id.toString(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(item.nameEn),
                    if (item.nameBn != null)
                      Text(
                        item.nameBn!,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              widget.onChanged(value);
            },
          ),
      ],
    );
  }

  Widget _buildCheckboxField(ThemeData theme) {
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
                color: theme.colorScheme.onSurface,
              ),
            ),
            if (widget.field.pivot.required)
              Text(
                '*',
                style: TextStyle(color: theme.colorScheme.error, fontSize: 16),
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
              final isSelected =
                  (widget.value as List<String>?)?.contains(
                    item.id.toString(),
                  ) ??
                  false;
              return CheckboxListTile(
                title: Text(item.nameEn),
                subtitle: item.nameBn != null ? Text(item.nameBn!) : null,
                value: isSelected,
                onChanged: (checked) {
                  final currentList = widget.value as List<String>? ?? [];
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
    );
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
