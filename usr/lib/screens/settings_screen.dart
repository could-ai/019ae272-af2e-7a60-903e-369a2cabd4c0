import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _macController = TextEditingController();
  final _broadcastIpController = TextEditingController(text: '255.255.255.255');
  final _pcIpController = TextEditingController();
  final _portController = TextEditingController(text: '8080');
  final _secretController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _macController.text = prefs.getString('mac_address') ?? '';
      _broadcastIpController.text = prefs.getString('broadcast_ip') ?? '255.255.255.255';
      _pcIpController.text = prefs.getString('pc_ip') ?? '';
      _portController.text = prefs.getString('pc_port') ?? '8080';
      _secretController.text = prefs.getString('secret') ?? '';
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('mac_address', _macController.text);
    await prefs.setString('broadcast_ip', _broadcastIpController.text);
    await prefs.setString('pc_ip', _pcIpController.text);
    await prefs.setString('pc_port', _portController.text);
    await prefs.setString('secret', _secretController.text);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PC Configuration'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            'Wake-on-LAN Settings',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _macController,
            decoration: const InputDecoration(
              labelText: 'MAC Address',
              hintText: 'AA:BB:CC:DD:EE:FF',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _broadcastIpController,
            decoration: const InputDecoration(
              labelText: 'Broadcast IP',
              hintText: '255.255.255.255',
              border: OutlineInputBorder(),
            ),
          ),
          const Divider(height: 40),
          const Text(
            'Unlock Server Settings',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent),
          ),
          const SizedBox(height: 5),
          const Text(
            'Requires a companion script running on your PC to receive the unlock command.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _pcIpController,
            decoration: const InputDecoration(
              labelText: 'PC Local IP Address',
              hintText: '192.168.1.X',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _portController,
            decoration: const InputDecoration(
              labelText: 'Port',
              hintText: '8080',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _secretController,
            decoration: const InputDecoration(
              labelText: 'Secret / Password',
              hintText: 'Optional security token',
              border: OutlineInputBorder(),
            ),
            obscureText: true,
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: _saveSettings,
            icon: const Icon(Icons.save),
            label: const Text('Save Configuration'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 15),
            ),
          ),
        ],
      ),
    );
  }
}
