import 'dart:io';
import 'dart:math' show min;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/leaf_detection.dart';
import 'pest_color.dart';

/// Displays the original captured image with YOLO bounding boxes overlaid,
/// color-coded by pest type. Tapping a box calls [onLeafTapped].
///
/// The image is shown with BoxFit.contain so no pixel is cropped.
/// Bounding boxes are mapped to the actual image display rect (letterboxed).
class BoundingBoxOverlay extends StatefulWidget {
  final String originalImagePath;
  final List<LeafDetection> detectedLeaves;
  final int selectedIndex;
  final ValueChanged<int> onLeafTapped;

  const BoundingBoxOverlay({
    super.key,
    required this.originalImagePath,
    required this.detectedLeaves,
    required this.selectedIndex,
    required this.onLeafTapped,
  });

  @override
  State<BoundingBoxOverlay> createState() => _BoundingBoxOverlayState();
}

class _BoundingBoxOverlayState extends State<BoundingBoxOverlay> {
  Size? _imageNaturalSize;

  @override
  void initState() {
    super.initState();
    _loadImageNaturalSize();
  }

  @override
  void didUpdateWidget(BoundingBoxOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.originalImagePath != widget.originalImagePath) {
      _loadImageNaturalSize();
    }
  }

  Future<void> _loadImageNaturalSize() async {
    try {
      final bytes = await File(widget.originalImagePath).readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      if (mounted) {
        setState(() {
          _imageNaturalSize = Size(
            frame.image.width.toDouble(),
            frame.image.height.toDouble(),
          );
        });
      }
    } catch (_) {
      // Falls back to square mapping until size is known.
    }
  }

  /// Returns the rect (container-local pixels) where BoxFit.contain places
  /// the image. Bboxes must be mapped to this rect to stay aligned.
  Rect _imageDisplayRect(Size container) {
    final natural = _imageNaturalSize;
    if (natural == null || natural.width == 0 || natural.height == 0) {
      return Offset.zero & container;
    }
    final scale = min(
      container.width / natural.width,
      container.height / natural.height,
    );
    final displayW = natural.width * scale;
    final displayH = natural.height * scale;
    return Rect.fromLTWH(
      (container.width - displayW) / 2,
      (container.height - displayH) / 2,
      displayW,
      displayH,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Use natural image aspect ratio once known; fall back to 4:3 while loading.
    final natural = _imageNaturalSize;
    final aspectRatio = (natural != null && natural.height > 0)
        ? natural.width / natural.height
        : 4 / 3;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final containerSize = constraints.biggest;
            final imageRect = _imageDisplayRect(containerSize);

            return Stack(
              fit: StackFit.passthrough,
              children: [
                // ── Original image (fully visible, no cropping) ──────────────
                Image.file(
                  File(widget.originalImagePath),
                  fit: BoxFit.contain,
                  width: containerSize.width,
                  height: containerSize.height,
                  errorBuilder: (_, _, _) => Container(
                    color: AppColors.gray5,
                    child: const Center(
                      child: Icon(Icons.image_not_supported_rounded,
                          color: AppColors.gray3, size: 48),
                    ),
                  ),
                ),

                // ── Bounding boxes via CustomPainter ─────────────────────────
                Positioned.fill(
                  child: CustomPaint(
                    painter: _BoundingBoxPainter(
                      detectedLeaves: widget.detectedLeaves,
                      selectedIndex: widget.selectedIndex,
                      imageRect: imageRect,
                    ),
                  ),
                ),

                // ── Tappable regions for each box ────────────────────────────
                ...List.generate(widget.detectedLeaves.length, (index) {
                  final leaf = widget.detectedLeaves[index];
                  return Positioned(
                    left: imageRect.left + leaf.boxX * imageRect.width,
                    top: imageRect.top + leaf.boxY * imageRect.height,
                    width: leaf.boxWidth * imageRect.width,
                    height: leaf.boxHeight * imageRect.height,
                    child: GestureDetector(
                      onTap: () => widget.onLeafTapped(index),
                      behavior: HitTestBehavior.deferToChild,
                      child: const SizedBox.expand(),
                    ),
                  );
                }),

                // ── Leaf count badge ─────────────────────────────────────────
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.grid_view_rounded, color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.detectedLeaves.length} hojas',
                          style: const TextStyle(
                            fontFamily: 'Nunito',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Paints YOLO bounding boxes mapped to [imageRect] within the canvas.
class _BoundingBoxPainter extends CustomPainter {
  final List<LeafDetection> detectedLeaves;
  final int selectedIndex;

  /// The rect (in canvas-local pixels) where the image is actually drawn.
  /// All bbox coords are mapped relative to this rect.
  final Rect imageRect;

  _BoundingBoxPainter({
    required this.detectedLeaves,
    required this.selectedIndex,
    required this.imageRect,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < detectedLeaves.length; i++) {
      _paintBox(canvas, detectedLeaves[i], i == selectedIndex);
    }
  }

  void _paintBox(Canvas canvas, LeafDetection leaf, bool isSelected) {
    final x = imageRect.left + leaf.boxX * imageRect.width;
    final y = imageRect.top + leaf.boxY * imageRect.height;
    final w = leaf.boxWidth * imageRect.width;
    final h = leaf.boxHeight * imageRect.height;

    final rect = Rect.fromLTWH(x, y, w, h);
    final boxColor = getPestBoxColor(leaf.diagnosedPest);
    final fillColor = getPestBoxFillColor(leaf.diagnosedPest);

    // Fill
    canvas.drawRect(rect, Paint()..color = fillColor..style = PaintingStyle.fill);

    // Outline
    canvas.drawRect(
      rect,
      Paint()
        ..color = boxColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 3.5 : 2.0,
    );

    // Selection glow ring
    if (isSelected) {
      canvas.drawRect(
        rect.inflate(3),
        Paint()
          ..color = boxColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }

    // Label chip — solo el nombre de la plaga; el % de confianza se maneja
    // internamente (color/severidad) pero no se muestra al usuario.
    final labelText = getPestBoxLabel(leaf.diagnosedPest);

    final textStyle = ui.TextStyle(
      color: Colors.white,
      fontSize: 11,
      fontWeight: FontWeight.w800,
      fontFamily: 'Nunito',
    );

    final paragraph = (ui.ParagraphBuilder(ui.ParagraphStyle(
          textAlign: TextAlign.left,
          maxLines: 1,
        ))
          ..pushStyle(textStyle)
          ..addText(labelText))
        .build()
      ..layout(const ui.ParagraphConstraints(width: 200));

    final labelW = paragraph.longestLine;
    final labelH = paragraph.height;

    var labelX = x;
    var labelY = y - labelH - 4;
    if (labelY < 0) labelY = y + 4;
    if (labelX + labelW > imageRect.right) labelX = imageRect.right - labelW - 2;
    if (labelX < imageRect.left) labelX = imageRect.left + 2;

    final labelBgRect = Rect.fromLTWH(labelX - 4, labelY - 2, labelW + 8, labelH + 4);
    canvas.drawRRect(
      RRect.fromRectAndRadius(labelBgRect, const Radius.circular(6)),
      Paint()..color = boxColor..style = PaintingStyle.fill,
    );
    canvas.drawParagraph(paragraph, Offset(labelX, labelY));

    // Corner dot
    canvas.drawCircle(
      Offset(x + 8, y + 8),
      isSelected ? 6 : 5,
      Paint()..color = boxColor..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      Offset(x + 8, y + 8),
      isSelected ? 3 : 2,
      Paint()..color = Colors.white..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _BoundingBoxPainter old) {
    return old.selectedIndex != selectedIndex ||
        old.detectedLeaves != detectedLeaves ||
        old.imageRect != imageRect;
  }
}
