import 'dart:html' as html;
import 'dart:ui_web' as ui;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

class MapBoxIframeView extends StatefulWidget {
  const MapBoxIframeView({super.key});

  @override
  State<MapBoxIframeView> createState() => _MapBoxIframeViewState();
}

class _MapBoxIframeViewState extends State<MapBoxIframeView> {
  @override
  void initState() {
    super.initState();

    if (kIsWeb) {
      const accessToken = String.fromEnvironment('token_web');

      final String htmlContent = '''
      <!DOCTYPE html>
      <html>
        <head>
          <meta charset="utf-8" />
          <title>Map</title>
          <meta name="viewport" content="width=device-width, initial-scale=1" />
          <script src="https://api.mapbox.com/mapbox-gl-js/v3.11.0/mapbox-gl.js"></script>
          <link href="https://api.mapbox.com/mapbox-gl-js/v3.11.0/mapbox-gl.css" rel="stylesheet" />
          <style>
            html, body { margin: 0; padding: 0; height: 100%; }
            #map { width: 100%; height: 100%; }
          </style>
        </head>
        <body>
          <div id="map"></div>
          <script>
            mapboxgl.accessToken = "$accessToken";
            const map = new mapboxgl.Map({
              container: 'map',
              style: 'mapbox://styles/el03/cmaoalqvx01jl01qy9swq5ip4',
              center: [23.7275, 37.9838],
              zoom: 12
            });
            map.on('load', () => map.resize());
            map.setMinZoom(10);
          </script>
        </body>
      </html>
      ''';

      final blob = html.Blob([htmlContent], 'text/html');
      final url = html.Url.createObjectUrlFromBlob(blob);

      ui.platformViewRegistry.registerViewFactory('mapbox-view', (int viewId) {
        final iframe = html.IFrameElement()
          ..src = url
          ..id = 'map-iframe'
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.pointerEvents = 'auto';
        return iframe;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      return const Center(child: Text('Χάρτης διαθέσιμος μόνο στο Web.'));
    }
    return const HtmlElementView(viewType: 'mapbox-view');
  }
}
