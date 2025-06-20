import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

import '../models/event.dart';

class EventRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  DocumentReference getNewEventDocRef() {
    return _firestore.collection('events').doc();
  }

  Stream<List<Event>> getUpcomingEvents() {
    return _firestore
        .collection('events')
        .where('isPublic', isEqualTo: true)
        .where('dateTime', isGreaterThan: Timestamp.now())
        .orderBy('dateTime')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Event.fromMap(doc.data(), doc.id))
            .toList());
  }

  Stream<List<Event>> getAllUserEvents(String userId) {
    return _firestore
        .collection('events')
        .where('creatorId', isEqualTo: userId)
        .orderBy('dateTime')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Event.fromMap(doc.data(), doc.id))
            .toList());
  }

  Stream<List<Event>> getUserEvents(String userId) {
    return _firestore
        .collection('events')
        .where('creatorId', isEqualTo: userId)
        .where('dateTime', isGreaterThan: Timestamp.now())
        .orderBy('dateTime')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Event.fromMap(doc.data(), doc.id))
            .toList());
  }

  Stream<List<Event>> getEventsByDate(String userId, DateTime date) {
    return _firestore
        .collection('events')
        .where('creatorId', isEqualTo: userId)
        .where('dateTime', isGreaterThanOrEqualTo: date)
        .where('dateTime', isLessThan: date.add(const Duration(days: 1)))
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Event.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> createEvent({
    required Event event,
    File? image,
    List<File> attachments = const [],
  }) async {
    try {
      final docRef = _firestore.collection('events').doc(event.id);

      // Завантаження зображення
      String? imageUrl;
      if (image != null) {
        final ref = _storage.ref().child('event_images/${event.id}');
        await ref.putFile(image);
        imageUrl = await ref.getDownloadURL();
      }

      // Завантаження вкладень
      List<String> attachmentUrls = [];
      for (var attachment in attachments) {
        final ref = _storage.ref().child(
            'event_attachments/${event.id}/${attachment.path.split('/').last}');
        await ref.putFile(attachment);
        attachmentUrls.add(await ref.getDownloadURL());
      }

      // Збереження події з відомим ID
      await docRef.set({
        ...event.toMap(),
        'imageUrl': imageUrl,
        'attachments': attachmentUrls,
      });
    } catch (e) {
      debugPrint('Error creating event: $e');
      rethrow;
    }
  }

  Future<void> updateEvent({
    required Event event,
    File? newImage,
    List<File> newAttachments = const [],
    bool deleteExistingImage = false,
  }) async {
    try {
      if (event.id == null || event.id!.isEmpty) {
        throw ArgumentError('Event ID cannot be empty for updating an event.');
      }

      final docRef = _firestore.collection('events').doc(event.id);
      final currentDoc = await docRef.get();

      if (!currentDoc.exists) {
        throw Exception('Event with ID ${event.id} not found.');
      }

      final currentData = currentDoc.data()!;
      String? currentImageUrl = currentData['imageUrl'] as String?;
      List<String> currentAttachmentUrls =
          List<String>.from(currentData['attachments'] ?? []);

      String? updatedImageUrl = currentImageUrl;
      List<String> updatedAttachmentUrls = [];

      if (deleteExistingImage) {
        if (currentImageUrl != null && currentImageUrl.isNotEmpty) {
          try {
            await _storage.refFromURL(currentImageUrl).delete();
          } catch (e) {
            debugPrint('Error deleting old image from Storage: $e');
          }
        }
        updatedImageUrl = null;
      } else if (newImage != null) {
        if (currentImageUrl != null && currentImageUrl.isNotEmpty) {
          try {
            await _storage.refFromURL(currentImageUrl).delete();
          } catch (e) {
            debugPrint('Error deleting old image from Storage: $e');
          }
        }
        final imageRef = _storage
            .ref()
            .child('event_images/${event.id}/${newImage.path.split('/').last}');
        await imageRef.putFile(newImage);
        updatedImageUrl = await imageRef.getDownloadURL();
      }

      // Видаляємо всі попередні вкладення перед завантаженням нових
      for (var url in currentAttachmentUrls) {
        try {
          await _storage.refFromURL(url).delete();
        } catch (e) {
          debugPrint('Error deleting old attachment from Storage: $e');
        }
      }

      for (var attachment in newAttachments) {
        final attachmentRef = _storage.ref().child(
            'event_attachments/${event.id}/${attachment.path.split('/').last}');
        await attachmentRef.putFile(attachment);
        updatedAttachmentUrls.add(await attachmentRef.getDownloadURL());
      }

      await docRef.update({
        ...event.toMap(),
        'imageUrl': updatedImageUrl,
        'attachments': updatedAttachmentUrls,
      });
    } catch (e) {
      debugPrint('Error updating event: $e');
      rethrow;
    }
  }

  Future<void> changePublic(String eventId, bool isPublic) async {
    await _firestore.collection('events').doc(eventId).update({
      'isPublic': isPublic,
    });
  }

  Future<void> joinEvent(String eventId, String userId) async {
    await _firestore.collection('events').doc(eventId).update({
      'participants': FieldValue.arrayUnion([userId]),
    });
  }

  Future<void> leaveEvent(String eventId, String userId) async {
    await _firestore.collection('events').doc(eventId).update({
      'participants': FieldValue.arrayRemove([userId]),
    });
  }

  Future<void> deleteEvent(String eventId) async {
    await _firestore.collection('events').doc(eventId).delete();
  }
}
