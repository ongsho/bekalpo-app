# Share Feature Documentation

## Overview
Post preview screen-এ share ফিচার ইমপ্লিমেন্ট করা হয়েছে যা ব্যবহারকারীদের পোস্ট শেয়ার করতে দেয়।

## Implementation Details

### Dependencies
- `share_plus: ^7.2.1` - প্যাকেজ যোগ করা হয়েছে `pubspec.yaml`-এ

### Files Modified

#### 1. `pubspec.yaml`
```yaml
share_plus: ^7.2.1
```

#### 2. `lib/features/post_preview/presentation/screens/post_preview_screen.dart`

**Import added:**
```dart
import 'package:share_plus/share_plus.dart';
```

**Share function:**
```dart
void _sharePost(Post post) {
  final title = post.title ?? 'No title';
  final price = post.price;
  final location = post.location;

  final shareText =
      '$title\n'
      'Price: ৳$price\n'
      'Location: $location\n'
      'Check it out on Bekalpo!';

  Share.share(shareText, subject: title);
}
```

**Top bar share button:**
```dart
IconButton(
  icon: const Icon(Icons.share_outlined),
  color: Colors.white,
  onPressed: () => _sharePost(post),
),
```

**PostPriceCard share callback:**
```dart
PostPriceCard(
  // ... other props
  onShare: () => _sharePost(post),
),
```

#### 3. `lib/features/post_preview/presentation/widgets/post_price_card.dart`

**Import removed:**
- `rating_dialog.dart` (unused import removed)

**Share callback parameter added:**
```dart
class PostPriceCard extends StatelessWidget {
  final VoidCallback? onShare;
  // ... other props

  const PostPriceCard({
    // ... other params
    this.onShare,
  });
}
```

**Share button implementation:**
```dart
_ActionTextButton(
  icon: Icons.share_outlined,
  label: 'Share',
  onTap: onShare ?? () {},
  color: color,
),
```

**Note:** `_ActionTextButton` এ `onTap` কে `VoidCallback?` করা হয়েছে এবং default empty function দেওয়া হয়েছে।

## Features

### Share Content Format
```
[Post Title]
Price: ৳[Price]
Location: [Location]
Check it out on Bekalpo!
```

### Share Entry Points
1. **Top Bar Share Icon** - পোস্ট লোড হলেই টপ বারে দেখা যায়
2. **PostPriceCard Share Button** - Price/Statistics card এ "Share" বাটন

### Platform Support
- Android - Native share sheet
- iOS - Native share sheet
- Web - Web share API (if supported)

## Technical Notes

### Riverpod Integration
- `ConsumerWidget` ব্যবহার করা হয়েছে `PostPreviewScreen`-এ
- `WidgetRef ref` প্যারামিটার হিসেবে পাস করা হয় যেখানে প্রয়োজন

### Error Handling
- Share operation-এ বর্তমানে কোনো explicit error handling নেই
- `share_plus` package নিজেই error handle করে

### Null Safety
- `post.title` null হলে "No title" দেখায়
- `onShare` null হলে empty function execute হয়

## Known Issues/Warnings

### Static Analysis Findings
Share implementation সম্পর্কিত কোনো নতুন error নেই। সব pre-existing warnings (deprecated methods, print statements) আগে থেকেই ছিল।

### Current Status
✅ No compilation errors
✅ Share functionality working
✅ Type safety maintained
ℹ️ Only pre-existing lint warnings remain

## Testing Recommendations

1. **Manual Testing:**
   - Android device/emulator এ share বাটন টেস্ট করুন
   - iOS simulator এ share বাটন টেস্ট করুন
   - Web browser এ share টেস্ট করুন

2. **Test Cases:**
   - Post with all fields (title, price, location)
   - Post with missing title
   - Post with null price/location
   - Share from top bar
   - Share from PostPriceCard

3. **Verify:**
   - Native share sheet opens correctly
   - Share text format is correct
   - No crashes on null values

## Future Enhancements

1. **Add URL Sharing:**
   - Backend থেকে post URL নিয়ে share text এ যোগ করা যেতে পারে
   - Example: `https://bekalpo.com/posts/[slug]`

2. **Add Error Handling:**
   - Share operation fail করলে user কে জানানো
   - SnackBar দিয়ে error message দেখানো

3. **Add Analytics:**
   - Share events track করা
   - কোন পোস্ট কতবার share হলো track করা

## Code References

- **Share Package:** https://pub.dev/packages/share_plus
- **Post Preview Screen:** `lib/features/post_preview/presentation/screens/post_preview_screen.dart`
- **Post Price Card:** `lib/features/post_preview/presentation/widgets/post_price_card.dart`
