import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/local_db.dart';
import 'chat_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _chats = [];
  bool _loading = true;
  String _phone = '';

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final phone = prefs.getString('phone') ?? 'Papa Euro';
      
      // On s'assure que la DB est prête
      final chats = await LocalDb.instance.getChats();

      if (!mounted) return;
      setState(() {
        _phone = phone;
        _chats = chats;
        _loading = false;
      });
    } catch (e) {
      debugPrint("Erreur chargement : $e");
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('phone');

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Thème sombre cohérent
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'MESSAGERIE',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Colors.white),
        ),
        actions: [
          IconButton(
            tooltip: 'Actualiser',
            onPressed: _loadAll,
            icon: const Icon(Icons.refresh, color: Colors.indigoAccent),
          ),
          IconButton(
            tooltip: 'Déconnexion',
            onPressed: _logout,
            icon: const Icon(Icons.logout, color: Colors.redAccent),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.indigoAccent))
          : Column(
              children: [
                // Badge de statut utilisateur
                if (_phone.isNotEmpty)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.indigoAccent.withOpacity(0.2), Colors.transparent],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.indigoAccent.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.bolt_rounded, color: Colors.indigoAccent),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Session : $_phone\nMode Hors-ligne opérationnel',
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                // Liste des discussions
                Expanded(
                  child: _chats.isEmpty 
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        backgroundColor: const Color(0xFF1E293B),
                        color: Colors.indigoAccent,
                        onRefresh: _loadAll,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _chats.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final chat = _chats[index];
                            return Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E293B), // Gris bleu foncé
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                leading: CircleAvatar(
                                  radius: 25,
                                  backgroundColor: Colors.indigoAccent.withOpacity(0.1),
                                  child: const Icon(Icons.person_outline, color: Colors.indigoAccent),
                                ),
                                title: Text(
                                  chat['title'] ?? 'Sans nom',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                subtitle: Text(
                                  chat['lastMessage'] ?? 'Aucun message',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white38),
                                ),
                                trailing: const Icon(Icons.chevron_right, color: Colors.white10),
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ChatScreen(
                                        chatId: chat['id'] as int,
                                        title: chat['title'] as String,
                                      ),
                                    ),
                                  );
                                  _loadAll(); // Rafraîchir au retour
                                },
                              ),
                            );
                          },
                        ),
                      ),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64, color: Colors.white10),
          const SizedBox(height: 16),
          const Text("Aucune discussion trouvée", style: TextStyle(color: Colors.white24)),
        ],
      ),
    );
  }
}
