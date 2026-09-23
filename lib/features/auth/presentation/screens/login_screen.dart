import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sign in is ready to connect.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFBFC),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 52),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _BrandHeader(),
                    const SizedBox(height: 42),
                    Text(
                      'Welcome back',
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sign in to continue making a difference.',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 15,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 30),
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _FieldLabel(label: 'Email address'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            decoration: _inputDecoration(
                              hintText: 'you@example.com',
                              icon: Icons.mail_outline_rounded,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Enter your email address';
                              }
                              if (!value.contains('@')) return 'Enter a valid email address';
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          _FieldLabel(label: 'Password'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _submit(),
                            decoration: _inputDecoration(
                              hintText: 'Enter your password',
                              icon: Icons.lock_outline_rounded,
                            ).copyWith(
                              suffixIcon: IconButton(
                                tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Enter your password';
                              }
                              if (value.length < 6) return 'Use at least 6 characters';
                              return null;
                            },
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {},
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFFAA2943),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text('Forgot password?'),
                            ),
                          ),
                          const SizedBox(height: 8),
                          FilledButton(
                            onPressed: _submit,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFAA2943),
                              foregroundColor: Colors.white,
                              minimumSize: const Size.fromHeight(54),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            child: const Text('Sign in'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Expanded(child: Divider(color: colorScheme.outlineVariant)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Text(
                            'OR',
                            style: TextStyle(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: colorScheme.outlineVariant)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.g_mobiledata_rounded, size: 28),
                      label: const Text('Continue with Google'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colorScheme.onSurface,
                        minimumSize: const Size.fromHeight(52),
                        side: BorderSide(color: colorScheme.outlineVariant),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        textStyle: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'New to BloodConnectSL?',
                          style: TextStyle(color: colorScheme.onSurfaceVariant),
                        ),
                        TextButton(
                          onPressed: () => context.push('/signup'),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFFAA2943),
                            padding: const EdgeInsets.only(left: 6),
                          ),
                          child: const Text('Create account'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({required String hintText, required IconData icon}) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: Icon(icon, size: 21),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE5D9DC)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE5D9DC)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFAA2943), width: 1.5),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: const Color(0xFFAA2943),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.water_drop_outlined,
            color: Colors.white,
            size: 29,
          ),
        ),
        const SizedBox(width: 12),
        const Text(
          'BloodConnectSL',
          style: TextStyle(
            color: Color(0xFF252022),
            fontSize: 21,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: Color(0xFF30282A),
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}