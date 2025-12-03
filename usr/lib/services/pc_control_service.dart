import 'dart:io';
import 'package:http/http.dart' as http;

class PcControlService {
  /// Sends a Magic Packet to wake up the PC via Wake-on-LAN
  static Future<void> wakePC(String macAddress, String broadcastIp) async {
    if (macAddress.isEmpty) throw Exception("MAC Address is empty");
    
    // Clean MAC address
    final String cleanMac = macAddress.replaceAll(':', '').replaceAll('-', '');
    if (cleanMac.length != 12) throw Exception("Invalid MAC Address format");

    // Create Magic Packet
    // 6 bytes of 0xFF
    List<int> packet = List.filled(6, 0xFF);
    
    // 16 repetitions of the MAC address
    List<int> macBytes = [];
    for (int i = 0; i < 12; i += 2) {
      macBytes.add(int.parse(cleanMac.substring(i, i + 2), radix: 16));
    }
    
    for (int i = 0; i < 16; i++) {
      packet.addAll(macBytes);
    }

    // Send UDP Broadcast
    RawDatagramSocket? socket;
    try {
      socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      socket.broadcastEnabled = true;
      socket.send(packet, InternetAddress(broadcastIp), 9); // Port 9 is standard for WoL
    } catch (e) {
      print("Error sending WoL packet: $e");
      rethrow;
    } finally {
      socket?.close();
    }
  }

  /// Sends an HTTP request to the PC to trigger unlock
  /// Note: Requires a companion server running on the PC
  static Future<void> unlockPC(String ip, String port, String secret) async {
    if (ip.isEmpty || port.isEmpty) throw Exception("IP or Port is empty");

    final url = Uri.parse('http://$ip:$port/unlock');
    try {
      final response = await http.post(
        url,
        body: {'secret': secret},
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode != 200) {
        throw Exception("Failed to unlock: Server responded with ${response.statusCode}");
      }
    } catch (e) {
      print("Error sending unlock signal: $e");
      rethrow;
    }
  }
}
