import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_colors.dart';
import '../../screens/auth/login/login_constants.dart';
import '../../screens/auth/login/service_branch_switcher.dart';
import '../../screens/business_selection/business_selection_screen.dart';
import '../../screens/customer/book_slot_screen.dart';
import '../../screens/customer/business_detail_screen.dart';
import '../../screens/customer/customer_home_screen.dart';
import '../../screens/customer/customer_orders_screen.dart';
import '../../screens/customer/customer_settings_screen.dart';
import '../../screens/customer/near_me_screen.dart';
import '../../screens/dashboard/dashboard_screen.dart';
import '../../screens/notifications/notifications_screen.dart';
import '../../screens/orders/order_detail_screen.dart';
import '../../screens/orders/orders_screen.dart';
import '../../screens/payment/payment_screen.dart';
import '../../screens/products/add_product_screen.dart'
    show AddProductScreen, InvestorDemoAddProductScenario;
import '../../screens/products/products_screen.dart';
import '../../screens/legal/terms_and_backend_handoff_screen.dart';
import '../../screens/service_worker/job_request_detail_screen.dart';
import '../../screens/service_worker/service_worker_home_screen.dart';
import '../../screens/service_worker/service_worker_live_map_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/rider/rider_home_screen.dart';
import '../../screens/riders/rider_team_screen.dart';
import '../../apps/common/role_login_screens.dart'
    show RiderLoginScreen;
import 'investor_demo_deck_screen.dart';
import '../../models/order.dart';
import '../../providers/auth_provider.dart';
import '../../providers/business_provider.dart';
import '../../providers/job_provider.dart';
import '../../providers/order_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/rider_team_provider.dart';
import '../../models/business_type.dart';
import '../../models/product.dart';
import '../constants/grocery_categories.dart';
import 'demo_typewriter.dart';
import 'demo_voice.dart';
import 'investor_demo_fixtures.dart';

enum DemoTrack { quick, complete, full, business, customer, worker }

/// Wired from [LoginScreen]: controllers + setState so demo can type like a real user.
class LoginDemoControls {
  const LoginDemoControls({
    required this.syncAuthTab,
    required this.shellSetState,
    required this.isMounted,
    required this.emailCtrl,
    required this.passwordCtrl,
    required this.loginPhoneCtrl,
    required this.nameCtrl,
    required this.phoneCtrl,
    required this.signupEmailCtrl,
    required this.signupPasswordCtrl,
    required this.areaCtrl,
    required this.setLoginUserType,
    required this.setLoginServiceBranch,
    required this.setSignupUserType,
    required this.setSignupServiceBranch,
  });

  final void Function(int tabIndex) syncAuthTab;
  final void Function(VoidCallback fn) shellSetState;
  final bool Function() isMounted;

  final TextEditingController emailCtrl;
  final TextEditingController passwordCtrl;
  final TextEditingController loginPhoneCtrl;
  final TextEditingController nameCtrl;
  final TextEditingController phoneCtrl;
  final TextEditingController signupEmailCtrl;
  final TextEditingController signupPasswordCtrl;
  final TextEditingController areaCtrl;

  final void Function(UserType t) setLoginUserType;
  final void Function(ServiceBranch b) setLoginServiceBranch;
  final void Function(UserType t) setSignupUserType;
  final void Function(ServiceBranch b) setSignupServiceBranch;
}

/// Scripted investor demo: typewriter on auth + overlays + onboarding sheet + screen tour.
class InvestorDemoWalkthrough {
  InvestorDemoWalkthrough._();

  static OverlayEntry? _hintEntry;

  /// Active deck for presenter chrome (progress label, accent).
  static DemoTrack _deckTrack = DemoTrack.business;

  static const int _kBusinessSteps = 18;
  static const int _kCustomerSteps = 10;
  static const int _kWorkerSteps = 8;

  static Future<void> run(
    BuildContext launcherContext, {
    required LoginDemoControls demo,
    DemoTrack track = DemoTrack.business,
  }) async {
    _deckTrack = track;
    switch (track) {
      case DemoTrack.quick:
        await _runQuickDemo(launcherContext, demo);
        return;
      case DemoTrack.complete:
        await _runCompleteDemo(launcherContext, demo);
        return;
      case DemoTrack.full:
        await _runFullDemo(launcherContext, demo);
        return;
      case DemoTrack.business:
        await _runBusinessOwnerDemo(launcherContext, demo);
        return;
      case DemoTrack.customer:
        await _runCustomerDemo(launcherContext, demo);
        return;
      case DemoTrack.worker:
        await _runWorkerDemo(launcherContext, demo);
        return;
    }
  }

  /// A short, high-signal walkthrough (2–3 min) for first-time viewers.
  /// Goal: anyone can understand what the app does without getting lost.
  static Future<void> _runQuickDemo(
    BuildContext launcherContext,
    LoginDemoControls d,
  ) async {
    final nav = Navigator.of(launcherContext, rootNavigator: true);

    Future<void> pause([int ms = 520]) =>
        Future<void>.delayed(Duration(milliseconds: ms));

    Future<void> narrate(
      String title,
      String subtitle, {
      int? stepIndex,
      int totalSteps = 6,
      int ms = 5200,
    }) async {
      await pause(220);
      if (!launcherContext.mounted) return;
      _showCoach(
        launcherContext,
        title,
        subtitle,
        stepIndex: stepIndex,
        totalSteps: totalSteps,
      );
      unawaited(DemoVoice.speak(title, subtitle));
      await Future<void>.delayed(Duration(milliseconds: ms));
      _removeCoach();
    }

    Future<void> flash(
      Widget page,
      String title,
      String subtitle, {
      required int stepIndex,
      int totalSteps = 6,
      int dwellMs = 7800,
      int peekUiMs = 950,
    }) async {
      await pause(240);
      if (!launcherContext.mounted) return;

      final route = MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => page,
      );

      final done = Completer<void>();
      unawaited(
        nav.push(route).whenComplete(() {
          if (!done.isCompleted) done.complete();
        }),
      );

      final peek = peekUiMs.clamp(400, dwellMs);
      await Future<void>.delayed(Duration(milliseconds: peek));
      if (!launcherContext.mounted) return;

      _showCoach(
        launcherContext,
        title,
        subtitle,
        stepIndex: stepIndex,
        totalSteps: totalSteps,
      );
      unawaited(DemoVoice.speak(title, subtitle));
      await Future<void>.delayed(Duration(milliseconds: dwellMs - peek));
      _removeCoach();
      if (!launcherContext.mounted) return;
      if (route.isActive) nav.pop();
      await done.future;
    }

    try {
      if (!launcherContext.mounted) return;

      await narrate(
        'What this app does',
        'Customers place orders or request services. Businesses manage items, deals, and orders. '
            'Team riders and service providers fulfill and update status.',
        stepIndex: 1,
      );

      await flash(
        const BusinessSelectionScreen(),
        'Businesses set up their type',
        'Grocery, restaurant, rent-a-car, or services — each unlocks the right workflow.',
        stepIndex: 2,
        dwellMs: 9000,
      );

      await flash(
        const AddProductScreen(
          investorDemoPrefill: true,
          investorDemoScenario: InvestorDemoAddProductScenario.groceryBundle,
        ),
        'Merchant adds items and deals',
        'Add products, then create bundles/combos for seasonal promotions.',
        stepIndex: 3,
        dwellMs: 10000,
      );

      await flash(
        const OrdersScreen(initialOrdersTabIndex: 1),
        'Orders come in, status updates go out',
        'Pending → Active → Completed. Customer always sees the latest status.',
        stepIndex: 4,
        dwellMs: 9500,
      );

      await flash(
        const NearMeScreen(),
        'Customer finds nearby options',
        'Discovery uses distance/radius so the customer sees what’s close and available.',
        stepIndex: 5,
        dwellMs: 9500,
      );

      await flash(
        const ServiceWorkerLiveMapScreen(),
        'Fulfillment view',
        'Team riders and service providers can navigate, accept work, and complete tasks.',
        stepIndex: 6,
        dwellMs: 9500,
      );
    } finally {
      _removeCoach();
    }
  }

  /// Full demo in the same "quick" style (5–6 min).
  /// Covers: merchant → customer → services → team rider.
  static Future<void> _runFullDemo(
    BuildContext launcherContext,
    LoginDemoControls d,
  ) async {
    final nav = Navigator.of(launcherContext, rootNavigator: true);

    const totalSteps = 10;

    Future<void> pause([int ms = 520]) =>
        Future<void>.delayed(Duration(milliseconds: ms));

    Future<void> narrate(
      String title,
      String subtitle, {
      int? stepIndex,
      int ms = 5200,
    }) async {
      await pause(220);
      if (!launcherContext.mounted) return;
      _showCoach(
        launcherContext,
        title,
        subtitle,
        stepIndex: stepIndex,
        totalSteps: totalSteps,
      );
      unawaited(DemoVoice.speak(title, subtitle));
      await Future<void>.delayed(Duration(milliseconds: ms));
      _removeCoach();
    }

    Future<void> flash(
      Widget page,
      String title,
      String subtitle, {
      required int stepIndex,
      int dwellMs = 9000,
      int peekUiMs = 950,
    }) async {
      await pause(240);
      if (!launcherContext.mounted) return;

      final route = MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => page,
      );

      final done = Completer<void>();
      unawaited(
        nav.push(route).whenComplete(() {
          if (!done.isCompleted) done.complete();
        }),
      );

      final peek = peekUiMs.clamp(400, dwellMs);
      await Future<void>.delayed(Duration(milliseconds: peek));
      if (!launcherContext.mounted) return;

      _showCoach(
        launcherContext,
        title,
        subtitle,
        stepIndex: stepIndex,
        totalSteps: totalSteps,
      );
      unawaited(DemoVoice.speak(title, subtitle));
      await Future<void>.delayed(Duration(milliseconds: dwellMs - peek));
      _removeCoach();
      if (!launcherContext.mounted) return;
      if (route.isActive) nav.pop();
      await done.future;
    }

    try {
      if (!launcherContext.mounted) return;

      await narrate(
        'Full demo (all flows)',
        'Merchant adds items and deals. Customers order and track updates. Service providers accept nearby jobs. '
            'Team riders deliver using their login.',
        stepIndex: 1,
        ms: 6200,
      );

      await flash(
        const BusinessSelectionScreen(),
        '1) Choose business type',
        'Pick grocery, restaurant, rent-a-car, or services to unlock the right workflow.',
        stepIndex: 2,
        dwellMs: 9000,
      );

      await flash(
        const AddProductScreen(
          investorDemoPrefill: true,
          investorDemoScenario: InvestorDemoAddProductScenario.groceryBundle,
        ),
        '2) Add items and deals',
        'Products, bundles, combos — create promotions in minutes.',
        stepIndex: 3,
        dwellMs: 10500,
      );

      await flash(
        const OrdersScreen(initialOrdersTabIndex: 1),
        '3) Manage orders',
        'Accept, assign, and move orders through Pending → Active → Completed.',
        stepIndex: 4,
        dwellMs: 9500,
      );

      await flash(
        const RiderTeamScreen(),
        '4) Team rider directory',
        'Create rider IDs here. Riders log in from “Team rider login”.',
        stepIndex: 5,
        dwellMs: 9500,
      );

      await flash(
        const CustomerHomeScreen(),
        '5) Customer discovery',
        'Customers browse nearby businesses and services.',
        stepIndex: 6,
        dwellMs: 9000,
      );

      await flash(
        const NearMeScreen(),
        '6) Nearby (radius)',
        'Nearby uses a radius so results stay close and relevant.',
        stepIndex: 7,
        dwellMs: 9000,
      );

      await flash(
        BusinessDetailScreen(
          business: investorDemoCheckoutBusiness(),
          investorDemoAutoPlaceOrder: true,
        ),
        '7) Checkout',
        'Pick items and place an order. Status updates start immediately.',
        stepIndex: 8,
        dwellMs: 14000,
        peekUiMs: 1600,
      );

      await flash(
        const ServiceWorkerHomeScreen(),
        '8) Service provider jobs',
        'New requests appear here. Accept and start.',
        stepIndex: 9,
        dwellMs: 9000,
      );

      await flash(
        const RiderLoginScreen(),
        '9) Team rider login',
        'Your own riders log in and handle assigned deliveries.',
        stepIndex: 10,
        dwellMs: 9500,
      );
    } finally {
      _removeCoach();
    }
  }

  /// Complete system demo (8–12 min), still easy language.
  /// Story order (easy to narrate): merchant → customer → team rider → services → revenue.
  static Future<void> _runCompleteDemo(
    BuildContext launcherContext,
    LoginDemoControls d,
  ) async {
    final nav = Navigator.of(launcherContext, rootNavigator: true);

    /// One progress bar across intro, bridges, and screens (viewer always knows position).
    const totalSteps = 24;

    Future<void> pause([int ms = 520]) =>
        Future<void>.delayed(Duration(milliseconds: ms));

    Future<void> narrate(
      String title,
      String subtitle, {
      int? stepIndex,
      int ms = 7200,
    }) async {
      await pause(240);
      if (!launcherContext.mounted) return;
      _showCoach(
        launcherContext,
        title,
        subtitle,
        stepIndex: stepIndex,
        totalSteps: totalSteps,
      );
      unawaited(DemoVoice.speak(title, subtitle));
      await Future<void>.delayed(Duration(milliseconds: ms));
      _removeCoach();
    }

    Future<void> flash(
      Widget page,
      String title,
      String subtitle, {
      required int stepIndex,
      int dwellMs = 11800,
      int peekUiMs = 1200,
    }) async {
      await pause(260);
      if (!launcherContext.mounted) return;

      final route = MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => page,
      );

      final done = Completer<void>();
      unawaited(
        nav.push(route).whenComplete(() {
          if (!done.isCompleted) done.complete();
        }),
      );

      final peek = peekUiMs.clamp(400, dwellMs);
      await Future<void>.delayed(Duration(milliseconds: peek));
      if (!launcherContext.mounted) return;

      _showCoach(
        launcherContext,
        title,
        subtitle,
        stepIndex: stepIndex,
        totalSteps: totalSteps,
      );
      unawaited(DemoVoice.speak(title, subtitle));
      await Future<void>.delayed(Duration(milliseconds: dwellMs - peek));
      _removeCoach();
      if (!launcherContext.mounted) return;
      if (route.isActive) nav.pop();
      await done.future;
    }

    try {
      if (!launcherContext.mounted) return;

      await narrate(
        'Complete demo — what you will see',
        'Four actors: the merchant builds the storefront, the customer orders, the team rider delivers, '
            'the service provider fulfills jobs nearby. Revenue comes last.',
        stepIndex: 1,
        ms: 9000,
      );

      await flash(
        const BusinessSelectionScreen(),
        'Part 1 · Merchant · business type',
        'Pick grocery, restaurant, rent-a-car, or services — each unlocks the right workflows.',
        stepIndex: 2,
      );

      await flash(
        const DashboardScreen(investorDemoAutoOpenDrawer: true),
        'Merchant · dashboard',
        'One hub: catalogue, pending orders, team riders — everything the merchant needs daily.',
        stepIndex: 3,
        peekUiMs: 1600,
      );

      await flash(
        const AddProductScreen(
          investorDemoPrefill: true,
          investorDemoScenario: InvestorDemoAddProductScenario.groceryBundle,
        ),
        'Merchant · add items & bundles',
        'List single items and bundles (combos/deals). This is where promotions live.',
        stepIndex: 4,
      );

      await flash(
        const ProductsScreen(),
        'Merchant · catalogue',
        'Search, tabs, edits — merchants keep pricing and stock feeling “under control”.',
        stepIndex: 5,
      );

      await flash(
        const OrdersScreen(initialOrdersTabIndex: 1),
        'Merchant · order queue',
        'Orders appear here. Tabs keep Pending vs Active vs Done obvious for staff.',
        stepIndex: 6,
      );

      await flash(
        OrderDetailScreen(
          order: investorDemoDeliveryOrderForAssign(),
          investorDemoAutoOpenAssignSheet: true,
        ),
        'Merchant · order detail & assign rider',
        'One screen: buyer, items, address, notes — assign a team rider without losing context.',
        stepIndex: 7,
      );

      await narrate(
        'Part 2 · Customer',
        'Now the shopper side: find something nearby, add to cart, and place one order.',
        stepIndex: 8,
        ms: 7000,
      );

      await flash(
        const CustomerHomeScreen(),
        'Customer · discovery',
        'Browse shops and services — the same app for food, groceries, and more.',
        stepIndex: 9,
      );

      await flash(
        const NearMeScreen(),
        'Customer · near you',
        'Radius filtering keeps listings relevant — “close” beats “everything”.',
        stepIndex: 10,
      );

      await flash(
        BusinessDetailScreen(
          business: investorDemoCheckoutBusiness(),
          investorDemoAutoPlaceOrder: true,
        ),
        'Customer · storefront & checkout',
        'Cart → confirm → placed. That creates the merchant order we just queued.',
        stepIndex: 11,
        dwellMs: 15000,
        peekUiMs: 1600,
      );

      await narrate(
        'Part 3 · Team rider (merchant-owned)',
        'Delivery is staffed by merchants today: rider IDs created in “Team riders”.',
        stepIndex: 12,
        ms: 7000,
      );

      await flash(
        const RiderTeamScreen(),
        'Team rider · directory',
        'Issue Rider ID + phone — structured dispatch beats random chat threads.',
        stepIndex: 13,
      );

      await flash(
        const RiderLoginScreen(),
        'Team rider · login',
        'Riders use “Team rider login” — not the main gig-rider signup (phase 2 idea).',
        stepIndex: 14,
      );

      await flash(
        const RiderHomeScreen(),
        'Team rider · workspace',
        'Assigned deliveries show up here. Status updates propagate to the buyer.',
        stepIndex: 15,
      );

      await narrate(
        'Part 4 · Service provider jobs',
        'Technicians see nearby requests, open details, and navigate.',
        stepIndex: 16,
        ms: 7000,
      );

      await flash(
        const ServiceWorkerHomeScreen(),
        'Technician · job board',
        'Requests drop in newest-first — accept jobs you can fulfil today.',
        stepIndex: 17,
      );

      await flash(
        JobRequestDetailScreen(request: investorDemoSampleJobAc()),
        'Technician · job detail',
        'Issue notes, ETA, maps link — clarity before dispatch.',
        stepIndex: 18,
      );

      await flash(
        const ServiceWorkerLiveMapScreen(),
        'Technician · live map',
        'Pin + routing reduces missed turns and arguing about addresses.',
        stepIndex: 19,
      );

      await narrate(
        'Revenue · how money is made',
        'Revenue has 3 levers: (1) subscriptions paid monthly by merchants/providers, (2) usage fees per '
            'order / booking / delivery as volume grows, (3) paid promotions (featured listings).',
        stepIndex: 20,
        ms: 12000,
      );

      await narrate(
        'Revenue · simple monthly calculation',
        'Example: 200 active merchants on a 49/month plan = 9,800/month. Add small usage fees on orders '
            'and deliveries to scale as activity grows.',
        stepIndex: 21,
        ms: 11000,
      );

      await narrate(
        'Plans · what you sell',
        'Starter for small merchants, Growth for busy merchants, Pro for multi-branch. '
            'Service providers can have a dedicated plan focused on jobs and visibility.',
        stepIndex: 22,
        ms: 11000,
      );

      await narrate(
        '12‑month roadmap',
        'Months 1–2: stabilize onboarding. 3–5: retention and operations. 6–9: promotions + scale. '
            '10–12: expansion and optional platform-wide riders.',
        stepIndex: 23,
        ms: 12000,
      );

      await flash(
        const InvestorDemoDeckScreen(),
        'Investor slide (numbers + plan)',
        'A clean one-screen summary: how it works, revenue levers, calculator, and roadmap.',
        stepIndex: 24,
        dwellMs: 20000,
        peekUiMs: 1200,
      );
    } finally {
      _removeCoach();
    }
  }

  static Future<void> _runBusinessOwnerDemo(
    BuildContext launcherContext,
    LoginDemoControls d,
  ) async {
    final nav = Navigator.of(launcherContext, rootNavigator: true);

    Future<void> pause([int ms = 520]) =>
        Future<void>.delayed(Duration(milliseconds: ms));

    Future<void> typing(
      TextEditingController c,
      String text, {
      Duration perChar = const Duration(milliseconds: 38),
    }) =>
        DemoTypewriter.fill(
          c,
          text,
          perChar: perChar,
          shouldAbort: () => !d.isMounted(),
        );

    void wipeAuthFields() {
      if (!d.isMounted()) return;
      d.shellSetState(() {
        d.emailCtrl.clear();
        d.passwordCtrl.clear();
        d.loginPhoneCtrl.clear();
        d.nameCtrl.clear();
        d.phoneCtrl.clear();
        d.signupEmailCtrl.clear();
        d.signupPasswordCtrl.clear();
        d.areaCtrl.clear();
      });
    }

    Future<void> narrate(
      String title,
      String subtitle, {
      int? stepIndex,
      int ms = 8200,
      int settleMsBeforeCaption = 0,
    }) async {
      await pause(260 + settleMsBeforeCaption);
      if (!launcherContext.mounted) return;
      _showCoach(
        launcherContext,
        title,
        subtitle,
        stepIndex: stepIndex,
        totalSteps: _kBusinessSteps,
      );
      unawaited(DemoVoice.speak(title, subtitle));
      await Future<void>.delayed(Duration(milliseconds: ms));
      _removeCoach();
    }

    /// Short caption after an action (e.g. typing) so the viewer reads context after seeing it.
    Future<void> recap(
      String title,
      String subtitle, {
      int? stepIndex,
      int ms = 4200,
    }) async {
      await pause(240);
      if (!launcherContext.mounted) return;
      _showCoach(
        launcherContext,
        title,
        subtitle,
        stepIndex: stepIndex,
        totalSteps: _kBusinessSteps,
      );
      unawaited(DemoVoice.speak(title, subtitle));
      await Future<void>.delayed(Duration(milliseconds: ms));
      _removeCoach();
    }

    /// Pushes a screen, lets the UI render [peekUiMs] with no caption, then shows the coach on top.
    Future<void> flash(
      Widget page,
      String title,
      String subtitle, {
      required int stepIndex,
      int dwellMs = 7800,
      int peekUiMs = 1100,
    }) async {
      await pause(260);
      if (!launcherContext.mounted) return;

      final route = MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => page,
      );

      final done = Completer<void>();
      unawaited(
        nav.push(route).whenComplete(() {
          if (!done.isCompleted) done.complete();
        }),
      );

      final peek = peekUiMs.clamp(400, dwellMs);
      await Future<void>.delayed(Duration(milliseconds: peek));

      if (!launcherContext.mounted) return;
      _showCoach(
        launcherContext,
        title,
        subtitle,
        stepIndex: stepIndex,
        totalSteps: _kBusinessSteps,
      );
      unawaited(DemoVoice.speak(title, subtitle));

      final captionMs = dwellMs - peek;
      await Future<void>.delayed(
        Duration(milliseconds: captionMs < 2000 ? 2000 : captionMs),
      );

      _removeCoach();
      if (!launcherContext.mounted) return;
      if (route.isActive) nav.pop();
      await done.future;
    }

    try {
      if (!launcherContext.mounted) return;
      InvestorDemoLastCheckout.placedOrderId = null;

      Future<void> seedBusinessDemoData() async {
        if (!launcherContext.mounted) return;
        final biz = launcherContext.read<BusinessProvider>();
        final products = launcherContext.read<ProductProvider>();
        final orders = launcherContext.read<OrderProvider>();
        final team = launcherContext.read<RiderTeamProvider>();

        // Ensure a stable business id for scoping (grocery for this demo).
        if ((biz.selectedBusiness?.id ?? '').isEmpty) {
          final type = BusinessType.all.firstWhere(
            (t) => t.id == 'grocery',
            orElse: () => BusinessType.all.first,
          );
          await biz.selectBusiness(type);
        }
        final bizId = biz.selectedBusiness?.id ?? 'grocery';

        // Seed a team rider so Assign Rider sheet can actually pick someone.
        await team.ensureLoaded();
        final already = team
            .ridersFor(bizId)
            .any(
              (r) =>
                  r.riderId.toLowerCase() ==
                  kInvestorDemoTeamRiderId.toLowerCase(),
            );
        if (!already) {
          await team.addRider(
            businessId: bizId,
            riderId: kInvestorDemoTeamRiderId,
            name: 'Ali Rider',
            phone: kInvestorDemoTeamRiderPhone,
            maxAllowed: null,
          );
        }

        // Seed a real product so ProductsScreen visibly contains it (not just a pre-filled form).
        final skuId = 'sku_ramadan_pack';
        final hasSku = products.products.any((p) => p.id == skuId);
        if (!hasSku) {
          products.addProduct(
            Product(
              id: skuId,
              businessTypeId: bizId,
              name: 'Ramadan Family Pack',
              description:
                  'Bundle pack (dates + drink + staples) — limited offer.',
              price: 3499,
              category: GroceryCategories.aisleNames[3],
              discountPercent: 15,
              unit: 'per pack',
              isRamzanSpecial: true,
              bundleItems: const [
                'Premium dates 500g',
                'Rooh Afza 750ml',
                'Chana daal 1kg',
              ],
            ),
          );
        }

        // Seed multiple daily orders so OrdersScreen looks alive.
        final daily = <Order>[
          investorDemoDeliveryOrderForAssign(),
          Order(
            id: 'ORD-DEMO-PENDING-002',
            customerId: 'demo_customer_2',
            customerName: 'Sara Buyer',
            customerPhone: '03004567890',
            customerAddress: 'Model Town, Karachi',
            customerLat: 24.8612,
            customerLng: 67.0099,
            items: const [
              OrderItem(
                productId: 'sku_ramadan_pack',
                productName: 'Ramadan Family Pack',
                quantity: 1,
                unitPrice: 3499,
              ),
            ],
            status: OrderStatus.pending,
            notes: 'Leave at reception',
            businessTypeId: bizId,
            businessTypeName: 'Grocery',
            deliveryCharge: 150,
            isDelivery: true,
          ),
          Order(
            id: 'ORD-DEMO-COMPLETED-003',
            customerId: 'demo_customer_3',
            customerName: 'Hassan Buyer',
            customerPhone: '03009998877',
            customerAddress: 'Johar Chorangi, Karachi',
            customerLat: 24.9120,
            customerLng: 67.1492,
            items: const [
              OrderItem(
                productId: 'inv_milk',
                productName: 'Full Cream Milk 1L',
                quantity: 2,
                unitPrice: 285,
              ),
              OrderItem(
                productId: 'inv_bread',
                productName: 'Brown Bread Large',
                quantity: 1,
                unitPrice: 230,
              ),
            ],
            status: OrderStatus.completed,
            notes: 'Delivered — demo',
            businessTypeId: bizId,
            businessTypeName: 'Grocery',
            deliveryCharge: 80,
            isDelivery: true,
          ),
        ];
        for (final o in daily) {
          if (!orders.orders.any((x) => x.id == o.id)) {
            orders.addOrder(o);
          }
        }
      }

      Future<void> pickBiz(String businessTypeId) async {
        if (!launcherContext.mounted) return;
        final biz = launcherContext.read<BusinessProvider>();
        BusinessType type;
        try {
          type = BusinessType.all.firstWhere((t) => t.id == businessTypeId);
        } catch (_) {
          type = BusinessType.all.firstWhere(
            (t) => t.id == 'grocery',
            orElse: () => BusinessType.all.first,
          );
        }
        await biz.selectBusiness(type);
      }

      await narrate(
        'Step 1 — What the merchant gets',
        'A simple operations app: add items and deals, receive orders, update status, and assign your '
            'own team rider for delivery.',
        stepIndex: 1,
        ms: 8200,
      );

      if (!launcherContext.mounted) return;
      wipeAuthFields();
      d.syncAuthTab(1);
      await pause(400);
      d.shellSetState(() => d.setLoginUserType(UserType.businessOwner));
      d.shellSetState(() => d.setSignupUserType(UserType.businessOwner));
      await pause(450);

      await typing(d.nameCtrl, 'Demo POS Shop');
      await pause(200);
      await typing(d.signupEmailCtrl, 'merchant.demo@bizzway.pk');
      await pause(180);
      await typing(d.signupPasswordCtrl, 'demo123');
      await pause(450);

      await recap(
        'Step 2 — New merchant registration',
        'Store name, email, password—then choose your business type (grocery, restaurant, rent-a-car, '
            'or services).',
        stepIndex: 2,
        ms: 4600,
      );

      wipeAuthFields();
      d.syncAuthTab(0);
      await pause(350);
      await typing(d.emailCtrl, 'demo.owner@bizzway.pk');
      await pause(180);
      await typing(d.passwordCtrl, 'demo123');
      await pause(450);

      await recap(
        'Step 3 — Returning merchant login',
        'Email + password—daily entry for owners managing items, deals, and orders.',
        stepIndex: 3,
        ms: 4400,
      );

      await narrate(
        'Step 4 — Delivery network policy',
        'Delivery can be handled by your own team rider. You create rider IDs in the side menu and '
            'they log in using “Team rider login”.',
        stepIndex: 4,
        ms: 4200,
      );

      if (launcherContext.mounted) {
        await ServiceBranchSwitcher.showRiderComingSoonSheet(launcherContext);
      }

      await pause(260);

      await flash(
        const BusinessSelectionScreen(),
        'Step 5 — Choose business type',
        'Each type unlocks the right tools: grocery bundles, restaurant combos, rent-a-car listings, '
            'or service workflows.',
        stepIndex: 5,
        dwellMs: 9500,
        peekUiMs: 1100,
      );

      await pause(600);
      if (launcherContext.mounted) {
        await openInvestorDemoBusinessSetupSheet(launcherContext);
      }
      await pause(450);

      await narrate(
        'Step 6 — Store profile & delivery zone',
        'Set branding, hours, and delivery radius so customers know where you deliver and what to expect.',
        stepIndex: 6,
        ms: 6400,
      );

      await seedBusinessDemoData();

      await flash(
        const DashboardScreen(investorDemoAutoOpenDrawer: true),
        'Step 7 — Side menu: Meray riders',
        'Tap the menu (top-left). Meray riders is where you issue Rider ID + mobile—your '
            'delivery staff use these on Team rider login. Same flow whether you run a mart, '
            'kitchen, or dark-store.',
        stepIndex: 7,
        dwellMs: 15000,
        peekUiMs: 1600,
      );

      await flash(
        const RiderTeamScreen(),
        'Step 8 — Team rider directory',
        'Add or edit riders: ID, name, phone. Assign deliveries in a structured way (instead of manual '
            'messages).',
        stepIndex: 8,
        dwellMs: 13800,
        peekUiMs: 1400,
      );

      await flash(
        const OrdersScreen(initialOrdersTabIndex: 1),
        'Step 9 — Order queue (Pending)',
        'New orders land here. Move them through Pending → Active → Completed with clear status updates.',
        stepIndex: 9,
        dwellMs: 10500,
        peekUiMs: 1400,
      );

      Order detailTarget = investorDemoDeliveryOrderForAssign();
      if (launcherContext.mounted) {
        final op = launcherContext.read<OrderProvider>();
        final bp = launcherContext.read<BusinessProvider>();
        final bid = bp.selectedBusiness?.id ?? 'grocery';
        final pendingAssignable = op.orders.where((o) {
          final noRider = (o.assignedRiderName ?? '').trim().isEmpty;
          return o.businessTypeId == bid &&
              o.isDelivery &&
              noRider &&
              o.status != OrderStatus.completed &&
              o.status != OrderStatus.cancelled;
        }).toList();
        if (pendingAssignable.isNotEmpty) {
          pendingAssignable.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          detailTarget = pendingAssignable.first;
        }
      }

      await flash(
        OrderDetailScreen(
          order: detailTarget,
          investorDemoAutoOpenAssignSheet: true,
        ),
        'Step 10 — Dispatch to rider',
        'Assign the order to your team rider—customer phone and PKR order value travel with the job '
            'so your rider can execute cash-on-delivery or contactless handover.',
        stepIndex: 10,
        dwellMs: 17800,
        peekUiMs: 1300,
      );

      await flash(
        const ProductsScreen(),
        'Step 11 — Product catalog (PKR)',
        'Everything customers see on the storefront—priced in rupees, synced with what you publish. '
            'Switch vertical after this tour to compare forms.',
        stepIndex: 11,
        dwellMs: 7800,
        peekUiMs: 1000,
      );

      await pickBiz('grocery');
      await pause(320);
      await flash(
        const AddProductScreen(
          investorDemoScenario: InvestorDemoAddProductScenario.groceryBundle,
        ),
        'Step 12 — Grocery bundle listing',
        'Hypermart-style pack: bundle lines, discount %, Ramadan flag—ideal for seasonal pushes and '
            'staple combos Pakistani households buy every week.',
        stepIndex: 12,
        dwellMs: 14800,
        peekUiMs: 1300,
      );

      await pickBiz('restaurant');
      await pause(320);
      await flash(
        const AddProductScreen(
          investorDemoScenario: InvestorDemoAddProductScenario.restaurantCombo,
        ),
        'Step 13 — Restaurant combo meal',
        'Multi-item combo with one PKR price—same logic as chain meal boxes and iftar deals across '
            'cities.',
        stepIndex: 13,
        dwellMs: 14800,
        peekUiMs: 1300,
      );

      await pickBiz('rentacar');
      await pause(320);
      await flash(
        const AddProductScreen(
          investorDemoScenario: InvestorDemoAddProductScenario.rentacarVehicle,
        ),
        'Step 14 — Rent-a-car fleet row',
        'List each vehicle by segment (SUV, Sedan, …)—daily PKR rate for self-drive or tour packages, '
            'matching weekend and event demand.',
        stepIndex: 14,
        dwellMs: 13800,
        peekUiMs: 1300,
      );

      await pickBiz('grocery');
      await pause(240);

      await flash(
        const PaymentScreen(),
        'Step 15 — Plans & settlements',
        'Merchant subscription and payout paths—including JazzCash / Easypaisa-style settlement '
            'expectations as you scale beyond cash.',
        stepIndex: 15,
        dwellMs: 7500,
        peekUiMs: 900,
      );

      await flash(
        const NotificationsScreen(),
        'Step 16 — Alerts & notifications',
        'Operational signals: new orders, rider movement—stay ahead of peak slots without losing '
            'WhatsApp-level urgency.',
        stepIndex: 16,
        dwellMs: 6800,
        peekUiMs: 900,
      );

      await flash(
        const ProfileScreen(),
        'Step 17 — Brand & delivery economics',
        'Theme colour for your storefront and PKR delivery rules—keep pricing consistent whether '
            'you serve one neighbourhood or multiple phases.',
        stepIndex: 17,
        dwellMs: 10800,
        peekUiMs: 1100,
      );

      await flash(
        const TermsAndBackendHandoffScreen(),
        'Step 18 — Terms & compliance',
        'Merchant terms your buyers accept—important for trust and dispute handling in local '
            'e-commerce.',
        stepIndex: 18,
        dwellMs: 9800,
        peekUiMs: 1100,
      );

      await narrate(
        'Merchant tour complete',
        'End-to-end Pakistan merchant story: onboarding, Meray riders & dispatch, PKR catalog '
            '(grocery, food, mobility), JazzCash/Easypaisa-ready billing, and compliance.',
        stepIndex: null,
        ms: 8200,
      );
    } finally {
      _removeCoach();
      wipeAuthFields();
      if (d.isMounted()) {
        d.syncAuthTab(0);
        d.shellSetState(() {
          d.setLoginUserType(UserType.businessOwner);
          d.setSignupUserType(UserType.customer);
          d.setLoginServiceBranch(ServiceBranch.home);
          d.setSignupServiceBranch(ServiceBranch.home);
        });
      }
      if (launcherContext.mounted) {
        nav.popUntil((r) => r.isFirst);
      }
    }
  }

  static Future<void> _runCustomerDemo(
    BuildContext launcherContext,
    LoginDemoControls d,
  ) async {
    final nav = Navigator.of(launcherContext, rootNavigator: true);

    Future<void> pause([int ms = 520]) =>
        Future<void>.delayed(Duration(milliseconds: ms));

    Future<void> typing(
      TextEditingController c,
      String text, {
      Duration perChar = const Duration(milliseconds: 38),
    }) =>
        DemoTypewriter.fill(
          c,
          text,
          perChar: perChar,
          shouldAbort: () => !d.isMounted(),
        );

    void wipeAuthFields() {
      if (!d.isMounted()) return;
      d.shellSetState(() {
        d.emailCtrl.clear();
        d.passwordCtrl.clear();
        d.loginPhoneCtrl.clear();
        d.nameCtrl.clear();
        d.phoneCtrl.clear();
        d.signupEmailCtrl.clear();
        d.signupPasswordCtrl.clear();
        d.areaCtrl.clear();
      });
    }

    Future<void> narrate(
      String title,
      String subtitle, {
      int? stepIndex,
      int ms = 7800,
    }) async {
      await pause(260);
      if (!launcherContext.mounted) return;
      _showCoach(
        launcherContext,
        title,
        subtitle,
        stepIndex: stepIndex,
        totalSteps: _kCustomerSteps,
      );
      unawaited(DemoVoice.speak(title, subtitle));
      await Future<void>.delayed(Duration(milliseconds: ms));
      _removeCoach();
    }

    Future<void> recap(
      String title,
      String subtitle, {
      int? stepIndex,
      int ms = 4000,
    }) async {
      await pause(240);
      if (!launcherContext.mounted) return;
      _showCoach(
        launcherContext,
        title,
        subtitle,
        stepIndex: stepIndex,
        totalSteps: _kCustomerSteps,
      );
      unawaited(DemoVoice.speak(title, subtitle));
      await Future<void>.delayed(Duration(milliseconds: ms));
      _removeCoach();
    }

    Future<void> flash(
      Widget page,
      String title,
      String subtitle, {
      required int stepIndex,
      int dwellMs = 9500,
      int peekUiMs = 1100,
    }) async {
      await pause(260);
      if (!launcherContext.mounted) return;

      final route = MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => page,
      );

      final done = Completer<void>();
      unawaited(
        nav.push(route).whenComplete(() {
          if (!done.isCompleted) done.complete();
        }),
      );

      final peek = peekUiMs.clamp(400, dwellMs);
      await Future<void>.delayed(Duration(milliseconds: peek));
      if (!launcherContext.mounted) return;
      _showCoach(
        launcherContext,
        title,
        subtitle,
        stepIndex: stepIndex,
        totalSteps: _kCustomerSteps,
      );
      unawaited(DemoVoice.speak(title, subtitle));
      await Future<void>.delayed(Duration(milliseconds: dwellMs - peek));
      _removeCoach();
      if (!launcherContext.mounted) return;
      if (route.isActive) nav.pop();
      await done.future;
    }

    try {
      if (!launcherContext.mounted) return;

      await narrate(
        'Step 1 — Customer flow (simple)',
        'Browse nearby options, place an order, and track updates — that’s the whole customer journey.',
        stepIndex: 1,
        ms: 6600,
      );

      d.syncAuthTab(0);
      wipeAuthFields();
      d.shellSetState(() => d.setLoginUserType(UserType.customer));
      await pause(450);

      await typing(d.loginPhoneCtrl, '03001234567');
      await pause(160);
      await typing(d.passwordCtrl, 'demo123');
      await pause(400);

      await recap(
        'Step 2 — Customer login',
        'Sign in fast and land on discovery.',
        stepIndex: 2,
        ms: 3600,
      );

      wipeAuthFields();
      d.syncAuthTab(1);
      await pause(350);
      d.shellSetState(() => d.setSignupUserType(UserType.customer));
      await pause(300);
      await typing(d.phoneCtrl, '03001112223');
      await pause(140);
      await typing(d.signupPasswordCtrl, 'demo123');
      await pause(120);
      await typing(d.areaCtrl, 'DHA Phase 6, Karachi');
      await pause(400);

      await recap(
        'Step 3 — New customer signup',
        'Create an account, set your area, and start browsing nearby.',
        stepIndex: 3,
        ms: 3800,
      );

      wipeAuthFields();
      d.syncAuthTab(0);

      await flash(
        const CustomerHomeScreen(),
        'Step 4 — Home & discovery',
        'Start browsing: categories, search, and nearby options.',
        stepIndex: 4,
        dwellMs: 8600,
        peekUiMs: 1200,
      );

      await flash(
        const NearMeScreen(),
        'Step 5 — Near Me & technicians',
        'Nearby uses a radius so results stay relevant and close.',
        stepIndex: 5,
        dwellMs: 8600,
        peekUiMs: 1200,
      );

      await flash(
        BusinessDetailScreen(
          business: investorDemoCheckoutBusiness(),
          investorDemoAutoPlaceOrder: true,
        ),
        'Step 6 — Storefront & checkout',
        'Pick items, confirm delivery, place the order.',
        stepIndex: 6,
        dwellMs: 15000,
        peekUiMs: 1600,
      );

      await flash(
        const CustomerOrdersScreen(),
        'Step 7 — My orders',
        'Track status updates for every order.',
        stepIndex: 7,
        dwellMs: 8200,
        peekUiMs: 1100,
      );

      final rentBiz = investorDemoRentACarForBooking();
      await flash(
        BookSlotScreen(
          business: rentBiz,
          item: rentBiz.items.first,
        ),
        'Step 8 — Book vehicle / slot',
        'Reserve self-drive or timed slots—deposit terms and PKR totals before confirm, suited to '
            'weekend travel and events.',
        stepIndex: 8,
        dwellMs: 12500,
        peekUiMs: 1300,
      );

      await flash(
        const CustomerSettingsScreen(),
        'Step 9 — Account & preferences',
        'Profile, notifications, and theme—control how you shop and stay informed.',
        stepIndex: 9,
        dwellMs: 9200,
        peekUiMs: 1100,
      );

      await flash(
        const TermsAndBackendHandoffScreen(),
        'Step 10 — Terms & privacy',
        'Customer policies—transparency for digital commerce and repeat trust.',
        stepIndex: 10,
        dwellMs: 8800,
        peekUiMs: 1100,
      );

      await narrate(
        'Shopper tour complete',
        'PKR marketplace flow: discovery → checkout → tracking → bookings → settings—replay anytime '
            'for investors or training.',
        stepIndex: null,
        ms: 7200,
      );
    } finally {
      _removeCoach();
      wipeAuthFields();
      if (d.isMounted()) {
        d.syncAuthTab(0);
        d.shellSetState(() {
          d.setLoginUserType(UserType.customer);
          d.setSignupUserType(UserType.customer);
        });
      }
      if (launcherContext.mounted) {
        nav.popUntil((r) => r.isFirst);
      }
    }
  }

  static Future<void> _runWorkerDemo(
    BuildContext launcherContext,
    LoginDemoControls d,
  ) async {
    final nav = Navigator.of(launcherContext, rootNavigator: true);

    Future<void> pause([int ms = 520]) =>
        Future<void>.delayed(Duration(milliseconds: ms));

    Future<void> typing(
      TextEditingController c,
      String text, {
      Duration perChar = const Duration(milliseconds: 38),
    }) =>
        DemoTypewriter.fill(
          c,
          text,
          perChar: perChar,
          shouldAbort: () => !d.isMounted(),
        );

    void wipeAuthFields() {
      if (!d.isMounted()) return;
      d.shellSetState(() {
        d.emailCtrl.clear();
        d.passwordCtrl.clear();
        d.loginPhoneCtrl.clear();
        d.nameCtrl.clear();
        d.phoneCtrl.clear();
        d.signupEmailCtrl.clear();
        d.signupPasswordCtrl.clear();
        d.areaCtrl.clear();
      });
    }

    Future<void> narrate(
      String title,
      String subtitle, {
      int? stepIndex,
      int ms = 7800,
    }) async {
      await pause(260);
      if (!launcherContext.mounted) return;
      _showCoach(
        launcherContext,
        title,
        subtitle,
        stepIndex: stepIndex,
        totalSteps: _kWorkerSteps,
      );
      unawaited(DemoVoice.speak(title, subtitle));
      await Future<void>.delayed(Duration(milliseconds: ms));
      _removeCoach();
    }

    Future<void> recap(
      String title,
      String subtitle, {
      int? stepIndex,
      int ms = 4000,
    }) async {
      await pause(240);
      if (!launcherContext.mounted) return;
      _showCoach(
        launcherContext,
        title,
        subtitle,
        stepIndex: stepIndex,
        totalSteps: _kWorkerSteps,
      );
      unawaited(DemoVoice.speak(title, subtitle));
      await Future<void>.delayed(Duration(milliseconds: ms));
      _removeCoach();
    }

    Future<void> flash(
      Widget page,
      String title,
      String subtitle, {
      required int stepIndex,
      int dwellMs = 9500,
      int peekUiMs = 1100,
    }) async {
      await pause(260);
      if (!launcherContext.mounted) return;

      final route = MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => page,
      );

      final done = Completer<void>();
      unawaited(
        nav.push(route).whenComplete(() {
          if (!done.isCompleted) done.complete();
        }),
      );

      final peek = peekUiMs.clamp(400, dwellMs);
      await Future<void>.delayed(Duration(milliseconds: peek));
      if (!launcherContext.mounted) return;
      _showCoach(
        launcherContext,
        title,
        subtitle,
        stepIndex: stepIndex,
        totalSteps: _kWorkerSteps,
      );
      unawaited(DemoVoice.speak(title, subtitle));
      await Future<void>.delayed(Duration(milliseconds: dwellMs - peek));
      _removeCoach();
      if (!launcherContext.mounted) return;
      if (route.isActive) nav.pop();
      await done.future;
    }

    try {
      if (!launcherContext.mounted) return;

      await narrate(
        'Step 1 — Field & rider overview (PK)',
        'For Pakistan’s service economy: AC/plumbing/electrical jobs on mobile, plus store-hired '
            'riders. Platform gig-riders roll out separately—your merchant’s Team rider IDs work '
            'today.',
        stepIndex: 1,
        ms: 8400,
      );

      wipeAuthFields();
      d.syncAuthTab(0);
      d.shellSetState(() {
        d.setLoginUserType(UserType.serviceWorker);
        d.setLoginServiceBranch(ServiceBranch.home);
      });
      await pause(450);

      await typing(d.loginPhoneCtrl, '03009876543');
      await pause(160);
      await typing(d.passwordCtrl, 'demo123');
      await pause(400);

      await recap(
        'Step 2 — Technician login',
        '03XX phone + password—the lane for tradespeople serving homes and SMEs in Karachi, '
            'Lahore, Islamabad, and beyond.',
        stepIndex: 2,
        ms: 4500,
      );

      if (launcherContext.mounted) {
        launcherContext.read<JobProvider>().seedDemoJobsIfEmpty();
      }
      await pause(200);

      await flash(
        const ServiceWorkerHomeScreen(),
        'Step 3 — Job board',
        'Pending / Active / Completed—each card shows area + issue so you accept jobs you can '
            'actually reach on time.',
        stepIndex: 3,
        dwellMs: 12800,
        peekUiMs: 1400,
      );

      await flash(
        JobRequestDetailScreen(request: investorDemoSampleJobAc()),
        'Step 4 — Job detail',
        'Full address, issue description, ETA—same clarity you’d expect on a WhatsApp lead, but '
            'structured for acceptance and routing.',
        stepIndex: 4,
        dwellMs: 13200,
        peekUiMs: 1300,
      );

      await flash(
        const ServiceWorkerLiveMapScreen(),
        'Step 5 — Navigation map',
        'When GPS is on, route to the customer pin—cuts “address confusion” common on Pakistani '
            'streets and gated communities.',
        stepIndex: 5,
        dwellMs: 9000,
        peekUiMs: 1200,
      );

      await narrate(
        'Step 6 — Rider policy briefing',
        'Same sheet merchants see: phased gig-rider network vs Team rider IDs—aligned with local '
            'hiring reality.',
        stepIndex: 6,
        ms: 4400,
      );

      if (launcherContext.mounted) {
        await ServiceBranchSwitcher.showRiderComingSoonSheet(launcherContext);
      }

      await pause(260);

      await flash(
        const RiderLoginScreen(),
        'Step 7 — Team rider login',
        'Rider ID + mobile from the merchant—no separate gig signup for staff riders your shop '
            'already employs.',
        stepIndex: 7,
        dwellMs: 11800,
        peekUiMs: 1300,
      );

      await flash(
        const RiderHomeScreen(),
        'Step 8 — Rider workspace',
        'Assigned drops, customer contact, mark complete—structured ops instead of informal WhatsApp '
            'chains alone.',
        stepIndex: 8,
        dwellMs: 11800,
        peekUiMs: 1200,
      );

      await narrate(
        'Field tour complete',
        'Jobs → detail → map → policy → Team rider login → delivery workspace—replay for rider '
            'training or investor Q&A.',
        stepIndex: null,
        ms: 7200,
      );
    } finally {
      _removeCoach();
      wipeAuthFields();
      if (d.isMounted()) {
        d.shellSetState(() {
          d.setLoginUserType(UserType.businessOwner);
          d.setLoginServiceBranch(ServiceBranch.home);
        });
      }
      if (launcherContext.mounted) {
        nav.popUntil((r) => r.isFirst);
      }
    }
  }

  static String _deckEyebrow(DemoTrack t) {
    switch (t) {
      case DemoTrack.quick:
        return 'QUICK DEMO';
      case DemoTrack.complete:
        return 'MASTER DEMO';
      case DemoTrack.full:
        return 'FULL DEMO';
      case DemoTrack.business:
        return 'MERCHANT TOUR';
      case DemoTrack.customer:
        return 'CUSTOMER TOUR';
      case DemoTrack.worker:
        return 'FIELD TOUR';
    }
  }

  static void _showCoach(
    BuildContext context,
    String title,
    String body, {
    int? stepIndex,
    required int totalSteps,
  }) {
    _removeCoach();
    final overlay = Overlay.of(context, rootOverlay: true);

    _hintEntry = OverlayEntry(
      builder: (ctx) => _InvestorPresenterBanner(
        rootContext: context,
        deckEyebrow: _deckEyebrow(_deckTrack),
        title: title,
        body: body.replaceAll('**', ''),
        stepIndex: stepIndex,
        totalSteps: totalSteps,
      ),
    );
    overlay.insert(_hintEntry!);
  }

  static void _removeCoach() {
    _hintEntry?.remove();
    _hintEntry = null;
  }
}

/// Premium presenter strip: reads like product keynote captions, not debug subtitles.
class _InvestorPresenterBanner extends StatefulWidget {
  const _InvestorPresenterBanner({
    required this.rootContext,
    required this.deckEyebrow,
    required this.title,
    required this.body,
    required this.stepIndex,
    required this.totalSteps,
  });

  final BuildContext rootContext;
  final String deckEyebrow;
  final String title;
  final String body;
  final int? stepIndex;
  final int totalSteps;

  @override
  State<_InvestorPresenterBanner> createState() =>
      _InvestorPresenterBannerState();
}

class _InvestorPresenterBannerState extends State<_InvestorPresenterBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic);
    _slide = Tween<Offset>(
      begin: const Offset(0, -0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic));
    _anim.forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _exitDemo() {
    final n = Navigator.of(widget.rootContext, rootNavigator: true);
    if (n.canPop()) n.pop();
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.paddingOf(context).top;
    final screenH = MediaQuery.sizeOf(context).height;
    final grad = AppColors.gradientFrom(AppColors.primary);
    final seg = widget.stepIndex;
    final denom = widget.totalSteps <= 0 ? 1 : widget.totalSteps;
    final progress = seg != null ? (seg.clamp(1, denom)) / denom : 0.0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: AbsorbPointer(
            absorbing: true,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.14),
                    Colors.black.withValues(alpha: 0.05),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 14,
          right: 14,
          top: topPad + 10,
          child: FadeTransition(
            opacity: _fade,
            child: SlideTransition(
              position: _slide,
              child: Material(
                elevation: 18,
                shadowColor: Colors.black.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(20),
                color: AppColors.surface,
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: 560,
                    maxHeight: screenH * 0.34,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border.withValues(alpha: 0.85)),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white,
                        AppColors.primaryLight.withValues(alpha: 0.35),
                      ],
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(19),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          width: 5,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: grad,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(14, 12, 12, 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.auto_awesome_rounded,
                                      size: 16,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        widget.deckEyebrow,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 10,
                                          letterSpacing: 1.15,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      'Pricing · PKR',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.4,
                                        color: AppColors.textHint,
                                      ),
                                    ),
                                  ],
                                ),
                                if (seg != null) ...[
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Text(
                                        'Segment $seg / ${widget.totalSteps}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(6),
                                          child: LinearProgressIndicator(
                                            value: progress,
                                            minHeight: 6,
                                            backgroundColor:
                                                AppColors.primaryLight,
                                            valueColor:
                                                const AlwaysStoppedAnimation(
                                              AppColors.primary,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                const SizedBox(height: 10),
                                Text(
                                  widget.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15.5,
                                    height: 1.25,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Expanded(
                                  child: SingleChildScrollView(
                                    physics: const BouncingScrollPhysics(),
                                    child: Text(
                                      widget.body,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        height: 1.48,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: _exitDemo,
                                    style: TextButton.styleFrom(
                                      foregroundColor: AppColors.textSecondary,
                                    ),
                                    child: const Text(
                                      'Exit demo',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
