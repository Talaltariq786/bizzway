// Shared types and static lists for login screens.

enum ServiceBranch { home, rider }

class WorkerPlanInfo {
  final String id;
  final String title;
  final int price;
  final String subtitle;
  final String saveText;

  const WorkerPlanInfo({
    required this.id,
    required this.title,
    required this.price,
    required this.subtitle,
    required this.saveText,
  });
}

class RiderPlanInfo {
  final String id;
  final String title;
  final String subtitle;
  final String badge;

  const RiderPlanInfo({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.badge,
  });
}

const List<String> kWorkerProfessions = [
  'Electrician',
  'Plumber',
  'Carpenter',
  'Painter',
  'Mechanic',
  'AC Technician',
  /// Collects scrap / kabar from homes; rates shown on Near Me profile (PKR).
  'Kabariwala · scrap buyer',
];

/// True for workers who buy scrap / kabar (show rate editor in service app).
bool professionIsKabariScrap(String? profession) {
  if (profession == null || profession.trim().isEmpty) return false;
  final p = profession.toLowerCase();
  return p.contains('kabari') ||
      p.contains('scrap') ||
      p.contains('kabadi') ||
      p.contains('kabad');
}

/// Default material lines in the kabari rate editor (PKR per kg or best).
const List<String> kKabariScrapMaterialRows = [
  'Plastic (PET / bottles)',
  'Paper / cardboard',
  'Iron / steel scrap',
  'Aluminium',
  'Bossi / mixed kabar',
  'Glass',
  'Copper',
];

const List<WorkerPlanInfo> kWorkerPlans = [
  WorkerPlanInfo(
    id: 'monthly',
    title: 'Monthly',
    price: 750,
    subtitle: 'Rs 750 / month',
    saveText: 'Standard',
  ),
  WorkerPlanInfo(
    id: 'six_months',
    title: '6 Months',
    price: 4050,
    subtitle: 'Rs 4,050 / 6 months',
    saveText: 'Save Rs 450',
  ),
  WorkerPlanInfo(
    id: 'yearly',
    title: 'Yearly',
    price: 7200,
    subtitle: 'Rs 7,200 / year',
    saveText: 'Save Rs 1,800',
  ),
];

const List<RiderPlanInfo> kRiderPlans = [
  RiderPlanInfo(
    id: 'rider_monthly',
    title: 'Monthly',
    subtitle: 'Rs 1,500 / month',
    badge: 'Flexible',
  ),
  RiderPlanInfo(
    id: 'rider_six_months',
    title: '6 Months',
    subtitle: 'Rs 800 / month · Rs 4,800 total',
    badge: 'Best value',
  ),
];
