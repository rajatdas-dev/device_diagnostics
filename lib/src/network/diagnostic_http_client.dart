import 'dart:async';
import 'package:http/http.dart' as http;
import '../core/diagnostic_controller.dart';

/// Opt-in HTTP instrumentation for requests sent through this client only.
/// Does not capture headers, bodies, URLs, or traffic from other clients/apps.
class DiagnosticHttpClient extends http.BaseClient {
  DiagnosticHttpClient({http.Client? inner}) : _inner = inner ?? http.Client();
  final http.Client _inner;
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final sent = request.contentLength ?? 0;
    final response = await _inner.send(request);
    var received = 0;
    var recorded = false;

    void recordOnce() {
      if (recorded) return;
      recorded = true;

      DiagnosticController.instance
          .recordNetwork(receivedBytes: received, sentBytes: sent);
    }

    final stream = response.stream.transform(
        StreamTransformer<List<int>, List<int>>.fromHandlers(
            handleData: (chunk, sink) {
      received += chunk.length;
      sink.add(chunk);
    }, handleDone: (sink) {
      recordOnce();
      sink.close();
    }, handleError: (Object error, StackTrace stack, sink) {
      recordOnce();
      sink.addError(error, stack);
    }));
    // StreamTransformer accounting is finalized when the consumer drains the body.
    return http.StreamedResponse(stream, response.statusCode,
        contentLength: response.contentLength,
        request: response.request,
        headers: response.headers,
        isRedirect: response.isRedirect,
        persistentConnection: response.persistentConnection,
        reasonPhrase: response.reasonPhrase);
  }

  @override
  void close() {
    _inner.close();
    super.close();
  }
}
