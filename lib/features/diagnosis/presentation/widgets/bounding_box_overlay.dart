import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/leaf_detection.dart';
import 'pest_color.dart';

/// A widget that displays the original captured image with YOLO bounding boxes
/// overlaid on top, color-coded by pest type.
///
/// Each box is labeled with the detected pest and confidence.
/// Tapping a box selects it and calls [onLeafTapped].
class BoundingBoxOverlay extends StatelessWidget {
  /// The full path to the original captured image.
  final String originalImagePath;

  /// The list of detected leaves with their bounding box coordinates.
  /// Coordinates are normalized (0.0–1.0) YOLO format.
  final List<LeafDetection> detectedLeaves;

  /// Index of the currently selected leaf, used to highlight the active box.
  final int selectedIndex;

  /// Callback fired when the user taps a bounding box.
  /// Receives the index of the tapped leaf.
  final ValueChanged<int> onLeafTapped;

  const BoundingBoxOverlay({
    super.key,
    required this.originalImagePath,
    required this.detectedLeaves,
    required this.selectedIndex,
    required this.onLeafTapped,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 1,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = constraints.biggest;

            return Stack(
              fit: StackFit.passthrough,
              children: [
                // ── Original image ────────────────────────────────────────────
                Image.file(
                  File(originalImagePath),
                  fit: BoxFit.cover,
                  width: size.width,
                  height: size.height,
                  errorBuilder: (_, _, _) => Container(
                    color: AppColors.gray5,
                    child: const Center(
                      child: Icon(Icons.image_not_supported_rounded,
                          color: AppColors.gray3, size: 48),
                    ),
                  ),
                ),

                // ── Bounding boxes drawn via CustomPainter ──────────────────
                Positioned.fill(
                  child: CustomPaint(
                    painter: _BoundingBoxPainter(
                      detectedLeaves: detectedLeaves,
                      selectedIndex: selectedIndex,
                      imageSize: size,
                    ),
                  ),
                ),

                // ── Invisible tappable regions for each box ───────────────────
                ...List.generate(detectedLeaves.length, (index) {
                  final leaf = detectedLeaves[index];
                  final rect = _normalizedRect(
                    leaf.boxX,
                    leaf.boxY,
                    leaf.boxWidth,
                    leaf.boxHeight,
                    size.width,
                    size.height,
                  );

                  return Positioned(
                    left: rect.left,
                    top: rect.top,
                    width: rect.width,
                    height: rect.height,
                    child: GestureDetector(
                      onTap: () => onLeafTapped(index),
                      behavior: HitTestBehavior.deferToChild,
                      child: const SizedBox.expand(),
                    ),
                  );
                }),

                // ── Corner badge: leaf count ────────────────────────────────
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.grid_view_rounded,
                            color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '${detectedLeaves.length} hojas',
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

  /// Converts normalized YOLO coordinates (0–1) to a pixel-level Rect.
  Rect _normalizedRect(
    double x,
    double y,
    double w,
    double h,
    double imageWidth,
    double imageHeight,
  ) {
    return Rect.fromLTWH(
      x * imageWidth,
      y * imageHeight,
      w * imageWidth,
      h * imageHeight,
    );
  }
}

/// Paints YOLO bounding boxes with pest-colored outlines, label chips,
/// and a highlight ring around the currently selected leaf.
class _BoundingBoxPainter extends CustomPainter {
  final List<LeafDetection> detectedLeaves;
  final int selectedIndex;
  final Size imageSize;

  _BoundingBoxPainter({
    required this.detectedLeaves,
    required this.selectedIndex,
    required this.imageSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < detectedLeaves.length; i++) {
      final leaf = detectedLeaves[i];
      final isSelected = i == selectedIndex;
      _paintBox(canvas, size, leaf, isSelected);
    }
  }

  void _paintBox(
      Canvas canvas, Size size, LeafDetection leaf, bool isSelected) {
    final x = leaf.boxX * size.width;
    final y = leaf.boxY * size.height;
    final w = leaf.boxWidth * size.width;
    final h = leaf.boxHeight * size.height;

    final rect = Rect.fromLTWH(x, y, w, h);
    final boxColor = getPestBoxColor(leaf.diagnosedPest);
    final fillColor = getPestBoxFillColor(leaf.diagnosedPest);

    // ── Fill inside the box ───────────────────────────────────────────
    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    canvas.drawRect(rect, fillPaint);

    // ── Box outline ───────────────────────────────────────────────────
    final strokePaint = Paint()
      ..color = boxColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 3.5 : 2.0;
    canvas.drawRect(rect, strokePaint);

    // ── Dashed selection ring for selected box ───────────────────────
    if (isSelected) {
      final highlightPaint = Paint()
        ..color = boxColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      // Outer glow rect (slightly larger)
      final glowRect = rect.inflate(3);
      canvas.drawRect(glowRect, highlightPaint);
    }

    // ── Label chip above the box ──────────────────────────────────────
    final label = getPestBoxLabel(leaf.diagnosedPest);
    final confidence = leaf.confidence;

    final textStyle = ui.TextStyle(
      color: Colors.white,
      fontSize: 11,
      fontWeight: FontWeight.w800,
      fontFamily: 'Nunito',
    );

    final labelParagraph = ui.ParagraphBuilder(ui.ParagraphStyle(
          textAlign: TextAlign.left,
          maxLines: 1,
        ))
      ..pushStyle(textStyle)
      ..addText(confidence != null ? '$label ${(confidence * 100).toInt()}%' : label);

    final paragraph = labelParagraph.build()
      ..layout(const ui.ParagraphConstraints(width: 200));

    final labelWidth = paragraph.longestLine;
    final labelHeight = paragraph.height;

    // Position label: top-left corner of box, or clamped to image bounds
    var labelX = x;
    var labelY = y - labelHeight - 4;

    // If label would go above image top, place it inside the box
    if (labelY < 0) {
      labelY = y + 4;
    }
    // If label would overflow right, align to right edge
    if (labelX + labelWidth > size.width) {
      labelX = size.width - labelWidth - 2;
    }
    if (labelX < 0) labelX = 2;

    // Label background
    final labelRect = Rect.fromLTWH(
      labelX - 4,
      labelY - 2,
      labelWidth + 8,
      labelHeight + 4,
    );

    final labelBgPaint = Paint()
      ..color = boxColor
      ..style = PaintingStyle.fill;
    final rrect = RRect.fromRectAndRadius(labelRect, const Radius.circular(6));
    canvas.drawRRect(rrect, labelBgPaint);

    // Label text
    canvas.drawParagraph(paragraph, Offset(labelX, labelY));

    // ── Pest type icon dot inside box (top-left corner) ───────────────
    final dotPaint = Paint()
      ..color = boxColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(x + 8, y + 8),
      isSelected ? 6 : 5,
      dotPaint,
    );

    // White inner dot for visibility
    final innerDotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(x + 8, y + 8), isSelected ? 3 : 2, innerDotPaint);
  }

  @override
  bool shouldRepaint(covariant _BoundingBoxPainter oldDelegate) {
    return oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.detectedLeaves != detectedLeaves;
  }
}