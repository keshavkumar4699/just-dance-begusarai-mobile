/// Just Dance — square crop UI: pan/zoom the photo inside a square window;
/// returns the crop rect in natural pixels (null = skip/cancel).
/// `CropView` is embeddable anywhere (bottom sheets included); `CropScreen`
/// is a thin full-screen route wrapper for flows that want one.
library;

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../widgets/common.dart';

class CropScreen extends StatefulWidget {
  final Uint8List bytes;
  const CropScreen({super.key, required this.bytes});

  /// Pushes the crop UI; resolves to the crop rect (natural px) or null.
  static Future<ui.Rect?> push(BuildContext context, Uint8List bytes) {
    return Navigator.push<ui.Rect?>(
      context,
      MaterialPageRoute(builder: (_) => CropScreen(bytes: bytes)),
    );
  }

  @override
  State<CropScreen> createState() => _CropScreenState();
}

class _CropScreenState extends State<CropScreen> {
  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(title: const Text('Crop photo')),
      body: CropView(
        bytes: widget.bytes,
        onDone: (rect) => Navigator.pop(context, rect),
      ),
    );
  }
}

/// The interactive crop area + Skip/Done buttons, embeddable in a sheet.
class CropView extends StatefulWidget {
  final Uint8List bytes;
  final ValueChanged<ui.Rect?> onDone;
  const CropView({super.key, required this.bytes, required this.onDone});

  @override
  State<CropView> createState() => _CropViewState();
}

class _CropViewState extends State<CropView> {
  final _controller = TransformationController();
  ui.Size? _natural;
  double _viewSize = 0;
  double _displayScale = 1; // natural px -> displayed px (before user zoom)

  @override
  void initState() {
    super.initState();
    _decode();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _decode() async {
    final codec = await ui.instantiateImageCodec(widget.bytes);
    final frame = await codec.getNextFrame();
    if (!mounted) return;
    setState(
        () => _natural = ui.Size(frame.image.width.toDouble(), frame.image.height.toDouble()));
    frame.image.dispose();
  }

  ui.Rect? _computeCrop() {
    final n = _natural;
    if (n == null || _viewSize == 0 || _displayScale == 0) return null;
    final inv = Matrix4.inverted(_controller.value);
    final topLeft = MatrixUtils.transformPoint(inv, Offset.zero);
    final bottomRight =
        MatrixUtils.transformPoint(inv, Offset(_viewSize, _viewSize));

    // Displayed px -> natural px
    var left = topLeft.dx / _displayScale;
    var top = topLeft.dy / _displayScale;
    var right = bottomRight.dx / _displayScale;
    var bottom = bottomRight.dy / _displayScale;

    var width = right - left;
    var height = bottom - top;
    var side = width < height ? width : height;

    final double maxSide = n.width < n.height ? n.width : n.height;
    side = side.clamp(1.0, maxSide);
    left = left.clamp(0.0, n.width - side);
    top = top.clamp(0.0, n.height - side);

    return ui.Rect.fromLTWH(left, top, side, side);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Column(
      children: [
        Expanded(
          child: Center(
            child: LayoutBuilder(builder: (context, box) {
              final size = box.maxWidth.clamp(0.0, box.maxHeight) * 0.90;
              if (_natural != null && size > 0 && _viewSize != size) {
                _viewSize = size;
                _displayScale = (size / _natural!.width) > (size / _natural!.height)
                    ? size / _natural!.width
                    : size / _natural!.height;
                final dispW = _natural!.width * _displayScale;
                final dispH = _natural!.height * _displayScale;
                _controller.value = Matrix4.translationValues(
                    (size - dispW) / 2, (size - dispH) / 2, 0);
              }

              final dispW = _natural != null ? _natural!.width * _displayScale : 0.0;
              final dispH = _natural != null ? _natural!.height * _displayScale : 0.0;

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      border: Border.all(color: c.gold, width: 1.5),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: _natural == null
                          ? const Center(child: CircularProgressIndicator())
                          : InteractiveViewer(
                              transformationController: _controller,
                              minScale: 1.0,
                              maxScale: 5.0,
                              constrained: false,
                              boundaryMargin: EdgeInsets.zero,
                              child: Image.memory(
                                widget.bytes,
                                width: dispW,
                                height: dispH,
                                fit: BoxFit.fill,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.touch_app_outlined, size: 14, color: c.textMuted),
                      const SizedBox(width: 6),
                      Text(
                        'Drag photo to move • Pinch to zoom',
                        style: TextStyle(
                          color: c.textMuted,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
          child: Row(
            children: [
              Expanded(
                child: GhostButton('Skip crop',
                    icon: Icons.crop_free,
                    onTap: () => widget.onDone(null)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GoldButton('Done',
                    icon: Icons.crop,
                    onTap: () => widget.onDone(_computeCrop())),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
