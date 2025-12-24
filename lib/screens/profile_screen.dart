import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  bool _isLogin = true; // Toggle between Login and Sign Up
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      if (_isLogin) {
        await _authService.signIn(
          email: email,
          password: password,
        );
      } else {
        final session = await _authService.signUp(
          email: email,
          password: password,
        );

        if (mounted) {
          if (session != null) {
             ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Cuenta creada y sesión iniciada!')),
            );
          } else {
            // Session is null, meaning email verification is likely required
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Cuenta creada! Por favor revisa tu correo para verificar.')),
            );
             setState(() {
              _isLogin = true;
            });
          }
        }
      }
    } on AuthException catch (error) {
      if (mounted) {
        String message = error.message;

        // Attempt to extract cleaner message from JSON if it looks like one
        if (message.startsWith('{') && message.contains('"message":')) {
          try {
             final RegExp regex = RegExp(r'"message":"([^"]+)"');
             final match = regex.firstMatch(message);
             if (match != null && match.groupCount >= 1) {
               message = match.group(1) ?? message;
             }
          } catch (_) {}
        }

        // Handle specific known Supabase email errors
        if (message.contains("Error sending verification email") ||
            message.contains("Error sending confirmation email")) {
             _showEmailConfigErrorDialog();
             return;
        } else if (message.contains("User already registered")) {
             message = "Este usuario ya está registrado. Intenta iniciar sesión.";
        } else if (message.contains("Invalid login credentials")) {
             message = "Credenciales incorrectas. Verifica tu email y contraseña.";
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error inesperado: ${error.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleResetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa un email válido para restablecer la contraseña.')),
      );
      return;
    }

    try {
      await _authService.resetPasswordForEmail(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Se ha enviado un correo para restablecer tu contraseña.')),
        );
      }
    } on AuthException catch (e) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: Colors.redAccent),
        );
      }
    } catch (e) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al solicitar restablecimiento.'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  void _showEmailConfigErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error de Configuración de Supabase'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  'El servicio de correo de tu proyecto Supabase no está configurado correctamente o ha excedido su límite.'),
              SizedBox(height: 16),
              Text(
                  'Para solucionar esto durante el desarrollo y poder registrarte:'),
              SizedBox(height: 8),
              Text('1. Ve a tu panel de Supabase.'),
              Text('2. Authentication > Providers > Email.'),
              Text('3. Desactiva "Confirm email".'),
              SizedBox(height: 16),
              Text(
                  'Revisa el archivo SUPABASE_SETUP.md para más detalles.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  Future<void> _signOut() async {
    await _authService.signOut();
  }

  @override
  Widget build(BuildContext context) {
    // Listen to Auth State
    return StreamBuilder<AuthState>(
      stream: _authService.onAuthStateChange,
      builder: (context, snapshot) {
        final session = _authService.currentSession;

        // If logged in, show profile
        if (session != null) {
          return _buildUserProfile(session.user);
        }

        // If not logged in, show Auth Form
        return _buildAuthForm();
      },
    );
  }

  Widget _buildUserProfile(User user) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey.shade100,
                child: Icon(Icons.person, size: 60, color: Colors.grey.shade400),
              ),
              const SizedBox(height: 24),
              Text(
                user.email ?? 'Usuario',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'ID: ${user.id.substring(0, 8)}...',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 40),
              // Placeholder for future features
              ListTile(
                leading: const Icon(Icons.favorite_border),
                title: const Text('Mis Favoritos'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Próximamente")));
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: const Text('Configuración'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Próximamente")));
                },
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _signOut,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Cerrar Sesión'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAuthForm() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.lock_outline_rounded,
                  size: 64,
                  color: Colors.black87,
                ),
                const SizedBox(height: 24),
                Text(
                  _isLogin ? 'Bienvenido de nuevo' : 'Crea tu cuenta',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isLogin
                      ? 'Inicia sesión para guardar tus favoritos.'
                      : 'Regístrate para empezar a coleccionar.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 40),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa un email';
                    }
                    if (!value.contains('@')) {
                      return 'Ingresa un email válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                  ),
                  obscureText: _obscurePassword,
                  validator: (value) {
                     if (value == null || value.isEmpty) {
                      return 'Por favor ingresa tu contraseña';
                    }
                    if (value.length < 6) {
                      return 'La contraseña debe tener al menos 6 caracteres';
                    }
                    return null;
                  },
                ),
                if (_isLogin) ...[
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _handleResetPassword,
                      child: Text(
                        '¿Olvidaste tu contraseña?',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ] else
                   const SizedBox(height: 24),

                if (_isLoading)
                  const Center(child: CircularProgressIndicator(color: Colors.black))
                else
                  ElevatedButton(
                    onPressed: _handleAuth,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      _isLogin ? 'Iniciar Sesión' : 'Registrarse',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isLogin = !_isLogin;
                      // Clear errors when switching
                      _formKey.currentState?.reset();
                    });
                  },
                  child: RichText(
                    text: TextSpan(
                      text: _isLogin
                          ? '¿No tienes cuenta? '
                          : '¿Ya tienes cuenta? ',
                      style: TextStyle(color: Colors.grey.shade600),
                      children: [
                        TextSpan(
                          text: _isLogin ? 'Regístrate' : 'Inicia Sesión',
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                 const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
