/// Calls the Worker, and decides when not to.
///
/// The app never talks to a model provider directly: the key, the rate limit,
/// the image cache and the model choice all live in the Worker. See
/// `worker/src/index.js`.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../domain/models/enums.dart';
import '../../domain/models/food.dart';

/// One food the model proposed. Not yet an entry — nothing is written until the
/// user confirms.
class ProposedItem {
  const ProposedItem({
    required this.name,
    required this.grams,
    required this.macros,
    required this.confidence,
    required this.confidenceReason,
    this.portionDesc,
    this.fromCache = false,
  });

  final String name;
  final double grams;
  final Macros macros;
  final Confidence confidence;
  final String confidenceReason;
  final String? portionDesc;

  /// True when this came from a value the user previously accepted, not from
  /// the model. Such an item is shown sharp and confident, because the user
  /// already agreed to these numbers once.
  final bool fromCache;

  Macros macrosFor(double newGrams) =>
      grams <= 0 ? Macros.zero : macros.scaled(newGrams / grams);

  ProposedItem copyWith({double? grams, Macros? macros, String? portionDesc}) =>
      ProposedItem(
        name: name,
        grams: grams ?? this.grams,
        macros: macros ?? this.macros,
        confidence: confidence,
        confidenceReason: confidenceReason,
        portionDesc: portionDesc ?? this.portionDesc,
        fromCache: fromCache,
      );
}

/// What went wrong, in terms the UI can turn into something actionable.
enum VisionFailure {
  /// No usable connection. Manual logging still works, and the photo is kept.
  offline,

  /// The daily or hourly cap was reached.
  rateLimited,

  /// The Worker answered, but not with something usable.
  badResponse,

  /// The Worker or the model was unreachable or errored.
  server,

  /// Took too long. Distinguished from [server] because retrying a timeout is
  /// far more often worthwhile.
  timeout,
}

class VisionException implements Exception {
  const VisionException(this.failure, {this.retryAfter});

  final VisionFailure failure;
  final Duration? retryAfter;

  /// The message shown to the user.
  ///
  /// Every one of these says what happened and what still works. "Something
  /// went wrong" is never acceptable here: the user has just taken a photo of
  /// a meal they are about to stop caring about.
  String get message => switch (failure) {
    VisionFailure.offline =>
      "No connection, so the photo can't be analysed right now. You can still "
          'add this meal by hand.',
    VisionFailure.rateLimited =>
      "That's all the photo estimates for today. Adding food by hand still "
          'works and is unlimited.',
    VisionFailure.badResponse =>
      "The estimate came back unreadable. Try another photo, or add the meal "
          'by hand.',
    VisionFailure.server =>
      "The estimate service isn't responding. Your photo is saved — try again "
          'in a moment, or add the meal by hand.',
    VisionFailure.timeout =>
      'That took too long. Try again, or add the meal by hand.',
  };
}

class VisionService {
  VisionService({
    required this.endpoint,
    required this.deviceId,
    this.sharedSecret,
    http.Client? client,
    this.timeout = const Duration(seconds: 45),
  }) : _client = client ?? http.Client();

  /// The Worker's `/analyze` URL. Empty means the photo path is not configured,
  /// which is a normal state for a build without a deployed Worker.
  final String endpoint;

  final String deviceId;
  final String? sharedSecret;
  final Duration timeout;
  final http.Client _client;

  bool get isConfigured => endpoint.isNotEmpty;

  /// Analyses a JPEG.
  ///
  /// Throws [VisionException] rather than returning an error object, because
  /// every caller has to handle failure and a nullable return makes that easy
  /// to forget.
  Future<List<ProposedItem>> analyse(List<int> jpegBytes, {String? hint}) async {
    if (!isConfigured) {
      throw const VisionException(VisionFailure.server);
    }

    final http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse(endpoint),
            headers: {
              'content-type': 'application/json',
              'x-device-id': deviceId,
              if (sharedSecret != null) 'authorization': 'Bearer $sharedSecret',
            },
            body: jsonEncode({
              'image_base64': base64Encode(jpegBytes),
              'user_hint': hint,
            }),
          )
          .timeout(timeout);
    } on TimeoutException {
      throw const VisionException(VisionFailure.timeout);
    } on SocketException {
      throw const VisionException(VisionFailure.offline);
    } on http.ClientException {
      throw const VisionException(VisionFailure.offline);
    }

    if (response.statusCode == 429) {
      throw VisionException(
        VisionFailure.rateLimited,
        retryAfter: _retryAfter(response),
      );
    }
    if (response.statusCode != 200) {
      throw const VisionException(VisionFailure.server);
    }

    return parseItems(response.body);
  }

  Duration? _retryAfter(http.Response response) {
    try {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final seconds = body['retry_after_seconds'];
      if (seconds is num) return Duration(seconds: seconds.round());
    } catch (_) {
      // A rate-limit response without a parseable body is still a rate limit.
    }
    return null;
  }

  void dispose() => _client.close();
}

/// Parses the Worker's response.
///
/// Separate from [VisionService] so it can be tested against captured payloads
/// without a socket. Tolerant of missing optional fields and intolerant of
/// missing required ones — a half-parsed item that silently reads as 0 kcal is
/// worse than a visible failure.
List<ProposedItem> parseItems(String body) {
  final Map<String, dynamic> decoded;
  try {
    decoded = jsonDecode(body) as Map<String, dynamic>;
  } catch (_) {
    throw const VisionException(VisionFailure.badResponse);
  }

  final raw = decoded['items'];
  if (raw is! List) throw const VisionException(VisionFailure.badResponse);

  final items = <ProposedItem>[];
  for (final entry in raw) {
    if (entry is! Map) continue;

    final name = (entry['name'] as Object?)?.toString().trim() ?? '';
    if (name.isEmpty) continue;

    final grams = _double(entry['grams']);
    if (grams == null || grams <= 0) continue;

    final kcal = _double(entry['kcal']);
    if (kcal == null) continue;

    items.add(
      ProposedItem(
        name: name,
        grams: grams,
        macros: Macros(
          kcal: kcal,
          proteinG: _double(entry['protein_g']) ?? 0,
          carbsG: _double(entry['carbs_g']) ?? 0,
          fatG: _double(entry['fat_g']) ?? 0,
        ),
        confidence: switch (entry['confidence']) {
          'high' => Confidence.high,
          'medium' => Confidence.medium,
          // Anything unrecognised is treated as low, so an unexpected value
          // makes the app more cautious rather than less.
          _ => Confidence.low,
        },
        // `??` alone is not enough: an empty string is not null, and a blank
        // reason renders as empty space under a blurred number — the one place
        // the user most needs to be told why they are being asked.
        confidenceReason: _text(entry['confidence_reason']) ?? 'no reason given',
        portionDesc: _text(entry['portion_desc']),
      ),
    );
  }

  if (items.isEmpty) throw const VisionException(VisionFailure.badResponse);
  return items;
}

/// A trimmed non-empty string, or null.
String? _text(Object? value) {
  final text = value?.toString().trim();
  return (text == null || text.isEmpty) ? null : text;
}

double? _double(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}
