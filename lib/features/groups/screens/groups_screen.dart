import 'package:flutter/material.dart';
import 'package:big_board/features/groups/models/group.dart';
import 'package:big_board/features/groups/services/groups_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GroupsScreen extends StatefulWidget {
  @override
  _GroupsScreenState createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  final GroupsService _groupsService = GroupsService();
  List<Group> userGroups = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    setState(() => isLoading = true);
    final groups = await _groupsService.getUserGroups(userId);
    setState(() {
      userGroups = groups;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Groups'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => _showCreateGroupDialog(context),
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: userGroups.length,
              itemBuilder: (context, index) {
                final group = userGroups[index];
                return ListTile(
                  leading: group.avatarUrl != null
                      ? CircleAvatar(backgroundImage: NetworkImage(group.avatarUrl!))
                      : CircleAvatar(child: Text(group.name[0])),
                  title: Text(group.name),
                  subtitle: Text('${group.memberIds.length} members'),
                  onTap: () => _showGroupDetails(context, group),
                );
              },
            ),
    );
  }

  Future<void> _showCreateGroupDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Create New Group'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: 'Group Name'),
            ),
            TextField(
              controller: descController,
              decoration: InputDecoration(labelText: 'Description (Optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final userId = Supabase.instance.client.auth.currentUser?.id;
              if (userId == null) return;

              await _groupsService.createGroup(
                name: nameController.text,
                ownerId: userId,
                description: descController.text,
              );
              
              Navigator.pop(context);
              _loadGroups();
            },
            child: Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showGroupDetails(BuildContext context, Group group) {
    // Navigate to group details screen
    // You can create a separate GroupDetailsScreen for this
  }
} 