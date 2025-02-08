import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:guardix/service/auth/auth_exception.dart';
import 'package:guardix/service/auth/auth_service.dart';
import 'package:guardix/service/cloud/models/chat.dart';

import 'package:guardix/service/cloud/models/cloud_report.dart';
import 'package:guardix/service/cloud/cloud_storage_constants.dart';
import 'package:guardix/service/cloud/cloud_storage_exceptions.dart';
import 'package:guardix/service/cloud/models/message.dart';

class FirebaseCloudStorage {
  final reports = FirebaseFirestore.instance.collection(reportCollectionName);

  final users = FirebaseFirestore.instance.collection(userCollectionName);

  final trustedContacts = FirebaseFirestore.instance.collection(
      trustedContactCollectionName); // chatrooms of the current user

  final chatRooms = FirebaseFirestore.instance
      .collection(chatRoomCollectionName); // all chatrooms that has the chats

  final chats = FirebaseFirestore.instance.collection(chatsCollectionName);

  Stream<DocumentSnapshot<Map<String, dynamic>>> getChatsStream(
      String trustedContactDocId) {
    return trustedContacts.doc(trustedContactDocId).snapshots();
  }

  // send message
  Future<void> buildChat(
      String senderPhone, String receiverPhone, message) async {
    // construct chat room ID for the two users (sorted to ensure uniqueness)
    List<String> ids = [senderPhone, receiverPhone];

    ids.sort(); // used sneder and receiver phone number to generate id as they are the user_id in 'users' database to make chatroom id unique.
    String chatRoomID = ids.join('_');
    DocumentReference chatRoomReference = chatRooms.doc(chatRoomID);
    DocumentReference chatReference = chats.doc(chatRoomID);
    final Timestamp timestamp = Timestamp.now();
    //print('$senderPhone $receiverPhone');

    Message newMessage = Message(
      senderPhone: senderPhone,
      receiverPhone: receiverPhone,
      message: message,
      timestamp: timestamp,
    );

    Chat chat = Chat(
        chatRoomReference: chatRoomReference,
        senderPhone: senderPhone,
        lastMessage: message,
        timestamp: timestamp);

    try {
      chatRoomReference
          .collection(chatRoomMessageCollectionName)
          .add(newMessage.toMap());
    } catch (e) {
      throw CouldNotSendMessage();
    }

    try {
      chats.doc(chatRoomID).set(chat.toMap());
    } catch (e) {
      throw CouldNotUpdateChat();
    }

    try {
      addTrustedContact(chatRoomID, chatReference);
    } catch (e) {
      throw CouldNotAddContact();
    }
  }

  Future<void> addTrustedContact(
      String chatRoomId, DocumentReference chatRoomReference) async {
    final String userId = AuthService.firebase().currentUser!.id;

    DocumentSnapshot docSnapshot = await trustedContacts.doc(userId).get();

    if (docSnapshot.exists) {
      await trustedContacts.doc(userId).update({
        'chats_reference': FieldValue.arrayUnion(
            [chatRoomReference]), // Add chatRoomId to array
      });
    } else {
      await trustedContacts.doc(userId).set({
        'chats_reference': FieldValue.arrayUnion(
            [chatRoomReference]), // Add chatRoomId to array
      });
    }
  }

  void addNewChat({
    required String fromNumber,
    required String toNumber,
  }) async {
    try {
      const message = 'Hello.\n I am added you to my trusted contact. Thanks';
      buildChat(fromNumber, toNumber, message);
    } catch (e) {
      throw CouldNotCreateChats();
    }
  }

  Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      QuerySnapshot querySnapshot =
          await users.where(userIdFieldName, isEqualTo: userId).get();

      if (querySnapshot.docs.isNotEmpty) {
        var userDoc = querySnapshot.docs.first;
        return userDoc.data() as Map<String, dynamic>;
      } else {
        return null;
      }
    } catch (e) {
      throw UserNotFoundAuthException();
    }
  }

  void createNewUser(
      {required String userName,
      required String email,
      required String phone,
      required bool isAdmin}) async {
    try {
      String userId = AuthService.firebase().currentUser!.id;
      await users.doc(userId).set({
        userNameFieldName: userName,
        userEmailFieldName: email,
        userPhoneFieldName: phone,
        userIsAdminFieldName: isAdmin,
      });
    } catch (e) {
      throw CouldNotAddUserException();
    }
  }

  Future<void> deleteReport({
    required String documentId,
  }) async {
    try {
      await reports.doc(documentId).delete();
    } catch (e) {
      throw CouldNotDeleteReportException();
    }
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
      });
    } catch (e) {
      throw CouldNotUpdateReportException();
    }
  }

  /// Get all the reports of that category live as they are occuring in reports collection
  Stream<Iterable<CloudReport>> allCategoryReports({
    String? category,
  }) {
    return reports.snapshots().map((event) => event.docs
        .map((doc) => CloudReport.fromSnapshot(doc))
        .where((report) =>
            category == null || category == '' || report.category == category));
  }

  /// Get all the reports of current user
  Stream<Iterable<CloudReport>> getMyReports({
    required String userEmail,
    String? reportStatus,
  }) {
    return reports.snapshots().map((event) => event.docs
        .map((doc) => CloudReport.fromSnapshot(doc))
        .where((report) =>
            (reportStatus == null ||
                reportStatus == '' ||
                report.reportStatus == reportStatus) &&
            report.ownerEmail == userEmail));
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
  }) async {
    try {
      await reports.add({
        ownerEmailFieldName: ownerEmail,
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
      });
    } catch (e) {
      throw CouldNotCreateReportException();
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

  static final FirebaseCloudStorage _shared =
      FirebaseCloudStorage._sharedInstance();

  // private constructor
  FirebaseCloudStorage._sharedInstance();
  // factory constructor
  factory FirebaseCloudStorage() => _shared;
}
