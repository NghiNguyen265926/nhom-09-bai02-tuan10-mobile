import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const DoAnApp());
}

// Du lieu loai de tai duoc lay tu SQL Server thong qua API.
class LoaiDeTai {
  final int loaiDeTaiId;
  final String tenLoai;

  const LoaiDeTai({
    required this.loaiDeTaiId,
    required this.tenLoai,
  });

  factory LoaiDeTai.fromJson(Map<String, dynamic> json) {
    return LoaiDeTai(
      loaiDeTaiId: (json['loaiDeTaiId'] ?? json['LoaiDeTaiId']) as int,
      tenLoai: (json['tenLoai'] ?? json['TenLoai'] ?? '').toString(),
    );
  }
}

// Du lieu chuyen nganh duoc lay tu SQL Server thong qua API.
class ChuyenNganh {
  final int chuyenNganhId;
  final String tenChuyenNganh;
  final String moTa;

  const ChuyenNganh({
    required this.chuyenNganhId,
    required this.tenChuyenNganh,
    required this.moTa,
  });

  factory ChuyenNganh.fromJson(Map<String, dynamic> json) {
    return ChuyenNganh(
      chuyenNganhId:
          (json['chuyenNganhId'] ?? json['ChuyenNganhId']) as int,
      tenChuyenNganh:
          (json['tenChuyenNganh'] ?? json['TenChuyenNganh'] ?? '').toString(),
      moTa: (json['moTa'] ?? json['MoTa'] ?? '').toString(),
    );
  }
}

class DoAnApp extends StatelessWidget {
  const DoAnApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ListView Demo',
      theme: ThemeData(
        useMaterial3: false,
        primarySwatch: Colors.amber,
        scaffoldBackgroundColor: const Color(0xFFF5F3EA),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFFB300),
          foregroundColor: Colors.black87,
          elevation: 2,
        ),
      ),
      home: const ManHinhDoAn(),
    );
  }
}

class ManHinhDoAn extends StatefulWidget {
  const ManHinhDoAn({super.key});

  @override
  State<ManHinhDoAn> createState() => _ManHinhDoAnState();
}

class _ManHinhDoAnState extends State<ManHinhDoAn> {
  // Android Emulator: 10.0.2.2 tro den may tinh host.
  // Neu chay Flutter tren Windows/Web, doi thanh http://localhost:5243/api.
  static const String baseUrl = 'http://10.0.2.2:5232/api';
  List<LoaiDeTai> _loaiDeTais = [];
  List<ChuyenNganh> _chuyenNganhs = [];
  int? _loaiDangChon;
  bool _dangTaiLoai = false;
  bool _dangTaiChuyenNganh = false;
  String? _loi;

  @override
  void initState() {
    super.initState();
    _taiLoaiDeTai();
  }

  Future<void> _taiLoaiDeTai() async {
    setState(() {
      _dangTaiLoai = true;
      _loi = null;
    });

    try {
      final response = await http
          .get(Uri.parse('$baseUrl/LoaiDeTai'))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception('API trả về HTTP ${response.statusCode}');
      }

      final List<dynamic> duLieu = jsonDecode(response.body) as List<dynamic>;
      final danhSach = duLieu
          .map((item) => LoaiDeTai.fromJson(item as Map<String, dynamic>))
          .toList();

      if (!mounted) return;
      setState(() {
        _loaiDeTais = danhSach;
        _loaiDangChon = danhSach.isEmpty ? null : danhSach.first.loaiDeTaiId;
      });

      if (_loaiDangChon != null) {
        await _taiChuyenNganh(_loaiDangChon!);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loi = 'Không tải được loại đề tài. Hãy kiểm tra API và SQL Server.\n$e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _dangTaiLoai = false;
        });
      }
    }
  }

  Future<void> _taiChuyenNganh(int loaiDeTaiId) async {
    setState(() {
      _loaiDangChon = loaiDeTaiId;
      _dangTaiChuyenNganh = true;
      _loi = null;
    });

    try {
      final uri = Uri.parse('$baseUrl/ChuyenNganh').replace(
        queryParameters: {'loaiDeTaiId': loaiDeTaiId.toString()},
      );

      final response = await http
          .get(uri)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception('API trả về HTTP ${response.statusCode}');
      }

      final List<dynamic> duLieu = jsonDecode(response.body) as List<dynamic>;
      final danhSach = duLieu
          .map((item) => ChuyenNganh.fromJson(item as Map<String, dynamic>))
          .toList();

      if (!mounted) return;
      setState(() {
        _chuyenNganhs = danhSach;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _chuyenNganhs = [];
          _loi = 'Không tải được danh sách chuyên ngành.\n$e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _dangTaiChuyenNganh = false;
        });
      }
    }
  }

  void _hienThiChiTiet(ChuyenNganh item) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item.tenChuyenNganh),
        content: Text(item.moTa),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ListView Demo',
          style: TextStyle(fontSize: 18),
        ),
        leading: const Icon(Icons.home, size: 21),
        actions: [
          IconButton(
            tooltip: 'Tải lại dữ liệu',
            onPressed: _dangTaiLoai ? null : _taiLoaiDeTai,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Thanh tieu de phan loai de tai.
          Container(
            height: 34,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            color: const Color(0xFF2196F3),
            child: const Text(
              'Chọn loại đề tài',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),

          // Cac nut tron loai de tai, du lieu lay tu API.
          SizedBox(
            height: 100,
            child: _dangTaiLoai && _loaiDeTais.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _loaiDeTais.isEmpty
                    ? const Center(child: Text('Chưa có loại đề tài'))
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        scrollDirection: Axis.horizontal,
                        itemCount: _loaiDeTais.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 6),
                        itemBuilder: (context, index) {
                          final item = _loaiDeTais[index];
                          final selected = item.loaiDeTaiId == _loaiDangChon;

                          return InkWell(
                            onTap: _dangTaiChuyenNganh
                                ? null
                                : () => _taiChuyenNganh(item.loaiDeTaiId),
                            borderRadius: BorderRadius.circular(50),
                            child: Container(
                              width: 66,
                              height: 66,
                              margin: const EdgeInsets.symmetric(vertical: 2),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: selected
                                    ? const Color(0xFF5121B8)
                                    : const Color(0xFF673AB7),
                                shape: BoxShape.circle,
                                border: selected
                                    ? Border.all(color: Colors.white, width: 2)
                                    : null,
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x22000000),
                                    blurRadius: 3,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(5),
                              child: Text(
                                item.tenLoai,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),

          // Thanh tieu de phan chuyen nganh.
          Container(
            height: 34,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            color: const Color(0xFF2196F3),
            child: const Text(
              'Chọn chuyên ngành thực hiện',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),

          if (_dangTaiChuyenNganh) const LinearProgressIndicator(minHeight: 3),

          if (_loi != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Text(
                    _loi!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _taiLoaiDeTai,
                    child: const Text('Thử tải lại'),
                  ),
                ],
              ),
            ),

          Expanded(
            child: _chuyenNganhs.isEmpty
                ? Center(
                    child: Text(
                      _loi == null
                          ? 'Chưa có chuyên ngành để hiển thị'
                          : 'Kiểm tra kết nối rồi thử tải lại',
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(4, 2, 4, 70),
                    itemCount: _chuyenNganhs.length,
                    itemBuilder: (context, index) {
                      final item = _chuyenNganhs[index];

                      return Card(
                        color: const Color(0xFFF0EDDD),
                        elevation: 1,
                        margin: const EdgeInsets.symmetric(
                          horizontal: 2,
                          vertical: 3,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                          side: const BorderSide(
                            color: Color(0xFFAAA79C),
                            width: 0.8,
                          ),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () => _hienThiChiTiet(item),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 8,
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.home,
                                  size: 21,
                                  color: Color(0xFF555555),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.tenChuyenNganh,
                                        style: const TextStyle(
                                          color: Color(0xFFE04B4B),
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        item.moTa,
                                        style: const TextStyle(
                                          color: Color(0xFF666666),
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.arrow_forward,
                                  size: 21,
                                  color: Color(0xFF777777),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
