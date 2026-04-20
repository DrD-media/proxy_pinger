import 'package:flutter/material.dart';
import '../domain/entities/proxy.dart';

class MarkersPanel extends StatefulWidget {
  final ProxyMarkers markers;
  final Function(ProxyMarkers) onChanged;

  const MarkersPanel({
    super.key,
    required this.markers,
    required this.onChanged,
  });

  @override
  State<MarkersPanel> createState() => _MarkersPanelState();
}

class _MarkersPanelState extends State<MarkersPanel> {
  late ProxyMarkers _currentMarkers;

  @override
  void initState() {
    super.initState();
    _currentMarkers = widget.markers;
  }

  @override
  void didUpdateWidget(MarkersPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.markers != widget.markers) {
      _currentMarkers = widget.markers;
    }
  }

  void _updateMarkers(ProxyMarkers newMarkers) {
    setState(() {
      _currentMarkers = newMarkers;
    });
    widget.onChanged(newMarkers);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Маркеры', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildMarkerRow('Wi-Fi', Icons.wifi, _currentMarkers.wifi, (v) => _updateMarkers(_currentMarkers.copyWith(wifi: v))),
          const SizedBox(height: 12),
          _buildMarkerRow('Mobile', Icons.import_export, _currentMarkers.mobile, (v) => _updateMarkers(_currentMarkers.copyWith(mobile: v))),
          const SizedBox(height: 12),
          Row(
            children: [
              const SizedBox(width: 60),
              GestureDetector(
                onTap: () => _updateMarkers(_currentMarkers.copyWith(favorite: !_currentMarkers.favorite)),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _currentMarkers.favorite ? Icons.star : Icons.star_border,
                        color: _currentMarkers.favorite ? Colors.amber : Colors.grey,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Избранное',
                        style: TextStyle(
                          fontSize: 12,
                          color: _currentMarkers.favorite ? Colors.amber : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMarkerRow(String title, IconData icon, int currentValue, Function(int) onTap) {
    // Цвета: красный, оранжевый, желтый, зеленый, серый
    final colors = [Colors.red, Colors.orange, Colors.amber, Colors.green, Colors.grey];
    return Row(
      children: [
        SizedBox(width: 60, child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500))),
        ...List.generate(5, (index) {
          final isSelected = currentValue == index + 1;
          return GestureDetector(
            onTap: () => onTap(index + 1),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isSelected ? colors[index].withOpacity(0.2) : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isSelected ? colors[index] : Colors.grey.shade300),
              ),
              child: Icon(icon, size: 20, color: isSelected ? colors[index] : Colors.grey.shade400),
            ),
          );
        }),
      ],
    );
  }
}