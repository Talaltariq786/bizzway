import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/gym_pakistan_schema.dart';
import '../../models/business.dart';
import '../../providers/gym_management_provider.dart';

/// Customer: pick Pakistan-market package → online admission ticket (pay cash at gym).
class GymOnlineAdmissionScreen extends StatefulWidget {
  const GymOnlineAdmissionScreen({super.key, required this.business});

  final Business business;

  @override
  State<GymOnlineAdmissionScreen> createState() =>
      _GymOnlineAdmissionScreenState();
}

class _GymOnlineAdmissionScreenState extends State<GymOnlineAdmissionScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _trainerCtrl = TextEditingController();
  String? _packageId;
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _trainerCtrl.dispose();
    super.dispose();
  }

  Color get _accent => widget.business.color;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final pid = _packageId;
    if (pid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a membership package')),
      );
      return;
    }
    final biz = widget.business;
    try {
      final adm = context.read<GymManagementProvider>().requestAdmission(
            businessId: biz.businessTypeId,
            businessName: biz.name,
            packageId: pid,
            memberName: _nameCtrl.text,
            phone: _phoneCtrl.text,
            trainerPreference: _trainerCtrl.text,
          );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.confirmation_number_rounded, color: _accent),
              const SizedBox(width: 8),
              const Expanded(child: Text('Admission ticket')),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Yeh ticket gym par le jayein. Wahan cash payment ke baad membership start ho jaye gi.',
                  style: TextStyle(height: 1.35),
                ),
                const SizedBox(height: 16),
                SelectableText(
                  adm.ticketCode,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: _accent,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${adm.packageName} • Rs. ${adm.feePkr.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: adm.ticketCode));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ticket copied')),
                );
              },
              child: const Text('Copy code'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not submit: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pkgs = GymPakistanSchema.defaultPackages;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Online admission'),
        backgroundColor: _accent,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            Text(
              widget.business.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Package choose karein — payment gym par cash hogi. Ticket save kar lein.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            const Text(
              'Membership packages',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            ...pkgs.map((p) {
              final id = p['id']! as String;
              final name = p['name']! as String;
              final fee = (p['feePkr'] as num).toDouble();
              final days = (p['durationDays'] as num?)?.toInt();
              final sessions = (p['sessionCount'] as num?)?.toInt();
              final sel = _packageId == id;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    onTap: () => setState(() => _packageId = id),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: sel ? _accent : AppColors.border,
                          width: sel ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            sel
                                ? Icons.radio_button_checked_rounded
                                : Icons.radio_button_off_rounded,
                            color: sel ? _accent : AppColors.textHint,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  [
                                    'Rs. ${fee.toStringAsFixed(0)}',
                                    if (days != null && days > 0)
                                      '$days days',
                                    if (sessions != null) '$sessions sessions',
                                  ].join(' · '),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Full name',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.trim().length < 2) {
                  return 'Name required';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone number',
                hintText: '03xx-xxxxxxx',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.trim().length < 10) {
                  return 'Valid phone required';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _trainerCtrl,
              decoration: const InputDecoration(
                labelText: 'Trainer preference (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _submit,
              style: FilledButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Generate admission ticket'),
            ),
          ],
        ),
      ),
    );
  }
}
