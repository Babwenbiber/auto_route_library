import 'dart:async';
import 'package:flutter/material.dart';

/// Signature for a function that returns a void future
/// Used in [DeferredWidget] to load deferred libraries
typedef LibraryLoader = Future<void> Function();

/// Signature for a function that returns a widget
/// Used in [DeferredWidget] to build the lazy-loaded library
typedef DeferredWidgetBuilder = Widget Function();

/// Wraps the child inside a deferred module loader.
///
/// The child is created and a single instance of the Widget is maintained in
/// state as long as closure to create widget stays the same.
class DeferredWidget extends StatefulWidget {
  /// default constructor
  DeferredWidget(
    this.libraryLoader,
    this.createWidget, {
    super.key,
    Widget? placeholder,
  }) : placeholder = placeholder ?? Container();

  /// Triggers the deferred library loading process
  final LibraryLoader libraryLoader;

  /// Creates the actual widget after it's loaded
  final DeferredWidgetBuilder createWidget;

  /// The widget is displayed until [libraryLoader] is done loading
  final Widget placeholder;
  static final Map<LibraryLoader, Future<void>> _moduleLoaders = {};
  static final Set<LibraryLoader> _loadedModules = {};

  static Future<void> _preload(LibraryLoader loader) {
    if (!_moduleLoaders.containsKey(loader)) {
      _moduleLoaders[loader] = loader().then((dynamic _) {
        _loadedModules.add(loader);
      });
    }
    return _moduleLoaders[loader]!;
  }

  @override
  State<DeferredWidget> createState() => _DeferredWidgetState();
}

class _DeferredWidgetState extends State<DeferredWidget> {
  _DeferredWidgetState();

  Widget? _loadedChild;
  DeferredWidgetBuilder? _loadedCreator;

  @override
  void initState() {
    /// If module was already loaded immediately create widget instead of
    /// waiting for future or zone turn.
    if (DeferredWidget._loadedModules.contains(widget.libraryLoader)) {
      _onLibraryLoaded();
    } else {
      DeferredWidget._preload(widget.libraryLoader)
          .then((dynamic _) => _onLibraryLoaded());
    }
    super.initState();
  }

  void _onLibraryLoaded() {
    setState(() {
      _loadedCreator = widget.createWidget;
      _loadedChild = _loadedCreator!();
    });
  }

  @override
  Widget build(BuildContext context) {
    /// If closure to create widget changed, create new instance, otherwise
    /// treat as const Widget.
    if (_loadedCreator != widget.createWidget && _loadedCreator != null) {
      _loadedCreator = widget.createWidget;
      _loadedChild = _loadedCreator!();
    }
    return _loadedChild ?? widget.placeholder;
  }
}

/// Displays a progress indicator when the widget is a deferred component
/// and is currently being installed.
class DeferredLoadingPlaceholder extends StatelessWidget {
  /// default constructor
  const DeferredLoadingPlaceholder({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
