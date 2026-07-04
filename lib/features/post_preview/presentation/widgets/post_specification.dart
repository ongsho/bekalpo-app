import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/post.dart';
import 'shared/section_card.dart';

/// Renders the dynamic specification rows for a post: skips price fields
/// (shown elsewhere), resolves brand/model display names, and renders
/// multi-select field values as chips when more than one is selected.
class PostSpecification extends StatelessWidget {
  final Post post;

  const PostSpecification({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final rows = _buildRows();

    if (rows.isEmpty) {
      return Text(
        'No specifications available',
        style: TextStyle(color: Colors.grey.shade600),
      );
    }

    return Column(
      children: List.generate(rows.length, (i) {
        return Column(
          children: [
            rows[i],
            if (i != rows.length - 1)
              Divider(height: 1, color: Colors.grey.shade100),
          ],
        );
      }),
    );
  }

  List<Widget> _buildRows() {
    if (post.fieldValues == null || post.fieldValues!.isEmpty) return [];

    final rows = <Widget>[];
    for (final field in post.fieldValues!) {
      if (field.fieldSlug == 'price' || field.fieldSlug == 'price_type') {
        continue;
      }

      String displayValue;
      List<dynamic> selectedItems = [];

      if (field.fieldSlug == 'brand') {
        displayValue = post.brand?.nameEn ?? '';
      } else if (field.fieldSlug == 'model') {
        displayValue = post.model?.nameEn ?? '';
      } else if (field.valueIds != null &&
          field.valueIds!.isNotEmpty &&
          field.items != null) {
        selectedItems = field.items!
            .where((item) => field.valueIds!.contains(item.id))
            .toList();
        displayValue = selectedItems.map((item) => item.nameEn ?? '').join(
          ', ',
        );
      } else {
        displayValue = field.value ?? '';
      }

      if (displayValue.isEmpty) continue;

      final isMultiChip = selectedItems.length > 1;

      rows.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 4,
                child: Text(
                  (field.title ?? field.fieldSlug ?? '')
                      .toString()
                      .toUpperCase(),
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              Expanded(
                flex: 6,
                child: isMultiChip
                    ? Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: selectedItems
                            .map(
                              (item) => BadgeChip(
                                text: item.nameEn ?? '',
                                background: AppColors.brand500.withOpacity(
                                  0.08,
                                ),
                                foreground: AppColors.brand500,
                              ),
                            )
                            .toList(),
                      )
                    : (field.valueIds != null && field.valueIds!.isNotEmpty
                          ? Align(
                              alignment: Alignment.centerLeft,
                              child: BadgeChip(
                                text: displayValue,
                                background: AppColors.brand500.withOpacity(
                                  0.08,
                                ),
                                foreground: AppColors.brand500,
                              ),
                            )
                          : Text(
                              displayValue,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            )),
              ),
            ],
          ),
        ),
      );
    }

    return rows;
  }
}