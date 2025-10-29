import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../bloc/auth/auth_state.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleRegister() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
            AuthSignUpRequested(
              email: _emailController.text.trim().toLowerCase(),
              password: _passwordController.text,
              fullName: _nameController.text.trim(),
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    final maxWidth = isTablet ? 500.0 : size.width * 0.9;

    return Scaffold(
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            context.go('/home');
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(child: Text(state.message)),
                  ],
                ),
                backgroundColor: AppColors.errorRed,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.all(16),
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return Stack(
            children: [
              // Fondo con gradiente
              Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                ),
              ),
              
              // Círculos decorativos de fondo - Diferentes posiciones que el Login
              Positioned(
                top: -150,
                left: -120,
                child: Container(
                  width: 350,
                  height: 350,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.orange.withOpacity(0.25),
                        Colors.transparent,
                      ],
                    ),
                  ),
                )
                    .animate(onPlay: (controller) => controller.repeat(reverse: true))
                    .scale(duration: 3500.ms, begin: const Offset(0.9, 0.9), end: const Offset(1.3, 1.3)),
              ),
              
              Positioned(
                bottom: -100,
                right: -100,
                child: Container(
                  width: 350,
                  height: 350,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.primaryRed.withOpacity(0.2),
                        Colors.transparent,
                      ],
                    ),
                  ),
                )
                    .animate(onPlay: (controller) => controller.repeat(reverse: true))
                    .scale(duration: 3000.ms, begin: const Offset(1.0, 1.0), end: const Offset(1.4, 1.4)),
              ),
              
              Positioned(
                top: size.height * 0.4,
                left: -80,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.purple.withOpacity(0.15),
                        Colors.transparent,
                      ],
                    ),
                  ),
                )
                    .animate(onPlay: (controller) => controller.repeat(reverse: true))
                    .scale(duration: 4000.ms, begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2)),
              ),
              
              // Contenido principal
              SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo flotante con efecto glass - Ícono diferente
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 2,
                            ),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withOpacity(0.15),
                                Colors.white.withOpacity(0.05),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryRed.withOpacity(0.3),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Icon(
                                Icons.person_add_rounded,
                                size: 60,
                                color: AppColors.primaryRed,
                              ),
                            ),
                          ),
                        )
                            .animate()
                            .fadeIn(duration: 600.ms)
                            .scale(delay: 100.ms, duration: 600.ms, curve: Curves.elasticOut)
                            .then(delay: 200.ms)
                            .shake(hz: 0.3, duration: 1000.ms),
                        
                        const SizedBox(height: 25),
                        
                        // Tarjeta de registro con glassmorphism
                        Container(
                          constraints: BoxConstraints(maxWidth: maxWidth),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1.5,
                            ),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withOpacity(0.15),
                                Colors.white.withOpacity(0.05),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(30),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                              child: Container(
                                padding: const EdgeInsets.all(32),
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Título PALOMIX
                                      ShaderMask(
                                        shaderCallback: (bounds) => LinearGradient(
                                          colors: [
                                            AppColors.primaryRed,
                                            Colors.orange,
                                            AppColors.primaryRed,
                                          ],
                                        ).createShader(bounds),
                                        child: Text(
                                          'PALOMIX',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 42,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white,
                                            letterSpacing: 6,
                                          ),
                                        ),
                                      )
                                          .animate()
                                          .fadeIn(delay: 200.ms, duration: 600.ms)
                                          .slideY(begin: -0.3, end: 0, curve: Curves.easeOut),
                                      
                                      const SizedBox(height: 12),
                                      
                                      // Subtítulo
                                      Text(
                                        'Crear Cuenta',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 20,
                                          color: AppColors.softWhite.withOpacity(0.9),
                                          fontWeight: FontWeight.w500,
                                          letterSpacing: 1,
                                        ),
                                      )
                                          .animate()
                                          .fadeIn(delay: 300.ms, duration: 600.ms),
                                      
                                      const SizedBox(height: 32),
                                      
                                      // Campo de nombre
                                      _buildGlassTextField(
                                        controller: _nameController,
                                        label: 'Nombre Completo',
                                        icon: Icons.person_rounded,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Por favor ingresa tu nombre';
                                          }
                                          if (value.length < 3) {
                                            return 'Mínimo 3 caracteres';
                                          }
                                          return null;
                                        },
                                      )
                                          .animate()
                                          .fadeIn(delay: 400.ms, duration: 600.ms)
                                          .slideX(begin: -0.3, end: 0, curve: Curves.easeOut),
                                      
                                      const SizedBox(height: 16),
                                      
                                      // Campo de email - ✅ REGEX CORREGIDO
                                      _buildGlassTextField(
                                        controller: _emailController,
                                        label: 'Correo Electrónico',
                                        icon: Icons.email_rounded,
                                        keyboardType: TextInputType.emailAddress,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Por favor ingresa tu correo';
                                          }
                                          final email = value.trim();
                                          // ✅ CORRECCIÓN: Usar comillas dobles para evitar problemas con comilla simple
                                          final emailRegex = RegExp(
                                              r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$");
                                          if (!emailRegex.hasMatch(email)) {
                                            return 'Correo inválido';
                                          }
                                          return null;
                                        },
                                      )
                                          .animate()
                                          .fadeIn(delay: 500.ms, duration: 600.ms)
                                          .slideX(begin: -0.3, end: 0, curve: Curves.easeOut),
                                      
                                      const SizedBox(height: 16),
                                      
                                      // Campo de contraseña
                                      _buildGlassTextField(
                                        controller: _passwordController,
                                        label: 'Contraseña',
                                        icon: Icons.lock_rounded,
                                        obscureText: _obscurePassword,
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscurePassword
                                                ? Icons.visibility_rounded
                                                : Icons.visibility_off_rounded,
                                            color: AppColors.softWhite.withOpacity(0.7),
                                            size: 22,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _obscurePassword = !_obscurePassword;
                                            });
                                          },
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Por favor ingresa tu contraseña';
                                          }
                                          if (value.length < 6) {
                                            return 'Mínimo 6 caracteres';
                                          }
                                          return null;
                                        },
                                      )
                                          .animate()
                                          .fadeIn(delay: 600.ms, duration: 600.ms)
                                          .slideX(begin: -0.3, end: 0, curve: Curves.easeOut),
                                      
                                      const SizedBox(height: 16),
                                      
                                      // Campo de confirmar contraseña
                                      _buildGlassTextField(
                                        controller: _confirmPasswordController,
                                        label: 'Confirmar Contraseña',
                                        icon: Icons.lock_outline_rounded,
                                        obscureText: _obscureConfirmPassword,
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscureConfirmPassword
                                                ? Icons.visibility_rounded
                                                : Icons.visibility_off_rounded,
                                            color: AppColors.softWhite.withOpacity(0.7),
                                            size: 22,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _obscureConfirmPassword = !_obscureConfirmPassword;
                                            });
                                          },
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Por favor confirma tu contraseña';
                                          }
                                          if (value != _passwordController.text) {
                                            return 'Las contraseñas no coinciden';
                                          }
                                          return null;
                                        },
                                      )
                                          .animate()
                                          .fadeIn(delay: 700.ms, duration: 600.ms)
                                          .slideX(begin: -0.3, end: 0, curve: Curves.easeOut),
                                      
                                      const SizedBox(height: 32),
                                      
                                      // Botón de registro mejorado
                                      _buildGlassButton(
                                        text: 'Registrarse',
                                        onPressed: isLoading ? null : _handleRegister,
                                        isLoading: isLoading,
                                      )
                                          .animate()
                                          .fadeIn(delay: 800.ms, duration: 600.ms)
                                          .scale(delay: 800.ms, duration: 400.ms, curve: Curves.easeOut),
                                      
                                      const SizedBox(height: 24),
                                      
                                      // Divider decorativo
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Divider(
                                              color: AppColors.softWhite.withOpacity(0.3),
                                              thickness: 0.5,
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 16),
                                            child: Text(
                                              'o',
                                              style: TextStyle(
                                                color: AppColors.softWhite.withOpacity(0.6),
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: Divider(
                                              color: AppColors.softWhite.withOpacity(0.3),
                                              thickness: 0.5,
                                            ),
                                          ),
                                        ],
                                      ).animate().fadeIn(delay: 900.ms),
                                      
                                      const SizedBox(height: 24),
                                      
                                      // Enlace a login
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            '¿Ya tienes cuenta? ',
                                            style: TextStyle(
                                              color: AppColors.softWhite.withOpacity(0.8),
                                              fontSize: 15,
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () => context.go('/login'),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(8),
                                                gradient: LinearGradient(
                                                  colors: [
                                                    AppColors.primaryRed.withOpacity(0.2),
                                                    Colors.orange.withOpacity(0.2),
                                                  ],
                                                ),
                                              ),
                                              child: Text(
                                                'Inicia Sesión',
                                                style: TextStyle(
                                                  color: AppColors.primaryRed,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      )
                                          .animate()
                                          .fadeIn(delay: 1000.ms, duration: 600.ms)
                                          .slideY(begin: 0.3, end: 0),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )
                            .animate()
                            .fadeIn(delay: 150.ms, duration: 800.ms)
                            .scale(
                              delay: 150.ms,
                              duration: 800.ms,
                              begin: const Offset(0.8, 0.8),
                              end: const Offset(1.0, 1.0), // ✅ CORRECCIÓN: Agregado el parámetro 'end'
                              curve: Curves.easeOut,
                            ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Widget personalizado para campos de texto con efecto glass
  Widget _buildGlassTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscureText,
            validator: validator,
            style: TextStyle(
              color: AppColors.softWhite,
              fontSize: 16,
            ),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(
                color: AppColors.softWhite.withOpacity(0.7),
                fontSize: 14,
              ),
              prefixIcon: Icon(
                icon,
                color: AppColors.primaryRed.withOpacity(0.8),
                size: 22,
              ),
              suffixIcon: suffixIcon,
              filled: true,
              fillColor: Colors.transparent,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: AppColors.primaryRed.withOpacity(0.5),
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: AppColors.errorRed.withOpacity(0.5),
                  width: 1.5,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: AppColors.errorRed,
                  width: 2,
                ),
              ),
              errorStyle: TextStyle(
                color: AppColors.errorRed.withOpacity(0.9),
                fontSize: 12,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 18,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Botón personalizado con efecto glass
  Widget _buildGlassButton({
    required String text,
    required VoidCallback? onPressed,
    bool isLoading = false,
  }) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: onPressed == null
              ? [
                  Colors.grey.withOpacity(0.5),
                  Colors.grey.withOpacity(0.3),
                ]
              : [
                  AppColors.primaryRed,
                  Colors.orange,
                ],
        ),
        boxShadow: onPressed == null
            ? []
            : [
                BoxShadow(
                  color: AppColors.primaryRed.withOpacity(0.5),
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: isLoading
                ? SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.softWhite,
                      ),
                    ),
                  )
                : Text(
                    text,
                    style: TextStyle(
                      color: AppColors.pureWhite,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
