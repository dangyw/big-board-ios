import 'package:flutter/material.dart';

class GroupMemberAssignments extends StatelessWidget {
  final Map<String, String> memberNames;
  final Map<String, String> memberPhotos;
  final Map<String, int> allocations;
  final Function(String) onQuickIncrement;
  final VoidCallback onEditDistribution;

  const GroupMemberAssignments({
    Key? key,
    required this.memberNames,
    required this.memberPhotos,
    required this.allocations,
    required this.onQuickIncrement,
    required this.onEditDistribution,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pick Distribution',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              TextButton.icon(
                icon: Icon(Icons.edit),
                label: Text('Adjust'),
                onPressed: onEditDistribution,
              ),
            ],
          ),
        ),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16),
            itemCount: memberNames.length,
            itemBuilder: (context, index) {
              final memberId = memberNames.keys.elementAt(index);
              final memberName = memberNames[memberId] ?? 'Unknown';
              final photoUrl = memberPhotos[memberId];
              final pickCount = allocations[memberId] ?? 0;
              
              return Padding(
                padding: EdgeInsets.only(right: 12),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () => onQuickIncrement(memberId),
                      child: CircleAvatar(
                        radius: 25,
                        backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                        backgroundColor: photoUrl != null ? Colors.transparent : Colors.grey[300],
                        child: photoUrl == null 
                            ? Text(memberName[0], style: TextStyle(color: Colors.black87))
                            : null,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '$pickCount',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
} 