import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:guardix/components/toast.dart';
import 'package:guardix/constants/colors.dart';
import 'package:guardix/service/auth/auth_exception.dart';
import 'package:guardix/service/cloud/cloud_storage_constants.dart';
import 'package:guardix/service/cloud/cloud_storage_exceptions.dart';
import 'package:guardix/service/cloud/firebase_cloud_storage.dart';

import 'package:guardix/utilities/dialogs/contact_not_registered_dialog.dart';
import 'package:guardix/utilities/dialogs/error_dialog.dart';
import 'package:guardix/utilities/helpers/local_storage.dart';
import 'package:guardix/utilities/helpers/make_phone_message_email.dart';

class AddContactsView extends StatefulWidget {
  const AddContactsView({super.key});

  @override
  State<AddContactsView> createState() => _AddContactsViewState();
}

class _AddContactsViewState extends State<AddContactsView> {
  List<Contact>? _contacts;
  List<Contact>? _filteredContacts;
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchContacts();
    _searchController.addListener(_filterContacts);
  }

  Future<void> addToContact(String phone) async {
    String contactName;
    String contactId;

    if (phone.isNotEmpty) {
      String userNumber = await LocalStorage.getUserPhone() ?? '';
      String userName = await LocalStorage.getUserName() ?? '';
      try {
        var user =
            await FirebaseCloudStorage().getUserDataByPhone(phone: phone);

        contactName = user?[userNameFieldName];
        contactId = user?[userIdFieldName];

        try {
          FirebaseCloudStorage().addNewChat(
              fromNumber: userNumber,
              toNumber: phone,
              fromName: userName,
              toName: contactName,
              toId: contactId,
              isAdmin: false);

          List<String> ids = [userNumber, phone];

          ids.sort();
          String chatRoomId = 'chats/${ids.join('_')}';

          LocalStorage.addTrustedContact(chatRoomId, contactName);
        } on CouldNotCreateChatsException {
          if (mounted) {
            showErrorDialog(
                context, 'Faild to add the number. Please try again.');
          }
        }
      } on UserNotFoundAuthException {
        bool share = false;
        if (mounted) {
          share = await showContactNotRegistered(context: context);
        }

        if (mounted) {
          if (share) {
            //sendBackgroundMessage(context, phone, 'Emergency Message');
            sendMessage(context, phone,
                'Download and Install \'Guardi-X\'\nhttps://github.com/Ashfak-Uzzaman/guardi-x');
          }
        }
      } catch (e) {
        if (mounted) {
          showErrorDialog(context, 'An error occured');
        }
      }
    }
  }

  Future<List<Contact>> getContactsFromPhoneNumbers(
      List<String> phoneNumbers) async {
    // Fetch all contacts with their phone numbers
    List<Contact> contacts = await FlutterContacts.getContacts(
        withProperties: true, withPhoto: true);

    List<Contact> matchedContacts = contacts.where((contact) {
      return contact.phones.any((phone) => phoneNumbers.contains(phone.number));
    }).toList();

    return matchedContacts;
  }

/*
  Future<void> _fetchRegisteredContacts() async {
    // Step 1: Get phone contacts (only numbers)
    List<Contact> contacts = await FlutterContacts.getContacts(
        withProperties: true, withPhoto: true);
    // Extract and normalize phone numbers
    List<String> phoneNumbers = contacts
        .expand((contact) => contact.phones.map((phone) => phone.number))
        .toList();
    if (phoneNumbers.isEmpty) {
      setState(() {
        _contacts = [];
        _isLoading = false;
      });
      return;
    }
    // Step 2: Query Firestore for matching phone numbers
    List<Contact> matchedContacts = [];
    // 'whereIn' supports a max of 10 values per query, so we split into batches
    for (int i = 0; i < phoneNumbers.length; i += 10) {
      List<String> subList = phoneNumbers.sublist(
          i, (i + 10 > phoneNumbers.length) ? phoneNumbers.length : i + 10);
      try {
        QuerySnapshot snapshot = await FirebaseFirestore.instance
            .collection('Users')
            .where(FieldPath.documentId, whereIn: subList)
            .get();
        // Step 3: Match Firestore users with phone contacts
        for (var doc in snapshot.docs) {
          String phoneNumber = doc.id; // Document ID is the phone number
          // Find contact from local contacts list
          Contact? matchedContact = contacts.firstWhereOrNull(
            (contact) =>
                contact.phones.any((phone) => phone.number == phoneNumber),
          );
          if (matchedContact != null) matchedContacts.add(matchedContact);
        }
      } catch (e) {
        print("Error fetching contacts from Firestore: $e");
      }
    }
    // Step 4: Update _contacts and UI
    setState(() {
      _contacts = matchedContacts;
      _filteredContacts = _contacts;
      _isLoading = false;
    });
  }
*/

  Future _fetchContacts() async {
    if (await FlutterContacts.requestPermission()) {
      final contacts = await FlutterContacts.getContacts(
          withProperties: true, withPhoto: true);

      setState(() {
        _contacts = contacts;
        _filteredContacts = contacts;
        _isLoading = false;
      });
    } else {
      // ignore: use_build_context_synchronously
      showErrorDialog(context, 'Permission Denied');
    }
  }

  void _filterContacts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredContacts = _contacts
          ?.where((contact) =>
              contact.displayName.length >= query.length &&
                  contact.displayName
                          .toLowerCase()
                          .substring(0, query.length) ==
                      query ||
              contact.phones.any((phone) =>
                  phone.number.length >= query.length &&
                  phone.number.toLowerCase().substring(0, query.length) ==
                      query))
          .toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: whiteColor,
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              )
            : null,
        title: const Text(
          'Your Contacts',
          style: TextStyle(color: whiteColor),
        ),
        centerTitle: true,
        backgroundColor: midnightBlueColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Search Contacts',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  // Prevents layout errors. Without Expanded, the Column widget containing the search bar and ListView.builder might cause an error.
                  // This happens because ListView.builder is infinite in height by default, and Flutter needs to know how much space it should take.
                  // Expanded forces it to fill the 'remaining space' inside the Column. Visual explanation is given bellow of the code!!
                  child: _filteredContacts == null || _filteredContacts!.isEmpty
                      ? const Center(child: Text('No Contact Found'))
                      : ListView.builder(
                          itemCount: _filteredContacts!.length,
                          itemBuilder: (context, index) {
                            Contact contact = _filteredContacts![index];
                            return ListTile(
                              onTap: () {
                                try {
                                  String phone = contact.phones.first.number
                                      .replaceAll(RegExp(r'\D'),
                                          ''); // Removes all non-digits

                                  if (phone.startsWith('88')) {
                                    phone = phone.substring(2, phone.length);
                                  }

                                  addToContact(phone);
                                } catch (e) {
                                  showToast('Empty Contact');
                                }
                              },
                              title: Text(contact.displayName.isNotEmpty
                                  ? contact.displayName
                                  : "Unnamed Contact"),
                              subtitle: Text(contact.phones.isNotEmpty
                                  ? contact.phones.first.number
                                  : "Number Not Added"),
                              leading: (contact.photo != null &&
                                      contact.photo!.isNotEmpty)
                                  ? CircleAvatar(
                                      backgroundImage:
                                          MemoryImage(contact.photo!))
                                  : CircleAvatar(
                                      child: Text(contact.displayName.isNotEmpty
                                          ? contact.displayName[0]
                                          : '#')),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

/*
Without Expanded (❌ Incorrect behavior):
+----------------------+
| Search Bar (fixed)  |
+----------------------+
|                     |  
|   ListView (grows)  |  ❌ Might cause overflow issues
|                     |
+----------------------+
 */

/*
With Expanded (✅ Correct behavior):
+----------------------+
| Search Bar (fixed)  |
+----------------------+
|                     |  
|   ListView (fills)  |  ✅ Proper layout
|                     |
+----------------------+
 */
