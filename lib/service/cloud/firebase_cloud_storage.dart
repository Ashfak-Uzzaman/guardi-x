import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:guardix/components/toast.dart';
import 'package:guardix/service/auth/auth_exception.dart';
import 'package:guardix/service/auth/auth_service.dart';
import 'package:guardix/service/cloud/model/chat.dart';
import 'package:guardix/service/cloud/model/cloud_advocate.dart';
import 'package:guardix/service/cloud/model/cloud_legal_info.dart';
import 'package:guardix/service/cloud/model/cloud_report.dart';
import 'package:guardix/service/cloud/cloud_storage_constants.dart';
import 'package:guardix/service/cloud/cloud_storage_exceptions.dart';
import 'package:guardix/service/cloud/model/cloud_report_comment.dart';
import 'package:guardix/service/cloud/model/cloud_user.dart';
import 'package:guardix/service/cloud/model/message.dart';

class FirebaseCloudStorage {
  final reports = FirebaseFirestore.instance.collection(reportCollectionName);
  final users = FirebaseFirestore.instance.collection(userCollectionName);
  final advocates =
      FirebaseFirestore.instance.collection(advocateCollectionName);
  final legalInfos =
      FirebaseFirestore.instance.collection(legalInfoCollectionName);
  final reportComments =
      FirebaseFirestore.instance.collection(reportCommentCollectionName);

  final trustedContacts = FirebaseFirestore.instance.collection(
      trustedContactCollectionName); // chatrooms of the current user

  final chatRooms = FirebaseFirestore.instance
      .collection(chatRoomCollectionName); // all chatrooms that has the chats

  final chats = FirebaseFirestore.instance.collection(chatsCollectionName);

  Stream<DocumentSnapshot<Map<String, dynamic>>> getChatsStream(
      String trustedContactDocId) {
    return trustedContacts.doc(trustedContactDocId).snapshots();
  }

  Stream<QuerySnapshot> getChatQueryStream(List<dynamic> chatRefs) {
    return FirebaseFirestore.instance
        .collection(chatsCollectionName)
        .where(
            FieldPath
                .documentId, // FieldPath.documentId is used to query by document ID
            whereIn:
                chatRefs) // whereIn allows fetching multiple documents at once // has a limit by google pagla
        .orderBy(timestampFieldName,
            descending: true) // Descending order (newest first)
        .snapshots();
  }

  Stream<QuerySnapshot> getMessagesStream(DocumentReference chatRoomDocRef) {
    return chatRoomDocRef
        .collection(messageCollectionName) // Access the messages collection
        .orderBy(timestampFieldName,
            descending: false) //Ascending order (oldest first)
        .snapshots();
  }

/*
What is batch in Firebase Firestore?
A batch in Firestore (WriteBatch) is used to perform multiple write operations (update, set, delete) in a single atomic transaction. This means all operations succeed together or fail together, ensuring data consistency and reducing unnecessary reads/writes.

Why Use a Batch?
Efficiency: Instead of updating each document individually (which triggers multiple writes and network requests), a batch groups them into one network request.
Atomicity: If any update fails, none of the updates are applied.
Performance: Reduces Firestore billing cost by minimizing the number of writes.

 */

  Future<DocumentReference> getDocumentReference(
      String collectionName, String documentId) async {
    return FirebaseFirestore.instance
        .collection(collectionName)
        .doc(documentId);
  }

  Future<void> updateMessageStatus(DocumentReference chatRoomReference) async {
    try {
      QuerySnapshot querySnapshot = await chatRoomReference
          .collection(chatRoomMessageCollectionName)
          .where(isMessageSeenFieldName, isEqualTo: false)
          .get();

      WriteBatch batch = FirebaseFirestore.instance
          .batch(); // A batch in Firestore (WriteBatch) is used to perform multiple write operations (update, set, delete) in a single atomic transaction
      // Instead of updating each document individually batch is efficient.  If any update fails, none of the updates are applied.

      for (QueryDocumentSnapshot doc in querySnapshot.docs) {
        batch.update(doc.reference, {isMessageSeenFieldName: true});
      }

      // Commit batch update
      await batch.commit();
    } catch (e) {
      throw CouldNotUpdateMessageStatus();
    }
  }

  Future<void> updateChat(
      {required String senderPhone,
      required String receiverPhone,
      required String senderName,
      required String receiverName,
      required String message,
      required Timestamp timestamp,
      required String chatRoomId,
      required DocumentReference chatRoomReference,
      required bool isRead}) async {
    Chat chat = Chat(
        chatRoomReference: chatRoomReference,
        senderPhone: senderPhone,
        receiverPhone: receiverPhone,
        senderName: senderName,
        receiverName: receiverName,
        lastMessage: message,
        timestamp: timestamp,
        isRead: isRead);

    try {
      await chats.doc(chatRoomId).set(chat.toMap());
    } catch (e) {
      throw CouldNotUpdateChat();
    }
  }

  Future<void> sendMessage(
    String senderPhone,
    String receiverPhone,
    String senderName,
    String receiverName,
    String message,
    String chatRoomId,
    DocumentReference chatRoomReference,
  ) async {
    final Timestamp timestamp = Timestamp.now();

    Message newMessage = Message(
      senderPhone: senderPhone,
      receiverPhone: receiverPhone,
      message: message,
      timestamp: timestamp,
      isSeen: false,
    );

    Chat chat = Chat(
        chatRoomReference: chatRoomReference,
        senderPhone: senderPhone,
        receiverPhone: receiverPhone,
        senderName: senderName,
        receiverName: receiverName,
        lastMessage: message,
        timestamp: timestamp,
        isRead: false);

    try {
      await chatRoomReference
          .collection(chatRoomMessageCollectionName)
          .add(newMessage.toMap());

      await chats.doc(chatRoomId).set(chat.toMap());
    } catch (e) {
      throw CouldNotSendMessage();
    }

    try {
      updateChat(
        senderPhone: senderPhone,
        receiverPhone: receiverPhone,
        senderName: senderName,
        receiverName: receiverName,
        message: message,
        timestamp: timestamp,
        chatRoomId: chatRoomId,
        chatRoomReference: chatRoomReference,
        isRead: false,
      );
    } catch (e) {
      throw CouldNotUpdateChat();
    }
  }

  // send message
  Future<void> buildChat(
      String senderPhone,
      String receiverPhone,
      String senderName,
      String receiverName,
      String receiverId,
      String message,
      String chatRoomId) async {
    DocumentReference chatRoomReference = chatRooms.doc(chatRoomId);
    DocumentReference chatReference = chats.doc(chatRoomId);
    final Timestamp timestamp = Timestamp.now();

    Message newMessage = Message(
        senderPhone: senderPhone,
        receiverPhone: receiverPhone,
        message: message,
        timestamp: timestamp,
        isSeen: false);

    Chat chat = Chat(
        chatRoomReference: chatRoomReference,
        senderPhone: senderPhone,
        receiverPhone: receiverPhone,
        senderName: senderName,
        receiverName: receiverName,
        lastMessage: message,
        timestamp: timestamp,
        isRead: false);

    try {
      await chatRoomReference.collection(chatRoomMessageCollectionName).add(
          newMessage
              .toMap()); // Here an exception is given. if I prin the e it shows: package:cloud_firestore_platform_interface/src/internal/pointer.dart': Failed assertion: line 56 pos 12: 'isDocument()': is not true.
    } catch (e) {
      throw CouldNotSendMessage();
    }

    try {
      await chats.doc(chatRoomId).set(chat.toMap());
    } catch (e) {
      throw CouldNotUpdateChat();
    }

    try {
      await addTrustedContact(chatRoomId, receiverId, chatReference);
    } catch (e) {
      throw CouldNotAddContact();
    }
  }

  Future<void> addTrustedContact(String chatRoomId, String receiverId,
      DocumentReference chatRoomReference) async {
    String userId = AuthService.firebase().currentUser!.id;
    print('userid = $userId');

    DocumentSnapshot docSnapshot = await trustedContacts.doc(userId).get();

    if (docSnapshot.exists) {
      print('hello userid = $userId');
      try {
        print('bitor -1');
        await trustedContacts.doc(userId).update({
          chatsReferenceFieldName: FieldValue.arrayUnion(
              [chatRoomReference]), // Add chatRoomId to array
        });
        print('bitor -2');
      } catch (e) {
        print('hola $e');
      }
    } else {
      print('hi userid = $userId');
      await trustedContacts.doc(userId).set({
        chatsReferenceFieldName: FieldValue.arrayUnion([
          chatRoomReference
        ]), // Add chatRoomId to array //  I want that if the array already contains thus 'chatRoomReference' not to add again and return false. how?
      });
    }
    userId = receiverId;
    print('userid = $userId');

    docSnapshot = await trustedContacts.doc(userId).get();

    if (docSnapshot.exists) {
      print('hello userid = $userId');
      await trustedContacts.doc(userId).update({
        chatsReferenceFieldName: FieldValue.arrayUnion(
            [chatRoomReference]), // Add chatRoomId to array
      });
    } else {
      print('hi userid = $userId');
      await trustedContacts.doc(userId).set({
        chatsReferenceFieldName: FieldValue.arrayUnion(
            [chatRoomReference]), // Add chatRoomId to array
      });
    }
  }

  Future<bool> isChatReferencePresent(
      String userId, String chatRoomPath) async {
    DocumentSnapshot docSnapshot = await trustedContacts.doc(userId).get();

    if (docSnapshot.exists) {
      List<dynamic> chatsReference = docSnapshot[chatsReferenceFieldName] ?? [];

      // Converting DocumentReference objects to paths
      List<String> chatPaths = chatsReference
          .map((ref) => (ref as DocumentReference)
              .path) // Extract path only. // map used to iterate over the list of DocumentReference objects
          .toList();
/*
      for (String path in chatPaths) {
        print(path); // Output: chats/01643216242_01736361622
      }
*/
      return chatPaths.contains(chatRoomPath);
    }

    return false; // Document does not exist or no chat references
  }
// getTrustedContactsName(tustedContacts);

  Future<List<String>> getTrustedContactsName(
      List<String> trustedContacts, String userPhone) async {
    String receiverNumber = '';

    List<String> contactsName = [];
    for (String items in trustedContacts) {
      String chatRoomId = items.substring(6);
      if (chatRoomId.substring(0, 11).compareTo(userPhone) == 0) {
        receiverNumber = chatRoomId.substring(12);
      } else {
        receiverNumber = chatRoomId.substring(0, 11);
      }

      try {
        QuerySnapshot snapshot = await users
            .where(userPhoneFieldName, isEqualTo: receiverNumber)
            .get();

        if (snapshot.docs.isNotEmpty) {
          DocumentSnapshot doc = snapshot
              .docs[0]; // Get the first document (assuming phone is unique)
          Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
          String userName = data![userNameFieldName];
          contactsName.add(userName);
        } else {
          showToast('An error Occured.');
        }
      } catch (e) {
        showToast('An error Occured. Check Network Connection');
      }
    }

    return contactsName; // Document does not exist or no chat references
  }

  Future<List<String>> getTrustedContacts(String userId) async {
    DocumentSnapshot docSnapshot = await trustedContacts.doc(userId).get();

    List<String> contacts = [];

    if (docSnapshot.exists) {
      List<dynamic> chatsReference = docSnapshot[chatsReferenceFieldName] ?? [];

      // Converting DocumentReference objects to paths
      List<String> chatPaths = chatsReference
          .map((ref) => (ref as DocumentReference)
              .path) // map used to iterate over the list of DocumentReference objects./ hre it Extract path only fom the ref as DocumentReference
          .toList();

      for (String path in chatPaths) {
        contacts.add(path); // chats/01643216242_01736361622
      }
    }

    return contacts; // Document does not exist or no chat references
  }

  void addNewChat({
    required String fromNumber,
    required String toNumber,
    required String fromName,
    required String toName,
    required String toId,
    required bool isAdmin,
  }) async {
    // constructing chat room ID for the two users (sorted to ensure uniqueness)
    List<String> ids = [fromNumber, toNumber];

    ids.sort(); // used sneder and receiver phone number to generate id as they are the user_id in 'users' database to make chatroom id unique.
    String chatRoomId = 'chats/${ids.join('_')}';
    String currentUserId = AuthService.firebase().currentUser!.id;

    bool x = await isChatReferencePresent(currentUserId, chatRoomId);

    if (x) {
      showToast('This contact is already added');
      return;
    }

    try {
      final message =
          isAdmin ? '' : 'Hello. I added you to my Trusted contact.';
      chatRoomId = ids.join('_');

      buildChat(
          fromNumber, toNumber, fromName, toName, toId, message, chatRoomId);

      if (!isAdmin) {
        showToast('Contact added successfully');
      }
    } catch (e) {
      throw CouldNotCreateChatsException();
    }
  }

  Future<Map<String, dynamic>?> getUserData({
    required String userId,
  }) async {
    try {
      DocumentSnapshot documentSnapshot = await users.doc(userId).get();

      var userDoc = documentSnapshot.data() as Map<String, dynamic>;
      return userDoc;
    } catch (e) {
      throw UserNotFoundAuthException();
    }
  }

  Future<Map<String, dynamic>?> getUserDataByPhone(
      {required String phone}) async {
    // Query Firestore to find the document where 'phone' field matches
    QuerySnapshot querySnapshot =
        await users.where(userPhoneFieldName, isEqualTo: phone).get();

    // Check if a matching document exists
    if (querySnapshot.docs.isNotEmpty) {
      // Return the first matched document
      return querySnapshot.docs.first.data() as Map<String, dynamic>;
    } else {
      throw UserNotFoundAuthException(); // Handle user not found case
    }
  }

  Stream<Iterable<CloudReportComment>> getAllComments({
    required String reportId,
  }) {
    return reportComments
        .doc(reportId)
        .collection(commentSubCollectionName)
        .snapshots()
        .map((event) =>
            event.docs.map((doc) => CloudReportComment.fromSnapshot(doc)));
  }

  Future<void> deleteComment({
    required String reportId,
    required String commentId,
  }) async {
    try {
      await reportComments
          .doc(reportId)
          .collection(commentSubCollectionName)
          .doc(commentId)
          .delete();
    } catch (e) {
      throw CouldNotDeleteCommentException();
    }
  }

  void addNewComment({
    required String reportId,
    required String userId,
    required String userName,
    required String comment,
  }) async {
    try {
      await reportComments
          .doc(reportId)
          .collection(commentSubCollectionName)
          .add({
        userIdFieldName: userId,
        userNameFieldName: userName,
        commentsFieldName: comment,
        createdAtFieldName: FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw CouldNotAddCommentException();
    }
  }

  Stream<Iterable<CloudLegalInfo>> getAllLegalInfos() {
    return legalInfos.snapshots().map(
        (event) => event.docs.map((doc) => CloudLegalInfo.fromSnapshot(doc)));
  }

  Future<void> deleteLegalInfo({
    required String documentId,
  }) async {
    try {
      await legalInfos.doc(documentId).delete();
    } catch (e) {
      throw CouldNotDeleteLawException();
    }
  }

  void addNewLegalInfo({
    required String lawTitle,
    required String lawDescription,
  }) async {
    try {
      await legalInfos.add({
        lawTitleFieldName: lawTitle,
        lawDescriptionFieldName: lawDescription,
      });
    } catch (e) {
      throw CouldNotCreateLawException();
    }
  }

  /// Get all the advocates
  Stream<Iterable<CloudAdvocate>> getAllAdvocates() {
    return advocates.snapshots().map(
        (event) => event.docs.map((doc) => CloudAdvocate.fromSnapshot(doc)));
  }

  Future<void> deleteAdvocate({
    required String documentId,
  }) async {
    try {
      await advocates.doc(documentId).delete();
    } catch (e) {
      throw CouldNotDeleteAdvocateException();
    }
  }

  void addNewAdvocate({
    required String advocateName,
    required String advocateType,
    required String advocateEmail,
    required String advocatePhone,
    required String advocateAddress,
  }) async {
    try {
      await advocates.add({
        advocateNameFieldName: advocateName,
        advocateTypeFieldName: advocateType,
        advocateEmailFieldName: advocateEmail,
        advocatePhoneFieldName: advocatePhone,
        advocateAddressFieldName: advocateAddress,
      });
    } catch (e) {
      throw CouldNotCreateAdvocateException();
    }
  }

  Future<CloudUser> getUser({
    required String userId,
  }) async {
    try {
      final doc = await users.doc(userId).get();
      return CloudUser.fromDocSnapshot(doc);
    } catch (e) {
      throw CouldNotGetUserException();
    }
  }

  Future<void> updateUser({
    required String userName,
    required String phone,
  }) async {
    try {
      String userId = AuthService.firebase().currentUser!.id;
      await users.doc(userId).update({
        userNameFieldName: userName,
        userPhoneFieldName: phone,
      });
    } catch (e) {
      throw CouldNotUpdateUserException();
    }
  }

  void createNewUser({
    required String userName,
    required String email,
    required String phone,
    required bool isAdmin,
  }) async {
    try {
      String userId = AuthService.firebase().currentUser!.id;
      await users.doc(userId).set({
        userIdFieldName: userId,
        userNameFieldName: userName,
        userEmailFieldName: email,
        userPhoneFieldName: phone,
        userIsAdminFieldName: isAdmin,
      });
    } catch (e) {
      throw CouldNotAddUserException();
    }
  }

  /*Future<Iterable<CloudReport>> getChats() async {
    try {
      return await reports
          .where(
            
          )
          .get()
          .then(
            (value) => value.docs.map((doc) => CloudReport.fromSnapshot(doc)),
          );
    } catch (e) {
      throw CouldNotGetAllReportsException();
    }
  }*/

  Future<void> deleteReport({
    required String documentId,
  }) async {
    try {
      await reports.doc(documentId).delete();
    } catch (e) {
      throw CouldNotDeleteReportException();
    }
  }

  /// update upvote, downvote and flags
  Future<void> updateReportUserAction({
    required String documentId,
    required int flags,
    required int upvotes,
    required int downvotes,
    required Map<String, List<String>> userActions,
  }) async {
    await reports.doc(documentId).update({
      flagsFieldName: flags,
      upvotesFieldName: upvotes,
      downvotesFieldName: downvotes,
      userActionsFieldName: userActions,
    });
  }

  /// update a report status
  Future<void> updateReport({
    required String documentId,
    required String victimName,
    required String victimAddress,
    required String victimContact,
    required String witnessName,
    required String witnessContact,
    required String dateOfCrime,
    required String timeOfCrime,
    required String locationOfCrime,
    required String descriptionOfCrime,
    required String injuryType,
    required String policeStation,
    required String reportStatus,
    required int flags,
    required int upvotes,
    required int downvotes,
    required Map<String, List<String>> userActions,
  }) async {
    try {
      await reports.doc(documentId).update({
        victimNameFieldName: victimName,
        victimAddressFieldName: victimAddress,
        victimContactFieldName: victimContact,
        witnessNameFieldName: witnessName,
        witnessContactFieldName: witnessContact,
        dateOfCrimeFieldName: dateOfCrime,
        timeOfCrimeFieldName: timeOfCrime,
        locationOfCrimeFieldName: locationOfCrime,
        descriptionOfCrimeFieldName: descriptionOfCrime,
        injuryTypeFieldName: injuryType,
        policeStationFieldName: policeStation,
        reportStatusFieldName: reportStatus,
        flagsFieldName: flags,
        upvotesFieldName: upvotes,
        downvotesFieldName: downvotes,
        userActionsFieldName: userActions,
      });
    } catch (e) {
      throw CouldNotUpdateReportException();
    }
  }

  Future<CloudReport> getReport({
    required String documentId,
  }) async {
    try {
      final doc = await reports.doc(documentId).get();
      return CloudReport.fromDocSnapshot(doc);
    } catch (e) {
      throw CouldNotGetReportException();
    }
  }

  Stream<CloudReport> getReportStream({
    required String documentId,
  }) {
    try {
      return reports.doc(documentId).snapshots().map((doc) {
        return CloudReport.fromDocSnapshot(doc);
      });
    } catch (e) {
      throw CouldNotGetReportException();
    }
  }

  /// Get all the reports of that category live as they are occuring in reports collection
  // Stream<Iterable<CloudReport>> allCategoryReports({
  //   String? category,
  //   bool? flag,
  // }) {
  //   return reports.snapshots().map(
  //         (event) =>
  //             event.docs.map((doc) => CloudReport.fromSnapshot(doc)).where(
  //                   (report) =>
  //                       (category == null ||
  //                           category == '' ||
  //                           report.category == category) &&
  //                       (flag == null || !flag || (flag && report.flags > 0)),
  //                 ),
  //       );
  // }

  Stream<Iterable<CloudReport>> allCategoryReports({
    String? category,
    bool? flag,
    bool? sortByUpvote,
    bool? sortByLatest,
  }) {
    Query<Map<String, dynamic>> query = reports;

    if (sortByUpvote == true) {
      query = query.orderBy(upvotesFieldName, descending: true);
    }

    if (sortByLatest == true) {
      query = query.orderBy(createdAtFieldName, descending: true);
    }

    return query.snapshots().map(
          (event) =>
              event.docs.map((doc) => CloudReport.fromSnapshot(doc)).where(
                    (report) =>
                        (category == null ||
                            category.isEmpty ||
                            report.category == category) &&
                        (flag == null || !flag || (flag && report.flags > 0)),
                  ),
        );
    // return reports.snapshots().map(
    //   (event) {
    //   final reportsList = event.docs
    //       .map((doc) => CloudReport.fromSnapshot(doc))
    //       .where(
    //         (report) =>
    //             (category == null ||
    //                 category == '' ||
    //                 report.category == category) &&
    //             (flag == null || !flag || (flag && report.flags > 0)),
    //       )
    //       .toList();

    //     if (sortByUpvote == true) {
    //       reportsList.sort((a, b) => b.upvotes.compareTo(a.upvotes));
    //     }

    //     if (sortByLatest == true) {
    //       reportsList.sort((a, b) {
    //         final dateTimeA = mergeDateTime(a.dateOfCrime, a.timeOfCrime);
    //         final dateTimeB = mergeDateTime(b.dateOfCrime, b.timeOfCrime);

    //         return dateTimeB.compareTo(dateTimeA);
    //       });
    //     }
    //     return reportsList;
    //   },
    // );
  }

  /// Get all the reports of current user
  Stream<Iterable<CloudReport>> getMyReports({
    required String userEmail,
    String? reportStatus,
  }) {
    return reports
        .orderBy(createdAtFieldName, descending: true)
        .snapshots()
        .map(
          (event) => event.docs
              .map((doc) => CloudReport.fromSnapshot(doc))
              .where((report) =>
                  (reportStatus == null ||
                      reportStatus == '' ||
                      report.reportStatus == reportStatus) &&
                  report.ownerEmail == userEmail),
        );
  }

  /// Takes a snapshot at a point of time, and returns
  Future<Iterable<CloudReport>> getCategoryReports({
    required String category,
  }) async {
    try {
      return await reports
          .where(
            categoryFieldName,
            isEqualTo: category,
          )
          .get()
          .then(
            (value) => value.docs.map((doc) => CloudReport.fromSnapshot(doc)),
          );
    } catch (e) {
      throw CouldNotGetAllReportsException();
    }
  }

  void createNewReport({
    required String ownerEmail,
    required String ownerName,
    required String category,
    required String victimName,
    required String victimAddress,
    required String victimContact,
    required String witnessName,
    required String witnessContact,
    required String dateOfCrime,
    required String timeOfCrime,
    required String locationOfCrime,
    required String descriptionOfCrime,
    required String injuryType,
    required String policeStation,
    required String reportStatus,
    required int flags,
    required int upvotes,
    required int downvotes,
  }) async {
    try {
      await reports.add({
        ownerEmailFieldName: ownerEmail,
        ownerNameFieldName: ownerName,
        categoryFieldName: category,
        victimNameFieldName: victimName,
        victimAddressFieldName: victimAddress,
        victimContactFieldName: victimContact,
        witnessNameFieldName: witnessName,
        witnessContactFieldName: witnessContact,
        dateOfCrimeFieldName: dateOfCrime,
        timeOfCrimeFieldName: timeOfCrime,
        locationOfCrimeFieldName: locationOfCrime,
        descriptionOfCrimeFieldName: descriptionOfCrime,
        injuryTypeFieldName: injuryType,
        policeStationFieldName: policeStation,
        reportStatusFieldName: reportStatus,
        flagsFieldName: flags,
        upvotesFieldName: upvotes,
        downvotesFieldName: downvotes,
        createdAtFieldName: FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw CouldNotCreateReportException();
    }
  }

  static final FirebaseCloudStorage _shared =
      FirebaseCloudStorage._sharedInstance();

  // private constructor
  FirebaseCloudStorage._sharedInstance();
  // factory constructor
  factory FirebaseCloudStorage() => _shared;
}
