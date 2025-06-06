import 'package:flutter/material.dart';
import 'package:shots_studio/models/collection_model.dart';
import 'package:shots_studio/models/screenshot_model.dart';
import 'package:shots_studio/screens/collection_detail_screen.dart';
import 'package:shots_studio/services/analytics_service.dart';
import 'package:shots_studio/widgets/collections/collection_list_item.dart';

class AllCollectionsScreen extends StatefulWidget {
  final List<Collection> collections;
  final List<Screenshot> allScreenshots;
  final Function(Collection) onUpdateCollection;
  final Function(String) onDeleteCollection;
  final Function(String) onDeleteScreenshot;

  const AllCollectionsScreen({
    super.key,
    required this.collections,
    required this.allScreenshots,
    required this.onUpdateCollection,
    required this.onDeleteCollection,
    required this.onDeleteScreenshot,
  });

  @override
  State<AllCollectionsScreen> createState() => _AllCollectionsScreenState();
}

class _AllCollectionsScreenState extends State<AllCollectionsScreen> {
  @override
  Widget build(BuildContext context) {
    // Track screen access
    AnalyticsService().logScreenView('all_collections_screen');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Collections'),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body:
          widget.collections.isEmpty
              ? Center(
                child: Text(
                  'No collections yet. Create one from the home screen!',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: widget.collections.length,
                itemBuilder: (context, index) {
                  final collection = widget.collections[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: CollectionListItem(
                      collection: collection,
                      onTap: () {
                        AnalyticsService().logFeatureUsed(
                          'collection_opened_from_all_collections',
                        );
                        Navigator.of(context)
                            .push(
                              MaterialPageRoute(
                                builder:
                                    (context) => CollectionDetailScreen(
                                      collection: collection,
                                      allCollections: widget.collections,
                                      allScreenshots: widget.allScreenshots,
                                      onUpdateCollection: (updatedCollection) {
                                        widget.onUpdateCollection(
                                          updatedCollection,
                                        );
                                        setState(() {
                                          // This will trigger a rebuild of the UI
                                        });
                                      },
                                      onDeleteCollection:
                                          widget.onDeleteCollection,
                                      onDeleteScreenshot:
                                          widget.onDeleteScreenshot,
                                    ),
                              ),
                            )
                            .then((_) {
                              // Refresh the UI when returning from collection detail
                              setState(() {});
                            });
                      },
                    ),
                  );
                },
              ),
    );
  }
}
