import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:guardix/constants/colors.dart';
import 'package:guardix/service/auth/auth_service.dart';
import 'package:guardix/service/cloud/firebase_cloud_storage.dart';
import 'package:guardix/views/chat/chat_list_view.dart';
import 'package:guardix/views/drawer/contacts/add_contact_view.dart';

class ChatView extends StatefulWidget {
  const ChatView({super.key});

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final String trustedContactDocId = AuthService.firebase().currentUser!.id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Emergency Message',
          style: TextStyle(color: whiteColor),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const AddContactsView()),
              );
            },
            icon: const FaIcon(
              FontAwesomeIcons.userPlus,
              size: 20,
              color: whiteColor,
            ),
          ),
        ],
        centerTitle: true,
        backgroundColor: midnightBlueColor,
      ),
      // This widget ( StreamBuilder<DocumentSnapshot>) listens to a real-time stream of a Firestore document.
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseCloudStorage().getChatsStream(trustedContactDocId),
        builder: (context, trustedContactSnapshot) {
          if (trustedContactSnapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!trustedContactSnapshot
                  .hasData || //  not fetched data from Firestore
              !trustedContactSnapshot.data!.exists) {
            // !trustedContactSnapshot.data!.exists: If the document itself does not exist in Firestore.
            return const Center(child: Text("No Trusted Contacts"));
          }

          List<dynamic> chatRefs =
              trustedContactSnapshot.data!.get('chats_reference');

          if (chatRefs.isEmpty) {
            return const Center(child: Text("No chats available!"));
          }

          return Padding(
            padding: const EdgeInsets.fromLTRB(8.0, 16.0, 8.0, 8.0),
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseCloudStorage().getChatQueryStream(chatRefs),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No Chats Available!"));
                }

                List<DocumentSnapshot> chatDocs = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: chatDocs.length,
                  itemBuilder: (context, index) {
                    var chatData = chatDocs[index];

                    return StreamBuilder<DocumentSnapshot>(
                      stream: chatData.reference.snapshots(),
                      builder: (context, chatSnapshot) {
                        if (chatSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        if (!chatSnapshot.hasData ||
                            !chatSnapshot.data!.exists) {
                          return const SizedBox.shrink();
                        }

                        var currentChatData = chatSnapshot.data!;

                        return FutureBuilder<GestureDetector>(
                          future: chatListView(context, currentChatData),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }
                            if (snapshot.hasError) {
                              return const Center(
                                  child: Text("Error loading chat"));
                            }
                            if (!snapshot.hasData) {
                              return const SizedBox.shrink();
                            }
                            return snapshot
                                .data!; // If the future completes but returns null, show an empty widget.
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
