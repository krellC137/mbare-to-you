# Firebase Setup Walkthrough for MbareToYou

Follow these steps carefully to set up Firebase for your app. This guide assumes you're starting from scratch.

---

## Part 1: Create Firebase Project (10 minutes)

### Step 1: Go to Firebase Console

1. Open your browser and go to: https://console.firebase.google.com/
2. Sign in with your Google account
3. Click **"Add project"** (or **"Create a project"** if this is your first one)

### Step 2: Create the Project

1. **Project name**: Enter `MbareToYou` (or whatever you prefer)
2. Click **Continue**
3. **Google Analytics**: Toggle OFF for now (you can enable later)
4. Click **Create project**
5. Wait for Firebase to set up your project (takes 30-60 seconds)
6. Click **Continue** when done

---

## Part 2: Enable Firebase Authentication (5 minutes)

### Step 1: Go to Authentication

1. In your Firebase project, look at the left sidebar
2. Click **Build** (expand it)
3. Click **Authentication**
4. Click **Get started** button

### Step 2: Enable Email/Password Sign-In

1. Click the **Sign-in method** tab at the top
2. Find **Email/Password** in the list
3. Click on it
4. Toggle **Enable** to ON
5. Click **Save**

**You're done with Authentication setup!**

---

## Part 3: Set Up Firestore Database (5 minutes)

### Step 1: Go to Firestore

1. In the left sidebar, under **Build**
2. Click **Firestore Database**
3. Click **Create database** button

### Step 2: Choose Security Rules

1. Select **Start in test mode** (we'll secure it later)
2. Click **Next**

### Step 3: Choose Location

1. Choose a location closest to you (e.g., `us-central`, `europe-west`, etc.)
2. Click **Enable**
3. Wait for Firestore to initialize (takes 30-60 seconds)

**You're done with Firestore setup!**

---

## Part 4: Configure Your Flutter App (IMPORTANT!)

Now we need to connect your Flutter app to this Firebase project.

### Option A: Using FlutterFire CLI (Recommended - Automatic)

**This will automatically generate the correct configuration files.**

1. **Open a NEW command prompt/terminal** (separate from the one running your app)

2. **Navigate to your project**:
   ```
   cd C:\Users\krell.chiparausha\StudioProjects\mbare_to_you\apps\customer_app
   ```

3. **Login to Firebase**:
   ```
   dart pub global run flutterfire_cli:flutterfire login
   ```
   - This will open your browser
   - Sign in with the same Google account you used for Firebase Console
   - Click **Allow** to grant permissions
   - You'll see "Success!" in the browser
   - Return to your terminal

4. **Configure Firebase for your app**:
   ```
   dart pub global run flutterfire_cli:flutterfire configure
   ```

   **Follow the prompts**:
   - **Select project**: Use arrow keys to select **MbareToYou** (the project you just created)
   - **Select platforms**:
     - Press **Space** to select **android** (it should show `[x] android`)
     - Press **Enter** to continue
   - The CLI will generate `lib/firebase_options.dart` with your actual Firebase configuration
   - You'll see: "Firebase configuration file lib/firebase_options.dart generated successfully"

5. **You're done with this step!** The file `firebase_options.dart` is now configured correctly.

### Option B: Manual Configuration (If FlutterFire CLI doesn't work)

**Only do this if Option A failed.**

1. Go back to Firebase Console: https://console.firebase.google.com/
2. Select your **MbareToYou** project
3. Click the **gear icon** (⚙️) next to "Project Overview" → **Project settings**
4. Scroll down to **"Your apps"** section
5. Click the **Android icon** (robot)
6. Register your app:
   - **Android package name**: `com.example.mbare_to_you`
   - **App nickname** (optional): `MbareToYou Customer App`
   - **Debug signing certificate SHA-1** (optional): Leave blank for now
   - Click **Register app**
7. **Download config file**: Click **Download google-services.json**
8. **Add to your project**:
   - Save the file to: `C:\Users\krell.chiparausha\StudioProjects\mbare_to_you\apps\customer_app\android\app\`
   - Make sure it's named exactly `google-services.json`
9. Click **Next**, then **Continue to console**

---

## Part 5: Create Your First User Account (3 minutes)

Now let's create a test account so you can log in.

### Option A: Using the App (Easiest)

1. **Make sure your app is running** on your phone
2. On the login screen, tap **Register**
3. Fill in the form:
   - **Name**: `Demo User`
   - **Email**: `demo@mbaretoyou.com`
   - **Password**: `demo123`
4. Tap **Create Account**
5. **Done!** The account is created and you'll be logged in

### Option B: Create in Firebase Console

1. Go to Firebase Console → **Authentication** → **Users** tab
2. Click **Add user** button
3. Enter:
   - **Email**: `demo@mbaretoyou.com`
   - **Password**: `demo123`
4. Click **Add user**

### Step 2: Add User Data to Firestore

**Important**: You also need to add the user document to Firestore.

1. Go to Firebase Console → **Firestore Database**
2. Click **Start collection** (or **+ Start collection** if you see that)
3. **Collection ID**: Enter `users`
4. Click **Next**
5. **Document ID**:
   - Copy the user's UID from Authentication → Users tab (looks like: `hG7KpQm3XYZabc123...`)
   - Paste it as the Document ID
6. **Add fields** by clicking **Add field** for each:

   | Field Name | Type | Value |
   |------------|------|-------|
   | `id` | string | (same UID) |
   | `email` | string | demo@mbaretoyou.com |
   | `displayName` | string | Demo User |
   | `role` | string | customer |
   | `isActive` | boolean | true |
   | `createdAt` | timestamp | (click clock icon and select current time) |
   | `updatedAt` | timestamp | (click clock icon and select current time) |

7. Click **Save**

---

## Part 6: Add Test Data (10-15 minutes)

Let's add some vendors and products so you can test the app!

### Add First Vendor

1. In Firestore Database, click **Start collection** (if this is your first) or **+ Add collection**
2. **Collection ID**: `vendors`
3. Click **Next** or **Auto-ID** for document
4. **Add these fields** one by one:

   | Field Name | Type | Value |
   |------------|------|-------|
   | `id` | string | (copy the auto-generated doc ID) |
   | `name` | string | Fresh Produce by Mai Chipo |
   | `description` | string | Fresh vegetables and fruits daily from Mbare Market |
   | `ownerId` | string | (your user UID from step 5) |
   | `marketSection` | string | Section A - Vegetables |
   | `categories` | array | [Vegetables, Fruits] - click array, add items |
   | `isApproved` | boolean | true |
   | `isActive` | boolean | true |
   | `rating` | number | 4.5 |
   | `reviewCount` | number | 24 |
   | `logoUrl` | string | (leave empty) |
   | `address` | string | Mbare Musika, Section A, Stall 15 |
   | `phone` | string | +263 77 123 4567 |
   | `email` | string | chipo@mbaretoyou.com |
   | `deliveryFee` | number | 2.5 |
   | `minimumOrder` | number | 5 |
   | `isDeliveryAvailable` | boolean | true |
   | `businessHours` | map | (see below) |
   | `createdAt` | timestamp | (current time) |
   | `updatedAt` | timestamp | (current time) |

5. For `businessHours` (type: map):
   - Click **Add field**
   - Add these nested fields:
     - `monday`: "06:00-18:00"
     - `tuesday`: "06:00-18:00"
     - `wednesday`: "06:00-18:00"
     - `thursday`: "06:00-18:00"
     - `friday`: "06:00-18:00"
     - `saturday`: "06:00-16:00"
     - `sunday`: "CLOSED"

6. Click **Save**

### Add Second Vendor (Optional but recommended)

Repeat the above but with different values:
- **name**: Musika Meats
- **description**: Premium quality meat and poultry
- **categories**: [Meat, Poultry]
- **marketSection**: Section B - Meat
- (other fields similar)

### Add Products

1. Click **Start collection** or **+ Add collection**
2. **Collection ID**: `products`
3. Add **Product 1 - Tomatoes**:

   | Field Name | Type | Value |
   |------------|------|-------|
   | `id` | string | (auto-generated doc ID) |
   | `vendorId` | string | (copy vendor ID from step above) |
   | `name` | string | Fresh Tomatoes |
   | `description` | string | Locally grown ripe tomatoes |
   | `category` | string | Vegetables |
   | `price` | number | 2.5 |
   | `unit` | string | kg |
   | `stock` | number | 50 |
   | `isAvailable` | boolean | true |
   | `imageUrl` | string | (leave empty) |
   | `createdAt` | timestamp | (current time) |
   | `updatedAt` | timestamp | (current time) |

4. Click **Save**

5. **Add more products** (recommended 3-5 more):
   - Onions (1.8 per kg)
   - Cabbage (1.2 per head)
   - Potatoes (2.0 per kg)
   - Carrots (1.5 per kg)
   - Whole Chicken (8.5 per kg) - use second vendor's ID

---

## Part 7: Test Your App!

1. **Restart your app** (or hot reload won't show new Firebase config)
   - In the terminal where Flutter is running, press `R` (capital R for full restart)
   - OR close the app on your phone and reopen it

2. **Login**:
   - On the login screen, tap the **Auto-fill** button
   - Tap **Sign In**
   - You should be logged in and see the home screen!

3. **Explore**:
   - Home screen should show your vendors
   - Tap a vendor to see products
   - Add products to cart
   - Test checkout
   - View orders

---

## Troubleshooting

### "Firebase not configured" error
- Make sure you ran `flutterfire configure` successfully
- Check that `lib/firebase_options.dart` has real values (not "YOUR_PROJECT_ID")
- Do a full restart of the app (press `R` in terminal)

### "No vendors showing"
- Go to Firestore and verify:
  - Vendors collection exists
  - Vendors have `isApproved: true` and `isActive: true`
  - Check spelling of field names (case-sensitive!)

### "Can't login"
- Verify Email/Password authentication is enabled in Firebase Console
- Check that user exists in Authentication → Users
- Make sure user document exists in Firestore → users collection
- Password must match what you set (demo123)

### "Products not loading"
- Verify `vendorId` in products matches actual vendor document ID (copy-paste it)
- Check products have `isAvailable: true`

---

## Quick Reference

**Test Credentials:**
- Email: demo@mbaretoyou.com
- Password: demo123

**Firebase Console:**
- Main: https://console.firebase.google.com/
- Your Project: https://console.firebase.google.com/project/YOUR_PROJECT_ID/

**Commands:**
- Login: `dart pub global run flutterfire_cli:flutterfire login`
- Configure: `dart pub global run flutterfire_cli:flutterfire configure`
- Restart app: Press `R` in the terminal running Flutter

---

**You're all set! Enjoy testing your MbareToYou app!** 🎉
