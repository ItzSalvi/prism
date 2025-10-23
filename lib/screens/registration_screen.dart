import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/firebase_service.dart';

class RegistrationScreen extends StatefulWidget {
  final bool isGoogleSignIn;
  final String? googleEmail;
  final String? googleName;
  final String? password;
  
  const RegistrationScreen({
    super.key,
    this.isGoogleSignIn = false,
    this.googleEmail,
    this.googleName,
    this.password,
  });

  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emergencyContactController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  final _physicianController = TextEditingController();
  
  DateTime? _selectedBirthDate;
  int? _calculatedAge;
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _error;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    // Pre-fill email and name if from Google sign-in
    if (widget.isGoogleSignIn) {
      _emailController.text = widget.googleEmail ?? '';
      if (widget.googleName != null) {
        List<String> nameParts = widget.googleName!.split(' ');
        _firstNameController.text = nameParts.isNotEmpty ? nameParts[0] : '';
        if (nameParts.length > 1) {
          _lastNameController.text = nameParts.sublist(1).join(' ');
        }
      }
    } else {
      // Pre-fill email and password if from sign-up
      _emailController.text = widget.googleEmail ?? '';
      _passwordController.text = widget.password ?? '';
      if (widget.googleName != null) {
        List<String> nameParts = widget.googleName!.split(' ');
        _firstNameController.text = nameParts.isNotEmpty ? nameParts[0] : '';
        if (nameParts.length > 1) {
          _lastNameController.text = nameParts.sublist(1).join(' ');
        }
      }
    }

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    _slideAnimation = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _emergencyContactController.dispose();
    _emergencyPhoneController.dispose();
    _physicianController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _calculateAge() {
    if (_selectedBirthDate != null) {
      DateTime now = DateTime.now();
      int age = now.year - _selectedBirthDate!.year;
      if (now.month < _selectedBirthDate!.month || 
          (now.month == _selectedBirthDate!.month && now.day < _selectedBirthDate!.day)) {
        age--;
      }
      setState(() {
        _calculatedAge = age;
      });
    }
  }

  bool _validateForm() {
    // For Google sign-in users, all fields except physician are required
    if (widget.isGoogleSignIn) {
      if (_firstNameController.text.trim().isEmpty) {
        setState(() {
          _error = 'First name is required';
        });
        return false;
      }
      if (_lastNameController.text.trim().isEmpty) {
        setState(() {
          _error = 'Last name is required';
        });
        return false;
      }
      if (_phoneController.text.trim().isEmpty) {
        setState(() {
          _error = 'Phone number is required';
        });
        return false;
      }
      if (_selectedBirthDate == null) {
        setState(() {
          _error = 'Birth date is required';
        });
        return false;
      }
      if (_emergencyContactController.text.trim().isEmpty) {
        setState(() {
          _error = 'Emergency contact is required';
        });
        return false;
      }
      if (_emergencyPhoneController.text.trim().isEmpty) {
        setState(() {
          _error = 'Emergency contact phone is required';
        });
        return false;
      }
    } else {
      // For sign-up users, check password and use standard form validation
      if (_passwordController.text.trim().isEmpty) {
        setState(() {
          _error = 'Password is required';
        });
        return false;
      }
      if (_passwordController.text.trim().length < 6) {
        setState(() {
          _error = 'Password must be at least 6 characters';
        });
        return false;
      }
      if (!_formKey.currentState!.validate()) return false;
    }
    
    return true;
  }

  Future<void> _selectBirthDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1990),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Color(0xFFDC2626),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF1F2937),
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _selectedBirthDate) {
      setState(() {
        _selectedBirthDate = picked;
      });
      _calculateAge();
    }
  }

  Future<void> _submitRegistration() async {
    if (!_validateForm()) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final firebaseService = FirebaseService();
      
      String userId;
      
      if (widget.isGoogleSignIn) {
        // User is already signed in with Google, just need to complete profile
        userId = authProvider.user!.uid;
      } else {
        // Create new account with email/password
        await authProvider.signUpWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text.trim(),
          '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
        );
        userId = authProvider.user!.uid;
      }
      
      // Store extended user profile
      await firebaseService.storeExtendedUserProfile(
        userId: userId,
        firstName: _firstNameController.text.trim(),
        middleName: _middleNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        birthDate: _selectedBirthDate!,
        age: _calculatedAge!,
        emergencyContact: _emergencyContactController.text.trim(),
        emergencyPhone: _emergencyPhoneController.text.trim(),
        physician: _physicianController.text.trim().isNotEmpty ? _physicianController.text.trim() : null,
      );
      
      // Update profile completion status
      await authProvider.markProfileComplete();
      
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFEF7F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Registration Form',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1F2937),
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Color(0xFFDC2626)),
          onPressed: () {
            if (widget.isGoogleSignIn) {
              // If user came from Google sign-in, sign them out to return to login
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              authProvider.signOutAndReturnToLogin();
            } else {
              // If user came from sign-up form, just go back
              Navigator.of(context).pop();
            }
          },
        ),
      ),
      body: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _slideAnimation.value),
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      _buildHeader(),
                      SizedBox(height: 32),
                      
                      // Error Message
                      if (_error != null) _buildErrorMessage(),
                      
                      // Personal Information Section
                      _buildSectionHeader('Personal Information', Icons.person_outline_rounded),
                      SizedBox(height: 16),
                      
                      // Name Fields
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _firstNameController,
                              label: 'First Name',
                              validator: (value) {
                                if (!widget.isGoogleSignIn && (value == null || value.isEmpty)) {
                                  return 'Required';
                                }
                                return null;
                              },
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: _buildTextField(
                              controller: _middleNameController,
                              label: 'Middle Name',
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      _buildTextField(
                        controller: _lastNameController,
                        label: 'Last Name',
                        validator: (value) {
                          if (!widget.isGoogleSignIn && (value == null || value.isEmpty)) {
                            return 'Required';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      
                      // Birth Date and Age
                      _buildBirthDateField(),
                      SizedBox(height: 16),
                      
                      // Contact Information Section
                      _buildSectionHeader('Contact Information', Icons.contact_phone_outlined),
                      SizedBox(height: 16),
                      
                      // Email (disabled for Google sign-in)
                      _buildTextField(
                        controller: _emailController,
                        label: 'Email Address',
                        enabled: !widget.isGoogleSignIn,
                        validator: (value) {
                          if (!widget.isGoogleSignIn && (value == null || value.isEmpty)) {
                            return 'Required';
                          }
                          if (!widget.isGoogleSignIn && !value!.contains('@')) {
                            return 'Invalid email';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      
                      // Password (only for email/password sign-up)
                      if (!widget.isGoogleSignIn) ...[
                        _buildPasswordField(),
                        SizedBox(height: 16),
                      ],
                      
                      // Phone Number
                      _buildTextField(
                        controller: _phoneController,
                        label: 'Phone Number',
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (!widget.isGoogleSignIn && (value == null || value.isEmpty)) {
                            return 'Required';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 24),
                      
                      // Emergency Contact Section
                      _buildSectionHeader('Emergency Contact', Icons.emergency_outlined),
                      SizedBox(height: 16),
                      
                      _buildTextField(
                        controller: _emergencyContactController,
                        label: 'Emergency Contact Name',
                        validator: (value) {
                          if (!widget.isGoogleSignIn && (value == null || value.isEmpty)) {
                            return 'Required';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      _buildTextField(
                        controller: _emergencyPhoneController,
                        label: 'Emergency Contact Phone',
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (!widget.isGoogleSignIn && (value == null || value.isEmpty)) {
                            return 'Required';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 24),
                      
                      // Physician Section (Optional)
                      _buildSectionHeader('Physician Information (Optional)', Icons.medical_services_outlined),
                      SizedBox(height: 16),
                      
                      _buildTextField(
                        controller: _physicianController,
                        label: 'Physician Name',
                      ),
                      SizedBox(height: 32),
                      
                      // Submit Button
                      _buildSubmitButton(),
                      SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFEE2E2), Color(0xFFFEF2F2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Color(0xFFDC2626),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.health_and_safety_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Complete Your Health Profile',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Help us personalize your health monitoring experience',
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              _error!,
              style: TextStyle(
                color: Color(0xFF991B1B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Color(0xFFFEE2E2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Color(0xFFDC2626), size: 20),
        ),
        SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1F2937),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool enabled = true,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(
        color: enabled ? Color(0xFF1F2937) : Color(0xFF9CA3AF),
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Color(0xFF6B7280),
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: enabled ? Colors.white : Color(0xFFF9FAFB),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFFDC2626), width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      validator: (value) {
        if (!widget.isGoogleSignIn && (value == null || value.isEmpty)) {
          return 'Required';
        }
        if (!widget.isGoogleSignIn && value!.length < 6) {
          return 'Must be at least 6 characters';
        }
        return null;
      },
      style: TextStyle(
        color: Color(0xFF1F2937),
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        labelText: 'Password',
        labelStyle: TextStyle(
          color: Color(0xFF6B7280),
          fontWeight: FontWeight.w500,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
            color: Color(0xFF9CA3AF),
          ),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFFDC2626), width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildBirthDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Birth Date',
          style: TextStyle(
            color: Color(0xFF6B7280),
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        SizedBox(height: 8),
        InkWell(
          onTap: _selectBirthDate,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: Color(0xFFDC2626), size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedBirthDate != null
                        ? '${_selectedBirthDate!.day}/${_selectedBirthDate!.month}/${_selectedBirthDate!.year}'
                        : 'Select your birth date',
                    style: TextStyle(
                      color: _selectedBirthDate != null ? Color(0xFF1F2937) : Color(0xFF9CA3AF),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (_calculatedAge != null) ...[
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Age: $_calculatedAge',
                      style: TextStyle(
                        color: Color(0xFFDC2626),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (_selectedBirthDate == null && !widget.isGoogleSignIn)
          Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text(
              'Required',
              style: TextStyle(
                color: Color(0xFFDC2626),
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Color(0xFFEF4444).withOpacity(0.3),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitRegistration,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Creating Profile...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Complete Registration',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
