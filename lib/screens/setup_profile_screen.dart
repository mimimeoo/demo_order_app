import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_colors.dart';

class SetupProfileScreen extends StatefulWidget {
  final String phoneNumber;
  const SetupProfileScreen({super.key, required this.phoneNumber});

  @override
  State<SetupProfileScreen> createState() => _SetupProfileScreenState();
}

class _SetupProfileScreenState extends State<SetupProfileScreen> {
  // Constants
  final Color _primaryColor = AppColors.primaryBright;
  
  // Controllers
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailController = TextEditingController();
  final _dobController = TextEditingController();

  // State
  String _gender = 'Chị';
  bool _isObscure = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  // Hàm chọn ngày sinh
  Future<void> _selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2004),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(primary: _primaryColor),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _dobController.text = "${picked.day}/${picked.month}/${picked.year}");
    }
  }

  // Logic gửi dữ liệu
  Future<void> _submitData() async {
    final name = _nameController.text.trim();
    final pass = _passwordController.text.trim();
    final email = _emailController.text.trim();
    final dob = _dobController.text.trim();

    if (name.isEmpty || pass.isEmpty || email.isEmpty || dob.isEmpty) {
      _showSnackBar("Vui lòng điền đủ thông tin nhé!");
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.phoneNumber)
          .update({
            'displayName': name,
            'email': email,
            'password': pass,
            'gender': _gender,
            'dateOfBirth': dob,
            'isProfileComplete': true,
          });

      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      _showSnackBar("Lỗi: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message),        backgroundColor: Colors.red,
));
    
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Container(
              transform: Matrix4.translationValues(0, -20, 0),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Chào mừng, hãy cho BrewGo biết thêm về bạn nhé",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 25),
                    _buildGenderSelector(),
                    const SizedBox(height: 20),
                    _buildInput("Tên của bạn", _nameController, isRequired: true),
                    _buildInput("Tạo mật khẩu", _passwordController, isRequired: true, isPassword: true),
                    
                    // Ô Ngày sinh có thể bấm để chọn lịch
                    GestureDetector(
                      onTap: _selectDate,
                      child: AbsorbPointer(
                        child: _buildInput("Ngày sinh", _dobController, isRequired: true, hint: "Chọn ngày sinh"),
                      ),
                    ),
                    
                    _buildInput("Email", _emailController, isRequired: true),
                    const SizedBox(height: 30),
                    _buildSubmitButton(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage("assets/images/sukien.jpg"),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildGenderSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Xưng hô", style: TextStyle(color: Colors.grey)),
        Row(
          children: ['Anh', 'Chị'].map((val) => Row(
            children: [
              Radio<String>(
                value: val,
                groupValue: _gender,
                activeColor: _primaryColor,
                onChanged: (v) => setState(() => _gender = v!),
              ),
              Text(val),
              const SizedBox(width: 20),
            ],
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitData,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBright,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _isLoading 
          ? const CircularProgressIndicator(color: Colors.white)
          : const Text("TIẾP TỤC", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildInput(String label, TextEditingController controller, {String? hint, bool isRequired = false, bool isPassword = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              text: label,
              style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w500, fontSize: 14),
              children: [ if (isRequired) const TextSpan(text: " (*)", style: TextStyle(color: Colors.red)) ],
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            obscureText: isPassword ? _isObscure : false,
            decoration: InputDecoration(
              hintText: hint,
              suffixIcon: isPassword ? IconButton(
                icon: Icon(_isObscure ? Icons.visibility_off : Icons.visibility, size: 20),
                onPressed: () => setState(() => _isObscure = !_isObscure),
              ) : null,
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _primaryColor, width: 1.5)),
            ),
          ),
        ],
      ),
    );
  }
}