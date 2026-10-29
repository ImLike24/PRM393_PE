import 'package:flutter/material.dart';
import '../models/song.dart';
import '../services/music_service.dart';
import '../services/session.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final ctrl = TextEditingController();
  List<Song> results = [];
  List<Map<String, dynamic>> history = [];
  bool loading = false;

  @override
  void initState() {
    super.initState();
    MusicService.changeNotifier.addListener(_onDataChanged);
    _loadHistory();
  }

  @override
  void dispose() {
    MusicService.changeNotifier.removeListener(_onDataChanged);
    ctrl.dispose();
    super.dispose();
  }

  void _onDataChanged() {
    if (!mounted) return;
    if (ctrl.text.trim().isNotEmpty) {
      _search(ctrl.text);
    } else {
      _loadHistory();
    }
  }

  Future<void> _loadHistory() async {
    history = await MusicService.instance.getSearchHistory();
    if (mounted) setState(() {});
  }

  Future<void> _search([String? text]) async {
    final q = (text ?? ctrl.text).trim();
    if (q.isEmpty) return;
    ctrl.text = q;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => loading = true);
    try {
      results = await MusicService.instance.searchSongs(q);
      await _loadHistory();
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tim kiem')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: ctrl,
              decoration: InputDecoration(
                hintText: 'Bai hat, ca si...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: _search,
                ),
                border: const OutlineInputBorder(),
              ),
              onSubmitted: _search,
            ),
          ),
          if (Session.isLoggedIn && history.isNotEmpty) ...[
            ListTile(
              title: const Text('Tim kiem gan day'),
              trailing: TextButton(
                onPressed: () async {
                  await MusicService.instance.clearSearchHistory();
                  await _loadHistory();
                },
                child: const Text('Xoa tat ca'),
              ),
            ),
            ...history.map((h) {
              final id = h['id'] as int;
              final q = h['search_query']?.toString() ?? '';
              return ListTile(
                leading: const Icon(Icons.history),
                title: Text(q),
                onTap: () => _search(q),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () async {
                    await MusicService.instance.deleteSearchHistoryItem(id);
                    await _loadHistory();
                  },
                ),
              );
            }),
            const Divider(),
          ],
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
              itemCount: results.length,
              itemBuilder: (_, i) {
                final s = results[i];
                return ListTile(
                  title: Text(s.title),
                  subtitle: Text(s.artist),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}