import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/app_toast.dart';
import '../../core/utils/async_guard.dart';
import '../../providers/auth_provider.dart';
import '../../providers/business_provider.dart';
import '../../providers/rider_team_provider.dart';

class CustomerLoginScreen extends StatefulWidget {
  const CustomerLoginScreen({super.key});

  @override
  State<CustomerLoginScreen> createState() => _CustomerLoginScreenState();
}

class _CustomerLoginScreenState extends State<CustomerLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) return;
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final auth = context.read<AuthProvider>();
      final ok = await AsyncGuard.withTimeout(
        auth.loginWithPhone(
          _phoneCtrl.text.trim(),
          password: _passwordCtrl.text,
        ),
      );
      if (!mounted) return;
      if (ok) {
        Navigator.pushReplacementNamed(context, AppRoutes.customerHome);
      } else {
        showAppSnackBar(
          context,
          'Phone / password check karein.',
          kind: AppSnackKind.warning,
        );
      }
    } catch (e) {
      if (!mounted) return;
      showAppSnackBarFromException(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _RoleLoginScaffold(
      title: 'Customer Login',
      subtitle: 'Phone + password (signup jaisa)',
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone'),
              validator: (v) =>
                  (v ?? '').trim().length >= 10 ? null : 'Enter valid phone',
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _passwordCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
              validator: (v) =>
                  (v ?? '').trim().length >= 6 ? null : 'Min 6 characters',
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _busy ? null : _submit,
                child: Text(_busy ? 'Please wait...' : 'Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BusinessLoginScreen extends StatefulWidget {
  const BusinessLoginScreen({super.key});

  @override
  State<BusinessLoginScreen> createState() => _BusinessLoginScreenState();
}

class _BusinessLoginScreenState extends State<BusinessLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) return;
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final auth = context.read<AuthProvider>();
      final ok = await AsyncGuard.withTimeout(
        auth.login(_emailCtrl.text.trim(), _passwordCtrl.text),
      );
      if (!mounted) return;
      if (!ok) {
        showAppSnackBar(
          context,
          'Email / password check karein (min 6 characters).',
          kind: AppSnackKind.warning,
        );
        return;
      }

      final business = context.read<BusinessProvider>();
      await AsyncGuard.withTimeout(business.loadBusiness());
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        business.selectedBusiness == null
            ? AppRoutes.businessSelection
            : AppRoutes.dashboard,
      );
    } catch (e) {
      if (!mounted) return;
      showAppSnackBarFromException(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _RoleLoginScaffold(
      title: 'Business Login',
      subtitle: 'Owner account (email + password)',
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
              validator: (v) => (v ?? '').contains('@') ? null : 'Enter email',
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _passwordCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
              validator: (v) =>
                  (v ?? '').length >= 6 ? null : 'Min 6 characters',
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _busy ? null : _submit,
                child: Text(_busy ? 'Please wait...' : 'Login'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RiderLoginScreen extends StatefulWidget {
  const RiderLoginScreen({super.key});

  @override
  State<RiderLoginScreen> createState() => _RiderLoginScreenState();
}

class _RiderLoginScreenState extends State<RiderLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();
  final _riderIdCtrl = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _riderIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) return;
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final auth = context.read<AuthProvider>();
      final team = context.read<RiderTeamProvider>();
      await team.ensureLoaded();
      final hit = team.findTeamRiderForLogin(
        _riderIdCtrl.text.trim(),
        _phoneCtrl.text.trim(),
      );
      final ok = hit == null
          ? false
          : await AsyncGuard.withTimeout(
              auth.loginAsTeamRider(
                phone: _phoneCtrl.text.trim(),
                riderId: hit.rider.riderId,
                businessId: hit.businessId,
                riderName: hit.rider.name,
              ),
            );
      if (!mounted) return;
      if (ok) {
        Navigator.pushReplacementNamed(context, AppRoutes.riderHome);
      } else {
        showAppSnackBar(
          context,
          'Rider ID ya phone match nahi ho raha. Owner app se "Meray riders" check karein.',
          kind: AppSnackKind.warning,
        );
      }
    } catch (e) {
      if (!mounted) return;
      showAppSnackBarFromException(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _RoleLoginScaffold(
      title: 'Rider Login',
      subtitle: 'Team rider (store-assigned) — Rider ID + phone',
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _riderIdCtrl,
              decoration: const InputDecoration(labelText: 'Rider ID'),
              validator: (v) =>
                  (v ?? '').trim().isNotEmpty ? null : 'Enter rider id',
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone'),
              validator: (v) =>
                  (v ?? '').trim().length >= 10 ? null : 'Enter valid phone',
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _busy ? null : _submit,
                child: Text(_busy ? 'Please wait...' : 'Continue'),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Owner app me Profile → Meray riders se aap ka ID + phone add hota hai. '
              'Wohi yahan enter karein.',
              style: TextStyle(
                fontSize: 11.5,
                height: 1.35,
                color: AppColors.textSecondary.withValues(alpha: 0.95),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeServicesLoginScreen extends StatefulWidget {
  const HomeServicesLoginScreen({super.key});

  @override
  State<HomeServicesLoginScreen> createState() => _HomeServicesLoginScreenState();
}

class _HomeServicesLoginScreenState extends State<HomeServicesLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) return;
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final auth = context.read<AuthProvider>();
      final ok = await AsyncGuard.withTimeout(
        auth.loginWithPhone(
          _phoneCtrl.text.trim(),
          password: _passwordCtrl.text,
        ),
      );
      if (!mounted) return;
      if (ok) {
        final u = context.read<AuthProvider>();
        if (u.userType == UserType.rider) {
          Navigator.pushReplacementNamed(context, AppRoutes.riderHome);
        } else {
          Navigator.pushReplacementNamed(context, AppRoutes.serviceWorkerHome);
        }
      } else {
        showAppSnackBar(
          context,
          'Phone / password check karein.',
          kind: AppSnackKind.warning,
        );
      }
    } catch (e) {
      if (!mounted) return;
      showAppSnackBarFromException(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _RoleLoginScaffold(
      title: 'Home Services Login',
      subtitle: 'Phone + password',
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone'),
              validator: (v) =>
                  (v ?? '').trim().length >= 10 ? null : 'Enter valid phone',
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _passwordCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
              validator: (v) =>
                  (v ?? '').trim().length >= 6 ? null : 'Min 6 characters',
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _busy ? null : _submit,
                child: Text(_busy ? 'Please wait...' : 'Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleLoginScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _RoleLoginScaffold({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.black54),
            ),
            const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    );
  }
}

