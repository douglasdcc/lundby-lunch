import 'package:flutter_test/flutter_test.dart';

import 'package:lundby_lunch/ui/core/widgets/open_map_button.dart';

void main() {
  test('searches Google Maps for the address in Göteborg', () {
    final url = OpenMapButton.urlFor('Gropegårdsgatan 2');

    expect(url.scheme, 'https');
    expect(url.host, 'www.google.com');
    expect(url.path, '/maps/search/');
    expect(url.queryParameters, {
      'api': '1',
      'query': 'Gropegårdsgatan 2, Göteborg',
    });
  });
}
