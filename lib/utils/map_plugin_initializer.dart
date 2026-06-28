import 'map_plugin_initializer_stub.dart'
    if (dart.library.html) 'map_plugin_initializer_web.dart' as impl;

void initializeMapPlugin() {
  impl.initializeMapPlugin();
}
