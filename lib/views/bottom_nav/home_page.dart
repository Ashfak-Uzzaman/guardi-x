import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:guardix/constants/colors.dart';
import 'package:guardix/constants/routes.dart';
import 'package:guardix/utilities/decorations/banner_text_decoration.dart';
import 'package:guardix/utilities/decorations/card_decoration.dart';
import 'package:url_launcher/url_launcher.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<Map<String, dynamic>> _banners = [
    {
      'title': "Stay Alert",
      'text': "Report suspicious activities immediately to keep your community safe.",
      'backgroundColors': [Colors.blue, Colors.black],
      'textColor': whiteColor,
    },
    {
      'title': "Protect What Matters",
      'text': "Always secure personal belongings in public spaces.",
      'backgroundColors': [const Color(0xFF64B5F6), const Color(0xFFE0E0E0)],
      'textColor': blackColor,
    },
    {
      'title': "Safety First",
      'text': "Share your live location with trusted contacts in emergencies.",
      'backgroundColors': [const Color(0xFF2196F3), const Color(0xFF4DB6AC)],
      'textColor': whiteColor,
    },
    {
      'title': "Be Aware",
      'text': "Know your surroundings and avoid isolated areas at night.",
      'backgroundColors': [const Color(0xFF673AB7), const Color(0xFFE91E63)],
      'textColor': whiteColor,
    },
    {
      'title': "Community Power",
      'text': "Together we can fight crime by reporting incidents quickly.",
      'backgroundColors': [const Color(0xFFFF9800), const Color(0xFFFFEB3B)],
      'textColor': blackColor,
    },
  ];


  void _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );

    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      _showSnackBar('Could not launch the dialer');
    }
  }

  void _sendMessage(String phoneNumber) async {
    final Uri smsUri = Uri(
      scheme: 'sms',
      path: phoneNumber,
    );

    if (await canLaunchUrl(smsUri)) {
      await launchUrl(smsUri);
    } else {
      _showSnackBar('Could not launch the messaging app');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  int _currentBannerId = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          children: [
            Column(
              children: [
                const SizedBox(height: 5),
                CarouselSlider(
                  options: CarouselOptions(
                    aspectRatio: 16 / 8,
                    viewportFraction: 0.8,
                    initialPage: 0,
                    enableInfiniteScroll: true,
                    reverse: false,
                    autoPlay: true,
                    autoPlayInterval: const Duration(seconds: 3),
                    autoPlayAnimationDuration:
                        const Duration(milliseconds: 800),
                    autoPlayCurve: Curves.fastOutSlowIn,
                    enlargeCenterPage: true,
                    enlargeFactor: 0.3,
                    scrollDirection: Axis.horizontal,
                    onPageChanged: (index, reason) {
                      setState(() {
                        _currentBannerId = index;
                      });
                    },
                  ),
                  items: _banners.map((item) {
                    return Builder(
                      builder: (BuildContext context) {
                        return Container(
                          width: MediaQuery.of(context).size.width,
                          margin: const EdgeInsets.symmetric(horizontal: 5.0),
                          decoration: BoxDecoration(
                            color: softBlueColor,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: buildBannerDecoration(
                            title: item['title'],
                            text: item['text'],
                            backgroundColor: item['backgroundColors'],
                            titleColor: item['textColor'],
                            textColor: item['textColor'],
                            borderRadius: 15,
                          ),
                        );
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (int i = 0; i < _banners.length; i++)
                      Container(
                        width: i == _currentBannerId ? 20 : 10,
                        height: i == _currentBannerId ? 4 : 3,
                        margin: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: i == _currentBannerId
                              ? midnightBlueColor
                              : softBlueColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        buildCard(
                          context: context,
                          icon: Icons.warning,
                          text: 'Want to report a crime?',
                          onTap: () {
                            Navigator.of(context).pushNamed(selectCategoryRoute);
                          },
                        ),
                        const SizedBox(width: 12),
                        buildCard(
                          context: context,
                          icon: Icons.history,
                          text: 'View Your Case History',
                          onTap: () {
                            Navigator.of(context).pushNamed(trackRoute);
                          },
                        ),
                        const SizedBox(width: 12),
                        buildCard(
                          context: context,
                          icon: Icons.live_help,
                          text: 'Ongoing Incidents',
                          onTap: () {
                            Navigator.of(context).pushNamed(ongoingIncidentsRoute);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    height: 350,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10.0),
                      color: safetyOrangeColor,
                      boxShadow: const [
                        BoxShadow(
                          color: lightGreyColor,
                          blurRadius: 3.0,
                          offset: Offset(2.0, 2.0),
                        ),
                      ],
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Icon(
                            Icons.map_outlined,
                            size: 80,
                          ),
                          Text(
                            'Google Map Here',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: blackColor,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    'Find Expert Advocates for Your Legal Needs',
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      color: blackColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Container(
                            constraints: const BoxConstraints(
                              minWidth: 150,
                              maxWidth: 200,
                            ),
                            decoration: BoxDecoration(
                              color: softBlueColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Image.asset(
                                  'assets/images/lawyer_icon.png',
                                  height: 50,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Mr. Abc Xyz',
                                        style: TextStyle(
                                          color: midnightBlueColor,
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const Text(
                                        'Crime Lawyer',
                                        style: TextStyle(
                                          color: blackColor,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          IconButton(
                                            onPressed: () =>
                                                _makePhoneCall('123999'),
                                            icon: const Icon(
                                              Icons.call,
                                              color: midnightBlueColor,
                                            ),
                                          ),
                                          IconButton(
                                            onPressed: () =>
                                                _sendMessage('123999'),
                                            icon: const Icon(
                                              Icons.message,
                                              color: midnightBlueColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Container(
                            constraints: const BoxConstraints(
                              minWidth: 150,
                              maxWidth: 200,
                            ),
                            decoration: BoxDecoration(
                              color: softBlueColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Image.asset(
                                  'assets/images/lawyer_icon.png',
                                  height: 50,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Mr. Abc Xyz',
                                        style: TextStyle(
                                          color: midnightBlueColor,
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const Text(
                                        'Crime Lawyer',
                                        style: TextStyle(
                                          color: blackColor,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          IconButton(
                                            onPressed: () =>
                                                _makePhoneCall('123888'),
                                            icon: const Icon(
                                              Icons.call,
                                              color: midnightBlueColor,
                                            ),
                                          ),
                                          IconButton(
                                            onPressed: () =>
                                                _sendMessage('123888'),
                                            icon: const Icon(
                                              Icons.message,
                                              color: midnightBlueColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
