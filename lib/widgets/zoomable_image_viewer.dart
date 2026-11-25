import 'package:flutter/material.dart';

class ZoomableImageViewer extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const ZoomableImageViewer({
    super.key,
    required this.images,
    this.initialIndex = 0,
  }) : assert(images.length > 0);

  static Future<void> show({
    required BuildContext context,
    required List<String> images,
    int initialIndex = 0,
  }) {
    final cleanedImages = images
        .map((image) => image.trim())
        .where((image) => image.isNotEmpty)
        .toList();
    if (cleanedImages.isEmpty) return Future<void>.value();

    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => ZoomableImageViewer(
          images: cleanedImages,
          initialIndex: initialIndex.clamp(0, cleanedImages.length - 1).toInt(),
        ),
      ),
    );
  }

  @override
  State<ZoomableImageViewer> createState() => _ZoomableImageViewerState();
}

class _ZoomableImageViewerState extends State<ZoomableImageViewer> {
  static const double _minScale = 0.8;
  static const double _maxScale = 5;

  late final PageController _pageController;
  late final List<TransformationController> _transformationControllers;
  late int _currentIndex;
  Size _viewportSize = Size.zero;
  Offset _doubleTapPosition = Offset.zero;
  bool _isZoomed = false;

  TransformationController get _currentController =>
      _transformationControllers[_currentIndex];

  double get _currentScale => _currentController.value.getMaxScaleOnAxis();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex
        .clamp(0, widget.images.length - 1)
        .toInt();
    _pageController = PageController(initialPage: _currentIndex);
    _transformationControllers = List.generate(
      widget.images.length,
      (_) => TransformationController(),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final controller in _transformationControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _updateZoomState(int index) {
    if (index != _currentIndex || !mounted) return;
    final zoomed =
        _transformationControllers[index].value.getMaxScaleOnAxis() > 1.01;
    if (_isZoomed != zoomed) {
      setState(() => _isZoomed = zoomed);
    }
  }

  void _onPageChanged(int index) {
    _transformationControllers[_currentIndex].value = Matrix4.identity();
    _transformationControllers[index].value = Matrix4.identity();
    setState(() {
      _currentIndex = index;
      _isZoomed = false;
    });
  }

  Matrix4 _matrixAtScale(double scale, {Offset? focalPoint}) {
    final focal =
        focalPoint ?? Offset(_viewportSize.width / 2, _viewportSize.height / 2);
    return Matrix4.identity()
      ..setEntry(0, 0, scale)
      ..setEntry(1, 1, scale)
      ..setEntry(0, 3, focal.dx * (1 - scale))
      ..setEntry(1, 3, focal.dy * (1 - scale));
  }

  void _setScale(double scale, {Offset? focalPoint}) {
    final boundedScale = scale.clamp(_minScale, _maxScale).toDouble();
    _currentController.value = boundedScale == 1
        ? Matrix4.identity()
        : _matrixAtScale(boundedScale, focalPoint: focalPoint);
    _updateZoomState(_currentIndex);
  }

  void _toggleDoubleTapZoom() {
    if (_currentScale > 1.01) {
      _setScale(1);
    } else {
      _setScale(2.5, focalPoint: _doubleTapPosition);
    }
  }

  Widget _buildImagePage(int index, Size size) {
    return InteractiveViewer(
      transformationController: _transformationControllers[index],
      minScale: _minScale,
      maxScale: _maxScale,
      panEnabled: index == _currentIndex && _isZoomed,
      onInteractionUpdate: (_) => _updateZoomState(index),
      onInteractionEnd: (_) => _updateZoomState(index),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onDoubleTapDown: (details) {
          _doubleTapPosition = details.localPosition;
        },
        onDoubleTap: _toggleDoubleTapZoom,
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: Image.network(
            widget.images[index],
            fit: BoxFit.contain,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            },
            errorBuilder: (context, error, stackTrace) => const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.broken_image_outlined,
                    color: Colors.white70,
                    size: 40,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Không thể tải hình ảnh',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildZoomButton({
    required String tooltip,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: Colors.white12,
        foregroundColor: Colors.white,
      ),
      icon: Icon(icon),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  _buildZoomButton(
                    tooltip: 'Thu nhỏ',
                    icon: Icons.remove,
                    onPressed: () => _setScale(_currentScale - 0.5),
                  ),
                  _buildZoomButton(
                    tooltip: 'Đặt lại',
                    icon: Icons.filter_center_focus,
                    onPressed: () => _setScale(1),
                  ),
                  _buildZoomButton(
                    tooltip: 'Phóng to',
                    icon: Icons.add,
                    onPressed: () => _setScale(_currentScale + 0.5),
                  ),
                  Expanded(
                    child: Text(
                      '${_currentScale.toStringAsFixed(1)}x',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  _buildZoomButton(
                    tooltip: 'Đóng',
                    icon: Icons.close,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  _viewportSize = constraints.biggest;
                  return PageView.builder(
                    controller: _pageController,
                    itemCount: widget.images.length,
                    physics: _isZoomed
                        ? const NeverScrollableScrollPhysics()
                        : const PageScrollPhysics(),
                    onPageChanged: _onPageChanged,
                    itemBuilder: (context, index) =>
                        _buildImagePage(index, constraints.biggest),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16, top: 8),
              child: Text(
                '${_currentIndex + 1} / ${widget.images.length}',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
