import 'package:flutter/material.dart';

class PolicyScreen extends StatelessWidget {
  const PolicyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chính sách & Quyền riêng tư'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              
              Text(
                '1. Thu thập thông tin',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              
              SizedBox(height: 8),
              
              Text(
                'Ứng dụng có thể thu thập một số thông tin cơ bản như dữ liệu hoạt động đi bộ, vị trí và các cài đặt người dùng nhằm nâng cao trải nghiệm.',
              ),
              
              SizedBox(height: 16),
              Text(
                '2. Sử dụng thông tin',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              SizedBox(height: 8),
              Text(
                'Thông tin được thu thập chỉ được sử dụng để cung cấp và cải thiện dịch vụ, không chia sẻ cho bên thứ ba.',
              ),
              SizedBox(height: 16),
              Text(
                '3. Bảo mật',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              SizedBox(height: 8),
              Text(
                'Chúng tôi cam kết bảo mật dữ liệu của bạn và không lưu trữ thông tin cá nhân nhạy cảm nếu không được phép.',
              ),
              SizedBox(height: 16),
              Text(
                '4. Thay đổi chính sách',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              SizedBox(height: 8),
              Text(
                'Chính sách có thể được cập nhật. Người dùng nên kiểm tra thường xuyên để nắm rõ thông tin mới nhất.',
              ),
              SizedBox(height: 16),
              Text(
                '5. Liên hệ',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              SizedBox(height: 8),
              Text(
                'Nếu bạn có bất kỳ câu hỏi nào, vui lòng liên hệ qua email: support@walkingapp.com',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
