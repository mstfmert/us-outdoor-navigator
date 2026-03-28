import 'package:flutter/material.dart';

class ReportButton extends StatefulWidget {
  final VoidCallback onPressed;

  const ReportButton({
    super.key,
    required this.onPressed,
  });

  @override
  State<ReportButton> createState() => _ReportButtonState();
}

class _ReportButtonState extends State<ReportButton> {
  bool _isExpanded = false;

  void _toggleExpanded() {
    setState(() => _isExpanded = !_isExpanded);
  }

  void _handleReportType(String type) {
    _toggleExpanded();
    widget.onPressed();
    
    // Gerçek uygulamada burada rapor türüne göre işlem yapılacak
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Report submitted: $type'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_isExpanded) ...[
          _buildReportOption('Bear Sighting', Icons.pets),
          _buildReportOption('Road Closed', Icons.block),
          _buildReportOption('Fire Hazard', Icons.local_fire_department),
          _buildReportOption('Weather Alert', Icons.cloud),
          _buildReportOption('Other Issue', Icons.report_problem),
          const SizedBox(height: 8),
        ],
        FloatingActionButton(
          onPressed: _toggleExpanded,
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          child: Icon(
            _isExpanded ? Icons.close : Icons.report,
            size: 24,
          ),
        ),
      ],
    );
  }

  Widget _buildReportOption(String label, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: FloatingActionButton.extended(
        onPressed: () => _handleReportType(label),
        backgroundColor: Colors.black.withOpacity(0.8),
        foregroundColor: Colors.white,
        icon: Icon(icon, size: 20),
        label: Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
        extendedPadding: const EdgeInsets.symmetric(horizontal: 16),
      ),
    );
  }
}

class ReportDialog extends StatefulWidget {
  final double latitude;
  final double longitude;

  const ReportDialog({
    super.key,
    required this.latitude,
    required this.longitude,
  });

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  String _selectedType = 'Bear Sighting';
  List<String> _photoPaths = [];

  final List<String> _reportTypes = [
    'Bear Sighting',
    'Road Closed',
    'Fire Hazard',
    'Weather Alert',
    'Water Issue',
    'Campground Full',
    'Trash Problem',
    'Other Issue',
  ];

  Future<void> _takePhoto() async {
    // Gerçek uygulamada kamera/galeri erişimi olacak
    setState(() {
      _photoPaths.add('photo_${_photoPaths.length + 1}.jpg');
    });
  }

  Future<void> _submitReport() async {
    if (_formKey.currentState!.validate()) {
      // Gerçek uygulamada API'ye gönderilecek
      final reportData = {
        'type': _selectedType,
        'description': _descriptionController.text,
        'latitude': widget.latitude,
        'longitude': widget.longitude,
        'photos': _photoPaths,
        'timestamp': DateTime.now().toIso8601String(),
      };

      Navigator.pop(context, reportData);
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Submit Field Report'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Report type dropdown
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Issue Type',
                  border: OutlineInputBorder(),
                ),
                items: _reportTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedType = value!);
                },
              ),
              const SizedBox(height: 16),

              // Description field
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  hintText: 'Describe what you observed...',
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Photo section
              const Text(
                'Photos (Optional):',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              // Photo grid
              if (_photoPaths.isNotEmpty)
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _photoPaths.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: Icon(Icons.photo, size: 32),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _photoPaths.removeAt(index);
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),

              // Add photo button
              ElevatedButton.icon(
                onPressed: _takePhoto,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Add Photo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey[800],
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submitReport,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
          ),
          child: const Text('Submit Report'),
        ),
      ],
    );
  }
}