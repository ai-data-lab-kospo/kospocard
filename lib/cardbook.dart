import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:qr_flutter/qr_flutter.dart'; // QR 생성을 위해 반드시 필요
import 'package:share_plus/share_plus.dart'; // 텍스트 공유를 위해 반드시 필요
import 'models.dart';

class CardBookListView extends StatelessWidget {
  final List<BusinessCard> savedCards;
  final bool isSelectionMode;
  final Set<int> selectedIndices;
  final Function(int) onToggleSelection;
  final Function(int) onLongPress;
  final Function(BusinessCard) onShowDetail;
  final Function(String) onSearch;
  final Function(BusinessCard) onSaveContact;
  final String currentSearchQuery;
  final Color navyColor;
  final TextEditingController? searchController; // 추가: 외부에서 컨트롤러를 주입받음

  const CardBookListView({
    super.key,
    required this.savedCards,
    required this.isSelectionMode,
    required this.selectedIndices,
    required this.onToggleSelection,
    required this.onLongPress,
    required this.onShowDetail,
    required this.onSearch,
    required this.onSaveContact,
    required this.currentSearchQuery,
    required this.navyColor,
    this.searchController, // 추가
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 15, 16, 5),
          child: TextField(
            onChanged: onSearch,
            // 수정: 외부에서 전달받은 searchController를 우선 사용
            controller: searchController ?? (TextEditingController(text: currentSearchQuery)
              ..selection = TextSelection.fromPosition(
                  TextPosition(offset: currentSearchQuery.length))),
            decoration: InputDecoration(
              hintText: "이름, 회사명, 전화번호 등 검색",
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: currentSearchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        searchController?.clear(); // 컨트롤러가 있으면 비우기
                        onSearch('');
                      })
                  : null,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: navyColor, width: 1.5),
              ),
            ),
          ),
        ),
        Expanded(
          child: savedCards.isEmpty
              ? const Center(child: Text("검색 결과가 없거나 저장된 명함이 없습니다."))
              : ListView.builder(
                  key: const PageStorageKey('card_list_scroll_key'), // 추가: 스크롤 정보 유지를 위한 키
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 130),
                  itemCount: savedCards.length,
                  itemBuilder: (context, i) {
                    final isSelected = selectedIndices.contains(i);
                    final card = savedCards[i];

                    return GestureDetector(
                      onLongPress: () => onLongPress(i),
                      onTap: () {
                        if (isSelectionMode) {
                          onToggleSelection(i);
                        } else {
                          onShowDetail(card);
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.indigo.shade50
                              : Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          border: isSelected
                              ? Border.all(color: navyColor, width: 1.5)
                              : null,
                          boxShadow: [
                            if (!isSelected)
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 5)
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            leading: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: File(card.imagePath).existsSync()
                                      ? Image.file(File(card.imagePath),
                                          width: 75,
                                          height: 50,
                                          fit: BoxFit.cover)
                                      : const Icon(Icons.broken_image),
                                ),
                                if (isSelected)
                                  Positioned.fill(
                                    child: Container(
                                      decoration: BoxDecoration(
                                          color: navyColor.withOpacity(0.3),
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                      child: const Icon(Icons.check,
                                          color: Colors.white, size: 20),
                                    ),
                                  ),
                              ],
                            ),
                            title: Text(card.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (card.position.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(card.position,
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade700,
                                          fontWeight: FontWeight.w500)),
                                ],
                                const SizedBox(height: 4),
                                Text(card.korCo,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 13)),
                                Text(card.phone,
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600)),
                              ],
                            ),
                            trailing: isSelectionMode
                                ? Checkbox(
                                    value: isSelected,
                                    activeColor: navyColor,
                                    onChanged: (val) => onToggleSelection(i))
                                : IconButton(
                                    icon: Icon(Icons.person_add_alt_1_rounded,
                                        color: navyColor, size: 32),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text("연락처 등록"),
                                          content: Text(
                                              "${card.name} 님을 연락처에 등록하시겠습니까?"),
                                          actions: [
                                            TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(ctx),
                                                child: const Text("취소",
                                                    style: TextStyle(
                                                        color: Colors.grey))),
                                            TextButton(
                                                onPressed: () {
                                                  Navigator.pop(ctx);
                                                  onSaveContact(card);
                                                },
                                                child: Text("등록",
                                                    style: TextStyle(
                                                        color: navyColor,
                                                        fontWeight:
                                                            FontWeight.bold))),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class CardDetailView extends StatelessWidget {
  final BusinessCard card;
  final VoidCallback onBack;
  final VoidCallback onEdit;
  final Color navyColor;

  const CardDetailView({
    super.key,
    required this.card,
    required this.onBack,
    required this.onEdit,
    required this.navyColor,
  });

  // vCard 생성 로직 (아이폰 인식 최적화 포함)
  String _generateVCard() {
    return "BEGIN:VCARD\n"
        "VERSION:3.0\n"
        "N:;${card.name};;;\n"
        "FN:${card.name}\n"
        "ORG:${card.korCo}\n"
        "TITLE:${card.position}\n"
        "TEL;TYPE=CELL,VOICE:${card.phone}\n"
        "EMAIL;TYPE=WORK,INTERNET:${card.email}\n"
        "ADR;TYPE=WORK:;;${card.addr}\n"
        "END:VCARD";
  }

  // 공유 옵션 선택창 (바텀 시트)
  void _showShareOptions(BuildContext context) {
    final vCardData = _generateVCard();
    final plainText =
        "[명함 정보]\n이름: ${card.name}\n직위: ${card.position}\n회사: ${card.korCo}\n전화: ${card.phone}\n이메일: ${card.email}\n주소: ${card.addr}";

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text("명함 공유하기",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            ListTile(
              leading: const Icon(Icons.qr_code_2, color: Colors.black87),
              title: const Text("QR 코드로 공유"),
              subtitle: const Text("상대방 카메라로 연락처 바로 저장"),
              onTap: () {
                Navigator.pop(ctx);
                _showQRCodeDialog(context, vCardData);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share, color: Colors.black87),
              title: const Text("텍스트 정보 전달"),
              subtitle: const Text("카톡 등으로 텍스트 정보 보내기"),
              onTap: () {
                Navigator.pop(ctx);
                Share.share(plainText);
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  // QR 코드 팝업 다이얼로그
  void _showQRCodeDialog(BuildContext context, String qrData) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("${card.name}님의 명함 QR"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("상대방이 카메라로 스캔하면\n연락처를 저장할 수 있습니다.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 25),
            Center(
              child: SizedBox(
                width: 200,
                height: 200,
                child: QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 200.0,
                  gapless: false,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("닫기"))
        ],
      ),
    );
  }

  // URL 실행 공통 함수
  Future<void> _launchURL(
      BuildContext context, String urlString, String errorMessage) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(errorMessage)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("명함 상세 정보",
            style: TextStyle(fontWeight: FontWeight.bold)),
        leading:
            IconButton(icon: const Icon(Icons.arrow_back), onPressed: onBack),
        backgroundColor: navyColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: '공유하기',
            onPressed: () => _showShareOptions(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: File(card.imagePath).existsSync()
                      ? Image.file(File(card.imagePath),
                          width: double.infinity, fit: BoxFit.contain)
                      : Container(
                          height: 200,
                          color: Colors.grey[200],
                          child: const Icon(Icons.broken_image)),
                ),
              ),
            ),
            const SizedBox(height: 30),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05), blurRadius: 15)
                ],
              ),
              child: Column(
                children: [
                  _detailRow(Icons.person, "성명", card.name),
                  _detailRow(Icons.badge_outlined, "직위", card.position),
                  _detailRow(
                    Icons.phone_android,
                    "연락처",
                    card.phone,
                    actionIcon: Icons.call,
                    onAction: () => _launchURL(
                        context,
                        "tel:${card.phone.replaceAll(RegExp(r'[^0-9]'), '')}",
                        "전화를 걸 수 없습니다."),
                  ),
                  _detailRow(
                    Icons.email_outlined,
                    "이메일",
                    card.email,
                    actionIcon: Icons.mail_outline,
                    onAction: () => _launchURL(context, "mailto:${card.email}",
                        "메일 앱을 열 수 없습니다."),
                  ),
                  _detailRow(Icons.business, "회사명", card.korCo),
                  _detailRow(Icons.location_on_outlined, "주소", card.addr),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(30.0),
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit, color: Colors.white),
                  label: const Text("정보 수정하기",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: navyColor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15))),
                ),
              ),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value,
          {IconData? actionIcon, VoidCallback? onAction}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: navyColor),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 4),
                  Text(value,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600, height: 1.3)),
                ],
              ),
            ),
            if (actionIcon != null && value.trim().isNotEmpty)
              IconButton(
                icon: Icon(actionIcon,
                    color: navyColor.withOpacity(0.8), size: 24),
                onPressed: onAction,
              ),
          ],
        ),
      );
}