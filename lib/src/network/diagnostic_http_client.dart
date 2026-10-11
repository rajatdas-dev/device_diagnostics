
import 'dart:async';

import 'package:http/http.dart' as http;

import '../core/diagnostic_controller.dart';

/// Opt-in HTTP instrumentation for requests sent through this client.
///
/// Counts transferred body bytes only. It does not capture headers,
/// request/response contents, or traffic from other clients and apps.
class DiagnosticHttpClient extends http.BaseClient {
  DiagnosticHttpClient({http.Client? inner})
      : _inner = inner ?? http.Client();

  final http.Client _inner;

  @override
  Future<http.StreamedResponse> send(
      http.BaseRequest request,
      ) async {
    var sentBytes = 0;
    var receivedBytes = 0;
    var recorded = false;

    void recordOnce() {
      if (recorded) return;
      recorded = true;

      DiagnosticController.instance.recordNetwork(
        receivedBytes: receivedBytes,
        sentBytes: sentBytes,
      );
    }

    // finalize() provides the actual request body stream, including
    // streamed bodies whose contentLength is unknown.
    final requestBody = request.finalize();

    final streamedRequest = http.StreamedRequest(
      request.method,
      request.url,
    )
      ..headers.addAll(request.headers)
      ..followRedirects = request.followRedirects
      ..maxRedirects = request.maxRedirects
      ..persistentConnection = request.persistentConnection
      ..contentLength = request.contentLength;

    // Start the request so that the inner client can consume the
    // StreamedRequest while we forward the original body.
    final responseFuture = _inner.send(streamedRequest);

    try {
      await streamedRequest.sink.addStream(
        requestBody.transform(
          StreamTransformer<List<int>, List<int>>.fromHandlers(
            handleData: (chunk, sink) {
              sentBytes += chunk.length;
              sink.add(chunk);
            },
          ),
        ),
      );
    } finally {
      await streamedRequest.sink.close();
    }

    final response = await responseFuture;

    late final Stream<List<int>> responseStream;

    responseStream = response.stream.transform(
      StreamTransformer<List<int>, List<int>>.fromBind((source) {
        late final StreamController<List<int>> controller;
        StreamSubscription<List<int>>? subscription;

        controller = StreamController<List<int>>(
          onListen: () {
            subscription = source.listen(
                  (chunk) {
                receivedBytes += chunk.length;
                controller.add(chunk);
              },
              onError: (Object error, StackTrace stackTrace) {
                recordOnce();
                controller.addError(error, stackTrace);
              },
              onDone: () {
                recordOnce();
                controller.close();
              },
              cancelOnError: false,
            );
          },
          onPause: () => subscription?.pause(),
          onResume: () => subscription?.resume(),
          onCancel: () async {
            recordOnce();
            await subscription?.cancel();
          },
        );

        return controller.stream;
      }),
    );

    return http.StreamedResponse(
      responseStream,
      response.statusCode,
      contentLength: response.contentLength,
      request: response.request,
      headers: response.headers,
      isRedirect: response.isRedirect,
      persistentConnection: response.persistentConnection,
      reasonPhrase: response.reasonPhrase,
    );
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}
