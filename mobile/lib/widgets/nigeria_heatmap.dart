import 'package:flutter/material.dart';
import 'package:path_drawing/path_drawing.dart';

import '../data/nigeria_state_paths.dart';
import '../services/admin_api_client.dart';
import '../theme.dart';

/// A real (simplified) choropleth of Nigeria's states, colored by referral
/// risk, built from geoBoundaries' Nigeria ADM1 boundaries (CC-BY 4.0,
/// https://www.geoboundaries.org). Tapping a state selects it as a region
/// filter, same as the old region chips did.
class NigeriaHeatmap extends StatefulWidget {
  final List<AdminRegionTotal> regions;
  final String? selectedRegion;
  final ValueChanged<String?> onSelectRegion;

  const NigeriaHeatmap({
    super.key,
    required this.regions,
    required this.selectedRegion,
    required this.onSelectRegion,
  });

  @override
  State<NigeriaHeatmap> createState() => _NigeriaHeatmapState();
}

class _NigeriaHeatmapState extends State<NigeriaHeatmap> {
  late final Map<String, Path> _statePaths;

  @override
  void initState() {
    super.initState();
    _statePaths = {
      for (final entry in kNigeriaStatePaths.entries)
        entry.key: parseSvgPathData(entry.value),
    };
  }

  /// Backend regions look like "Kaduna State"; geoBoundaries shape names are
  /// bare state names ("Kaduna"), with the FCT as its full name.
  String? _shapeNameForRegion(String region) {
    if (region == 'Federal') return 'Abuja Federal Capital Territory';
    if (region.endsWith(' State')) {
      return region.substring(0, region.length - 6);
    }
    return region;
  }

  String _regionForShapeName(String shapeName) {
    if (shapeName == 'Abuja Federal Capital Territory') return 'Federal';
    return '$shapeName State';
  }

  void _handleTapUp(TapUpDetails details, Size widgetSize) {
    final scaleX = widgetSize.width / kNigeriaMapWidth;
    final scaleY = widgetSize.height / kNigeriaMapHeight;
    final point = Offset(
      details.localPosition.dx / scaleX,
      details.localPosition.dy / scaleY,
    );
    for (final entry in _statePaths.entries) {
      if (entry.value.contains(point)) {
        final region = _regionForShapeName(entry.key);
        widget.onSelectRegion(widget.selectedRegion == region ? null : region);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dataByShapeName = <String, AdminRegionTotal>{};
    for (final r in widget.regions) {
      final shapeName = _shapeNameForRegion(r.region);
      if (shapeName != null) dataByShapeName[shapeName] = r;
    }
    final selectedShapeName = widget.selectedRegion == null
        ? null
        : _shapeNameForRegion(widget.selectedRegion!);

    final highColor = RiskColors.of(context, 'high').fg;
    final mediumColor = RiskColors.of(context, 'medium').fg;
    final lowColor = RiskColors.of(context, 'low').fg;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: kNigeriaMapWidth / kNigeriaMapHeight,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = Size(constraints.maxWidth, constraints.maxHeight);
              return GestureDetector(
                onTapUp: (details) => _handleTapUp(details, size),
                child: CustomPaint(
                  size: size,
                  painter: _NigeriaMapPainter(
                    statePaths: _statePaths,
                    dataByShapeName: dataByShapeName,
                    selectedShapeName: selectedShapeName,
                    scheme: scheme,
                    highColor: highColor,
                    mediumColor: mediumColor,
                    lowColor: lowColor,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 14,
          runSpacing: 6,
          children: [
            _LegendItem(
              color: RiskColors.of(context, 'high').fg,
              label: 'High',
            ),
            _LegendItem(
              color: RiskColors.of(context, 'medium').fg,
              label: 'Medium',
            ),
            _LegendItem(color: RiskColors.of(context, 'low').fg, label: 'Low'),
            _LegendItem(
              color: scheme.surfaceContainerHighest,
              label: 'No cases',
            ),
          ],
        ),
      ],
    );
  }
}

class _NigeriaMapPainter extends CustomPainter {
  final Map<String, Path> statePaths;
  final Map<String, AdminRegionTotal> dataByShapeName;
  final String? selectedShapeName;
  final ColorScheme scheme;
  final Color highColor;
  final Color mediumColor;
  final Color lowColor;

  _NigeriaMapPainter({
    required this.statePaths,
    required this.dataByShapeName,
    required this.selectedShapeName,
    required this.scheme,
    required this.highColor,
    required this.mediumColor,
    required this.lowColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / kNigeriaMapWidth;
    final scaleY = size.height / kNigeriaMapHeight;
    canvas.save();
    canvas.scale(scaleX, scaleY);

    for (final entry in statePaths.entries) {
      final selected = entry.key == selectedShapeName;
      final data = dataByShapeName[entry.key];
      final fill = Paint()
        ..style = PaintingStyle.fill
        ..color = _colorFor(data);
      canvas.drawPath(entry.value, fill);

      final stroke = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = (selected ? 2.6 : 0.8) / scaleX
        ..color = selected ? scheme.primary : scheme.surface;
      canvas.drawPath(entry.value, stroke);
    }
    canvas.restore();
  }

  Color _colorFor(AdminRegionTotal? data) {
    if (data == null) return scheme.surfaceContainerHighest;
    if (data.referralFlagCount >= 2) return highColor;
    if (data.referralFlagCount >= 1) return mediumColor;
    return lowColor;
  }

  @override
  bool shouldRepaint(covariant _NigeriaMapPainter oldDelegate) =>
      oldDelegate.selectedShapeName != selectedShapeName ||
      !identical(oldDelegate.dataByShapeName, dataByShapeName);
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
