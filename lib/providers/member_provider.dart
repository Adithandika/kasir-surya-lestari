import 'package:flutter/foundation.dart';
import '../models/member.dart';
import '../services/database_service.dart';

class MemberProvider with ChangeNotifier {
  List<Member> _members = [];
  List<Member> _filteredMembers = [];
  String _searchQuery = '';

  List<Member> get members => _filteredMembers;

  MemberProvider() {
    _init();
  }

  Future<void> _init() async {
    _members = await DatabaseService.getAllMembers();
    _applyFilters();
  }

  void searchMember(String query) {
    _searchQuery = query.toLowerCase();
    _applyFilters();
  }

  void _applyFilters() {
    _filteredMembers = _members.where((m) {
      final nameMatches = m.name.toLowerCase().contains(_searchQuery);
      final phoneMatches = m.phone.contains(_searchQuery);
      final addressMatches = m.address?.toLowerCase().contains(_searchQuery) ?? false;
      return nameMatches || phoneMatches || addressMatches;
    }).toList();
    notifyListeners();
  }

  Future<void> addMember(Member member) async {
    await DatabaseService.saveMember(member);
    _members = await DatabaseService.getAllMembers();
    _applyFilters();
  }

  Future<void> updateMember(Member member) async {
    await DatabaseService.saveMember(member);
    _members = await DatabaseService.getAllMembers();
    _applyFilters();
  }

  Future<void> deleteMember(int id) async {
    await DatabaseService.deleteMember(id);
    _members = await DatabaseService.getAllMembers();
    _applyFilters();
  }

  Future<void> addPoints(int id, int points) async {
    final index = _members.indexWhere((m) => m.id == id);
    if (index != -1) {
      final updatedMember = _members[index].copyWith(
        points: _members[index].points + points,
      );
      await DatabaseService.saveMember(updatedMember);
      _members = await DatabaseService.getAllMembers();
      _applyFilters();
    }
  }

  Member? findByPhone(String phone) {
    try {
      return _members.firstWhere((m) => m.phone == phone);
    } catch (e) {
      return null;
    }
  }
}
