# Design Specifications

## Visual Style

### Bottom Navigation Bar
- **Height**: 56px (standard Material Design)
- **Elevation**: 8px
- **Border Radius**: 0px (full width)
- **Background Color**:
  - Light mode: `Colors.white`
  - Dark mode: `Color(0xFF1E1E1E)`

### Icons
- **Size**: 24px
- **Active Color**: `AppColors.brand500` (#0A66C1)
- **Inactive Color**: `Colors.grey` (#9E9E9E)
- **Style**: Material Icons
- **States**:
  - Inactive: Outlined icon
  - Active: Filled icon

### Labels
- **Font Size**: 12px
- **Font Weight**: Normal (400)
- **Active Color**: `AppColors.brand500` (#0A66C1)
- **Inactive Color**: `Colors.grey` (#9E9E9E)
- **Text Style**: Roboto (default Material font)
- **Language**: Bengali

### Selected Indicator
- **Type**: None (optional - can be added later)
- **Alternative**: Color change on active item

## Spacing
- **Icon to Label**: 4px
- **Item Spacing**: Evenly distributed
- **Horizontal Padding**: 0px (full width items)

## Behavior

### Tap Interaction
- **Response**: Instant tab switch
- **Animation**: None (instant switch)
- **Feedback**: Ripple effect (Material default)
- **Haptic**: Optional (can be added)

### State Preservation
- **Method**: `IndexedStack`
- **Benefit**: Each tab maintains its state
- **Trade-off**: All tabs stay in memory

### Navigation Logic
- **Default Tab**: Home (index 0)
- **Tab Switching**: Updates `navIndexProvider`
- **Deep Linking**: Can navigate to specific tabs
- **Back Button**: Exits app when on home tab

## Theme Integration

### Light Mode
```dart
BottomNavigationBar(
  backgroundColor: Colors.white,
  selectedItemColor: AppColors.brand500,
  unselectedItemColor: Colors.grey,
)
```

### Dark Mode
```dart
BottomNavigationBar(
  backgroundColor: Color(0xFF1E1E1E),
  selectedItemColor: AppColors.brand500,
  unselectedItemColor: Colors.grey,
)
```

## Responsive Design

### Mobile Portrait
- Full width bottom nav
- All 5 items visible
- Labels always visible

### Mobile Landscape
- Full width bottom nav
- All 5 items visible
- Labels always visible

### Tablet (Optional Enhancement)
- Consider side navigation for larger screens
- Keep bottom nav for consistency

## Accessibility

### Screen Reader
- Proper semantic labels for each item
- Announce tab changes
- Announce active state

### Touch Targets
- Minimum 48x48px touch target
- Adequate spacing between items

### Color Contrast
- Active items: 4.5:1 contrast ratio (WCAG AA)
- Inactive items: 3:1 contrast ratio (WCAG AA)

## Animation Specifications

### Tab Switch
- **Duration**: 0ms (instant)
- **Curve**: None
- **Reason**: Instant response for better UX

### Optional Enhancements
- Fade in/out for tab content: 200ms
- Scale effect on tap: 100ms
- Ripple effect: Material default

## Brand Consistency
- Use `AppColors.brand500` for active states
- Follow existing app theme
- Match typography with app design
- Consistent with Material Design guidelines
