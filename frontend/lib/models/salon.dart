class SalonService {
  final String id;
  final String name;
  final String description;
  final double price;
  final int durationMinutes;
  final String category;

  const SalonService({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.durationMinutes,
    required this.category,
  });
}

class Salon {
  final String id;
  final String name;
  final String address;
  final double rating;
  final int reviewCount;
  final String category;
  final List<String> specialties;
  final bool isOpen;
  final List<SalonService> services;

  const Salon({
    required this.id,
    required this.name,
    required this.address,
    required this.rating,
    required this.reviewCount,
    required this.category,
    required this.specialties,
    required this.isOpen,
    required this.services,
  });
}

class CustomerAppointment {
  final String id;
  final String salonId;
  final String salonName;
  final String serviceId;
  final String serviceName;
  final double price;
  final int durationMinutes;
  final DateTime dateTime;
  String status; // pending, confirmed, completed, cancelled
  final String? notes;

  CustomerAppointment({
    required this.id,
    required this.salonId,
    required this.salonName,
    required this.serviceId,
    required this.serviceName,
    required this.price,
    required this.durationMinutes,
    required this.dateTime,
    this.status = 'pending',
    this.notes,
  });
}

// ── Dummy data ──────────────────────────────────────────────────────────────

final List<Salon> dummySalons = [
  Salon(
    id: 's1',
    name: 'Glamour Studio',
    address: 'Block 7, Gulshan-e-Iqbal, Karachi',
    rating: 4.8,
    reviewCount: 124,
    category: 'Hair & Spa',
    specialties: ['Haircut', 'Coloring', 'Spa'],
    isOpen: true,
    services: [
      const SalonService(
        id: 'sv1',
        name: 'Haircut & Styling',
        description: 'Professional cut with blow dry finish',
        price: 800,
        durationMinutes: 45,
        category: 'Hair',
      ),
      const SalonService(
        id: 'sv2',
        name: 'Hair Coloring',
        description: 'Full color, highlights or balayage',
        price: 3500,
        durationMinutes: 120,
        category: 'Hair',
      ),
      const SalonService(
        id: 'sv3',
        name: 'Deep Conditioning Spa',
        description: 'Nourishing hair mask + scalp massage',
        price: 1500,
        durationMinutes: 60,
        category: 'Spa',
      ),
      const SalonService(
        id: 'sv4',
        name: 'Facial Treatment',
        description: 'Cleansing + toning + moisturizing',
        price: 1200,
        durationMinutes: 60,
        category: 'Skin',
      ),
    ],
  ),
  Salon(
    id: 's2',
    name: 'The Beauty Lounge',
    address: 'DHA Phase 5, Lahore',
    rating: 4.6,
    reviewCount: 89,
    category: 'Full Service',
    specialties: ['Nails', 'Waxing', 'Makeup'],
    isOpen: true,
    services: [
      const SalonService(
        id: 'sv5',
        name: 'Manicure & Pedicure',
        description: 'Classic nail care with polish',
        price: 1000,
        durationMinutes: 60,
        category: 'Nails',
      ),
      const SalonService(
        id: 'sv6',
        name: 'Gel Nails',
        description: 'Long-lasting gel polish application',
        price: 1800,
        durationMinutes: 75,
        category: 'Nails',
      ),
      const SalonService(
        id: 'sv7',
        name: 'Bridal Makeup',
        description: 'Full bridal look with airbrush',
        price: 8000,
        durationMinutes: 180,
        category: 'Makeup',
      ),
      const SalonService(
        id: 'sv8',
        name: 'Waxing (Full Body)',
        description: 'Complete waxing session',
        price: 2500,
        durationMinutes: 90,
        category: 'Waxing',
      ),
    ],
  ),
  Salon(
    id: 's3',
    name: 'Zen Wellness Spa',
    address: 'F-7 Markaz, Islamabad',
    rating: 4.9,
    reviewCount: 210,
    category: 'Spa & Wellness',
    specialties: ['Massage', 'Facial', 'Body Treatment'],
    isOpen: false,
    services: [
      const SalonService(
        id: 'sv9',
        name: 'Swedish Massage',
        description: 'Relaxing full body massage',
        price: 2500,
        durationMinutes: 60,
        category: 'Massage',
      ),
      const SalonService(
        id: 'sv10',
        name: 'Hot Stone Therapy',
        description: 'Deep muscle relaxation with hot stones',
        price: 3500,
        durationMinutes: 90,
        category: 'Massage',
      ),
      const SalonService(
        id: 'sv11',
        name: 'Gold Facial',
        description: 'Anti-aging gold leaf facial treatment',
        price: 3000,
        durationMinutes: 75,
        category: 'Skin',
      ),
    ],
  ),
  Salon(
    id: 's4',
    name: 'Style Hub',
    address: 'Johar Town, Lahore',
    rating: 4.4,
    reviewCount: 57,
    category: 'Hair Salon',
    specialties: ['Haircut', 'Keratin', 'Straightening'],
    isOpen: true,
    services: [
      const SalonService(
        id: 'sv12',
        name: 'Keratin Treatment',
        description: 'Smooth, frizz-free hair for months',
        price: 5000,
        durationMinutes: 150,
        category: 'Hair',
      ),
      const SalonService(
        id: 'sv13',
        name: 'Hair Straightening',
        description: 'Permanent straightening treatment',
        price: 4000,
        durationMinutes: 120,
        category: 'Hair',
      ),
      const SalonService(
        id: 'sv14',
        name: 'Men\'s Grooming',
        description: 'Haircut + beard trim + wash',
        price: 600,
        durationMinutes: 45,
        category: 'Hair',
      ),
    ],
  ),
];
