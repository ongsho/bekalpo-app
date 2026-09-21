# Flutter Font Scale Detection

## কীভাবে কোড থেকে ফোনের ফন্ট সেটিং জানা যায়

Flutter-এ `MediaQuery.textScaleFactor` ব্যবহার করে সিস্টেম ফন্ট স্কেল সেটিং জানা যায়।

## ব্যাখ্যা

```dart
final textScaleFactor = MediaQuery.of(context).textScaleFactor;
debugPrint('Font scale factor: $textScaleFactor');
```

## মানের অর্থ

- `1.0` = Default/Normal (স্বাভাবিক)
- `< 1.0` = Small (ছোট ফন্ট)
- `> 1.0` = Large (বড় ফন্ট)

## উদাহরণ মান

- 0.85 = Very Small
- 1.0 = Normal/Default
- 1.15 = Large
- 1.3 = Extra Large

## সম্পূর্ণ উদাহরণ

```dart
@override
Widget build(BuildContext context) {
  final textScaleFactor = MediaQuery.of(context).textScaleFactor;
  
  debugPrint('Font scale factor: $textScaleFactor');
  
  // ফন্ট সাইজ স্কেল অনুযায়ী পরিবর্তন
  final baseFontSize = 14;
  final scaledFontSize = baseFontSize * textScaleFactor;
  
  return Text(
    'Hello World',
    style: TextStyle(fontSize: scaledFontSize),
  );
}
```

## কখন ব্যবহার করবেন

- যখন আপনি চান যে আপনার অ্যাপ সিস্টেম ফন্ট সেটিং অনুযায়ী ফন্ট সাইজ পরিবর্তন করুক
- অ্যাক্সেসিবিলিটি উন্নত করার জন্য
- ব্যবহারকারীর পছন্দ অনুযায়ী UI সাজানোর জন্য

## নোট

- এটি শুধুমাত্র ফন্ট সাইজ স্কেল করে, অন্য UI এলিমেন্ট নয়
- ডিফল্টভাবে Flutter অনেক উইজেটে এটি অটোমেটিক প্রয়োগ করে
- আপনি চাইলে `Text` উইজেটে `textScaleFactor` প্যারামিটার দিয়ে এটি নিয়ন্ত্রণ করতে পারেন
