import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:couldai_user_app/services/pc_control_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _status = "Ready";
  bool _isProcessing = false;

  Future<void> _handleWakeAndUnlock() async {
    setState(() {
      _isProcessing = true;
      _status = "Processing...";
    });

    try {
      // Authentication removed as per request - direct execution
      
      // 1. Load Settings
      setState(() => _status = "Loading settings...");
      final prefs = await SharedPreferences.getInstance();
      final mac = prefs.getString('mac_address');
      final broadcastIp = prefs.getString('broadcast_ip') ?? '255.255.255.255';
      final pcIp = prefs.getString('pc_ip');
      final port = prefs.getString('pc_port') ?? '8080';
      final secret = prefs.getString('secret') ?? '';

      if (mac == null || mac.isEmpty) {
        _showError("Please configure PC settings first.");
        if (mounted) {
          Navigator.pushNamed(context, '/settings');
        }
        setState(() { _isProcessing = false; _status = "Setup Required"; });
        return;
      }

      // 2. Send Wake-on-LAN
      setState(() => _status = "Sending Wake Signal...");
      await PcControlService.wakePC(mac, broadcastIp);
      
      // 3. Send Unlock Signal
      if (pcIp != null && pcIp.isNotEmpty) {
        setState(() => _status = "Sending Unlock Signal...");
        try {
          await PcControlService.unlockPC(pcIp, port, secret);
          setState(() => _status = "Signal Sent!");
        } catch (e) {
           // It's expected to fail if PC is not yet awake
           setState(() => _status = "Wake Sent (Unlock failed/skipped)");
           print("Unlock failed (PC might be sleeping): $e");
        }
      } else {
        setState(() => _status = "Wake Signal Sent!");
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Wake command sent successfully!')),
        );
      }

    } catch (e) {
      _showError("Error: $e");
      setState(() => _status = "Error");
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PC Control'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _status,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 40),
            GestureDetector(
              onTap: _isProcessing ? null : _handleWakeAndUnlock,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isProcessing 
                      ? Colors.grey.shade800 
                      : Theme.of(context).colorScheme.primary,
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 5,
                    )
                  ],
                ),
                child: Icon(
                  Icons.power_settings_new,
                  size: 80,
                  color: _isProcessing ? Colors.white54 : Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              "Tap to Wake & Unlock",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                "Ensure your PC supports Wake-on-LAN and has the companion unlock server running.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
