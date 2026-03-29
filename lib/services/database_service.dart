import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/product.dart';
import '../models/order.dart';
import '../models/member.dart';

class DatabaseService {
  static late Isar isar;

  static Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    isar = await Isar.open(
      [ProductSchema, OrderModelSchema, MemberSchema],
      directory: dir.path,
    );
    
    // Trigger daily backup check
    await performDailyBackup();
  }

  // Backup logic
  static Future<void> performDailyBackup() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final backupDir = Directory(p.join(dir.path, 'backups'));
      
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }

      final now = DateTime.now();
      final dateStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      final backupFile = File(p.join(backupDir.path, 'backup_$dateStr.isar'));

      if (!await backupFile.exists()) {
        // Simple file copy for backup
        // Note: In a real production app, you might want to use isar.copyToFile()
        // but for now, we'll copy the actual file if isar is closed or use copyToFile.
        await isar.copyToFile(backupFile.path);
        debugPrint('Backup created: ${backupFile.path}');
        
        // Optional: Clean up old backups (keep last 7 days)
        final files = backupDir.listSync();
        if (files.length > 7) {
          files.sort((a, b) => a.statSync().modified.compareTo(b.statSync().modified));
          await files.first.delete();
        }
      }
    } catch (e) {
      debugPrint('Backup failed: $e');
    }
  }

  // Product CRUD
  static Future<List<Product>> getAllProducts() async {
    return await isar.products.where().findAll();
  }

  static Future<void> saveProduct(Product product) async {
    await isar.writeTxn(() async {
      await isar.products.put(product);
    });
  }

  static Future<void> deleteProduct(Id id) async {
    await isar.writeTxn(() async {
      await isar.products.delete(id);
    });
  }

  // Order CRUD
  static Future<List<OrderModel>> getOrderHistory() async {
    return await isar.orderModels.where().sortByDateDesc().findAll();
  }

  static Future<void> saveOrder(OrderModel order) async {
    await isar.writeTxn(() async {
      await isar.orderModels.put(order);
    });
  }

  // Member CRUD
  static Future<List<Member>> getAllMembers() async {
    return await isar.members.where().findAll();
  }

  static Future<void> saveMember(Member member) async {
    await isar.writeTxn(() async {
      await isar.members.put(member);
    });
  }

  static Future<void> deleteMember(Id id) async {
    await isar.writeTxn(() async {
      await isar.members.delete(id);
    });
  }


}
