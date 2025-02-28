import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

void main() {
  runApp(const CurrencyExchangeApp());
}

class CurrencyExchangeApp extends StatelessWidget {
  const CurrencyExchangeApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Currency Exchange App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const CurrencyExchangeScreen(),
    );
  }
}

class CurrencyExchangeScreen extends StatefulWidget {
  const CurrencyExchangeScreen({Key? key}) : super(key: key);

  @override
  State<CurrencyExchangeScreen> createState() => CurrencyExchangeScreenState();
}

class CurrencyExchangeScreenState extends State<CurrencyExchangeScreen> with SingleTickerProviderStateMixin {
  // Status untuk menandai proses loading
  bool _isLoading = false;
  
  // Pesan error jika terjadi masalah
  String? _errorMessage;
  
  // List untuk menyimpan data mata uang yang telah diproses
  List<Currency> _currencies = [];
  
  // Controller untuk fitur pencarian
  final TextEditingController _searchController = TextEditingController();
  
  // Controller untuk jumlah yang akan dikonversi
  final TextEditingController _amountController = TextEditingController();
  
  // List filtered untuk pencarian
  List<Currency> _filteredCurrencies = [];
  
  // Format angka untuk menampilkan nilai kurs
  final NumberFormat _currencyFormat = NumberFormat("#,##0.00", "en_US");
  
  // Mata uang yang dipilih untuk konversi
  Currency? _fromCurrency;
  Currency? _toCurrency;
  
  // Hasil konversi
  double _conversionResult = 0.0;
  
  // Tab controller untuk navigasi antara daftar kurs dan konverter
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Inisialisasi tab controller
    _tabController = TabController(length: 2, vsync: this);
    
    // Mengambil data kurs mata uang saat aplikasi pertama kali dibuka
    _fetchCurrencyRates();
    
    // Set default value untuk jumlah
    _amountController.text = '1';
    
    // Tambahkan listener untuk TextEditingController
    _searchController.addListener(() {
      _filterCurrencies(_searchController.text);
    });
  }

  @override
  void dispose() {
    // Membersihkan controller saat widget dihapus
    _searchController.dispose();
    _amountController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  /// Mengambil data kurs mata uang dari API
  Future<void> _fetchCurrencyRates() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Menggunakan API dari exchangerate-api.com
      final response = await http.get(
        Uri.parse('https://open.er-api.com/v6/latest/USD'),
      );

      if (response.statusCode == 200) {
        // Berhasil mendapatkan data
        final data = json.decode(response.body);
        
        // Memproses data yang diterima
        _processCurrencyData(data);
      } else {
        // Error dari server
        setState(() {
          _errorMessage = 'Failed to load data: Server error ${response.statusCode}';
        });
      }
    } catch (e) {
      // Error lainnya (koneksi, format, dll)
      setState(() {
        _errorMessage = 'Failed to load data: $e';
      });
    } finally {
      // Menandai bahwa proses loading telah selesai
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Memproses data kurs mata uang yang diterima dari API
  void _processCurrencyData(Map<String, dynamic> data) {
    try {
      final Map<String, dynamic> rates = data['rates'];
      final String baseCode = data['base_code'];
      final String lastUpdateTime = data['time_last_update_utc'];

      List<Currency> currencies = [];

      // Mengubah data kurs menjadi list objek Currency
      rates.forEach((code, rate) {
        currencies.add(
          Currency(
            code: code,
            name: _getCurrencyName(code),
            rate: rate.toDouble(),
            baseCode: baseCode,
            lastUpdate: lastUpdateTime,
          ),
        );
      });

      // Mengurutkan mata uang berdasarkan kode
      currencies.sort((a, b) => a.code.compareTo(b.code));

      setState(() {
        _currencies = currencies;
        _filteredCurrencies = currencies;
        
        // Set default mata uang untuk konversi
        if (_currencies.isNotEmpty) {
          // Cari USD dan IDR sebagai default
          _fromCurrency = _currencies.firstWhere(
            (c) => c.code == 'USD', 
            orElse: () => _currencies.first
          );
          
          _toCurrency = _currencies.firstWhere(
            (c) => c.code == 'IDR', 
            orElse: () => _currencies.length > 1 ? _currencies[1] : _currencies.first
          );
          
          // Hitung konversi awal
          _calculateConversion();
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to process data: $e';
      });
    }
  }

  /// Filter mata uang berdasarkan pencarian
    void _filterCurrencies(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCurrencies = List.from(_currencies);
      } else {
        _filteredCurrencies = _currencies
            .where((currency) =>
                currency.code.toLowerCase().contains(query.toLowerCase()) ||
                currency.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  /// Mendapatkan nama mata uang berdasarkan kode
  String _getCurrencyName(String code) {
  final Map<String, String> currencyNames = {
    'USD': 'United States Dollar',
    'EUR': 'Euro',
    'GBP': 'British Pound Sterling',
    'JPY': 'Japanese Yen',
    'CNY': 'Chinese Yuan',
    'IDR': 'Indonesian Rupiah',
    'AUD': 'Australian Dollar',
    'CAD': 'Canadian Dollar',
    'CHF': 'Swiss Franc',
    'HKD': 'Hong Kong Dollar',
    'SGD': 'Singapore Dollar',
    'MYR': 'Malaysian Ringgit',
    'KRW': 'South Korean Won',
    'INR': 'Indian Rupee',
    'THB': 'Thai Baht',
    'PHP': 'Philippine Peso',
    'TWD': 'Taiwan New Dollar',
    'VND': 'Vietnamese Dong',
    'RUB': 'Russian Ruble',
    'NZD': 'New Zealand Dollar',
    'BRL': 'Brazilian Real',
    'SAR': 'Saudi Riyal',
    'AED': 'United Arab Emirates Dirham',
    'ZAR': 'South African Rand',
    'TRY': 'Turkish Lira',
    'MXN': 'Mexican Peso',
    'SEK': 'Swedish Krona',
    'NOK': 'Norwegian Krone',
    'DKK': 'Danish Krone',
    'PLN': 'Polish Zloty',
    'CZK': 'Czech Koruna',
    'HUF': 'Hungarian Forint',
    'ILS': 'Israeli New Shekel',
    'ARS': 'Argentine Peso',
    'CLP': 'Chilean Peso',
    'EGP': 'Egyptian Pound',
    'KWD': 'Kuwaiti Dinar',
    'QAR': 'Qatari Riyal',
    'NGN': 'Nigerian Naira',
    'PKR': 'Pakistani Rupee',
    'BDT': 'Bangladeshi Taka',
    'LKR': 'Sri Lankan Rupee',
    'NPR': 'Nepalese Rupee',
    'MMK': 'Myanmar Kyat',
    'KHR': 'Cambodian Riel',
    'LAK': 'Lao Kip',
    'BND': 'Brunei Dollar',
    'MOP': 'Macanese Pataca',
    'UAH': 'Ukrainian Hryvnia',
    'RON': 'Romanian Leu',
    'BGN': 'Bulgarian Lev',
    'ISK': 'Icelandic Króna',
    'HRK': 'Croatian Kuna',
  };
    return currencyNames[code] ?? 'Unknown Currency';
  }
  
  /// Menghitung hasil konversi mata uang
  void _calculateConversion() {
    if (_fromCurrency == null || _toCurrency == null) {
      return;
    }
    
    double amount;
    try {
      amount = double.parse(_amountController.text.replaceAll(',', '.'));
    } catch (e) {
      // Jika input tidak valid, gunakan 0
      amount = 0;
    }
    
    // Hitung konversi
    // 1. Konversi ke USD (mata uang dasar)
    // 2. Konversi dari USD ke mata uang tujuan
    double fromRate = _fromCurrency!.rate;
    double toRate = _toCurrency!.rate;
    
    setState(() {
      _conversionResult = amount * (toRate / fromRate);
    });
  }
  
  /// Bertukar mata uang asal dan tujuan
  void _swapCurrencies() {
    setState(() {
      final temp = _fromCurrency;
      _fromCurrency = _toCurrency;
      _toCurrency = temp;
      _calculateConversion();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kurs Mata Uang'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchCurrencyRates,
            tooltip: 'Refresh Data',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.compare_arrows), text: 'Konverter'),
            Tab(icon: Icon(Icons.list), text: 'Daftar Kurs'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildConverterTab(),
          _buildCurrencyListTab(),
        ],
      ),
    );
  }

  /// Widget Tab Konverter Mata Uang
  Widget _buildConverterTab() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 60,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchCurrencyRates,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    if (_currencies.isEmpty) {
      return const Center(
        child: Text(
          'Tidak ada data mata uang',
          style: TextStyle(fontSize: 16),
          textAlign: TextAlign.center,
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Konversi Mata Uang',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Input jumlah
                  TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Jumlah',
                      border: OutlineInputBorder(),
                      hintText: 'Masukkan jumlah',
                    ),
                    onChanged: (_) => _calculateConversion(),
                  ),
                  const SizedBox(height: 16),
                  
                  // Dropdown mata uang asal
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Dari Mata Uang'),
                            const SizedBox(height: 8),
                            _buildCurrencyDropdown(
                              value: _fromCurrency,
                              onChanged: (Currency? currency) {
                                setState(() {
                                  _fromCurrency = currency;
                                  _calculateConversion();
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      
                      // Tombol tukar
                      IconButton(
                        icon: const Icon(Icons.swap_horiz),
                        onPressed: _swapCurrencies,
                        tooltip: 'Tukar Mata Uang',
                      ),
                      
                      // Dropdown mata uang tujuan
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Ke Mata Uang'),
                            const SizedBox(height: 8),
                            _buildCurrencyDropdown(
                              value: _toCurrency,
                              onChanged: (Currency? currency) {
                                setState(() {
                                  _toCurrency = currency;
                                  _calculateConversion();
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Hasil konversi
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          'Hasil Konversi',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_amountController.text} ${_fromCurrency?.code ?? ''} = ${_currencyFormat.format(_conversionResult)} ${_toCurrency?.code ?? ''}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Kurs: 1 ${_fromCurrency?.code ?? ''} = ${_toCurrency != null && _fromCurrency != null ? _currencyFormat.format(_toCurrency!.rate / _fromCurrency!.rate) : '0.00'} ${_toCurrency?.code ?? ''}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Info lebih lanjut
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Informasi Mata Uang',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Dari: ${_fromCurrency?.code ?? ''} - ${_fromCurrency?.name ?? ''}'),
                  Text('Ke: ${_toCurrency?.code ?? ''} - ${_toCurrency?.name ?? ''}'),
                  const SizedBox(height: 8),
                  const Text(
                    'Tip: Tekan tombol tukar untuk membalik konversi mata uang',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                  Text(
                    'Data terakhir diperbarui: ${_fromCurrency?.lastUpdate ?? ''}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Widget dropdown untuk pemilihan mata uang
  Widget _buildCurrencyDropdown({
    required Currency? value,
    required void Function(Currency?) onChanged,
  }) {
    return GestureDetector(
      onTap: () {
        // Tampilkan dialog pencarian saat dropdown diklik
        showDialog(
          context: context,
          builder: (context) => _buildSearchableCurrencyDialog(
            currentValue: value,
            onCurrencySelected: (currency) {
              onChanged(currency);
              Navigator.of(context).pop();
            },
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value != null 
                  ? '${value.code} - ${value.name}'
                  : 'Pilih mata uang',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }

  /// Dialog pencarian mata uang
  Widget _buildSearchableCurrencyDialog({
    required Currency? currentValue,
    required Function(Currency) onCurrencySelected,
  }) {
    // Controller untuk pencarian dalam dialog
    final TextEditingController dialogSearchController = TextEditingController();
    // List untuk menyimpan mata uang yang difilter dalam dialog
    List<Currency> dialogFilteredList = List.from(_currencies);
    
    return StatefulBuilder(
      builder: (context, setDialogState) {
        // Fungsi filter khusus untuk dialog
        void filterDialogCurrencies(String query) {
          setDialogState(() {
            if (query.isEmpty) {
              dialogFilteredList = List.from(_currencies);
            } else {
              dialogFilteredList = _currencies
                  .where((currency) =>
                      currency.code.toLowerCase().contains(query.toLowerCase()) ||
                      currency.name.toLowerCase().contains(query.toLowerCase()))
                  .toList();
            }
          });
        }
        
        return AlertDialog(
          title: const Text('Pilih Mata Uang'),
          content: Container(
            width: double.maxFinite,
            constraints: const BoxConstraints(
              maxHeight: 400,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Input pencarian
                TextField(
                  controller: dialogSearchController,
                  decoration: InputDecoration(
                    hintText: 'Cari mata uang...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    suffixIcon: dialogSearchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            dialogSearchController.clear();
                            filterDialogCurrencies('');
                          },
                        )
                      : null,
                  ),
                  onChanged: filterDialogCurrencies, // Menggunakan onChanged langsung
                  autofocus: true,
                ),
                const SizedBox(height: 8),
                
                // Daftar mata uang
                Expanded(
                  child: dialogFilteredList.isEmpty
                    ? const Center(
                        child: Text('Tidak ada mata uang yang sesuai'),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: dialogFilteredList.length,
                        itemBuilder: (context, index) {
                          final currency = dialogFilteredList[index];
                          final isSelected = currentValue?.code == currency.code;
                          
                          return ListTile(
                            title: Text(
                              '${currency.code} - ${currency.name}',
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            trailing: isSelected 
                              ? const Icon(Icons.check, color: Colors.blue)
                              : null,
                            onTap: () {
                              onCurrencySelected(currency);
                            },
                          );
                        },
                      ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
          ],
        );
      },
    );
  }

  /// Widget Tab Daftar Kurs Mata Uang
  Widget _buildCurrencyListTab() {
    return Column(
      children: [
        // Widget pencarian
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Cari Mata Uang',
              hintText: 'Contoh: USD, Euro, Rupiah',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _filterCurrencies('');
                      },
                    )
                  : null,
            ),
            onChanged: _filterCurrencies,
          ),
        ),
        
        // Menampilkan indikator loading, pesan error, atau data
        Expanded(
          child: _buildCurrencyListContent(),
        ),
      ],
    );
  }

  /// Membangun konten daftar mata uang berdasarkan state
  Widget _buildCurrencyListContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 60,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchCurrencyRates,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    if (_filteredCurrencies.isEmpty) {
      return const Center(
        child: Text(
          'Tidak ada data mata uang yang sesuai dengan pencarian',
          style: TextStyle(fontSize: 16),
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.builder(
      itemCount: _filteredCurrencies.length,
      itemBuilder: (context, index) {
        final currency = _filteredCurrencies[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 2,
          child: ListTile(
            leading: CircleAvatar(
              child: Text(
                currency.code.substring(0, 1),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(
              '${currency.code} - ${currency.name}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('Kurs: 1 ${currency.baseCode} = ${_currencyFormat.format(currency.rate)} ${currency.code}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  currency.rate > 1.0 ? Icons.arrow_upward : Icons.arrow_downward,
                  color: currency.rate > 1.0 ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.swap_horiz, color: Colors.blue),
                  onPressed: () {
                    setState(() {
                      // Set mata uang ini sebagai tujuan konversi
                      _toCurrency = currency;
                      _calculateConversion();
                      // Pindah ke tab konverter
                      _tabController.animateTo(0);
                    });
                  },
                  tooltip: 'Konversi ke ${currency.code}',
                )
              ],
            ),
            onTap: () {
              _showCurrencyDetails(currency);
            },
          ),
        );
      },
    );
  }

  /// Menampilkan detail mata uang dalam dialog
  void _showCurrencyDetails(Currency currency) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${currency.code} - ${currency.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Kurs: 1 ${currency.baseCode} = ${_currencyFormat.format(currency.rate)} ${currency.code}'),
            const SizedBox(height: 8),
            Text('Konversi balik: 1 ${currency.code} = ${_currencyFormat.format(1 / currency.rate)} ${currency.baseCode}'),
            const SizedBox(height: 16),
            Text('Terakhir diperbarui: ${currency.lastUpdate}'),
          ],
        ),
        actions: [
          // Tombol untuk konversi ke mata uang ini
          TextButton(
            onPressed: () {
              setState(() {
                _toCurrency = currency;
                _calculateConversion();
                Navigator.of(context).pop();
                _tabController.animateTo(0); // Pindah ke tab konverter
              });
            },
            child: Text('Konversi ke ${currency.code}'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }
}

/// Model untuk data mata uang
class Currency {
  final String code;
  final String name;
  final double rate;
  final String baseCode;
  final String lastUpdate;

  Currency({
    required this.code,
    required this.name,
    required this.rate,
    required this.baseCode,
    required this.lastUpdate,
  });
}