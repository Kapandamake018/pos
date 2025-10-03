import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../app_config.dart';
import '../config/api_config.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _baseCtrl;
  late TextEditingController _taxCtrl;
  bool _loading = true;
  late AppConfig _config;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    AppConfig.load().then((cfg) {
      _config = cfg;
      _baseCtrl = TextEditingController(text: _config.baseUrl);
      _taxCtrl = TextEditingController(text: _config.taxUrl);
      setState(() => _loading = false);
    });
  }

  @override
  void dispose() {
    _baseCtrl.dispose();
    _taxCtrl.dispose();
    super.dispose();
  }

  String? _validateUrl(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) {
      return 'Required';
    }
    if (!s.startsWith('http://') && !s.startsWith('https://')) {
      return 'Must start with http:// or https://';
    }
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    _config.baseUrl = _baseCtrl.text.trim();
    _config.taxUrl = _taxCtrl.text.trim();
    await _config.save();
    setState(() => _loading = false);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Settings saved')));
  }

  Future<void> _reset() async {
    setState(() => _loading = true);
    await _config.resetToDefaults();
    final cfg = await AppConfig.load();
    _baseCtrl.text = cfg.baseUrl;
    _taxCtrl.text = cfg.taxUrl;
    setState(() => _loading = false);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Reset to defaults')));
  }

  Future<void> _discover() async {
    setState(() => _loading = true);
    List<String> found = [];
    try {
      // Get local IPv4 address
      final interfaces = await NetworkInterface.list();
      String? localIp;
      for (var intf in interfaces) {
        for (var addr in intf.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            localIp = addr.address;
            break;
          }
        }
        if (localIp != null) break;
      }

      if (localIp == null) {
        throw Exception('Unable to determine device IP address');
      }

      final prefix = localIp.substring(0, localIp.lastIndexOf('.') + 1);
      final candidates = List.generate(254, (i) => '$prefix${i + 1}');

      final concurrency = 40;
      var index = 0;
      final List<Future<void>> workers = [];

      Future<void> worker() async {
        while (true) {
          int i;
          // get next index
          if (index >= candidates.length) break;
          i = index;
          index++;
          final ip = candidates[i];
          if (ip == localIp) continue;
          try {
            final uri = Uri.parse('http://$ip:8001/health');
            final resp = await http
                .get(uri)
                .timeout(const Duration(milliseconds: 400));
            if (resp.statusCode >= 200 && resp.statusCode < 300) {
              found.add(ip);
            }
          } catch (_) {
            // ignore
          }
        }
      }

      for (var i = 0; i < concurrency; i++) {
        workers.add(worker());
      }

      await Future.wait(workers);
    } catch (e) {
      // discovery errors are non-fatal; show message below
    } finally {
      setState(() => _loading = false);
    }

    if (!mounted) return;

    if (found.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hosts found on the local network')),
      );
      return;
    }

    // Let user pick the first or choose from list
    final picked = await showDialog<String?>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Discovered hosts'),
        children: [
          for (var ip in found)
            SimpleDialogOption(
              child: Text(ip),
              onPressed: () => Navigator.of(ctx).pop(ip),
            ),
          SimpleDialogOption(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(ctx).pop(null),
          ),
        ],
      ),
    );

    if (picked != null) {
      // populate controllers and save
      _baseCtrl.text = 'http://$picked:8001';
      _taxCtrl.text = 'http://$picked:8002';
      await _save();
    }
  }

  Future<String> _resolvedBase() async {
    final cfg = await AppConfig.load();
    final base = cfg.baseUrl.trim();
    if (base.isEmpty) return ApiConfig.baseUrl;
    return base;
  }

  Future<void> _testConnection() async {
    setState(() => _loading = true);
    try {
      final base = await _resolvedBase();
      final uri = Uri.parse('$base/health');
      final resp = await http.get(uri).timeout(const Duration(seconds: 2));
      if (!mounted) {
        return;
      }
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Connection OK')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connection failed: ${resp.statusCode}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Connection error: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _baseCtrl,
                decoration: const InputDecoration(labelText: 'BASE_URL'),
                validator: _validateUrl,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _taxCtrl,
                decoration: const InputDecoration(labelText: 'TAX_BASE_URL'),
                validator: _validateUrl,
              ),
              const SizedBox(height: 20),
              // Responsive button layout - Wrap prevents overflow on narrow screens
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: 140,
                    child: ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(44),
                      ),
                      child: const Text('Save'),
                    ),
                  ),
                  SizedBox(
                    width: 140,
                    child: OutlinedButton(
                      onPressed: _reset,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(44),
                      ),
                      child: const Text('Reset'),
                    ),
                  ),
                  SizedBox(
                    width: 140,
                    child: ElevatedButton.icon(
                      onPressed: _discover,
                      icon: const Icon(Icons.search),
                      label: const Text('Discover'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(44),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 140,
                    child: ElevatedButton.icon(
                      onPressed: _testConnection,
                      icon: const Icon(Icons.wifi),
                      label: const Text('Test'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(44),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              FutureBuilder<String>(
                future: _resolvedBase(),
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return const SizedBox.shrink();
                  }
                  return ListTile(
                    title: const Text('Using'),
                    subtitle: Text(snap.data!),
                    leading: const Icon(Icons.link),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
