import 'package:flutter/material.dart';

import '../../core/data/local_store.dart';
import '../../core/widgets/app_bottom_nav.dart';
import '../../core/widgets/pattern_page.dart';

class PortalScreen extends StatefulWidget {
  const PortalScreen({super.key});

  @override
  State<PortalScreen> createState() => _PortalScreenState();
}

class _PortalScreenState extends State<PortalScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  bool _authenticated = false;
  String? _error;
  String? _sessionEmail;

  @override
  void initState() {
    super.initState();
    _restore();
  }

  Future<void> _restore() async {
    final email = await LocalStore.instance.portalSessionEmail();
    if (!mounted) return;
    if (email != null && email.isNotEmpty) {
      setState(() {
        _authenticated = true;
        _sessionEmail = email;
      });
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _error = null;
      _loading = true;
    });
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    final email = _email.text.trim();
    final password = _password.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Enter your principal credentials.';
      });
      return;
    }
    if (password.length < 4) {
      setState(() {
        _loading = false;
        _error = 'Invalid credentials. Please try again.';
      });
      return;
    }

    await LocalStore.instance.savePortalSession(email);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _authenticated = true;
      _sessionEmail = email;
    });
  }

  Future<void> _logout() async {
    await LocalStore.instance.clearPortalSession();
    if (!mounted) return;
    setState(() {
      _authenticated = false;
      _sessionEmail = null;
      _password.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_authenticated) {
      return _PortalDashboard(
        email: _sessionEmail ?? 'Principal',
        onLogout: _logout,
      );
    }
    return _PortalLogin(
      email: _email,
      password: _password,
      obscure: _obscure,
      loading: _loading,
      error: _error,
      onToggleObscure: () => setState(() => _obscure = !_obscure),
      onLogin: _login,
    );
  }
}

class _PortalLogin extends StatelessWidget {
  const _PortalLogin({
    required this.email,
    required this.password,
    required this.obscure,
    required this.loading,
    required this.error,
    required this.onToggleObscure,
    required this.onLogin,
  });

  final TextEditingController email;
  final TextEditingController password;
  final bool obscure;
  final bool loading;
  final String? error;
  final VoidCallback onToggleObscure;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return PatternPage(
      breadcrumb: 'Home > Principal Portal',
      title: 'Portal',
      subtitle: 'PRINCIPAL LOGIN',
      bottom: const AppBottomNav(currentIndex: AppNavIndex.portal),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Secure access for principals. Session is stored locally '
            'for offline use.',
            style: PatternPage.body(
              size: 13,
              color: Colors.white.withValues(alpha: 0.75),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: email,
            keyboardType: TextInputType.emailAddress,
            style: PatternPage.body(size: 14),
            decoration: _decoration('Email'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: password,
            obscureText: obscure,
            onSubmitted: (_) => onLogin(),
            style: PatternPage.body(size: 14),
            decoration: _decoration('Password').copyWith(
              suffixIcon: IconButton(
                onPressed: onToggleObscure,
                icon: Icon(
                  obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: PatternPage.muted,
                ),
              ),
            ),
          ),
          if (error != null) ...[
            const SizedBox(height: 12),
            Text(
              error!,
              style: PatternPage.body(size: 12.5, color: const Color(0xFFE8A0A0)),
            ),
          ],
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: FilledButton(
              onPressed: loading ? null : onLogin,
              style: FilledButton.styleFrom(
                backgroundColor: PatternPage.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                loading ? 'Signing in…' : 'Sign In',
                style: PatternPage.panchang(size: 11, weight: FontWeight.w600),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Demo: any email + password of 4+ characters. Works offline.',
            style: PatternPage.body(size: 11.5, color: PatternPage.muted),
          ),
        ],
      ),
    );
  }

  InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: PatternPage.body(size: 13, color: PatternPage.muted),
      filled: true,
      fillColor: const Color(0xFF1C1C1E),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }
}

class _PortalDashboard extends StatelessWidget {
  const _PortalDashboard({required this.email, required this.onLogout});

  final String email;
  final VoidCallback onLogout;

  void _soon(BuildContext context, String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label — vault sync coming with Supabase')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PatternPage(
      breadcrumb: 'Home > Principal Portal',
      title: 'Portal',
      subtitle: email.toUpperCase(),
      bottom: const AppBottomNav(currentIndex: AppNavIndex.portal),
      actions: [
        TextButton(
          onPressed: onLogout,
          child: Text(
            'Sign out',
            style: PatternPage.body(size: 12, color: PatternPage.muted),
          ),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PatternSectionLabel('Documents'),
          const SizedBox(height: 8),
          PatternGroup(
            children: [
              PatternListRow(
                title: 'Documents Vault',
                subtitle: 'Certificates, manuals & records',
                leading: const PatternDocIcon(),
                onTap: () => _soon(context, 'Documents Vault'),
              ),
            ],
          ),
          const SizedBox(height: 28),
          const PatternSectionLabel('Operations'),
          const SizedBox(height: 8),
          PatternGroup(
            children: [
              PatternListRow(
                title: 'Maintenance Summary',
                subtitle: 'Status overview & upcoming checks',
                onTap: () => _soon(context, 'Maintenance Summary'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
