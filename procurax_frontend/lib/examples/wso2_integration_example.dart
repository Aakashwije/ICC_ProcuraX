import 'package:flutter/material.dart';
import 'package:procurax_frontend/services/wso2_api_service.dart';
import 'package:procurax_frontend/services/enhanced_procurement_service.dart';
import 'package:procurax_frontend/models/procurement_view.dart';

/// Example Widget showing WSO2 Integration
///
/// This demonstrates how to use the WSO2 services in your existing app
class WSO2IntegrationExample extends StatefulWidget {
  const WSO2IntegrationExample({Key? key}) : super(key: key);

  @override
  State<WSO2IntegrationExample> createState() => _WSO2IntegrationExampleState();
}

class _WSO2IntegrationExampleState extends State<WSO2IntegrationExample> {
  List<ProcurementView> _procurements = [];
  bool _isLoading = false;
  String _statusMessage = '';
  Map<String, dynamic> _serviceStatus = {};

  @override
  void initState() {
    super.initState();
    _loadServiceStatus();
    _loadProcurements();
  }

  Future<void> _loadServiceStatus() async {
    setState(() {
      _serviceStatus = EnhancedProcurementService.getServiceStatus();
    });
  }

  Future<void> _loadProcurements() async {
    setState(() {
      _isLoading = true;
      _statusMessage = '';
    });

    try {
      final procurements = await EnhancedProcurementService.getProcurementData(
        limit: 20,
      );
      setState(() {
        _procurements = procurements;
        _statusMessage =
            'Loaded ${procurements.length} procurements successfully';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _authenticateWithWSO2() async {
    // Example authentication
    final success = await WSO2ApiService.authenticate(
      username: 'demo@procurax.com',
      password: 'demo123',
    );

    if (success) {
      setState(() {
        _statusMessage = 'WSO2 Authentication successful!';
      });
      await _loadServiceStatus();
      await _loadProcurements();
    } else {
      setState(() {
        _statusMessage = 'WSO2 Authentication failed';
      });
    }
  }

  Future<void> _performHealthCheck() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final healthStatus =
          await EnhancedProcurementService.performHealthCheck();
      setState(() {
        _statusMessage = 'Health Check Results: ${healthStatus.toString()}';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Health Check Error: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WSO2 Integration Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Service Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Service Status',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text('Using WSO2: ${_serviceStatus['useWSO2'] ?? false}'),
                    Text(
                      'WSO2 Available: ${_serviceStatus['wso2Available'] ?? false}',
                    ),
                    Text(
                      'Fallback Enabled: ${_serviceStatus['enableFallback'] ?? false}',
                    ),
                    Text(
                      'Backend URL: ${_serviceStatus['backendUrl'] ?? 'N/A'}',
                    ),
                    if (_serviceStatus['wso2Url'] != null)
                      Text('WSO2 URL: ${_serviceStatus['wso2Url']}'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Action Buttons
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: [
                ElevatedButton(
                  onPressed: _isLoading ? null : _authenticateWithWSO2,
                  child: const Text('Authenticate WSO2'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _loadProcurements,
                  child: const Text('Reload Data'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _performHealthCheck,
                  child: const Text('Health Check'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _loadServiceStatus,
                  child: const Text('Refresh Status'),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Status Message
            if (_statusMessage.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _statusMessage.startsWith('Error')
                      ? Colors.red.shade100
                      : Colors.green.shade100,
                  border: Border.all(
                    color: _statusMessage.startsWith('Error')
                        ? Colors.red
                        : Colors.green,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _statusMessage,
                  style: TextStyle(
                    color: _statusMessage.startsWith('Error')
                        ? Colors.red.shade800
                        : Colors.green.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Data List
            Text(
              'Procurement Data (${_procurements.length} items)',
              style: Theme.of(context).textTheme.headlineSmall,
            ),

            const SizedBox(height: 8),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _procurements.isEmpty
                  ? const Center(
                      child: Text(
                        'No procurement data available.\nTry authenticating with WSO2 first.',
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.builder(
                      itemCount: _procurements.length,
                      itemBuilder: (context, index) {
                        final procurement = _procurements[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(
                              procurement.procurementItems.isNotEmpty
                                  ? procurement
                                        .procurementItems
                                        .first
                                        .materialList
                                  : 'No Materials',
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (procurement.procurementItems.isNotEmpty)
                                  Text(
                                    'Responsibility: ${procurement.procurementItems.first.responsibility}',
                                  ),
                                const SizedBox(height: 4),
                                Text(
                                  'Items: ${procurement.procurementItems.length} | '
                                  'Deliveries: ${procurement.upcomingDeliveries.length}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                            trailing: Chip(
                              label: Text(
                                procurement.procurementItems.isNotEmpty
                                    ? (procurement
                                              .procurementItems
                                              .first
                                              .status ??
                                          'Unknown')
                                    : 'No Status',
                              ),
                              backgroundColor: _getStatusColor(
                                procurement.procurementItems.isNotEmpty
                                    ? procurement.procurementItems.first.status
                                    : null,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isLoading ? null : () => _showCreateDialog(context),
        tooltip: 'Create Procurement Request',
        child: const Icon(Icons.add),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'approved':
        return Colors.green.shade100;
      case 'pending':
        return Colors.orange.shade100;
      case 'rejected':
        return Colors.red.shade100;
      default:
        return Colors.grey.shade100;
    }
  }

  void _showCreateDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final budgetController = TextEditingController();
    String selectedCategory = 'Office Supplies';
    String selectedUrgency = 'Medium';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Procurement Request'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: budgetController,
                decoration: const InputDecoration(labelText: 'Budget'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: const InputDecoration(labelText: 'Category'),
                items: ['Office Supplies', 'IT Equipment', 'Services', 'Other']
                    .map(
                      (cat) => DropdownMenuItem(value: cat, child: Text(cat)),
                    )
                    .toList(),
                onChanged: (value) => selectedCategory = value!,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedUrgency,
                decoration: const InputDecoration(labelText: 'Urgency'),
                items: ['Low', 'Medium', 'High', 'Critical']
                    .map(
                      (urg) => DropdownMenuItem(value: urg, child: Text(urg)),
                    )
                    .toList(),
                onChanged: (value) => selectedUrgency = value!,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _createProcurementRequest(
                title: titleController.text,
                description: descriptionController.text,
                budget: double.tryParse(budgetController.text) ?? 0.0,
                category: selectedCategory,
                urgency: selectedUrgency,
              );
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _createProcurementRequest({
    required String title,
    required String description,
    required double budget,
    required String category,
    required String urgency,
  }) async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Creating procurement request...';
    });

    try {
      final result = await EnhancedProcurementService.createProcurementRequest(
        title: title,
        description: description,
        category: category,
        budget: budget,
        urgency: urgency,
      );

      setState(() {
        _statusMessage =
            'Procurement request created successfully! ID: ${result['id']}';
      });

      // Reload the list
      await _loadProcurements();
    } catch (e) {
      setState(() {
        _statusMessage = 'Error creating procurement request: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
