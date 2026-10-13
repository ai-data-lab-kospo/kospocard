import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'models.dart';
import 'ocr_engine.dart';
import 'database_helper.dart';
import 'cardbook.dart';
import 'my_card_view.dart';
import 'backup_service.dart'; // 백업 서비스 임포트

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
    systemNavigationBarDividerColor: Colors.transparent,
  ));

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  runApp(const KCardAppRoot());
}

class KCardAppRoot extends StatelessWidget {
  const KCardAppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    const Color navyColor = Color(0xFF1A237E);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'K-Card Scanner',
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ko', 'KR'), // 한국어 지원
        Locale('en', 'US'), // 영어 지원 (필요시)
      ],
      locale: const Locale('ko', 'KR'), // 기본 언어를 한국어로 설정
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: navyColor, 
          primary: navyColor, 
          surface: Colors.white,
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        inputDecorationTheme: const InputDecorationTheme(
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          border: OutlineInputBorder(),
          focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: navyColor, width: 2)),
        ),
      ),
      home: const KCardApp(),
    );
  }
}

class KCardApp extends StatefulWidget {
  const KCardApp({super.key});
  @override
  State<KCardApp> createState() => _KCardAppState();
}

enum SourceType { camera, gallery }

class _KCardAppState extends State<KCardApp> with SingleTickerProviderStateMixin {
  int _viewMode = 0; 
  bool _isProcessing = false;
  List<BusinessCard> _allCards = [];      
  List<BusinessCard> _filteredCards = []; 
  String _searchQuery = ""; 
  BusinessCard? _selectedCard;
  late TabController _tabController;
  bool _isSelectionMode = false;
  final Set<int> _selectedIndices = {};
  
  Map<String, String>? myInfo; 
  Map<String, List<String>> _options = {'name': [], 'position': [], 'phone': [], 'email': [], 'korCo': [], 'addr': []};
  String? _tempImagePath;
  int? _editingId; 
  
  final _dbHelper = DatabaseHelper();
  final _picker = ImagePicker();
  final Color navyColor = const Color(0xFF1A237E);

  final _nameCtrl = TextEditingController();
  final _posCtrl = TextEditingController(); 
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _korCoCtrl = TextEditingController();
  final _addrCtrl = TextEditingController();
  
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData(); 
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameCtrl.dispose(); _posCtrl.dispose(); _phoneCtrl.dispose(); _emailCtrl.dispose(); _korCoCtrl.dispose(); _addrCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleBackup() async {
    try {
      String savedPath = await BackupService.saveToExcel();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('엑셀 백업 완료: 다운로드 폴더에 저장되었습니다.\n($savedPath)'),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 4),
          )
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('백업 실패: $e'), backgroundColor: Colors.red)
        );
      }
    }
  }

  Future<void> _handleRestore() async {
    try {
      final result = await BackupService.restoreFromExcel();
      if (result['added']! > 0 || result['skipped']! > 0) {
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${result['added']}개 추가됨, ${result['skipped']}개 중복 제외됨'),
              backgroundColor: Colors.green,
            )
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('복구 실패: $e'), backgroundColor: Colors.red)
        );
      }
    }
  }

  Future<void> _loadData() async {
    final cards = await _dbHelper.getCards();
    final savedMyInfo = await _dbHelper.getMyInfo();
    setState(() {
      _allCards = cards;
      myInfo = savedMyInfo; 
      _applyFilter(_searchQuery);
    });
  }
  void _applyFilter(String query) {
    setState(() {
      _searchQuery = query;
      if (_searchQuery.trim().isEmpty) {
        _filteredCards = _allCards;
      } else {
        final lowerQuery = _searchQuery.toLowerCase();
        final cleanQuery = _searchQuery.replaceAll(RegExp(r'[^0-9]'), '');
        _filteredCards = _allCards.where((card) {
          final nameMatch = card.name.toLowerCase().contains(lowerQuery);
          final companyMatch = card.korCo.toLowerCase().contains(lowerQuery);
          final phoneMatch = card.phone.toLowerCase().contains(lowerQuery) ||
              (cleanQuery.isNotEmpty &&
                  card.phone.replaceAll(RegExp(r'[^0-9]'), '').contains(cleanQuery));
          return nameMatch || companyMatch || phoneMatch;
        }).toList();
      }
      _isSelectionMode = false;
      _selectedIndices.clear();
    });
  }

  Future<void> _deleteSelectedCards() async {
    List<int> idsToDelete = _selectedIndices
        .map((index) => _filteredCards[index].id)
        .whereType<int>()
        .toList();
    if (idsToDelete.isNotEmpty) {
      await _dbHelper.deleteCards(idsToDelete);
      await _loadData(); 
    }
  }

  void _toggleSelection(int index) {
    setState(() {
      if (_selectedIndices.contains(index)) {
        _selectedIndices.remove(index);
        if (_selectedIndices.isEmpty) _isSelectionMode = false;
      } else {
        _selectedIndices.add(index);
      }
    });
  }

  Future<void> _saveToDeviceContacts(BusinessCard card) async {
    if (await FlutterContacts.requestPermission()) {
      final newContact = Contact()
        ..name.first = card.name
        ..phones = [Phone(card.phone)]
        ..emails = card.email.isNotEmpty ? [Email(card.email)] : []
        ..organizations = card.korCo.isNotEmpty 
            ? [Organization(company: card.korCo, title: card.position)] 
            : []
        ..addresses = card.addr.isNotEmpty ? [Address(card.addr)] : [];

      try {
        await FlutterContacts.openExternalInsert(newContact);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('연락처 저장 화면이 실행되었습니다.'), backgroundColor: Colors.blue)
          );
        }
      } catch (e) {
        try {
          await FlutterContacts.insertContact(newContact);
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('연락처에 바로 저장되었습니다.'), backgroundColor: Colors.green));
        } catch (e2) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('연락처 저장에 실패했습니다.'), backgroundColor: Colors.red));
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('연락처 접근 권한이 거부되었습니다.'), backgroundColor: Colors.red)
        );
      }
    }
  }

  Future<String?> _cropImageAction(String path) async {
    CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: '명함 영역 조정', 
          toolbarColor: navyColor, 
          toolbarWidgetColor: Colors.white, 
          initAspectRatio: CropAspectRatioPreset.ratio3x2, 
          lockAspectRatio: false,
          hideBottomControls: false,
          backgroundColor: Colors.black,
        ),
        IOSUiSettings(title: '명함 영역 조정'),
      ],
    );
    return croppedFile?.path;
  }

  Future<void> _processImageForBook(String path) async {
    final croppedPath = await _cropImageAction(path);
    if (croppedPath != null) {
      setState(() => _isProcessing = true);
      final data = await OCREngine.analyze(croppedPath);
      setState(() {
        _tempImagePath = croppedPath;
        _nameCtrl.text = data['name'] ?? "";
        _posCtrl.text = data['position'] ?? ""; 
        _phoneCtrl.text = data['phone'] ?? "";
        _emailCtrl.text = data['email'] ?? "";
        _korCoCtrl.text = data['korCo'] ?? "";
        _addrCtrl.text = data['addr'] ?? "";
        
        _options['name'] = List<String>.from(data['nameOptions'] ?? []);
        _options['position'] = List<String>.from(data['positionOptions'] ?? []); 
        _options['phone'] = List<String>.from(data['phoneOptions'] ?? []);
        _options['email'] = List<String>.from(data['emailOptions'] ?? []);
        _options['korCo'] = List<String>.from(data['korCoOptions'] ?? []);
        _options['addr'] = List<String>.from(data['addrOptions'] ?? []);
        _viewMode = 1;
        _isProcessing = false;
      });
    }
  }

  void _showAddCardOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("명함 추가하기", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: navyColor)),
              const SizedBox(height: 20),
              ListTile(
                leading: CircleAvatar(backgroundColor: const Color(0xFFE8EAF6), child: Icon(Icons.document_scanner, color: navyColor)),
                title: const Text('카메라로 스캔', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () async { 
                  Navigator.pop(context); 
                  try {
                    final scanner = DocumentScanner(options: DocumentScannerOptions(mode: ScannerMode.full));
                    final result = await scanner.scanDocument();
                    if (result.images?.isNotEmpty ?? false) _processImageForBook(result.images!.first);
                  } catch (e) { debugPrint(e.toString()); }
                },
              ),
              ListTile(
                leading: const CircleAvatar(backgroundColor: Color(0xFFF5F5F5), child: Icon(Icons.photo_library, color: Colors.grey)),
                title: const Text('갤러리에서 선택', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () async { 
                  Navigator.pop(context); 
                  final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                  if (image != null) _processImageForBook(image.path);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleMyInfoImage(SourceType type, Function(String) onResult) async {
    final XFile? img = await _picker.pickImage(source: type == SourceType.camera ? ImageSource.camera : ImageSource.gallery);
    if (img != null) {
      final croppedPath = await _cropImageAction(img.path);
      if (croppedPath != null) onResult(croppedPath);
    }
  }

  void _showMyInfoEditDialog() {
    final nameEdit = TextEditingController(text: myInfo?['name'] ?? "");
    final jobEdit = TextEditingController(text: myInfo?['job'] ?? "");
    final coEdit = TextEditingController(text: myInfo?['company'] ?? "");
    final phoneEdit = TextEditingController(text: myInfo?['phone'] ?? "");
    final emailEdit = TextEditingController(text: myInfo?['email'] ?? "");
    final addrEdit = TextEditingController(text: myInfo?['address'] ?? "");
    String? localImagePath = myInfo?['imagePath'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(myInfo == null ? "내 정보 등록" : "내 정보 수정", style: TextStyle(color: navyColor, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () {
                    showModalBottomSheet(context: context, builder: (bottomSheetCtx) => SafeArea(child: Wrap(children: [
                      ListTile(leading: const Icon(Icons.camera_alt), title: const Text('사진 촬영'), onTap: () { Navigator.pop(bottomSheetCtx); _handleMyInfoImage(SourceType.camera, (path) => setDialogState(() => localImagePath = path)); }),
                      ListTile(leading: const Icon(Icons.photo_library), title: const Text('갤러리에서 선택'), onTap: () { Navigator.pop(bottomSheetCtx); _handleMyInfoImage(SourceType.gallery, (path) => setDialogState(() => localImagePath = path)); }),
                    ])));
                  },
                  child: Container(
                    height: 140, width: double.infinity,
                    decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey[300]!)),
                    child: localImagePath != null && localImagePath!.isNotEmpty
                        ? ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.file(File(localImagePath!), fit: BoxFit.cover))
                        : Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_a_photo, color: navyColor, size: 30), const SizedBox(height: 10), const Text("명함 사진 등록", style: TextStyle(fontSize: 13, color: Colors.grey))]),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(controller: nameEdit, decoration: const InputDecoration(labelText: "성명")),
                const SizedBox(height: 10),
                TextField(controller: jobEdit, decoration: const InputDecoration(labelText: "직위")),
                const SizedBox(height: 10),
                TextField(controller: coEdit, decoration: const InputDecoration(labelText: "회사명")),
                const SizedBox(height: 10),
                TextField(controller: phoneEdit, decoration: const InputDecoration(labelText: "연락처")),
                const SizedBox(height: 10),
                TextField(controller: emailEdit, decoration: const InputDecoration(labelText: "이메일")),
                const SizedBox(height: 10),
                TextField(controller: addrEdit, decoration: const InputDecoration(labelText: "주소")),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("취소")),
            ElevatedButton(
              onPressed: () async {
                final newInfo = {
                  'name': nameEdit.text, 
                  'job': jobEdit.text, 
                  'company': coEdit.text, 
                  'phone': phoneEdit.text, 
                  'email': emailEdit.text, 
                  'address': addrEdit.text, 
                  'imagePath': localImagePath ?? ""
                };
                await _dbHelper.saveMyInfo(newInfo);
                await _loadData(); 
                Navigator.pop(ctx);
              }, 
              style: ElevatedButton.styleFrom(backgroundColor: navyColor), 
              child: const Text("저장", style: TextStyle(color: Colors.white))
            ),
          ],
        ),
      ),
    );
  }

  void _shareMyCard() {
    if (myInfo == null) return;
    final String name = myInfo!['name'] ?? "";
    final String company = myInfo!['company'] ?? "";
    final String job = myInfo!['job'] ?? "";
    final String phone = myInfo!['phone'] ?? "";
    final String email = myInfo!['email'] ?? "";
    final String address = myInfo!['address'] ?? "";
    final String plainText = "[명함 정보]\n성명: $name\n직위: $job\n회사: $company\n연락처: $phone\n이메일: $email\n주소: $address";
    final String vCardText = "BEGIN:VCARD\nVERSION:3.0\nN:;$name;;;\nFN:$name\nORG:$company\nTITLE:$job\nTEL;TYPE=CELL,VOICE:$phone\nEMAIL;TYPE=WORK,INTERNET:$email\nADR;TYPE=WORK:;;$address\nEND:VCARD";

    showModalBottomSheet(context: context, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))), builder: (ctx) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Padding(padding: EdgeInsets.all(20), child: Text("명함 공유 방식 선택", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
      ListTile(leading: const Icon(Icons.qr_code_2), title: const Text("QR 코드 공유"), onTap: () { Navigator.pop(ctx); _showQRCodeDialog(vCardText); }),
      ListTile(leading: const Icon(Icons.share), title: const Text("텍스트로 공유"), onTap: () { Navigator.pop(ctx); Share.share(plainText); }),
      const SizedBox(height: 10),
    ])));
  }

  void _showQRCodeDialog(String qrData) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text("내 명함 QR 코드"),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text("상대방이 카메라로 스캔하면\n연락처를 바로 저장할 수 있습니다.", textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 20),
        SizedBox(width: 200, height: 200, child: QrImageView(data: qrData, version: QrVersions.auto, size: 200.0)),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("닫기"))],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _viewMode == 0 && !_isSelectionMode,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        setState(() {
          if (_isSelectionMode) {
            _isSelectionMode = false;
            _selectedIndices.clear();
          } else {
            _viewMode = 0; 
          }
        });
      },
      child: _buildCurrentView(),
    );
  }

  Widget _buildCurrentView() {
    if (_viewMode == 1) {
      return Scaffold(
        appBar: AppBar(title: const Text("정보 편집", style: TextStyle(fontWeight: FontWeight.bold)), backgroundColor: navyColor, foregroundColor: Colors.white, centerTitle: true),
        body: SafeArea(child: _isProcessing ? const Center(child: CircularProgressIndicator()) : _buildEditView()),
      );
    }
    
    if (_viewMode == 2 && _selectedCard != null) {
      return SafeArea(
        child: CardDetailView(
          card: _selectedCard!,
          onBack: () => setState(() => _viewMode = 0),
          onEdit: () {
            setState(() {
              _editingId = _selectedCard!.id;
              _nameCtrl.text = _selectedCard!.name; 
              _posCtrl.text = _selectedCard!.position; 
              _phoneCtrl.text = _selectedCard!.phone; 
              _emailCtrl.text = _selectedCard!.email; 
              _korCoCtrl.text = _selectedCard!.korCo; 
              _addrCtrl.text = _selectedCard!.addr; 
              _tempImagePath = _selectedCard!.imagePath;
              _options = {'name': [], 'position': [], 'phone': [], 'email': [], 'korCo': [], 'addr': []};
              _viewMode = 1;
            });
          },
          navyColor: navyColor,
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(_isSelectionMode ? "${_selectedIndices.length}개 선택됨" : "K-Card Scanner", style: TextStyle(fontWeight: FontWeight.w900, color: navyColor)),
        backgroundColor: Colors.white, elevation: 0,
        actions: _isSelectionMode ? [IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () {
          showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text("삭제 확인"), content: Text("${_selectedIndices.length}개의 명함을 삭제하시겠습니까?"), actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("취소")),
            TextButton(onPressed: () { Navigator.pop(ctx); _deleteSelectedCards(); }, child: const Text("삭제", style: TextStyle(color: Colors.red))),
          ]));
        })] : [
          IconButton(icon: const Icon(Icons.file_download_outlined), onPressed: _handleBackup, tooltip: '엑셀로 백업'),
          IconButton(icon: const Icon(Icons.file_upload_outlined), onPressed: _handleRestore, tooltip: '엑셀로 복구'),
        ],
        bottom: TabBar(controller: _tabController, indicatorColor: navyColor, labelColor: navyColor, unselectedLabelColor: const Color(0xFFADB5BD), tabs: const [Tab(text: "내 명함"), Tab(text: "명함책")]),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            MyCardView(myInfo: myInfo, onEdit: _showMyInfoEditDialog, onDelete: () async { await _dbHelper.deleteMyInfo(); await _loadData(); }, onShare: _shareMyCard, navyColor: navyColor),
            CardBookListView(
              savedCards: _filteredCards, 
              isSelectionMode: _isSelectionMode, 
              selectedIndices: _selectedIndices, 
              onToggleSelection: _toggleSelection, 
              onLongPress: (i) => setState(() { _isSelectionMode = true; _selectedIndices.add(i); }), 
              onShowDetail: (card) => setState(() { _selectedCard = card; _viewMode = 2; }), 
              onSearch: _applyFilter, 
              onSaveContact: _saveToDeviceContacts, 
              currentSearchQuery: _searchQuery, 
              navyColor: navyColor,
              searchController: _searchCtrl,
            ),
          ],
        ),
      ),
      floatingActionButton: _isSelectionMode ? null : FloatingActionButton.extended(onPressed: _showAddCardOptions, backgroundColor: navyColor, icon: const Icon(Icons.add_a_photo, color: Colors.white), label: const Text("명함 추가", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildEditView() {
    return Column(children: [
      Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (_tempImagePath != null) Center(child: ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.file(File(_tempImagePath!), height: 180))),
        const SizedBox(height: 25),
        _editFieldWithDropdown(_nameCtrl, "성명", 'name'), 
        _editFieldWithDropdown(_posCtrl, "직위", 'position'), 
        _editFieldWithDropdown(_phoneCtrl, "연락처", 'phone'), 
        _editFieldWithDropdown(_emailCtrl, "이메일", 'email'), 
        _editFieldWithDropdown(_korCoCtrl, "회사명", 'korCo'), 
        _editFieldWithDropdown(_addrCtrl, "주소", 'addr'),
      ]))),
      _buildBottomButtons(),
    ]);
  }

  Widget _editFieldWithDropdown(TextEditingController ctrl, String label, String key) {
    return Padding(padding: const EdgeInsets.only(bottom: 18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: navyColor, fontSize: 13)),
      const SizedBox(height: 5),
      Row(children: [
        Expanded(child: TextField(controller: ctrl)),
        if (_options[key] != null && _options[key]!.length > 1)
          PopupMenuButton<String>(icon: Icon(Icons.expand_circle_down, color: navyColor), onSelected: (val) => setState(() => ctrl.text = val), itemBuilder: (ctx) => _options[key]!.map((opt) => PopupMenuItem(value: opt, child: Text(opt))).toList()),
      ]),
    ]));
  }

  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))]),
      child: Row(children: [
        Expanded(flex: 2, child: OutlinedButton(onPressed: () => setState(() { _viewMode = 0; _editingId = null; }), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15)), child: const Text("취소", style: TextStyle(color: Color(0xFF868E96))))),
        const SizedBox(width: 10),
        Expanded(flex: 2, child: ElevatedButton(onPressed: _showAddCardOptions, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE8EAF6), foregroundColor: navyColor, padding: const EdgeInsets.symmetric(vertical: 15), elevation: 0), child: const Text("재촬영", style: TextStyle(fontWeight: FontWeight.bold)))),
        const SizedBox(width: 10),
        Expanded(flex: 3, child: ElevatedButton(
          onPressed: () async {
            final card = BusinessCard(
              id: _editingId, 
              imagePath: _tempImagePath!, 
              name: _nameCtrl.text, 
              position: _posCtrl.text, 
              phone: _phoneCtrl.text, 
              email: _emailCtrl.text, 
              korCo: _korCoCtrl.text, 
              engCo: "", 
              addr: _addrCtrl.text
            );

            // 수정 시에는 update, 신규 시에는 insert 호출
            if (_editingId != null) {
              await _dbHelper.updateCard(card);
            } else {
              await _dbHelper.insertCard(card);
            }

            await _loadData(); 
            setState(() {
              _viewMode = 0;
              _editingId = null;
            });
          }, 
          style: ElevatedButton.styleFrom(backgroundColor: navyColor, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15)), 
          child: Text(_editingId != null ? "수정 완료" : "정보 저장", style: const TextStyle(fontWeight: FontWeight.bold))
        )),
      ]),
    );
  }
}