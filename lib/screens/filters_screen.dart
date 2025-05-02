import 'package:flutter/material.dart';

class FiltersScreen extends StatefulWidget {
  const FiltersScreen({Key? key}) : super(key: key);

  @override
  _FiltersScreenState createState() => _FiltersScreenState();
}

class _FiltersScreenState extends State<FiltersScreen> {
  // Filter settings
  RangeValues _ageRange = const RangeValues(18, 50);
  double _maxDistance = 50;
  String _genderPreference = 'Everyone';
  final List<String> _selectedInterests = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discovery Preferences'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          TextButton(
            onPressed: () {
              // Save filter settings
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Preferences saved')),
              );
              Navigator.of(context).pop();
            },
            child: const Text(
              'Save',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Age Range Slider
          const Text(
            'Age Range',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          RangeSlider(
            values: _ageRange,
            min: 18,
            max: 100,
            divisions: 82,
            labels: RangeLabels(
              '${_ageRange.start.round()}',
              '${_ageRange.end.round()}',
            ),
            onChanged: (RangeValues values) {
              setState(() {
                _ageRange = values;
              });
            },
            activeColor: Colors.red,
          ),
          Text(
            'Show people aged ${_ageRange.start.round()} to ${_ageRange.end.round()}',
            style: TextStyle(color: Colors.grey.shade600),
          ),

          const SizedBox(height: 24),

          // Distance Slider
          const Text(
            'Maximum Distance',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Slider(
            value: _maxDistance,
            min: 1,
            max: 100,
            divisions: 99,
            label: '${_maxDistance.round()} km',
            onChanged: (double value) {
              setState(() {
                _maxDistance = value;
              });
            },
            activeColor: Colors.red,
          ),
          Text(
            'Show people within ${_maxDistance.round()} km',
            style: TextStyle(color: Colors.grey.shade600),
          ),

          const SizedBox(height: 24),

          // Gender Preference
          const Text(
            'Show Me',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              buildGenderChip('Everyone'),
              buildGenderChip('Women'),
              buildGenderChip('Men'),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildGenderChip(String gender) {
    final isSelected = _genderPreference == gender;

    return ChoiceChip(
      label: Text(gender),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _genderPreference = gender;
          });
        }
      },
      backgroundColor: Colors.grey.shade200,
      selectedColor: Colors.red.shade100,
      labelStyle: TextStyle(
        color: isSelected ? Colors.red : Colors.black,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}