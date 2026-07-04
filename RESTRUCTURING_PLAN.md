# Bekalpo Project Restructuring Plan

## Current Structure Analysis

### Issues Identified
1. **Models mixed with widgets**: AdModel and AdCategory are defined inside widget files (ad_card.dart, category_grid.dart)
2. **Empty directories**: assets/, controllers/, models/, shared/components/, core/config/, core/state/, core/utils/
3. **Flat structure**: No clear feature-based organization
4. **Missing layers**: No clear separation between data, domain, and presentation
5. **Inconsistent organization**: Widgets scattered in shared/widgets/ with some in subdirectories

### Current Directory Structure
```
lib/
├── app/
│   ├── app.dart
│   ├── app_bootstrap.dart
│   └── router/app_routes.dart
├── assets/ (empty)
├── controllers/ (empty)
├── core/
│   ├── config/ (empty)
│   ├── constants/app_colors.dart
│   ├── network/
│   │   ├── api_service.dart
│   │   └── internet_service.dart
│   ├── state/ (empty)
│   ├── theme/app_theme.dart
│   └── utils/ (empty)
├── main.dart
├── models/ (empty)
├── screens/
│   ├── home/home_screen.dart
│   ├── no_internet/no_internet_screen.dart
│   └── splash/splash_screen.dart
├── services/
│   └── category_service.dart
└── shared/
    ├── components/ (empty)
    └── widgets/
        ├── ad_card.dart
        ├── app/app_bar.dart
        ├── category_grid.dart
        ├── connectivity_wrapper.dart
        ├── home_search_bar.dart
        ├── section_header.dart
        └── seller_card.dart
```

## Proposed Structure

### New Directory Structure
```
lib/
├── main.dart
├── app/
│   ├── app.dart
│   ├── app_bootstrap.dart
│   └── router/
│       └── app_routes.dart
├── core/
│   ├── constants/
│   │   └── app_colors.dart
│   ├── network/
│   │   ├── api_service.dart
│   │   └── internet_service.dart
│   └── theme/
│       └── app_theme.dart
├── features/
│   ├── home/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   ├── ad_model.dart
│   │   │   │   └── category_model.dart
│   │   │   └── services/
│   │   │       └── category_service.dart
│   │   └── presentation/
│   │       ├── screens/
│   │       │   └── home_screen.dart
│   │       └── widgets/
│   │           ├── ad_card.dart
│   │           ├── category_grid.dart
│   │           ├── home_search_bar.dart
│   │           └── section_header.dart
│   └── shared/
│       ├── presentation/
│       │   ├── screens/
│       │   │   ├── splash_screen.dart
│       │   │   └── no_internet_screen.dart
│       │   └── widgets/
│       │       ├── app_bar.dart
│       │       ├── connectivity_wrapper.dart
│       │       └── seller_card.dart
```

## Restructuring Steps

### Phase 1: Extract Models
1. Create `features/home/data/models/ad_model.dart` - extract AdModel from ad_card.dart
2. Create `features/home/data/models/category_model.dart` - extract AdCategory from category_grid.dart

### Phase 2: Reorganize Home Feature
1. Move `home_screen.dart` to `features/home/presentation/screens/`
2. Move `ad_card.dart` to `features/home/presentation/widgets/`
3. Move `category_grid.dart` to `features/home/presentation/widgets/`
4. Move `home_search_bar.dart` to `features/home/presentation/widgets/`
5. Move `section_header.dart` to `features/home/presentation/widgets/`
6. Move `category_service.dart` to `features/home/data/services/`

### Phase 3: Reorganize Shared Feature
1. Move `splash_screen.dart` to `features/shared/presentation/screens/`
2. Move `no_internet_screen.dart` to `features/shared/presentation/screens/`
3. Move `app_bar.dart` to `features/shared/presentation/widgets/`
4. Move `connectivity_wrapper.dart` to `features/shared/presentation/widgets/`
5. Move `seller_card.dart` to `features/shared/presentation/widgets/`

### Phase 4: Clean Up
1. Remove empty directories: assets/, controllers/, models/, shared/components/, core/config/, core/state/, core/utils/
2. Remove old directories: screens/, services/, shared/

### Phase 5: Update Imports
1. Update all import statements to reflect new structure
2. Update app_routes.dart imports
3. Update app_bootstrap.dart imports
4. Update app.dart imports
5. Update all widget imports

## Benefits of New Structure
1. **Feature-based organization**: Each feature (home, shared) is self-contained
2. **Clear separation**: Data, presentation, and domain layers are separated
3. **Scalability**: Easy to add new features without cluttering the structure
4. **Maintainability**: Related files are grouped together
5. **Best practices**: Follows Flutter architecture recommendations
