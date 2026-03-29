import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme.dart';
import '../../models/member.dart';
import '../../providers/member_provider.dart';
import '../../core/widgets/app_widgets.dart';

class MembershipScreen extends StatefulWidget {
  const MembershipScreen({super.key});

  @override
  State<MembershipScreen> createState() => _MembershipScreenState();
}

class _MembershipScreenState extends State<MembershipScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          AppHeader(
            badgeLabel: "CUSTOMER LOYALTY",
            title: "Program Member",
            actions: [
              ShadButton.outline(
                onPressed: () => _showMemberDialog(),
                size: ShadButtonSize.sm,
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.person_add_rounded, size: 16),
                    SizedBox(width: 8),
                    Text("Tambah Member", style: TextStyle(fontWeight: FontWeight.w800)),
                  ],
                ),
              ).animate().fadeIn(delay: 200.ms),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.screenPaddingH, AppTheme.contentPaddingTop, AppTheme.screenPaddingH, 8),
            child: AppSearchField(
              controller: _searchController,
              placeholder: "Cari nama atau telepon...",
              onChanged: (v) => context.read<MemberProvider>().searchMember(v),
            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
          ),
          const SizedBox(height: AppTheme.itemGap),
          Expanded(
            child: Consumer<MemberProvider>(
              builder: (context, provider, child) {
                if (provider.members.isEmpty) {
                  return _buildEmptyState().animate().fadeIn();
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.screenPaddingH, 0, AppTheme.screenPaddingH, AppTheme.bottomSafeArea),
                  itemCount: provider.members.length,
                  physics: const BouncingScrollPhysics(),
                  separatorBuilder: (context, index) => const SizedBox(height: 16),
                  itemBuilder: (context, index) => _buildMemberCard(provider.members[index])
                      .animate(delay: (index * 50).ms)
                      .fadeIn()
                      .slideY(begin: 0.1),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberCard(Member member) {
    return AppCard(
      padding: const EdgeInsets.all(20),
      radius: 24,
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withValues(alpha: 0.6),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                member.name.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 28,
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 17,
                    color: Theme.of(context).colorScheme.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.phone_rounded, size: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
                    const SizedBox(width: 6),
                    Text(
                      member.phone,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4), 
                        fontWeight: FontWeight.w700, 
                        fontSize: 12,
                      ),
                    ),
                    if (member.address != null && member.address!.isNotEmpty) ...[
                      const SizedBox(width: 16),
                      Icon(Icons.location_on_rounded, size: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          member.address!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4), 
                            fontWeight: FontWeight.w600, 
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Theme.of(context).primaryColor.withValues(alpha: 0.1)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "${member.points}",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Theme.of(context).primaryColor,
                    letterSpacing: -1.5,
                  ),
                ).animate(target: member.points > 100 ? 1 : 0).shimmer(duration: 2.seconds, color: Colors.white38),
                Text(
                  "LOYA POINTS",
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.5),
                    letterSpacing: 2.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Row(
            children: [
              _buildActionButton(
                Icons.edit_rounded,
                Theme.of(context).primaryColor,
                () => _showMemberDialog(member: member),
              ),
              const SizedBox(width: 8),
              _buildActionButton(Icons.delete_outline_rounded, AppTheme.errorColor, () => _confirmDelete(member)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, Color color, VoidCallback onPressed) {
    return ShadButton.ghost(
      onPressed: onPressed,
      padding: const EdgeInsets.all(8),
      child: Icon(icon, color: color, size: 18),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_alt_rounded,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
          ),
          const SizedBox(height: 16),
          Text(
            "Belum ada member",
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3), 
              fontSize: 16, 
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  void _showMemberDialog({Member? member}) {
    final theme = Theme.of(context);
    final nameController = TextEditingController(text: member?.name);
    final phoneController = TextEditingController(text: member?.phone);
    final addressController = TextEditingController(text: member?.address);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: theme.colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLG)),
        child: Container(
          padding: const EdgeInsets.all(32),
          width: 450,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppBadge(label: member == null ? "NEW MEMBER" : "EDIT MEMBER"),
                      const SizedBox(height: 12),
                      Text(
                        member == null ? "Tambah Member" : "Edit Informasi",
                        style: TextStyle(
                          fontSize: 24, 
                          fontWeight: FontWeight.w900,
                          color: theme.colorScheme.onSurface,
                          letterSpacing: -1,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: theme.scaffoldBackgroundColor,
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              const AppInputLabel(label: "NAMA LENGKAP"),
              const SizedBox(height: 10),
              ShadInput(
                controller: nameController,
                placeholder: const Text("Masukkan nama lengkap..."),
                leading: const Padding(padding: EdgeInsets.all(12), child: Icon(Icons.person_rounded, size: 18)),
              ),
              const SizedBox(height: 24),
              const AppInputLabel(label: "NOMOR TELEPON"),
              const SizedBox(height: 10),
              ShadInput(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                placeholder: const Text("Contoh: 0812..."),
                leading: const Padding(padding: EdgeInsets.all(12), child: Icon(Icons.phone_rounded, size: 18)),
              ),
              const SizedBox(height: 24),
              const AppInputLabel(label: "ALAMAT (OPSIONAL)"),
              const SizedBox(height: 10),
              ShadInput(
                controller: addressController,
                placeholder: const Text("Masukkan alamat lengkap..."),
                maxLines: 2,
                leading: const Padding(padding: EdgeInsets.all(12), child: Icon(Icons.location_on_rounded, size: 18)),
              ),
              const SizedBox(height: 40),
              Row(
                children: [
                  Expanded(
                    child: ShadButton.outline(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("BATAL", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ShadButton(
                      onPressed: () {
                        if (nameController.text.isEmpty || phoneController.text.isEmpty) return;
                        final provider = context.read<MemberProvider>();
                        if (member == null) {
                          provider.addMember(Member(
                            name: nameController.text.trim(), 
                            phone: phoneController.text.trim(), 
                            address: addressController.text.trim(),
                            createdAt: DateTime.now(),
                          ));
                        } else {
                          provider.updateMember(member.copyWith(
                            name: nameController.text.trim(), 
                            phone: phoneController.text.trim(),
                            address: addressController.text.trim(),
                          ));
                        }
                        Navigator.pop(context);
                      },
                      child: const Text("SIMPAN", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(Member member) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLG)),
        child: Container(
          padding: const EdgeInsets.all(32),
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_remove_rounded, color: AppTheme.errorColor, size: 40),
              ),
              const SizedBox(height: 24),
              const Text(
                "Hapus Member?",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5),
              ),
              const SizedBox(height: 12),
              Text(
                "Apakah Anda yakin ingin menghapus member \"${member.name}\"? Seluruh riwayat poin tidak dapat dipulihkan.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: ShadButton.outline(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("BATAL", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ShadButton.destructive(
                      onPressed: () {
                        context.read<MemberProvider>().deleteMember(member.id);
                        Navigator.pop(context);
                      },
                      child: const Text("HAPUS", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
