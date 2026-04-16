## Navigation & Features (Bizzway)

This document maps **Side Drawer** vs **Navbar / Bottom Bar** and what each item does in this repo.

### Important note (about older docs)
- Some earlier Bizzway notes mention custom drawers like `AppDrawer`, `RiderDrawer`, `CustomerHomeDrawer`, etc.
- This repo now uses a **custom push/slide drawer**: `lib/widgets/common/sliding_drawer_shell.dart`.
- Drawer panels:
  - Owner: `lib/widgets/common/owner_side_drawer.dart`
  - Rider: `lib/widgets/common/rider_side_drawer.dart`
  - Customer: `lib/widgets/common/customer_side_drawer.dart`

---

## Business Owner app (Owner Dashboard)

### Side Drawer (Owner)
- **Status**: **No side drawer** in the current owner shell.
- **Owner navigation** is primarily via the **bottom navbar** in `DashboardScreen`.

### Navbar / Bottom Bar (Owner)
- **Where used**: `lib/screens/dashboard/dashboard_screen.dart` → `class DashboardScreen`
- **Widget**: `CurvedNavigationBar`
- **Tabs (index → screen)**:
  - **0 → Dashboard home** (`_DashboardHome`)
  - **1 → Orders/Bookings** (`OrdersScreen`)
    - Label/icon changes for service businesses:
      - Service biz (`salon/gym/clinic`) → **Bookings**
      - Otherwise → **Orders**
  - **2 → Products/Services** (`ProductsScreen`)
    - Service biz → **Services**
    - Otherwise → **Products**
  - **3 → Customers** (`CustomersScreen`)
  - **4 → Profile** (`ProfileScreen`)

### Owner key actions (common)
- **Notifications**: Floating action button (only when tab index is 0) → `AppRoutes.notifications`
- **Add Product / Service**: “Quick Actions” → `AppRoutes.addProduct`
- **Payment**: “Quick Actions” (not shown for food businesses) → `AppRoutes.payment`
- **Profile shortcut**: dashboard header icon switches to tab index **4**

---

## Rider app (Rider Home)

### Side Drawer (Rider)
- **Status**: **No side drawer** in the current rider home screen.

### Navbar / Bottom Bar (Rider)
- **Status**: **No bottom navbar** in the current rider home screen.

### Rider Home screen (what it does)
- **Where used**: `lib/screens/rider/rider_home_screen.dart` → `class RiderHomeScreen`
- **Logout**: AppBar logout → `AuthProvider.logout()` → navigates to `AppRoutes.login` (replacement)
- **Orders shown**:
  - Only jobs that are rider jobs and visible to rider:
    - `j.isRiderJob == true`
    - `j.isVisibleToRider == true`
  - Must be within **5 km** of rider hub (based on `AuthProvider.riderHubLat/riderHubLng`)
- **Key UI sections**:
  - Rider profile card (email, optional bike, wallet, plan)
  - Delivery analytics (Daily / Weekly / Monthly / Yearly)
  - Orders list with actions:
    - Pending → Reject / Details
    - Accepted → Mark delivered (complete)

---

## Customer app (Customer Home)

### Side Drawer (Customer)
- **Status**: **No side drawer** in the current customer home shell.

### Bottom Navbar (Customer)
- **Where used**: `lib/screens/customer/customer_home_screen.dart` → `class CustomerHomeScreen`
- **Widget**: `CurvedNavigationBar`
- **Tabs (index → screen)**:
  - **0 → Home** (`_buildHome()`)
  - **1 → Near Me** (`NearMeScreen`)
  - **2 → Cart** (`_buildCartTab()`)
  - **3 → Bookings** (`MyBookingsScreen`)
  - **4 → Orders** (`CustomerOrdersScreen`)
- **Badges**:
  - **Cart badge**: `CartProvider` item count for active cart business
  - **Orders badge**: `OrderProvider.orders.length`

### Customer Home tab (features)
- **Top mini cards**:
  - **Address**: opens address selector bottom sheet (`_showAddressSheet`)
  - **Search**: filters visible businesses (in-screen search bar)
  - **Prayer**: prayer times UI (from `LocationProvider`)
  - **Upcoming**: jumps to **Bookings** tab (sets bottom nav index to 3)
- **Business browsing**:
  - Uses dummy businesses list (`allDummyBusinesses`)
  - Filtered by selected category (`BusinessType.customerBrowseTypes`) + search query
- **Live owner bridge (demo)**:
  - If `BusinessProvider.selectedBusiness != null`, “LIVE Registered on BizzWay” card appears
  - Built using `Business.fromOwner(...)` + products from `ProductProvider`

---

## Route map (high level)

Routes are defined in `lib/core/routes/app_routes.dart`.

### Common important routes
- **Auth**: `AppRoutes.splash`, `AppRoutes.login`, `AppRoutes.signup`
- **Owner**: `AppRoutes.businessSelection`, `AppRoutes.dashboard`, `AppRoutes.products`, `AppRoutes.addProduct`, `AppRoutes.orders`, `AppRoutes.customers`, `AppRoutes.notifications`, `AppRoutes.profile`, `AppRoutes.payment`
- **Customer**: `AppRoutes.customerHome`
- **Service worker**: `AppRoutes.serviceWorkerHome`
- **Rider**: `AppRoutes.riderHome`

