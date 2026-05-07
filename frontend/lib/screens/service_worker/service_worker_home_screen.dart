import 'dart:io';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/routes/app_routes.dart';
import '../../models/job_request.dart';
import '../../providers/auth_provider.dart';
import '../../providers/job_provider.dart';
import '../../widgets/common/sliding_drawer_shell.dart';
import '../auth/login/login_constants.dart';
import 'job_request_detail_screen.dart';

class ServiceWorkerHomeScreen extends StatefulWidget {
  const ServiceWorkerHomeScreen({super.key});

  @override
  State<ServiceWorkerHomeScreen> createState() => _ServiceWorkerHomeScreenState();
}

class _ServiceWorkerHomeScreenState extends State<ServiceWorkerHomeScreen> {
  int _tab = 0;
  final GlobalKey<SlidingDrawerShellState> _drawerKey =
      GlobalKey<SlidingDrawerShellState>();

  static const _titles = ['Jobs', 'History', 'Profile'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<JobProvider>().seedDemoJobsIfEmpty();
    });
  }

  void _selectTab(int index) {
    setState(() => _tab = index);
    _drawerKey.currentState?.closeDrawer();
  }

  Future<void> _signOut(AuthProvider auth) async {
    _drawerKey.currentState?.closeDrawer();
    await auth.logout();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final jobs = context.watch<JobProvider>();
    final auth = context.watch<AuthProvider>();
    final List<JobRequest> visibleJobs =
        _filteredJobs(jobs, auth).toList(growable: false);
    final List<JobRequest> pendingJobs =
        visibleJobs.where((j) => j.isPending).toList(growable: false);
    final List<JobRequest> activeJobs =
        visibleJobs.where((j) => j.isAccepted).toList(growable: false);
    final List<JobRequest> completedJobs =
        visibleJobs.where((j) => j.isCompleted).toList(growable: false);

    return SlidingDrawerShell(
      key: _drawerKey,
      drawer: _ServiceWorkerSideDrawer(
        selectedIndex: _tab,
        auth: auth,
        pendingCount: pendingJobs.length,
        activeCount: activeJobs.length,
        completedCount: completedJobs.length,
        onSelectTab: _selectTab,
        onClose: () => _drawerKey.currentState?.closeDrawer(),
        onLogout: () => _signOut(auth),
        showKabari: professionIsKabariScrap(auth.serviceProfession),
        onOpenScrapRates: () {
          _drawerKey.currentState?.closeDrawer();
          Navigator.pushNamed(context, AppRoutes.scrapRatesEditor);
        },
      ),
      child: Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textPrimary,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => _drawerKey.currentState?.toggleDrawer(),
          ),
          title: Text(_titles[_tab]),
          actions: [
            IconButton(
              tooltip: auth.isOnlineForWork ? 'Online' : 'Offline',
              icon: Icon(
                auth.isOnlineForWork ? Icons.wifi_rounded : Icons.wifi_off_rounded,
                color: auth.isOnlineForWork ? AppColors.primary : AppColors.textHint,
              ),
              onPressed: () => auth.setOnlineForWork(!auth.isOnlineForWork),
            ),
          ],
        ),
        body: IndexedStack(
          index: _tab,
          children: [
            _buildJobsTab(
              context: context,
              auth: auth,
              jobs: jobs,
              pendingJobs: pendingJobs,
              activeJobs: activeJobs,
            ),
            _buildHistoryTab(
              context: context,
              completedJobs: completedJobs,
            ),
            _buildProfileTab(
              context: context,
              auth: auth,
              pendingCount: pendingJobs.length,
              activeCount: activeJobs.length,
              completedCount: completedJobs.length,
            ),
          ],
        ),
        bottomNavigationBar: CurvedNavigationBar(
          index: _tab,
          height: 74,
          backgroundColor: Colors.transparent,
          color: AppColors.primary,
          animationDuration: const Duration(milliseconds: 380),
          animationCurve: Curves.easeOutCubic,
          onTap: _selectTab,
          items: const [
            Icon(Icons.work_outline_rounded, color: Colors.white),
            Icon(Icons.history_rounded, color: Colors.white),
            Icon(Icons.person_outline_rounded, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _buildJobsTab({
    required BuildContext context,
    required AuthProvider auth,
    required JobProvider jobs,
    required List<JobRequest> pendingJobs,
    required List<JobRequest> activeJobs,
  }) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _demoInfoBanner(),
        const SizedBox(height: 12),
        _onlineToggleCard(context, auth),
        const SizedBox(height: 12),
        if ((auth.serviceProfession ?? '').trim().isEmpty)
          _professionBanner(context, auth),
        _summaryCard(pendingJobs.length, activeJobs.length),
        const SizedBox(height: 10),
        if ((auth.serviceProfession ?? '').isNotEmpty ||
            (auth.serviceNic ?? '').isNotEmpty)
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                if ((auth.serviceImagePath ?? '').isNotEmpty)
                  CircleAvatar(
                    radius: 16,
                    backgroundImage: FileImage(File(auth.serviceImagePath!)),
                  )
                else
                  const Icon(
                    Icons.handyman_rounded,
                    color: AppColors.primary,
                    size: 18,
                  ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${auth.serviceProfession ?? 'Service Worker'}'
                    '${(auth.serviceNic ?? '').isNotEmpty ? ' • CNIC: ${auth.serviceNic}' : ''}',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                if ((auth.servicePlan ?? '').isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      auth.servicePlan!,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 14),
        const Text(
          'Pending Requests',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        if (pendingJobs.isEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              'No pending requests right now.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ),
        ...pendingJobs.map((job) => _jobCardPending(context, jobs, job)),
        if (activeJobs.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text(
            'Active Jobs',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          ...activeJobs.map((job) => _jobCardActive(context, jobs, job)),
        ],
      ],
    );
  }

  Widget _jobCardPending(BuildContext context, JobProvider jobs, JobRequest job) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  job.serviceTypeName,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                job.timeAgo,
                style: const TextStyle(
                  color: AppColors.textHint,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            job.issue,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            job.userAddress,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => jobs.reject(job.id),
                  child: const Text('Reject'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            JobRequestDetailScreen(request: job),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Details'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _jobCardActive(BuildContext context, JobProvider jobs, JobRequest job) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Accepted',
                  style: TextStyle(
                    color: AppColors.success,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                job.timeAgo,
                style: const TextStyle(
                  color: AppColors.textHint,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            job.issue,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            job.userAddress,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            JobRequestDetailScreen(request: job),
                      ),
                    );
                  },
                  child: const Text('Details'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => jobs.complete(job.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Mark Complete'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab({
    required BuildContext context,
    required List<JobRequest> completedJobs,
  }) {
    if (completedJobs.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No completed jobs yet.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Completed',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        ...completedJobs.map(
          (job) => Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: InkWell(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => JobRequestDetailScreen(request: job),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Completed',
                          style: TextStyle(
                            color: AppColors.success,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        job.timeAgo,
                        style: const TextStyle(
                          color: AppColors.textHint,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    job.issue,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    job.userAddress,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _demoInfoBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 18, color: AppColors.primary),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Neeche sample jobs hain — address, kaam ki detail aur map par location '
              'dekhne ka flow try karein. Profession set karne se filter match hota hai.',
              style: TextStyle(
                fontSize: 11.5,
                height: 1.35,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTab({
    required BuildContext context,
    required AuthProvider auth,
    required int pendingCount,
    required int activeCount,
    required int completedCount,
  }) {
    final title = (auth.serviceProfession ?? '').trim().isEmpty
        ? 'Service Worker'
        : auth.serviceProfession!.trim();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: AppColors.gradientPrimary),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.handyman_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.appName,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.88),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if ((auth.userEmail ?? '').isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        auth.userEmail!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.82),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _onlineToggleCard(context, auth),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _miniStat('Pending', '$pendingCount')),
            const SizedBox(width: 10),
            Expanded(child: _miniStat('Active', '$activeCount')),
            const SizedBox(width: 10),
            Expanded(child: _miniStat('Done', '$completedCount')),
          ],
        ),
        const SizedBox(height: 14),
        if ((auth.serviceProfession ?? '').trim().isEmpty)
          _professionBanner(context, auth),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.serviceWorkerLiveMap),
            icon: const Icon(Icons.my_location_rounded),
            label: const Text('Live location on map'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        if (professionIsKabariScrap(auth.serviceProfession)) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.scrapRatesEditor),
              icon: const Icon(Icons.currency_exchange_rounded),
              label: const Text('Scrap / kabar rates (PKR) — customer ko dikhe ga'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _miniStat(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 18,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _professionBanner(BuildContext context, AuthProvider auth) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.handyman_rounded, color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Select your profession to see only relevant jobs.',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          TextButton(
            onPressed: () => _pickProfession(context, auth),
            child: const Text('Set Now'),
          )
        ],
      ),
    );
  }

  void _pickProfession(BuildContext context, AuthProvider auth) {
    const options = [
      'Electrician',
      'Plumber',
      'Carpenter',
      'Painter',
      'Mechanic',
      'AC Technician',
    ];
    String selected = options.first;
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Select Profession'),
          content: DropdownButtonFormField<String>(
            key: ValueKey<String>(selected),
            initialValue: selected,
            items: options
                .map((o) => DropdownMenuItem<String>(value: o, child: Text(o)))
                .toList(),
            onChanged: (v) => setSheet(() => selected = v ?? selected),
            decoration: const InputDecoration(
              labelText: 'Profession',
              prefixIcon: Icon(Icons.handyman_rounded),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await auth.setServiceProfessionOnly(selected);
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
  Iterable<JobRequest> _filteredJobs(JobProvider jobs, AuthProvider auth) {
    // Service worker should never see rider/delivery pool jobs here.
    final nonRiderJobs = jobs.all.where((j) => !j.isRiderJob);
    final profRaw = (auth.serviceProfession ?? '').trim().toLowerCase();
    if (profRaw.isEmpty) {
      return nonRiderJobs.where((j) {
        if (!auth.isOnlineForWork && j.isPending) return false;
        return true;
      });
    }

    // Map the worker's profession to allowed service names
    Set<String> allowedNames;
    if (profRaw.contains('mechanic') || profRaw.contains('auto') || profRaw.contains('car')) {
      // Mechanic - all car/bike repair services
      allowedNames = {
        'puncture', 'tyre', 'battery', 'oil change', 'car repair',
        'bike repair', 'ac gas', 'brake', 'engine', 'suspension'
      };
    } else if (profRaw.contains('elec')) {
      // Electrician - all electrical work
      allowedNames = {
        'electrician', 'wiring', 'mcb', 'ac installation',
        'fan installation', 'electrical'
      };
    } else if (profRaw.contains('plumb')) {
      // Plumber - all plumbing work
      allowedNames = {
        'plumber', 'pipe', 'leak', 'tap', 'drainage',
        'water', 'toilet', 'shower'
      };
    } else if (profRaw.contains('carp')) {
      // Carpenter - all carpentry work
      allowedNames = {
        'carpenter', 'door', 'window', 'furniture',
        'wooden', 'cabinet', 'shelf'
      };
    } else if (profRaw.contains('paint')) {
      // Painter - all painting work
      allowedNames = {
        'painter', 'painting', 'wall paint',
        'interior', 'exterior', 'colour'
      };
    } else if (profRaw.contains('ac')) {
      // AC Technician - all AC services
      allowedNames = {
        'ac technician', 'ac repair', 'ac', 'aircon',
        'ac gas', 'ac servicing', 'cooling'
      };
    } else {
      // Fallback - match any job containing the profession name
      allowedNames = {profRaw};
    }

    return nonRiderJobs.where((j) {
      if (!auth.isOnlineForWork && j.isPending) return false;
      final name = (j.serviceTypeName).toString().toLowerCase().trim();
      return allowedNames.any((allowed) => name.contains(allowed) || allowed.contains(name));
    });
  }

  Widget _onlineToggleCard(BuildContext context, AuthProvider auth) {
    final on = auth.isOnlineForWork;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: on
            ? AppColors.primaryLight.withValues(alpha: 0.4)
            : AppColors.backgroundLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: on
              ? AppColors.primary.withValues(alpha: 0.35)
              : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Icon(
            on ? Icons.wifi_rounded : Icons.wifi_off_rounded,
            color: on ? AppColors.primary : AppColors.textSecondary,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  on ? 'Online' : 'Offline',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  on
                      ? 'You can receive new job requests.'
                      : 'New requests are hidden — turn on when you are available.',
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.3,
                    color: AppColors.textSecondary.withValues(alpha: 0.95),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: on,
            onChanged: (v) => auth.setOnlineForWork(v),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(int pending, int active) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: AppColors.gradientPrimary),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _metric('Pending', '$pending'),
          ),
          Expanded(
            child: _metric('Active', '$active'),
          ),
        ],
      ),
    );
  }

  Widget _metric(String title, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        Text(
          title,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _ServiceWorkerSideDrawer extends StatelessWidget {
  const _ServiceWorkerSideDrawer({
    required this.selectedIndex,
    required this.auth,
    required this.pendingCount,
    required this.activeCount,
    required this.completedCount,
    required this.onSelectTab,
    required this.onClose,
    required this.onLogout,
    this.showKabari = false,
    this.onOpenScrapRates,
  });

  final int selectedIndex;
  final AuthProvider auth;
  final int pendingCount;
  final int activeCount;
  final int completedCount;
  final void Function(int) onSelectTab;
  final VoidCallback onClose;
  final VoidCallback onLogout;
  final bool showKabari;
  final VoidCallback? onOpenScrapRates;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final title = (auth.serviceProfession ?? '').trim().isEmpty
        ? 'Service Worker'
        : auth.serviceProfession!.trim();

    return SafeArea(
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(16, 16 + top, 16, 14),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: AppColors.gradientPrimary,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.handyman_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.appName,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.88),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if ((auth.userEmail ?? '').isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          auth.userEmail!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.82),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Expanded(child: _drawerStat('Pending', pendingCount)),
                const SizedBox(width: 8),
                Expanded(child: _drawerStat('Active', activeCount)),
                const SizedBox(width: 8),
                Expanded(child: _drawerStat('Done', completedCount)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              children: [
                _drawerItem(
                  selected: selectedIndex == 0,
                  icon: Icons.work_outline_rounded,
                  title: 'Jobs',
                  subtitle: 'Requests & active jobs',
                  onTap: () => onSelectTab(0),
                ),
                _drawerItem(
                  selected: selectedIndex == 1,
                  icon: Icons.history_rounded,
                  title: 'History',
                  subtitle: 'Completed work',
                  onTap: () => onSelectTab(1),
                ),
                _drawerItem(
                  selected: selectedIndex == 2,
                  icon: Icons.person_outline_rounded,
                  title: 'Profile',
                  subtitle: 'Online status & account',
                  onTap: () => onSelectTab(2),
                ),
                if (showKabari && onOpenScrapRates != null)
                  _drawerItem(
                    selected: false,
                    icon: Icons.recycling_rounded,
                    title: 'Scrap rates (PKR)',
                    subtitle: 'Paper, plastic, iron — Near Me profile',
                    onTap: onOpenScrapRates!,
                  ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(12, 12, 12, 8),
                  child: Divider(),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.logout_rounded,
                    color: AppColors.error,
                  ),
                  title: const Text(
                    'Sign out',
                    style: TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onTap: onLogout,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _drawerItem({
    required bool selected,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primaryLight.withValues(alpha: 0.65)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.35)
                  : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primary.withValues(alpha: 0.12)
                      : AppColors.backgroundLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: selected ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
            ],
          ),
        ),
      ),
    );
  }

  Widget _drawerStat(String label, int value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(
            '$value',
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
