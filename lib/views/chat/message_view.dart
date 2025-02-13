import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:guardix/components/toast.dart';
import 'package:guardix/constants/colors.dart';
import 'package:guardix/service/cloud/cloud_storage_constants.dart';
import 'package:guardix/service/cloud/firebase_cloud_storage.dart';
import 'package:guardix/utilities/dialogs/choose_image_source_dialog.dart';
import 'package:guardix/utilities/helpers/format_timestamp.dart';
import 'package:guardix/utilities/helpers/generate_location_link.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart'; // Import url_launcher

class MessageView extends StatefulWidget {
  final DocumentReference chatRoomDocRef;
  final String chatRoomId;
  final String currentUserName;
  final String currentUserNumber;
  final String chatPersonName;
  final String chatPersonNumber;
  final String chatLastMessage;
  final Timestamp timestamp;
  final bool isRead;

  const MessageView({
    required this.chatRoomId,
    required this.chatRoomDocRef,
    required this.currentUserName,
    required this.chatPersonName,
    required this.currentUserNumber,
    required this.chatPersonNumber,
    required this.chatLastMessage,
    required this.timestamp,
    required this.isRead,
    super.key,
  });

  @override
  State<MessageView> createState() => _MessageViewState();
}

class _MessageViewState extends State<MessageView> {
  late TextEditingController _messageController;
  late ScrollController _scrollController; // Scroll controller

  late final ImagePicker _imagePicker;
  // ignore: unused_field
  XFile? _selectedImage;

  Future<void> _pickImage({
    required ImageSource source,
  }) async {
    final XFile? image = await _imagePicker.pickImage(source: source);
    if (image != null) {
      setState(() {
        _selectedImage = image;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
    // _messageController.addListener(
    //   () {
    //     setState(() {
    //       _isTextFieldEmpty = _messageController.text.isEmpty;
    //     });
    //   },
    // );
    _scrollController = ScrollController();
    _imagePicker = ImagePicker();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Function to open a link in browser or maps
  void _openLink(String url) async {
    Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      showToast('Can\'t launch URL');
    }
  }

  void _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );

    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {}
  }

  // Function to scroll to the bottom
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Row(
          children: [
            IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: whiteColor,
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
        title: Text(
          widget.chatPersonName,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: whiteColor,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const FaIcon(
              FontAwesomeIcons.video,
              size: 20,
              color: whiteColor,
            ),
          ),
          IconButton(
            onPressed: () => _makePhoneCall(widget.chatPersonNumber),
            icon: const Icon(
              Icons.phone,
              color: whiteColor,
            ),
          ),
        ],
        backgroundColor: midnightBlueColor,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseCloudStorage()
                  .getMessagesStream(widget.chatRoomDocRef),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No messages yet."));
                }

                final messages = snapshot.data!.docs;

                // print('receiver -> $receiver');

                // // Scroll to bottom when new messages arrive
                // WidgetsBinding.instance.addPostFrameCallback((_) {
                //   if (receiver.compareTo(widget.currentUserNumber) == 0) {
                //     print('hola');
                //     FirebaseCloudStorage()
                //         .updateMessageStatus(widget.chatRoomDocRef);
                //   }
                // _scrollToBottom();
                // });

                // Scroll to bottom when new messages arrive

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                });

                return ListView.builder(
                  controller: _scrollController, // Attach ScrollController
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    var data = messages[index].data() as Map<String, dynamic>;
                    final String message = data[messageFieldName];
                    // bool isLink = message.startsWith('http://') ||
                    //     message.startsWith('https://');

                    RegExp urlRegex = RegExp(r'(https?:\/\/|www\.)\S+');
                    Iterable<Match> matches = urlRegex.allMatches(message);
                    bool isLink = false;
                    int? startIndex, endIndex;
                    for (final match in matches) {
                      // ignore: unused_local_variable
                      String url = match.group(0)!; // The matched URL
                      isLink = true;
                      startIndex = match.start; // The start index of the URL
                      endIndex =
                          match.end; // The end index of the URL (exclusive)
                      // print(url);
                      // print(isLink);
                      // print(startIndex);
                      // print(endIndex);
                      break;
                    }

                    bool isMe =
                        widget.currentUserNumber == data[senderPhoneFieldName];

                    return Align(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 8.0),
                        child: _buildMessageBubble(
                            data, isMe, message, isLink, startIndex, endIndex),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10.0, 8.0, 10.0, 8.0),
            child: Container(
              decoration: BoxDecoration(
                color: whiteColor,
                borderRadius: BorderRadius.circular(30.0),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.grey,
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.blue,
                      size: 30.0,
                    ),
                    onPressed: () {
                      showImageSourceDialog(
                        context: context,
                      ).then(
                        (value) {
                          if (value == 'camera') {
                            _pickImage(source: ImageSource.camera);
                          } else if (value == 'gallery') {
                            _pickImage(source: ImageSource.gallery);
                          }
                        },
                      );
                    },
                  ),
                  IconButton(
                    onPressed: () async {
                      generateLocationLink().then(
                        (value) {
                          if (value != 'Error') {
                            if (_messageController.text.isEmpty) {
                              _messageController.text = value;
                            } else {
                              _messageController.text += ' $value ';
                            }
                          }
                        },
                      );
                    },
                    icon: const FaIcon(
                      FontAwesomeIcons.locationDot,
                      color: Colors.blue,
                      size: 28.0,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      keyboardType: TextInputType.multiline,
                      minLines: 1,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        hintText: "Send Message...",
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 26.0,
                      ),
                      onPressed: () {
                        if (_messageController.text.isNotEmpty) {
                          FirebaseCloudStorage().sendMessage(
                            widget.currentUserNumber,
                            widget.chatPersonNumber,
                            widget.currentUserName,
                            widget.chatPersonName,
                            _messageController.text,
                            widget.chatRoomId,
                            widget.chatRoomDocRef,
                          );
                          _messageController.clear();
                          _scrollToBottom();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget to build message bubbles
  Widget _buildMessageBubble(Map<String, dynamic> data, bool isMe,
      String message, bool isLink, int? linkStart, int? linkEnds) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: MediaQuery.of(context).size.width *
              0.33, // At least 1/3 screen width
          maxWidth: MediaQuery.of(context).size.width *
              0.7, // At most 70% screen width
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color:
                isMe ? Colors.blue[600] : Colors.grey[200], // Adjusted colors
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(isMe ? 12 : 0),
              topRight: Radius.circular(isMe ? 0 : 12),
              bottomLeft: const Radius.circular(12),
              bottomRight: const Radius.circular(12),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Message text with link detection
              _displayMessage(
                  message: message,
                  isLink: isLink,
                  isMe: isMe,
                  linkStart: linkStart,
                  linkEnds: linkEnds),
              const SizedBox(
                  height: 6), // Spacing between message and timestamp
              // Timestamp and read status
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    formatTimestamp(data[timestampFieldName], true),
                    style: TextStyle(
                      color: isMe ? Colors.white70 : Colors.grey[600],
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(
                      width: 4), // Spacing between timestamp and icon
                  if (isMe)
                    Icon(
                      data[isMessageSeenFieldName]
                          ? Icons.done_all
                          : Icons.done,
                      size: 16,
                      color: data[isMessageSeenFieldName]
                          ? const Color.fromARGB(255, 0, 255, 64)
                          : whiteColor,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _displayMessage({
    required String message,
    required bool isLink,
    required bool isMe,
    int? linkStart,
    int? linkEnds,
  }) {
    if (!isLink || linkStart == null || linkEnds == null) {
      return Text(
        message,
        style: TextStyle(
          color: isMe ? Colors.white : Colors.black87,
          decorationColor: isMe ? Colors.white : Colors.blue,
        ),
      );
    }

    // Splitting the message into three parts: before, link, and after
    String beforeLink = message.substring(0, linkStart);
    String linkText = message.substring(linkStart, linkEnds);
    String afterLink = message.substring(linkEnds);

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
              text: beforeLink,
              style: TextStyle(color: isMe ? Colors.white : Colors.black87)),
          TextSpan(
            text: linkText,
            style: TextStyle(
              color: isMe ? Colors.white : Colors.black87,
              decoration: TextDecoration.underline,
              decorationColor: isMe ? Colors.grey[200] : blackColor,
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () {
                _openLink(linkText);
              },
          ),
          TextSpan(
              text: afterLink,
              style: TextStyle(color: isMe ? Colors.white : Colors.black87)),
        ],
      ),
    );
  }
}
