import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:network_info_plus/network_info_plus.dart';

class Info extends StatefulWidget {
  const Info({super.key});

  @override
  State<Info> createState() => _InfoState();
}

class _InfoState extends State<Info> {
  @override
  void initState() {
    super.initState();
    startInfo();
  }

  startInfo() async {
    final info = NetworkInfo();

    final wifiName = await info.getWifiName(); // "FooNetwork"
    log('wifiName: $wifiName');
    final wifiBSSID = await info.getWifiBSSID(); // 11:22:33:44:55:66
    log('wifiBSSID: $wifiBSSID');
    final wifiIP = await info.getWifiIP(); // 192.168.1.43
    log('wifiIP: $wifiIP');
    final wifiIPv6 =
        await info.getWifiIPv6(); // 2001:0db8:85a3:0000:0000:8a2e:0370:7334
    log('wifiIPv6: $wifiIPv6');
    final wifiSubmask = await info.getWifiSubmask(); // 255.255.255.0
    log('wifiSubmask: $wifiSubmask');
    final wifiBroadcast = await info.getWifiBroadcast(); // 192.168.1.255
    log('wifiBroadcast: $wifiBroadcast');
    final wifiGateway = await info.getWifiGatewayIP(); // 192.168.1.1
    log('wifiGateway: $wifiGateway');
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
