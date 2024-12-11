class ParlayInvitationDialog extends StatelessWidget {
  final ParlayInvitation invitation;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const ParlayInvitationDialog({
    Key? key,
    required this.invitation,
    required this.onAccept,
    required this.onDecline,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Parlay Invitation'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('You have been invited to join a parlay!'),
          const SizedBox(height: 16),
          FutureBuilder<UserProfile>(
            future: UserProfileService().getProfile(invitation.inviterId),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Text('From: ${snapshot.data!.displayName}');
              }
              return const CircularProgressIndicator();
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            onDecline();
            Navigator.of(context).pop();
          },
          child: const Text('Decline'),
        ),
        ElevatedButton(
          onPressed: () {
            onAccept();
            Navigator.of(context).pop();
          },
          child: const Text('Accept'),
        ),
      ],
    );
  }
} 