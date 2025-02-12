import 'package:flutter/material.dart';
import 'package:guardix/components/toast.dart';
import 'package:guardix/constants/colors.dart';
import 'package:guardix/constants/services_and_numbers.dart';
import 'package:url_launcher/url_launcher.dart';

class SosView extends StatefulWidget {
  const SosView({super.key});

  @override
  State<SosView> createState() => _SosViewState();
}

class _SosViewState extends State<SosView> {
  void _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      showToast('Could not launch the dialer');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: whiteColor),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        title: const Text(
          'SOS Emergency',
          style: TextStyle(color: whiteColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: midnightBlueColor,
        elevation: 4,
      ),
      body: Container(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView.builder(
            itemCount: services.length,
            itemBuilder: (context, index) {
              return Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                elevation: 8,
                shadowColor: Colors.black,
                color: Colors.white,
                child: ListTile(
                  onTap: () => _makePhoneCall(numbers[index]),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                  leading: const CircleAvatar(
                    backgroundColor: midnightBlueColor,
                    child: Icon(Icons.local_phone, color: whiteColor),
                  ),
                  title: Text(
                    services[index],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded,
                      color: Colors.black54),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
