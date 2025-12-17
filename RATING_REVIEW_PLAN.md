# Rating & Review System Implementation Plan

## Overview
Allow customers to rate and review both **vendors** and **drivers** after order delivery. Reviews are visible to vendors/drivers in their respective apps.

---

## ✅ Completed So Far

### 1. Updated Review Model
**File**: `packages/mbare_core/lib/src/models/review_model.dart`

**Changes Made**:
- Added `ReviewType` enum with `product`, `vendor`, and `driver`
- Updated `ReviewModel` to support all three types:
  - `orderId` - Links review to specific order
  - `targetId` - ID of product/vendor/driver being reviewed
  - `type` - Type of review (product/vendor/driver)
  - `userPhoto` - Reviewer's photo for display
- Added helper methods: `hasComment`, `ratingDouble`

---

## 🔧 Implementation Steps Needed

### Step 1: Update Review Repository
**File**: `packages/mbare_data/lib/src/repositories/review_repository.dart`

**Add New Methods**:
```dart
/// Get reviews for a vendor
Stream<List<ReviewModel>> streamVendorReviews(String vendorId) {
  return _reviewsCollection
      .where('targetId', isEqualTo: vendorId)
      .where('type', isEqualTo: ReviewType.vendor.name)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => ReviewModel.fromJson(doc.data()))
          .toList());
}

/// Get reviews for a driver
Stream<List<ReviewModel>> streamDriverReviews(String driverId) {
  return _reviewsCollection
      .where('targetId', isEqualTo: driverId)
      .where('type', isEqualTo: ReviewType.driver.name)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => ReviewModel.fromJson(doc.data()))
          .toList());
}

/// Check if customer has reviewed vendor for an order
Future<Result<ReviewModel?>> getUserReviewForVendor(
  String userId,
  String vendorId,
  String orderId,
) async {
  // ... implementation
}

/// Check if customer has reviewed driver for an order
Future<Result<ReviewModel?>> getUserReviewForDriver(
  String userId,
  String driverId,
  String orderId,
) async {
  // ... implementation
}
```

**Add Providers**:
```dart
@riverpod
Stream<List<ReviewModel>> streamVendorReviews(
  StreamVendorReviewsRef ref,
  String vendorId,
) {
  final repository = ref.watch(reviewRepositoryProvider);
  return repository.streamVendorReviews(vendorId);
}

@riverpod
Stream<List<ReviewModel>> streamDriverReviews(
  StreamDriverReviewsRef ref,
  String driverId,
) {
  final repository = ref.watch(reviewRepositoryProvider);
  return repository.streamDriverReviews(driverId);
}
```

---

### Step 2: Create Rating Dialog Widget
**File**: `packages/mbare_ui/lib/src/widgets/rating_dialog.dart` (NEW)

**Purpose**: Reusable dialog for customers to rate and review

```dart
class RatingDialog extends StatefulWidget {
  const RatingDialog({
    required this.targetName, // "Vendor Name" or "Driver Name"
    required this.targetType, // "vendor" or "driver"
    this.existingReview, // For editing
    required this.onSubmit,
  });

  // Shows:
  // - Star rating selector (1-5 stars)
  // - Comment text field (optional)
  // - Submit button
}
```

---

### Step 3: Add Review Section to Customer Order Details
**File**: `apps/customer_app/lib/features/orders/presentation/pages/order_details_page.dart`

**Add After Order Items Section** (around line 80):
```dart
// Only show for delivered orders
if (order.isDelivered) ...[
  const SizedBox(height: AppSpacing.xl),
  Text('Your Feedback', style: AppTextStyles.titleLarge),
  const SizedBox(height: AppSpacing.md),

  // Vendor Review Card
  _ReviewCard(
    title: 'Rate Vendor',
    targetId: order.vendorId,
    targetName: vendorName, // Get from vendor provider
    orderId: order.id!,
    type: ReviewType.vendor,
  ),

  const SizedBox(height: AppSpacing.md),

  // Driver Review Card (if driver assigned)
  if (order.driverId != null)
    _ReviewCard(
      title: 'Rate Driver',
      targetId: order.driverId!,
      targetName: driverName, // Get from user provider
      orderId: order.id!,
      type: ReviewType.driver,
    ),
],
```

**Create `_ReviewCard` Widget**:
```dart
class _ReviewCard extends ConsumerWidget {
  const _ReviewCard({
    required this.title,
    required this.targetId,
    required this.targetName,
    required this.orderId,
    required this.type,
  });

  final String title;
  final String targetId;
  final String targetName;
  final String orderId;
  final ReviewType type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    if (user == null) return const SizedBox.shrink();

    // Check if review exists
    final reviewAsync = ref.watch(
      userReviewProvider(user.id, targetId, orderId, type)
    );

    return reviewAsync.when(
      data: (review) {
        if (review != null) {
          // Show existing review with edit button
          return Card(
            child: ListTile(
              title: Text(title),
              subtitle: Row(
                children: [
                  ...List.generate(5, (index) =>
                    Icon(
                      index < review.rating
                          ? Icons.star
                          : Icons.star_border,
                      color: AppColors.warning,
                      size: 16,
                    ),
                  ),
                  if (review.hasComment) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        review.comment!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
              trailing: TextButton(
                onPressed: () => _editReview(context, review),
                child: const Text('Edit'),
              ),
            ),
          );
        }

        // Show "Leave a Review" button
        return Card(
          child: ListTile(
            title: Text(title),
            subtitle: const Text('Help others by sharing your experience'),
            trailing: ElevatedButton(
              onPressed: () => _addReview(context),
              child: const Text('Rate'),
            ),
          ),
        );
      },
      loading: () => const Card(
        child: ListTile(
          title: CircularProgressIndicator(),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Future<void> _addReview(BuildContext context) async {
    final result = await showDialog<ReviewModel?>(
      context: context,
      builder: (context) => RatingDialog(
        targetName: targetName,
        targetType: type == ReviewType.vendor ? 'vendor' : 'driver',
        onSubmit: (rating, comment) async {
          // Submit review via repository
        },
      ),
    );

    if (result != null) {
      // Review submitted successfully
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thank you for your feedback!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _editReview(BuildContext context, ReviewModel review) async {
    // Similar to _addReview but with existing review
  }
}
```

---

### Step 4: Display Reviews in Vendor App
**File**: `apps/vendor_app/lib/features/analytics/presentation/pages/analytics_page.dart`

**Add New Tab**: "Reviews"

```dart
// Add to TabBar
const Tab(text: 'Reviews'),

// Add to TabBarView
_ReviewsTab(),

// Create ReviewsTab widget
class _ReviewsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    if (user == null) return const SizedBox.shrink();

    final reviewsAsync = ref.watch(
      streamVendorReviewsProvider(user.id),
    );

    return reviewsAsync.when(
      data: (reviews) {
        if (reviews.isEmpty) {
          return const Center(
            child: Text('No reviews yet'),
          );
        }

        // Calculate average rating
        final avgRating = reviews.fold<int>(
          0,
          (sum, review) => sum + review.rating,
        ) / reviews.length;

        return Column(
          children: [
            // Summary Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      avgRating.toStringAsFixed(1),
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) =>
                        Icon(
                          index < avgRating.round()
                              ? Icons.star
                              : Icons.star_border,
                          color: AppColors.warning,
                        ),
                      ),
                    ),
                    Text('${reviews.length} reviews'),
                  ],
                ),
              ),
            ),

            // Reviews List
            Expanded(
              child: ListView.builder(
                itemCount: reviews.length,
                itemBuilder: (context, index) {
                  final review = reviews[index];
                  return _ReviewListItem(review: review);
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
    );
  }
}

class _ReviewListItem extends StatelessWidget {
  const _ReviewListItem({required this.review});
  final ReviewModel review;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: review.userPhoto != null
                      ? NetworkImage(review.userPhoto!)
                      : null,
                  child: review.userPhoto == null
                      ? Text(review.userName[0].toUpperCase())
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.userName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: List.generate(5, (index) =>
                          Icon(
                            index < review.rating
                                ? Icons.star
                                : Icons.star_border,
                            color: AppColors.warning,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (review.createdAt != null)
                  Text(
                    _formatDate(review.createdAt!),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
            if (review.hasComment) ...[
              const SizedBox(height: 12),
              Text(review.comment!),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inMinutes}m ago';
    }
  }
}
```

---

### Step 5: Display Reviews in Driver App
**File**: `apps/driver_app/lib/features/profile/presentation/pages/profile_page.dart`

**Add Reviews Section**:
```dart
// Add after earnings section
ListTile(
  leading: const Icon(Icons.star),
  title: const Text('My Reviews'),
  trailing: const Icon(Icons.chevron_right),
  onTap: () => context.push('/reviews'),
),
```

**Create Reviews Page**:
**File**: `apps/driver_app/lib/features/reviews/presentation/pages/reviews_page.dart` (NEW)

Similar to vendor reviews tab, but:
- Shows driver reviews
- Uses `streamDriverReviewsProvider`

---

## 📊 Firestore Structure

### Reviews Collection
```
reviews/
  {reviewId}/
    id: string
    orderId: string
    userId: string (reviewer)
    userName: string
    userPhoto: string?
    targetId: string (vendor/driver/product ID)
    type: string ("vendor" | "driver" | "product")
    rating: number (1-5)
    comment: string?
    createdAt: timestamp
    updatedAt: timestamp?
```

### Indexes Required
```
- targetId + type + createdAt (descending)
- orderId + targetId + type
- userId + targetId + orderId
```

---

## 🎨 UI/UX Flow

### Customer Journey
1. Order is delivered
2. Opens order details page
3. Sees "Your Feedback" section
4. Taps "Rate" button for vendor
5. Rating dialog appears
6. Selects 1-5 stars
7. (Optional) Writes comment
8. Taps "Submit"
9. See confirmation "Thank you for your feedback!"
10. Repeat for driver

### Vendor Journey
1. Opens analytics page
2. Taps "Reviews" tab
3. Sees average rating and total review count
4. Scrolls through individual reviews
5. Can see customer name, rating, comment, and date

### Driver Journey
1. Opens profile page
2. Taps "My Reviews"
3. Sees list of all reviews from customers
4. Same display as vendor reviews

---

## ✅ Testing Checklist

- [ ] Customer can rate vendor after delivery
- [ ] Customer can rate driver after delivery
- [ ] Reviews appear in Firestore
- [ ] Vendor sees all their reviews
- [ ] Driver sees all their reviews
- [ ] Average rating updates correctly
- [ ] Can edit existing review
- [ ] Cannot review same target multiple times for one order
- [ ] Reviews display in correct order (newest first)
- [ ] Star rating displays correctly

---

## 🚀 Next Steps

1. **Update Review Repository** - Add vendor/driver methods
2. **Create Rating Dialog** - Reusable UI component
3. **Update Customer Order Details** - Add review cards
4. **Add Reviews to Vendor App** - Analytics tab
5. **Add Reviews to Driver App** - Profile section
6. **Test End-to-End** - Complete flow
7. **Add Firestore Indexes** - Performance optimization

---

**Status**: Ready for implementation! All planning complete. 💪
