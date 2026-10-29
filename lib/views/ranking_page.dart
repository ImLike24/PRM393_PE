import 'package:flutter/material.dart';
import '../models/song.dart';
import '../services/music_service.dart';

class RankingPage extends StatefulWidget {
  const RankingPage({super.key});

  @override
  State<RankingPage> createState() => _RankingPageState();
}

class _RankingPageState extends State<RankingPage> {
  List<Song> songs = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    MusicService.changeNotifier.addListener(_onDataChanged);
    _load();
  }

  @override
  void dispose() {
    MusicService.changeNotifier.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      songs = await MusicService.instance.getRanking();
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bang xep hang')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: songs.length,
        itemBuilder: (_, i) {
          final s = songs[i];
          return ListTile(
            leading: CircleAvatar(child: Text('${i + 1}')),
            title: Text(s.title),
            subtitle: Text(s.artist),
            trailing: Text('${s.luotNghe} nghe'),
          );
        },
      ),
    );
  }
}