import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:guardix/constants/colors.dart';
import 'package:guardix/service/cloud/cloud_storage_constants.dart';
import 'package:guardix/service/cloud/firebase_cloud_storage.dart';
import 'package:guardix/utilities/helpers/generate_location_link.dart';
import 'package:guardix/utilities/helpers/local_storage.dart';
import 'package:guardix/utilities/helpers/make_phone_message_email.dart';
import 'package:guardix/utilities/helpers/shake_detector.dart';
import 'package:guardix/views/bottom_nav/chat_view.dart';
import 'package:guardix/views/bottom_nav/home/home_view.dart';
import 'package:guardix/views/bottom_nav/report_view.dart';
import 'package:guardix/views/bottom_nav/sos_view.dart';

class NavigationMenu extends StatefulWidget {
  const NavigationMenu({super.key});

  @override
  State<NavigationMenu> createState() => _NavigationMenuState();
}

class _NavigationMenuState extends State<NavigationMenu> {
  int _selectedIndex = 0;
  static const List<Widget> _widgetOptions = [
    HomeView(),
    ChatView(),
    ReportView(),
    SosView(),
  ];

  late ShakeDetector _shakeDetector;
  bool shaked = false;
  @override
  void initState() {
    _shakeDetector = ShakeDetector(
      onShake: () async {
        shaked = true;
        //print('helllo');
        while (await LocalStorage.getEmergencyStatus() ?? true) {
          List<String> trustedContacts =
              await LocalStorage.getTrustedContacts();
          List<String> trustedContactNames =
              await LocalStorage.getTrustedContactNames();

          final String userNumber = await LocalStorage.getUserPhone() ?? '';
          final String senderName = await LocalStorage.getUserName() ?? '';
          String receiverNumber = '';
          String senderNumber = '';
          final firebaseStorage = FirebaseCloudStorage();
          final message =
              'I need emergency help! I\'m at ${await generateLocationLink()}.';

          for (int i = 0; i < trustedContacts.length; ++i) {
            String chatRoomId = trustedContacts[i].substring(6);

            if (chatRoomId.substring(0, 11).compareTo(userNumber) == 0) {
              receiverNumber = chatRoomId.substring(12);
              senderNumber = chatRoomId.substring(0, 11);
            } else {
              receiverNumber = chatRoomId.substring(0, 11);
              senderNumber = chatRoomId.substring(12);
            }

            final receiverName = trustedContactNames[i];
            final chatRoomRef = await firebaseStorage.getDocumentReference(
                chatsCollectionName, chatRoomId);
            firebaseStorage.sendMessage(senderNumber, receiverNumber,
                senderName, receiverName, message, chatRoomId, chatRoomRef);

            if (receiverNumber.compareTo(adminNumber) == 0) continue;
            if (shaked) {
              sendBackgroundMessage(receiverNumber, message);
              shaked = false;
            }
          }
          await Future.delayed(const Duration(seconds: 10));
        }
      },
    );
    _shakeDetector.startListening();
    super.initState();
  }

  @override
  void dispose() {
    _shakeDetector.stopListening();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: NavigationBar(
        height: 80,
        elevation: 0,
        indicatorColor: softBlueColor,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        surfaceTintColor: blackColor,
        backgroundColor: whiteColor,
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _onItemTapped(index);
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(
              Icons.home_outlined,
              size: 28,
              color: blackColor,
            ),
            label: 'Home',
          ),
          NavigationDestination(
            icon: FaIcon(
              FontAwesomeIcons.comments,
              size: 21,
              color: blackColor,
            ),
            label: 'Chat',
          ),
          NavigationDestination(
              icon: Icon(
                Icons.report_gmailerrorred,
                color: blackColor,
                size: 26,
              ),
              label: 'Report'),
          NavigationDestination(
            icon: FaIcon(
              Icons.sos_rounded,
              size: 21,
              color: blackColor,
            ),
            label: 'SOS',
          ),
        ],
      ),
      body: _widgetOptions[_selectedIndex],
    );
  }
}
