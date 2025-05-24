import 'package:flutter/material.dart';
import 'package:shots_studio/models/collection_model.dart';

class CollectionCard extends StatelessWidget {
  final Collection collection;
  final VoidCallback? onTap;

  const CollectionCard({super.key, required this.collection, this.onTap});

  @override
  Widget build(BuildContext context) {
    const double kDefaultInnerPadding = 12.0;
    const double kDefaultOuterOffset = 8.0;
    const double kIconContainerSize = 24.0;
    const double kIconGlyphSize = 16.0;
    const double kGapBetweenIconAndText = 4.0;

    final double textContainerLeftPadding =
        collection.isAutoAddEnabled
            ? kDefaultOuterOffset +
                kIconContainerSize +
                kGapBetweenIconAndText // Calculated for icon: 8 (offset) + 24 (size) + 4 (gap) = 36
            : kDefaultInnerPadding;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            Container(
              width: 120,
              padding: EdgeInsets.fromLTRB(
                textContainerLeftPadding,
                kDefaultInnerPadding, // top
                kDefaultInnerPadding, // right
                kDefaultInnerPadding, // bottom
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    collection.name ?? 'Untitled Collection',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Positioned(
              right: kDefaultOuterOffset,
              bottom: kDefaultOuterOffset,
              child: Container(
                width: kIconContainerSize,
                height: kIconContainerSize,
                decoration: BoxDecoration(
                  color: Colors.amber.shade200,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${collection.screenshotCount}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ),
            if (collection.isAutoAddEnabled)
              Positioned(
                left: kDefaultOuterOffset,
                bottom: kDefaultOuterOffset,
                child: Container(
                  width: kIconContainerSize,
                  height: kIconContainerSize,
                  decoration: BoxDecoration(
                    color: Colors.amber.shade200,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.auto_awesome_outlined,
                    size: kIconGlyphSize,
                    color: Colors.black,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
