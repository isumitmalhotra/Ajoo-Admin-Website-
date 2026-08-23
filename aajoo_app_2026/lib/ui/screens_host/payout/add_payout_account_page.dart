import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:rent_home/constants.dart';
import 'package:rent_home/ui/screens_host/payout/payout_controller.dart';
import 'package:rent_home/utils/input_sanitizers.dart';

class AddPayoutAccountPage extends StatefulWidget {
  const AddPayoutAccountPage({super.key});

  @override
  State<AddPayoutAccountPage> createState() => _AddPayoutAccountPageState();
}

class _AddPayoutAccountPageState extends State<AddPayoutAccountPage> {
  final _formKey = GlobalKey<FormState>();
  final _accountNumberCtrl = TextEditingController();
  final _confirmAccountNumberCtrl = TextEditingController();
  final _ifscCtrl = TextEditingController();
  final _holderNameCtrl = TextEditingController();

  late final PayoutController _controller;

  bool _bootstrapping = true;

  @override
  void initState() {
    super.initState();
    _controller = Get.isRegistered<PayoutController>()
        ? Get.find<PayoutController>()
        : Get.put(PayoutController());
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    // If we haven't fetched yet (e.g. opened directly from drawer), fetch now
    // so we can pre-fill in edit mode.
    if (_controller.accountDetails.value == null &&
        !_controller.isAccountLoading.value) {
      await _controller.fetchAccountDetails();
    }
    _prefill();
    if (mounted) setState(() => _bootstrapping = false);
  }

  void _prefill() {
    final acc = _controller.accountDetails.value;
    if (acc != null) {
      _accountNumberCtrl.text = acc.accountNumber;
      _confirmAccountNumberCtrl.text = acc.accountNumber;
      _ifscCtrl.text = acc.accountIfsc.toUpperCase();
    }
  }

  @override
  void dispose() {
    _accountNumberCtrl.dispose();
    _confirmAccountNumberCtrl.dispose();
    _ifscCtrl.dispose();
    _holderNameCtrl.dispose();
    super.dispose();
  }

  String? _validateAccountNumber(String? v) {
    if (v == null || v.trim().isEmpty) return 'Account number is required';
    final digits = v.trim();
    if (digits.length < 6 || digits.length > 20) {
      return 'Enter a valid account number (6–20 digits)';
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(digits)) {
      return 'Account number must be digits only';
    }
    return null;
  }

  String? _validateConfirmAccount(String? v) {
    if (v == null || v.isEmpty) return 'Please re-enter your account number';
    if (v.trim() != _accountNumberCtrl.text.trim()) {
      return 'Account numbers do not match';
    }
    return null;
  }

  String? _validateIfsc(String? v) {
    if (v == null || v.trim().isEmpty) return 'IFSC code is required';
    final ifsc = v.trim().toUpperCase();
    final ok = RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(ifsc);
    if (!ok) return 'Enter a valid IFSC code (e.g. HDFC0001234)';
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    final acc = _controller.accountDetails.value;
    final ok = await _controller.saveAccountDetails(
      accountNumber: _accountNumberCtrl.text.trim(),
      accountIfsc: _ifscCtrl.text.trim().toUpperCase(),
      // Collected by this form since it was written, and dropped on the way
      // out until now. Without it no transfer can be initiated at all.
      accountHolderName: _holderNameCtrl.text.trim(),
      accountId: acc?.hadId,
    );

    if (!mounted) return;

    if (ok) {
      Get.snackbar(
        'Saved',
        acc == null
            ? 'Bank account added successfully'
            : 'Bank account updated successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: kSuccess,
        colorText: Colors.white,
      );
      Navigator.of(context).pop(true);
    } else {
      Get.snackbar(
        'Error',
        'Could not save bank account. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: kDanger,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = _controller.accountDetails.value != null;

    if (_bootstrapping) {
      return Scaffold(
        backgroundColor: kcontentColor,
        appBar: AppBar(
          title: const Text('Bank Account'),
          backgroundColor: kSand,
          foregroundColor: kInk,
          centerTitle: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: kcontentColor,
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Bank Account' : 'Add Bank Account'),
        backgroundColor: kSand,
        foregroundColor: kInk,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _headerCard(isEdit),
                const SizedBox(height: 20),
                _field(
                  // NOT optional. RazorpayX cannot initiate a transfer without
                  // the name on the account, and the penny drop compares it to
                  // the name the bank holds — which is the check that catches
                  // a host entering somebody else's account.
                  controller: _holderNameCtrl,
                  label: 'Account Holder Name *',
                  icon: Icons.person_outline,
                  textCapitalization: TextCapitalization.words,
                  inputFormatters: AppInputFormatters.name,
                  validator: (v) {
                    final t = (v ?? '').trim();
                    if (t.isEmpty) return 'Account holder name is required';
                    if (t.length < 3) return 'Enter the full name on the account';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                _field(
                  controller: _accountNumberCtrl,
                  label: 'Account Number',
                  icon: Icons.account_balance,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(20),
                  ],
                  obscureText: false,
                  validator: _validateAccountNumber,
                ),
                const SizedBox(height: 14),
                _field(
                  controller: _confirmAccountNumberCtrl,
                  label: 'Confirm Account Number',
                  icon: Icons.lock_outline,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(20),
                  ],
                  validator: _validateConfirmAccount,
                ),
                const SizedBox(height: 14),
                _field(
                  controller: _ifscCtrl,
                  label: 'IFSC Code',
                  icon: Icons.code,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(11),
                    FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                  ],
                  validator: _validateIfsc,
                ),
                const SizedBox(height: 24),
                _infoNote(),
                const SizedBox(height: 24),
                _saveButton(isEdit),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _headerCard(bool isEdit) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCream,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kLine),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: kIndigo.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.account_balance_wallet_rounded,
                color: kIndigo, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEdit ? 'Update your payout account' : 'Add payout account',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: kInk,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Payouts will be transferred to this bank account.',
                  style: TextStyle(fontSize: 13, color: kMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,
    bool obscureText = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: kCream,
        prefixIcon: Icon(icon, color: kIndigo),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kLine),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kLine),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kIndigo, width: 1.4),
        ),
      ),
    );
  }

  Widget _infoNote() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: kSand,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kLine),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, size: 18, color: kMuted),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Double-check the account number and IFSC. Incorrect details may delay or fail payouts.',
              style: TextStyle(fontSize: 12.5, color: kInk2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _saveButton(bool isEdit) {
    return Obx(() {
      final saving = _controller.isSavingAccount.value;
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: saving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: kIndigo,
            foregroundColor: Colors.white,
            disabledBackgroundColor: kIndigo.withOpacity(0.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: saving
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: Colors.white,
                  ),
                )
              : Text(
                  isEdit ? 'Update Account' : 'Save Account',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      );
    });
  }
}
