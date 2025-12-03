import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:couldai_user_app/services/pc_control_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final LocalAuthentication auth = LocalAuthentication();
  String _status = "Ready";
  bool _isProcessing = false;

  Future<void> _handleWakeAndUnlock() async {
    setState(() {
      _isProcessing = true;
      _status = "Authenticating...";
    });

    try {
      // 1. Authenticate
      final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await auth.isDeviceSupported();

      bool didAuthenticate = false;
      
      if (canAuthenticate) {
        try {
          didAuthenticate = await auth.authenticate(
            localizedReason: 'Scan fingerprint to wake and unlock PC',
            options: const AuthenticationOptions(
              stickyAuth: true,
              biometricOnly: false,
            ),
          );
        } catch (e) {
          // Fallback for simulators or errors
          print("Auth error: $e");
          // For testing purposes in simulator where auth might fail or not be setup:
          // didAuthenticate = true; // Uncomment to bypass in dev
          _showError("Authentication failed: $e");
          setState(() { _isProcessing = false; _status = "Auth Failed"; });
          return;
        }
      } else {
        // If no biometrics, maybe just proceed or ask for pin (simplified here)
        _showError("Biometrics not available on this device");
        setState(() { _isProcessing = false; _status = "No Biometrics"; });
        return;
      }

      if (!didAuthenticate) {
        setState(() {
          _isProcessing = false;
          _status = "Cancelled";
        });
        return;
      }

      // 2. Load Settings
      setState(() => _status = "Loading settings...");
      final prefs = await SharedPreferences.getInstance();
      final mac = prefs.getString('mac_address');
      final broadcastIp = prefs.getString('broadcast_ip') ?? '255.255.255.255';
      final pcIp = prefs.getString('pc_ip');
      final port = prefs.getString('pc_port') ?? '8080';
      final secret = prefs.getString('secret') ?? '';

      if (mac == null || mac.isEmpty) {
        _showError("Please configure PC settings first.");
        Navigator.pushNamed(context, '/settings');
        setState(() { _isProcessing = false; _status = "Setup Required"; });
        return;
      }

      // 3. Send Wake-on-LAN
      setState(() => _status = "Sending Wake Signal...");
      await PcControlService.wakePC(mac, broadcastIp);
      
      // 4. Send Unlock Signal
      // We might want to wait a bit or send it immediately. 
      // If the PC is asleep, it takes time to wake up.
      // For "Unlock", usually the PC needs to be awake.
      // We'll try sending it immediately, but in reality, you might need a retry mechanism.
      if (pcIp != null && pcIp.isNotEmpty) {
        setState(() => _status = "Sending Unlock Signal...");
        // Small delay to allow network card to wake up fully if it was deep sleep? 
        // Actually WoL is fast, but OS boot/wake takes seconds.
        // We'll send it, but user might need to press again if PC was fully off.
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wake command sent successfully!')),
      );

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
                  Icons.fingerprint,
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
