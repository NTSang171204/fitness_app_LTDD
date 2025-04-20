import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserInfoFormScreen extends StatefulWidget {
  @override
  _UserInfoFormScreenState createState() => _UserInfoFormScreenState();
}

class _UserInfoFormScreenState extends State<UserInfoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  String name = '';
  String phone = '';
  String email = '';
  String gender = 'Male';
  double weight = 0;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      email = user.email ?? '';
    }
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final userDoc =
              FirebaseFirestore.instance.collection('users').doc(user.uid);

          await userDoc.set({
            'name': name.trim(),
            'phone': phone.trim(),
            'email': email,
            'gender': gender,
            'weight': weight,
          }, SetOptions(merge: true));

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lưu thông tin thành công!')),
          );

          Navigator.pushReplacementNamed(context, '/dailySteps');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi lưu thông tin: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Nhập thông tin cá nhân')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'Họ tên'),
                onSaved: (val) => name = val ?? '',
                validator: (val) =>
                    val == null || val.isEmpty ? 'Vui lòng nhập tên' : null,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Số điện thoại'),
                keyboardType: TextInputType.phone,
                onSaved: (val) => phone = val ?? '',
                validator: (val) =>
                    val == null || val.length < 9 ? 'Số điện thoại không hợp lệ' : null,
              ),
              TextFormField(
                initialValue: email,
                decoration: InputDecoration(labelText: 'Email'),
                enabled: false,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Cân nặng (kg)'),
                keyboardType: TextInputType.number,
                onSaved: (val) =>
                    weight = double.tryParse(val ?? '0') ?? 0,
                validator: (val) {
                  final w = double.tryParse(val ?? '');
                  if (w == null || w <= 0) return 'Nhập cân nặng hợp lệ';
                  return null;
                },
              ),
              DropdownButtonFormField<String>(
                value: gender,
                decoration: InputDecoration(labelText: 'Giới tính'),
                items: ['Male', 'Female', 'Other']
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (val) => setState(() => gender = val ?? 'Male'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submit,
                child: Text('Lưu'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: Colors.blue,
                  textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
