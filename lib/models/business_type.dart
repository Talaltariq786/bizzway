import 'package:flutter/material.dart';

class BusinessType {
  final String id;
  final String title;
  final IconData icon;
  final String imageUrl;
  final List<String> categories;
  final Color color;

  const BusinessType({
    required this.id,
    required this.title,
    required this.icon,
    required this.imageUrl,
    required this.categories,
    required this.color,
  });

  static List<BusinessType> get all => [
        const BusinessType(
          id: 'restaurant',
          title: 'Restaurant',
          icon: Icons.restaurant,
          imageUrl: 'https://via.placeholder.com/100?text=Restaurant',
          categories: ['Food', 'Drinks', 'Combos', 'Desserts'],
          color: Color(0xFFFF6B6B),
        ),
        const BusinessType(
          id: 'grocery',
          title: 'Grocery',
          icon: Icons.local_grocery_store,
          imageUrl: 'https://via.placeholder.com/100?text=Grocery',
          categories: ['Dairy', 'Bakery', 'Staples', 'Beverages'],
          color: Color(0xFF4CAF50),
        ),
        const BusinessType(
          id: 'salon',
          title: 'Salon',
          icon: Icons.content_cut,
          imageUrl: 'https://via.placeholder.com/100?text=Salon',
          categories: ['Haircuts', 'Treatments', 'Coloring', 'Styling', 'Spa'],
          color: Color(0xFFE91E63),
        ),
        const BusinessType(
          id: 'gym',
          title: 'Gym',
          icon: Icons.fitness_center,
          imageUrl: 'https://via.placeholder.com/100?text=Gym',
          categories: ['Memberships', 'Personal Training', 'Group Classes', 'Diet Plans', 'Assessment'],
          color: Color(0xFFFF9800),
        ),
        const BusinessType(
          id: 'clinic',
          title: 'Clinic',
          icon: Icons.local_hospital,
          imageUrl: 'https://via.placeholder.com/100?text=Clinic',
          categories: ['Consultations', 'Lab Tests', 'Vaccinations', 'Pharmacy'],
          color: Color(0xFF2196F3),
        ),
        const BusinessType(
          id: 'pharmacy',
          title: 'Pharmacy',
          icon: Icons.medication,
          imageUrl: 'https://via.placeholder.com/100?text=Pharmacy',
          categories: ['Medicines', 'Supplements', 'Personal Care', 'Equipment'],
          color: Color(0xFF00BCD4),
        ),
        const BusinessType(
          id: 'cafe',
          title: 'Café',
          icon: Icons.local_cafe,
          imageUrl: 'https://via.placeholder.com/100?text=Cafe',
          categories: ['Coffee', 'Tea', 'Pastries', 'Sandwiches'],
          color: Color(0xFF795548),
        ),
        const BusinessType(
          id: 'others',
          title: 'Others',
          icon: Icons.store,
          imageUrl: 'https://via.placeholder.com/100?text=Others',
          categories: ['Products', 'Services'],
          color: Color(0xFF9C27B0),
        ),

        // ── New business types ──────────────────────────────────────────
        const BusinessType(
          id: 'beauty',
          title: 'Beauty Parlor',
          icon: Icons.face_retouching_natural,
          imageUrl: 'https://via.placeholder.com/100?text=Beauty',
          categories: ['Facial', 'Waxing', 'Threading', 'Nails', 'Bridal', 'Mehndi'],
          color: Color(0xFFFF4081),
        ),
        const BusinessType(
          id: 'flowers',
          title: 'Flower Shop',
          icon: Icons.local_florist_rounded,
          imageUrl: 'https://via.placeholder.com/100?text=Flowers',
          categories: ['Bouquets', 'Arrangements', 'Plants', 'Gift Baskets', 'Wreaths'],
          color: Color(0xFF8BC34A),
        ),
        const BusinessType(
          id: 'rentacar',
          title: 'Rent a Car',
          icon: Icons.directions_car_rounded,
          imageUrl: 'https://via.placeholder.com/100?text=RentACar',
          categories: ['Economy', 'Sedan', 'SUV', 'Van', 'With Driver', 'Self Drive'],
          color: Color(0xFF607D8B),
        ),
        const BusinessType(
          id: 'mechanic',
          title: 'Auto Workshop',
          icon: Icons.build_rounded,
          imageUrl: 'https://via.placeholder.com/100?text=Mechanic',
          categories: ['Car Repair', 'Bike Repair', 'Puncture', 'Battery', 'Oil Change', 'Tyre'],
          color: Color(0xFF455A64),
        ),
        const BusinessType(
          id: 'homeservice',
          title: 'Home Services',
          icon: Icons.handyman_rounded,
          imageUrl: 'https://via.placeholder.com/100?text=HomeService',
          categories: ['Electrician', 'Plumber', 'Locksmith', 'Painter', 'AC Repair', 'Carpenter'],
          color: Color(0xFF5C6BC0),
        ),
        const BusinessType(
          id: 'petcare',
          title: 'Pet Care',
          icon: Icons.pets_rounded,
          imageUrl: 'https://via.placeholder.com/100?text=PetCare',
          categories: ['Vet Consultation', 'Grooming', 'Vaccination', 'Boarding', 'Emergency'],
          color: Color(0xFFFF7043),
        ),
      ];
}
