# Firestore Database Schema

## Overview

This document describes the Firestore collections structure for the MbareToYou application.

## Collections

### 1. users

**Path:** `/users/{userId}`

Stores user profile information for all user types.

```typescript
{
  id: string,                    // Document ID (matches Auth UID)
  email: string,
  role: string,                  // 'customer' | 'vendor' | 'driver' | 'admin'
  displayName?: string,
  phoneNumber?: string,
  photoUrl?: string,
  isActive: boolean,             // Default: true
  isEmailVerified: boolean,      // Default: false
  isPhoneVerified: boolean,      // Default: false
  createdAt: Timestamp,
  updatedAt: Timestamp,
  metadata?: {                   // Role-specific data
    [key: string]: any
  }
}
```

**Indexes:**
- `role` (ASC) + `isActive` (ASC) + `createdAt` (DESC)
- `email` (ASC)

---

### 2. vendors

**Path:** `/vendors/{vendorId}`

Stores vendor/market stall information.

```typescript
{
  id: string,                    // Document ID
  ownerId: string,               // Reference to users/{userId}
  businessName: string,
  tableNumber: string,           // e.g., "A-12", "B-05"
  marketSection: string,         // 'Section A' | 'Section B' | etc.
  description?: string,
  logoUrl?: string,
  phoneNumber?: string,
  email?: string,
  isApproved: boolean,           // Default: false (requires admin approval)
  isActive: boolean,             // Default: true
  rating: number,                // Default: 0.0 (0-5 scale)
  totalReviews: number,          // Default: 0
  totalOrders: number,           // Default: 0
  createdAt: Timestamp,
  updatedAt: Timestamp,
  metadata?: {
    approvedBy?: string,         // Admin user ID
    approvedAt?: Timestamp,
    [key: string]: any
  }
}
```

**Indexes:**
- `isApproved` (ASC) + `isActive` (ASC) + `rating` (DESC)
- `marketSection` (ASC) + `isActive` (ASC)
- `tableNumber` (ASC)
- `ownerId` (ASC)

---

### 3. products (subcollection)

**Path:** `/vendors/{vendorId}/products/{productId}`

Products listed by each vendor.

```typescript
{
  id: string,                    // Document ID
  vendorId: string,              // Parent vendor ID
  name: string,
  category: string,              // 'Vegetables' | 'Fruits' | 'Grains & Cereals' | etc.
  price: number,                 // In USD
  description?: string,
  unit?: string,                 // 'kg' | 'piece' | 'bunch' | etc.
  images: string[],              // Array of Cloud Storage URLs
  stockQuantity: number,         // Default: 0
  isAvailable: boolean,          // Default: true
  isActive: boolean,             // Default: true
  createdAt: Timestamp,
  updatedAt: Timestamp,
  metadata?: {
    [key: string]: any
  }
}
```

**Indexes:**
- `vendorId` (ASC) + `isActive` (ASC) + `category` (ASC)
- `vendorId` (ASC) + `isAvailable` (ASC)
- `category` (ASC) + `isAvailable` (ASC)

---

### 4. orders

**Path:** `/orders/{orderId}`

Customer orders with items from a single vendor.

```typescript
{
  id: string,                    // Document ID
  customerId: string,            // Reference to users/{userId}
  vendorId: string,              // Reference to vendors/{vendorId}
  driverId?: string,             // Reference to users/{userId} (assigned driver)

  // Order items
  items: [
    {
      productId: string,
      vendorId: string,
      quantity: number,
      unitPrice: number,
      productName: string,
      productImage?: string,
      unit?: string
    }
  ],

  // Pricing
  subtotal: number,              // Sum of (quantity * unitPrice)
  deliveryFee: number,           // Calculated based on distance
  total: number,                 // subtotal + deliveryFee

  // Status tracking
  status: string,                // 'pending' | 'confirmed' | 'preparing' | 'ready' |
                                 // 'picked_up' | 'in_transit' | 'delivered' | 'cancelled'

  // Delivery information
  deliveryAddress: {
    street: string,
    suburb: string,
    city: string,
    province?: string,
    postalCode?: string,
    latitude?: number,
    longitude?: number,
    additionalInfo?: string
  },

  // Payment information
  paymentId?: string,            // Reference to payments/{paymentId}
  paymentMethod?: string,        // 'ecocash' | 'card' | 'cash'
  paymentStatus?: string,        // 'pending' | 'processing' | 'completed' | 'failed' | 'refunded'

  // Notes
  customerNotes?: string,
  vendorNotes?: string,
  driverNotes?: string,

  // Timestamps
  createdAt: Timestamp,
  confirmedAt?: Timestamp,
  preparingAt?: Timestamp,
  readyAt?: Timestamp,
  pickedUpAt?: Timestamp,
  deliveredAt?: Timestamp,
  cancelledAt?: Timestamp,

  metadata?: {
    cancelReason?: string,
    [key: string]: any
  }
}
```

**Indexes:**
- `customerId` (ASC) + `createdAt` (DESC)
- `vendorId` (ASC) + `status` (ASC) + `createdAt` (DESC)
- `driverId` (ASC) + `status` (ASC)
- `status` (ASC) + `createdAt` (DESC)
- `paymentStatus` (ASC)

---

### 5. payments

**Path:** `/payments/{paymentId}`

Payment transaction records.

```typescript
{
  id: string,                    // Document ID
  orderId: string,               // Reference to orders/{orderId}
  customerId: string,            // Reference to users/{userId}
  amount: number,                // Total amount paid
  currency: string,              // 'USD'
  provider: string,              // 'ecocash' | 'stripe' | 'mock'
  status: string,                // 'pending' | 'processing' | 'completed' | 'failed' | 'refunded'

  // Provider response data
  providerTransactionId?: string,
  providerResponse?: {
    [key: string]: any           // Raw response from payment provider
  },

  // Error information
  errorCode?: string,
  errorMessage?: string,

  // Timestamps
  createdAt: Timestamp,
  processedAt?: Timestamp,
  completedAt?: Timestamp,
  failedAt?: Timestamp,
  refundedAt?: Timestamp,

  metadata?: {
    refundReason?: string,
    [key: string]: any
  }
}
```

**Indexes:**
- `orderId` (ASC)
- `customerId` (ASC) + `createdAt` (DESC)
- `status` (ASC) + `createdAt` (DESC)
- `providerTransactionId` (ASC)

---

### 6. drivers

**Path:** `/drivers/{driverId}`

Driver-specific information (extends user data).

```typescript
{
  id: string,                    // Document ID (matches userId)
  userId: string,                // Reference to users/{userId}
  vehicleType?: string,          // 'motorcycle' | 'car' | 'bicycle'
  vehicleNumber?: string,
  licenseNumber?: string,
  isApproved: boolean,           // Default: false
  isActive: boolean,             // Default: true
  isOnline: boolean,             // Default: false
  currentLocation?: {
    latitude: number,
    longitude: number,
    accuracy: number,
    timestamp: Timestamp
  },
  rating: number,                // Default: 0.0 (0-5 scale)
  totalReviews: number,          // Default: 0
  totalDeliveries: number,       // Default: 0
  totalEarnings: number,         // Default: 0
  createdAt: Timestamp,
  updatedAt: Timestamp,
  lastOnlineAt?: Timestamp,
  metadata?: {
    [key: string]: any
  }
}
```

**Indexes:**
- `isApproved` (ASC) + `isActive` (ASC) + `isOnline` (ASC)
- `userId` (ASC)

---

### 7. reviews

**Path:** `/reviews/{reviewId}`

Reviews for vendors and drivers.

```typescript
{
  id: string,                    // Document ID
  orderId: string,               // Reference to orders/{orderId}
  reviewerId: string,            // Reference to users/{userId}
  revieweeId: string,            // vendorId or driverId
  revieweeType: string,          // 'vendor' | 'driver'
  rating: number,                // 1-5 stars
  comment?: string,
  images?: string[],             // Optional review images
  createdAt: Timestamp,
  updatedAt?: Timestamp,
  metadata?: {
    [key: string]: any
  }
}
```

**Indexes:**
- `revieweeId` (ASC) + `revieweeType` (ASC) + `createdAt` (DESC)
- `reviewerId` (ASC) + `createdAt` (DESC)
- `orderId` (ASC)

---

### 8. notifications

**Path:** `/notifications/{notificationId}`

User notifications.

```typescript
{
  id: string,                    // Document ID
  userId: string,                // Recipient user ID
  type: string,                  // 'order_update' | 'payment_update' | 'driver_assigned' | etc.
  title: string,
  body: string,
  data?: {                       // Additional notification data
    orderId?: string,
    [key: string]: any
  },
  isRead: boolean,               // Default: false
  createdAt: Timestamp,
  readAt?: Timestamp
}
```

**Indexes:**
- `userId` (ASC) + `isRead` (ASC) + `createdAt` (DESC)

---

### 9. addresses

**Path:** `/addresses/{addressId}`

Saved delivery addresses for customers.

```typescript
{
  id: string,                    // Document ID
  userId: string,                // Reference to users/{userId}
  street: string,
  suburb: string,
  city: string,
  province?: string,
  postalCode?: string,
  country: string,               // Default: 'Zimbabwe'
  latitude?: number,
  longitude?: number,
  additionalInfo?: string,
  isDefault: boolean,            // Default: false
  createdAt: Timestamp
}
```

**Indexes:**
- `userId` (ASC) + `isDefault` (DESC)

---

## Security Considerations

### Read/Write Rules Summary

- **users**: Users can read/write their own document
- **vendors**: Public read (if approved), owner write
- **products**: Public read (if active), vendor owner write
- **orders**: Customer/vendor/driver can read their orders, system writes
- **payments**: Only backend (Cloud Functions) can write
- **drivers**: Public read (if approved), owner write
- **reviews**: Reviewer can write once per order
- **notifications**: User can read/update their own
- **addresses**: User can read/write their own

Detailed security rules are in `/infra/firebase/firestore.rules`.

---

## Data Migration Notes

### Initial Setup

1. Create Firestore database in Firebase Console
2. Deploy security rules: `firebase deploy --only firestore:rules`
3. Deploy indexes: `firebase deploy --only firestore:indexes`

### Seed Data

For development/testing, use the seed script:

```bash
cd infra/scripts
npm install
npm run seed
```

---

## Backup Strategy

- Enable Point-in-Time Recovery (PITR) in Firebase Console
- Schedule daily exports to Cloud Storage
- Retain backups for 30 days

---

*Last Updated: 2025-11-10*
