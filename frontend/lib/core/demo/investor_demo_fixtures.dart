import 'package:flutter/material.dart';

import '../constants/grocery_categories.dart';
import '../../models/business.dart';
import '../../models/job_request.dart';
import '../../models/order.dart';

/// Last order id from [BusinessDetailScreen] demo checkout — read by investor playback.
class InvestorDemoLastCheckout {
  InvestorDemoLastCheckout._();
  static String? placedOrderId;
}

/// Rent-a-car listing for customer demo (book slot / vehicle).
Business investorDemoRentACarForBooking() {
  const amber = Color(0xFFFF8F00);
  return Business(
    id: 'demo_rentacar_citydrive',
    name: 'CityDrive Rentals',
    address: 'Shahrah-e-Faisal — demo pickup point',
    rating: 4.7,
    reviewCount: 128,
    businessTypeId: 'rentacar',
    isOpen: true,
    tagline: 'Self-drive cars by the day',
    color: amber,
    phone: '03001110000',
    deliveryBaseCharge: 0,
    deliveryPerKmCharge: 0,
    deliveryRadiusKm: 50,
    items: [
      BusinessItem(
        id: 'rent_fortuner',
        name: 'Toyota Fortuner — self-drive',
        description: 'Daily self-drive SUV, full insurance bundle available at counter.',
        price: 12000,
        category: 'SUV',
        durationMinutes: 1440,
        unit: 'per day',
      ),
    ],
  );
}

/// Sample grocery storefront for investor demo — items + delivery so pickup/delivery UI loads.
Business investorDemoCheckoutBusiness() {
  const groceryGreen = Color(0xFF2E7D32);
  return Business(
    id: 'investor_demo_store',
    name: 'Karachi Demo Mart',
    address: 'Block 6 Gulistan-e-Jauhar — demo listing',
    rating: 4.9,
    reviewCount: 256,
    businessTypeId: 'grocery',
    isOpen: true,
    tagline: 'Groceries in PKR — pickup or same-day delivery',
    color: groceryGreen,
    phone: '03001122334',
    deliveryBaseCharge: 50,
    deliveryPerKmCharge: 20,
    deliveryRadiusKm: 5,
    items: [
      BusinessItem(
        id: 'inv_milk',
        name: 'Full Cream Milk 1L',
        description: 'Fresh dairy',
        price: 285,
        category: GroceryCategories.aisleNames[6], // Fresh Items
      ),
      BusinessItem(
        id: 'inv_bread',
        name: 'Brown Bread Large',
        description: 'Bakery',
        price: 230,
        category: GroceryCategories.aisleNames[4],
      ),
      BusinessItem(
        id: 'inv_oil',
        name: 'Cooking Oil 1L',
        description: 'Oil & Ghee aisle',
        price: 520,
        category: GroceryCategories.aisleNames[0],
      ),
      BusinessItem(
        id: 'inv_rice',
        name: 'Basmati Rice 5kg',
        description: 'Staples',
        price: 1850,
        category: GroceryCategories.aisleNames[1],
      ),
    ],
  );
}

/// Matches [JobProvider.seedDemoJobsIfEmpty] first demo job — home services detail screen.
JobRequest investorDemoSampleJobAc() {
  final base = DateTime.now().subtract(const Duration(minutes: 8));
  return JobRequest(
    id: 'demo-sw-1',
    userAddress:
        'Block 5, Clifton, Karachi — near Do Talwar (24.8138, 67.0299)',
    issue:
        'Split AC not cooling; suspect gas leak. Indoor + outdoor unit check.',
    serviceTypeId: 'ac',
    serviceTypeName: 'AC Technician',
    createdAt: base,
    status: 'pending',
    destLat: 24.8138,
    destLng: 67.0299,
  );
}

/// Canonical demo team rider (Meray riders + Team rider login). Must match guided-tour seed.
const String kInvestorDemoTeamRiderId = 'rider_01';
const String kInvestorDemoTeamRiderPhone = '03001230000';

/// Delivery order used in the guided tour: open detail + assign rider. Id must match [OrderProvider] seed.
Order investorDemoDeliveryOrderForAssign() {
  return Order(
    id: 'ORD-DEMO-RIDER-001',
    customerId: 'demo_customer',
    customerName: 'Demo Buyer',
    customerPhone: '03001112233',
    customerAddress: 'Street 12, Gulistan-e-Jauhar, Karachi',
    customerLat: 24.9056,
    customerLng: 67.1483,
    createdAt: DateTime(2026, 4, 30, 15, 45),
    assignedRiderId: kInvestorDemoTeamRiderId,
    assignedRiderName: 'Ali Rider',
    assignedRiderPhone: kInvestorDemoTeamRiderPhone,
    items: const [
      OrderItem(
        productId: 'sku_ramadan',
        productName: 'Ramadan Family Pack',
        quantity: 1,
        unitPrice: 3499,
      ),
      OrderItem(
        productId: 'sku_dates',
        productName: 'Premium Dates 500g',
        quantity: 2,
        unitPrice: 650,
      ),
    ],
    status: OrderStatus.active,
    notes: 'Ring doorbell — demo order',
    businessTypeId: 'grocery',
    businessTypeName: 'Grocery',
    deliveryCharge: 150,
    isDelivery: true,
  );
}
