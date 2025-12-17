# Firebase Setup Guide for MbareToYou

This guide will help you set up Firebase for the MbareToYou customer app so you can test all features.

## Prerequisites

Your Firebase project is already configured with the app (you have `firebase_options.dart`), so you just need to enable services and add test data.

## Step 1: Enable Firebase Authentication

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **mbare-to-you** (or whatever your project is named)
3. In the left sidebar, click **Authentication**
4. Click **Get Started** (if you haven't already)
5. Click **Sign-in method** tab
6. Enable **Email/Password**:
   - Click on **Email/Password**
   - Toggle **Enable** to ON
   - Click **Save**

## Step 2: Create Test User Account

You have two options:

### Option A: Use the App (Recommended)
1. Launch the app on your device
2. Click **Register** on the login screen
3. Fill in the form:
   - **Name**: Demo User
   - **Email**: demo@mbaretoyou.com
   - **Password**: demo123
4. Click **Create Account**
5. You'll be logged in automatically

### Option B: Create Manually in Firebase Console
1. In Firebase Console → **Authentication** → **Users** tab
2. Click **Add User**
3. Enter:
   - **Email**: demo@mbaretoyou.com
   - **Password**: demo123
4. Click **Add User**

## Step 3: Add User Data to Firestore

After creating the user account, you need to add the user document to Firestore:

1. In Firebase Console, click **Firestore Database** in the left sidebar
2. Click **Create database** (if not already created)
3. Choose **Start in test mode** for now (we'll secure it later)
4. Select a location closest to you
5. Click **Enable**

### Add User Document:
1. In Firestore, click **Start collection**
2. Collection ID: `users`
3. Click **Auto-ID** for Document ID (or use the UID from Authentication)
4. Add fields:
   ```
   id: (use the UID from Firebase Auth)
   email: "demo@mbaretoyou.com"
   displayName: "Demo User"
   role: "customer"
   isActive: true (boolean)
   createdAt: (click "timestamp" and select current time)
   updatedAt: (click "timestamp" and select current time)
   ```
5. Click **Save**

## Step 4: Add Test Vendors

1. In Firestore, create a new collection: `vendors`
2. Add your first vendor:
   - Click **Add Document**
   - Document ID: Auto-generate
   - Add fields:
   ```
   id: (same as document ID)
   name: "Fresh Produce by Mai Chipo"
   description: "Fresh vegetables and fruits daily from Mbare Market"
   ownerId: (use your user UID)
   marketSection: "Section A - Vegetables"
   categories: ["Vegetables", "Fruits"] (array)
   isApproved: true (boolean)
   isActive: true (boolean)
   rating: 4.5 (number)
   reviewCount: 24 (number)
   logoUrl: "" (optional - leave empty for now)
   address: "Mbare Musika, Section A, Stall 15"
   phone: "+263 77 123 4567"
   email: "chipo@mbaretoyou.com"
   deliveryFee: 2.5 (number)
   minimumOrder: 5 (number)
   isDeliveryAvailable: true (boolean)
   businessHours: {
     monday: "06:00-18:00"
     tuesday: "06:00-18:00"
     wednesday: "06:00-18:00"
     thursday: "06:00-18:00"
     friday: "06:00-18:00"
     saturday: "06:00-16:00"
     sunday: "CLOSED"
   } (map)
   createdAt: (timestamp)
   updatedAt: (timestamp)
   ```

3. Add a second vendor for variety:
   ```
   name: "Musika Meats"
   description: "Premium quality meat and poultry"
   categories: ["Meat", "Poultry"]
   marketSection: "Section B - Meat"
   ... (similar fields)
   ```

## Step 5: Add Test Products

1. In Firestore, create a new collection: `products`
2. Add sample products:

### Product 1 - Tomatoes
```
id: (auto-generate)
vendorId: (copy vendor ID from step 4)
name: "Fresh Tomatoes"
description: "Locally grown ripe tomatoes"
category: "Vegetables"
price: 2.5 (number)
unit: "kg"
stock: 50 (number)
isAvailable: true (boolean)
imageUrl: "" (optional)
createdAt: (timestamp)
updatedAt: (timestamp)
```

### Product 2 - Onions
```
name: "Red Onions"
description: "Fresh red onions"
category: "Vegetables"
price: 1.8 (number)
unit: "kg"
stock: 100 (number)
isAvailable: true (boolean)
vendorId: (same vendor ID)
createdAt: (timestamp)
updatedAt: (timestamp)
```

### Product 3 - Chicken
```
name: "Whole Chicken"
description: "Fresh whole chicken"
category: "Poultry"
price: 8.5 (number)
unit: "kg"
stock: 20 (number)
isAvailable: true (boolean)
vendorId: (second vendor ID from meat vendor)
createdAt: (timestamp)
updatedAt: (timestamp)
```

Add 5-10 more products for a better testing experience.

## Step 6: Test the App

Now you can test the full shopping flow:

1. **Login**: Use the auto-fill button on login screen
   - Email: demo@mbaretoyou.com
   - Password: demo123

2. **Browse**: You should see vendors and products on the home screen

3. **Add to Cart**: Click on products to add them to your cart

4. **Checkout**: Go to cart and proceed to checkout

5. **Track Orders**: View your orders in the Orders screen

## Quick Firebase Console Links

- **Authentication**: https://console.firebase.google.com/project/YOUR_PROJECT_ID/authentication/users
- **Firestore**: https://console.firebase.google.com/project/YOUR_PROJECT_ID/firestore
- **Project Settings**: https://console.firebase.google.com/project/YOUR_PROJECT_ID/settings/general

## Security Rules (Important!)

For testing, you're using test mode rules. Before going to production, update your Firestore rules:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read their own data
    match /users/{userId} {
      allow read: if request.auth != null && request.auth.uid == userId;
      allow write: if request.auth != null && request.auth.uid == userId;
    }

    // Anyone can read approved vendors and products
    match /vendors/{vendorId} {
      allow read: if resource.data.isApproved == true && resource.data.isActive == true;
      allow write: if request.auth != null && request.auth.uid == resource.data.ownerId;
    }

    match /products/{productId} {
      allow read: if true;
      allow create, update: if request.auth != null;
    }

    // Users can read/write their own orders
    match /orders/{orderId} {
      allow read, write: if request.auth != null && request.auth.uid == resource.data.customerId;
    }
  }
}
```

## Troubleshooting

### Can't login?
- Make sure Email/Password authentication is enabled in Firebase Console
- Check that the user exists in Firebase Authentication
- Verify the user document exists in Firestore `users` collection

### No vendors showing?
- Check that vendors have `isApproved: true` and `isActive: true`
- Verify the Firestore rules allow reading vendors

### Products not loading?
- Make sure `vendorId` in products matches the actual vendor document ID
- Check that products have `isAvailable: true`

## Next Steps

1. Add more vendors and products for a richer experience
2. Upload product images to Firebase Storage
3. Test the complete shopping flow: Browse → Add to Cart → Checkout → Track Order
4. Update Firestore security rules before production
