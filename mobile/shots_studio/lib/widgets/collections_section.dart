import 'package:flutter/material.dart';
import 'package:shots_studio/models/collection_model.dart';
import 'package:shots_studio/models/screenshot_model.dart';
import 'package:shots_studio/screens/create_collection_screen.dart';
import 'package:shots_studio/widgets/collection_card.dart';
import 'package:shots_studio/widgets/add_collection_button.dart';

class CollectionsSection extends StatelessWidget {
  final List<Collection> collections;
  final List<Screenshot> screenshots;
  final Function(Collection) onCollectionAdded;

  const CollectionsSection({
    super.key,
    required this.collections,
    required this.screenshots,
    required this.onCollectionAdded,
  });

  Future<void> _createCollection(BuildContext context) async {
    final Collection? newCollection = await Navigator.of(
      context,
    ).push<Collection>(
      MaterialPageRoute(
        builder:
            (context) =>
                CreateCollectionScreen(availableScreenshots: screenshots),
      ),
    );

    if (newCollection != null) {
      onCollectionAdded(newCollection);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Collections',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios),
                color: Colors.amber.shade200,
                onPressed: () {
                  // TODO: Implement navigation to collections screen
                },
              ),
            ],
          ),
        ),
        Container(
          height: 150,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              // Display existing collections or the "Create first collection" card
              Expanded(
                child:
                    collections.isEmpty
                        ? _buildCreateFirstCollectionCard(context)
                        : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: collections.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 16.0),
                              child: CollectionCard(
                                collection: collections[index],
                              ),
                            );
                          },
                        ),
              ),
              const SizedBox(width: 16),
              // Add button for creating new collections
              AddCollectionButton(onTap: () => _createCollection(context)),
            ],
          ),
        ),
      ],
    );
  }

  // Helper widget for the "Create your first collection" card
  Widget _buildCreateFirstCollectionCard(BuildContext context) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.brown[800],
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Create your first collection to',
              style: TextStyle(fontSize: 18, color: Colors.white70),
            ),
            SizedBox(height: 4),
            Text(
              'organize your screenshots',
              style: TextStyle(fontSize: 18, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
