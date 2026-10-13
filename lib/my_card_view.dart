import 'dart:io';
import 'package:flutter/material.dart';

class MyCardView extends StatelessWidget {
  final Map<String, String>? myInfo;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onShare;
  final Color navyColor;

  const MyCardView({
    super.key,
    required this.myInfo,
    required this.onEdit,
    required this.onDelete,
    required this.onShare,
    required this.navyColor,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 120),
      child: Column(
        children: [
          const SizedBox(height: 15),
          if (myInfo == null) ...[
            Center(
              child: Column(
                children: [
                  const SizedBox(height: 60),
                  Icon(Icons.contact_page_outlined, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 20),
                  const Text("사용자 정보를 입력해주세요.",
                      style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: 200,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text("정보 등록하기", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: navyColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: onShare,
                    icon: const Icon(Icons.qr_code_scanner, size: 18),
                    label: const Text("명함 공유", style: TextStyle(fontWeight: FontWeight.bold)),
                    style: TextButton.styleFrom(
                      foregroundColor: navyColor,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      backgroundColor: navyColor.withOpacity(0.08),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(25),
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15)],
              ),
              child: Column(
                children: [
                  if (myInfo!['imagePath'] != null && myInfo!['imagePath']!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.file(File(myInfo!['imagePath']!), height: 180, width: double.infinity, fit: BoxFit.cover),
                      ),
                    )
                  else
                    CircleAvatar(
                        radius: 50,
                        backgroundColor: const Color(0xFFE8EAF6),
                        child: Icon(Icons.person, size: 50, color: navyColor)),
                  const SizedBox(height: 10),
                  Text(myInfo!['name']!, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                  if (myInfo!['job'] != null && myInfo!['job']!.isNotEmpty)
                    Text(myInfo!['job']!, style: const TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text(myInfo!['company']!, style: TextStyle(color: navyColor, fontWeight: FontWeight.bold)),
                  const Divider(height: 40),
                  _myInfoRow(Icons.phone_iphone, myInfo!['phone']!),
                  _myInfoRow(Icons.email_outlined, myInfo!['email']!),
                  _myInfoRow(Icons.location_on_outlined, myInfo!['address']!),
                  const SizedBox(height: 25),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text("정보 수정"),
                        style: OutlinedButton.styleFrom(
                            foregroundColor: navyColor,
                            side: BorderSide(color: navyColor),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                        label: const Text("삭제", style: TextStyle(color: Colors.red)),
                        style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _myInfoRow(IconData icon, String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 16, color: const Color(0xFFADB5BD)),
          const SizedBox(width: 10),
          Flexible(child: Text(text, style: const TextStyle(fontSize: 14), overflow: TextOverflow.ellipsis))
        ]),
      );
}