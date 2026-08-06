import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'admin_service.dart';
import 'institution_service.dart';
import '../core/cache/local_cache_service.dart';

// ─── Data Models ────────────────────────────────────────────────────────────

class MessMeal {
  final String name;
  final List<String> items;
  final String imageUrl;

  MessMeal({required this.name, required this.items, this.imageUrl = ''});

  String get displayImageUrl {
    if (imageUrl.isNotEmpty) return imageUrl;
    if (name.contains('Breakfast')) return 'assets/mess/breakfast.png';
    if (name.contains('Lunch')) return 'assets/mess/lunch.png';
    if (name.contains('Snacks')) return 'assets/mess/snacks.png';
    if (name.contains('Dinner')) return 'assets/mess/dinner.png';
    return '';
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'items': items,
      'imageUrl': imageUrl,
    };
  }

  factory MessMeal.fromMap(Map<String, dynamic> map) {
    return MessMeal(
      name: map['name'] ?? '',
      items: List<String>.from(map['items'] ?? []),
      imageUrl: map['imageUrl'] ?? '',
    );
  }
}

class MessMenu {
  final String day;
  final List<MessMeal> meals;

  MessMenu({required this.day, required this.meals});

  Map<String, dynamic> toMap() => {
    'day': day,
    'meals': meals.map((m) => m.toMap()).toList(),
  };

  factory MessMenu.fromMap(Map<String, dynamic> map) => MessMenu(
    day: map['day'] ?? '',
    meals: (map['meals'] as List? ?? []).map((m) => MessMeal.fromMap(m)).toList(),
  );
}

class MessState {
  final Map<String, MessMenu> weeklyMenu;
  final bool isAdmin;
  final bool isEvenWeek;
  /// True when this state was loaded from the local Hive cache, not live Firestore.
  final bool fromCache;
  /// When the data was last successfully fetched from Firestore.
  final DateTime? lastUpdated;

  MessState({
    required this.weeklyMenu,
    required this.isAdmin,
    required this.isEvenWeek,
    this.fromCache = false,
    this.lastUpdated,
  });

  MessState copyWith({
    Map<String, MessMenu>? weeklyMenu,
    bool? isAdmin,
    bool? isEvenWeek,
    bool? fromCache,
    DateTime? lastUpdated,
  }) {
    return MessState(
      weeklyMenu: weeklyMenu ?? this.weeklyMenu,
      isAdmin: isAdmin ?? this.isAdmin,
      isEvenWeek: isEvenWeek ?? this.isEvenWeek,
      fromCache: fromCache ?? this.fromCache,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

// ─── Default Template ────────────────────────────────────────────────────────
//
// Used ONLY by the explicit admin "Initialize default menu" action.
// This data is NEVER written automatically — it is only written when an admin
// intentionally taps the "Initialize" button on an institution with no menu yet.

class MessDefaultTemplate {
  static const Map<String, Map<String, List<String>>> evenWeek = {
    'Monday': {
      'Breakfast': ['Poori', 'Aloo Masala Curry', 'BBL Sprouts', 'Banana', 'Tea/Coffee/Milk'],
      'Lunch': ['Rice', 'Vathakolambu', 'Curd', 'Fryums', 'Pickle', 'Salad'],
      'Snacks': ['Sundal', 'Tea/Coffee/Milk'],
      'Dinner': ['Tawa Chapathi', 'Channa Masala', 'Rice', 'Sambar', 'Fryums', 'Rasam', 'Boondi Laddu'],
    },
    'Tuesday': {
      'Breakfast': ['Ragi Dosa, Upma', 'Sambar, Groundnut Chutney', 'BBL Sprouts', 'Seasonal Cut Fruits', 'Tea/Coffee/Milk'],
      'Lunch': ['Rice', 'Rasam', 'Curd', 'Papad', 'Pickle', 'Seasonal Fruit Juice', 'Salad'],
      'Snacks': ['Bread Pakora', 'Tomato Sauce', 'Tea/Coffee/Milk'],
      'Dinner': ['Tomato Rice', 'Phulka', 'Aloo Brinjal Curry', 'Papad', 'Buttermilk', 'Gulab Jamun'],
    },
    'Wednesday': {
      'Breakfast': ['Masala Dosa', 'Sambar, Tomato Onion Chutney', 'BBL Sprouts', 'Banana', 'Tea/Coffee/Milk'],
      'Lunch': ['Rice', 'Rasam', 'Curd', 'Fryums', 'Pickle', 'Seasonal Fruit Juice', 'Salad'],
      'Snacks': ['Sweet Potato', 'Tea/Coffee/Milk'],
      'Dinner': ['Special Dinner'],
    },
    'Thursday': {
      'Breakfast': ['Chow Chow Bath', 'Mysore Bonda', 'Coconut Chutney', 'BBL Sprouts', 'Seasonal Cut Fruits', 'Tea/Coffee/Milk'],
      'Lunch': ['Rice', 'Mix Veg Karakozhambu', 'Rasam', 'Curd', 'Papad', 'Gongura Chutney', 'Salad'],
      'Snacks': ['Channa Chat', 'Tea/Coffee/Milk'],
      'Dinner': ['Chole Bature', 'Rajma Rice', 'Buttermilk', 'Parippu Payasam'],
    },
    'Friday': {
      'Breakfast': ['Rava Idly, Vada (2)', 'Sambar, Tomato Onion Chutney', 'BBL Sprouts', 'Banana', 'Tea/Coffee/Milk'],
      'Lunch': ['Rice', 'Sambar', 'Curd', 'Fryums', 'Pickle', 'Seasonal Fruit Juice', 'Salad'],
      'Snacks': ['Mix Veg Maggi', 'Tomato Sauce', 'Tea/Coffee/Milk'],
      'Dinner': ['Paneer Curry', 'Tawa Chapathi', 'Veg Biryani', 'Raitha', 'Sweet Boondi'],
    },
    'Saturday': {
      'Breakfast': ['Onion Paratha', 'Kabuli Channa Masala, Curd, Pickle', 'BBL Sprouts', 'Seasonal Cut Fruits', 'Tea/Coffee/Milk'],
      'Lunch': ['Rice', 'Rasam', 'Papad', 'Pickle', 'Banana Juice', 'Salad'],
      'Snacks': ['Aloo Samosa', 'Tea/Coffee/Milk'],
      'Dinner': ['Dosa', 'Peanut Chutney', 'Plain Rice', 'Mixed Dal', 'Buttermilk', 'Bread Halwa'],
    },
    'Sunday': {
      'Breakfast': ['Onion Dosa', 'Sambar, Coconut Chutney', 'BBL Sprouts', 'Seasonal Cut Fruits', 'Tea/Coffee/Milk'],
      'Lunch': ['Plain Biryani', 'Raitha', 'Rice', 'Dal', 'Veg Fry', 'Curd', 'Salad'],
      'Snacks': ['Pani Puri', 'Green Chutney', 'Tea/Coffee/Milk'],
      'Dinner': ['Idyappam', 'Sambar', 'Idli Karam', 'Ghee', 'Lemon Rice', 'Pickle', 'Curd Rice', 'Sweet Pongal'],
    },
  };

  static const Map<String, Map<String, List<String>>> oddWeek = {
    'Monday': {
      'Breakfast': ['Pongal, Vada (3)', 'Sambar, Groundnut Chutney', 'BBL Sprouts', 'Banana', 'Tea/Coffee/Milk'],
      'Lunch': ['Phulka', 'Dal Makhani', 'Bhindi Fry', 'Rice', 'Sambar', 'Rasam', 'Curd', 'Pickle', 'Papad', 'Fruit Juice', 'Salad'],
      'Snacks': ['Pasta', 'Tea/Coffee/Milk'],
      'Dinner': ['Chole Bature', 'Onion Mirch Salad', 'White Rice', 'Snake Gourd Kootu', 'Curd', 'Rasam', 'Banana'],
    },
    'Tuesday': {
      'Breakfast': ['Idli, Rice Bonda', 'Sambar, Coconut Chutney', 'BBL Sprouts', 'Seasonal Cut Fruits', 'Tea/Coffee/Milk'],
      'Lunch': ['Tawa Chapathi', 'Dum Aloo', 'Beans Carrot Poriyal', 'Rice', 'Panchratan Dal', 'Rasam', 'Curd', 'Fryums', 'Pickle', 'Salad'],
      'Snacks': ['Onion Pakoda', 'Tea/Coffee/Milk'],
      'Dinner': ['Rice', 'Sambar', 'Tawa Chapathi', 'Channa Masala', 'Fryums', 'Beetroot Poriyal', 'Bread Halwa'],
    },
    'Wednesday': {
      'Breakfast': ['Puri', 'Aloo Curry', 'BBL Sprouts', 'Banana', 'Tea/Coffee/Milk'],
      'Lunch': ['Phulka', 'Andhra Tomato Dal', 'Onion Pakoda', 'Perugu Pachadi', 'Rice', 'Rasam', 'Masala Papad', 'Cabbage Moong Dal', 'Pickle', 'Fruit Juice', 'Salad'],
      'Snacks': ['Boiled Groundnuts', 'Tea/Coffee/Milk'],
      'Dinner': ['Phulka', 'Veg Biryani', 'Raitha', 'Paneer Manchurian', 'Dal Fry', 'Sabudhana Kheer'],
    },
    'Thursday': {
      'Breakfast': ['Wheat Rava Upma, Poha', 'Mysore Bonda (3)', 'Tomato Onion Chutney', 'BBL Sprouts', 'Seasonal Cut Fruits', 'Tea/Coffee/Milk'],
      'Lunch': ['Tawa Chapathi', 'Kadai Panner', 'Rice', 'Masala Sambar', 'Curd', 'Fryums', 'Pickle', 'Salad'],
      'Snacks': ['Sweet Corn', 'Tea/Coffee/Milk'],
      'Dinner': ['Lacha Paratha', 'Salna', 'Kovakai Poriyal', 'Rice', 'Rasam', 'Onion Salad', 'Badam Milk'],
    },
    'Friday': {
      'Breakfast': ['Rava Idly, Vada (3)', 'Sambar, Groundnut Chutney', 'BBL Sprouts', 'Banana', 'Tea/Coffee/Milk'],
      'Lunch': ['Phulka', 'Rajma Dal', 'Jeera Rice', 'Dum Aloo', 'Rice', 'Rasam', 'Curd', 'Fryums', 'Salad'],
      'Snacks': ['Masala Vada', 'Tomato Sauce', 'Tea/Coffee/Milk'],
      'Dinner': ['Tawa Chapathi', 'Veg Pulao', 'Raitha', 'Kaju Curry', 'Kesari Bat'],
    },
    'Saturday': {
      'Breakfast': ['Aloo Paratha', 'Channa Masala, Curd, Pickle', 'BBL Sprouts', 'Seasonal Cut Fruits', 'Tea/Coffee/Milk'],
      'Lunch': ['Lauki Chana Dal', 'Gobi 65', 'Rice', 'Rasam', 'Curd', 'Fryums', 'Pickle', 'Salad'],
      'Snacks': ['Millet Snack', 'Tea/Coffee/Milk'],
      'Dinner': ['Phulka', 'Channa Peas Palak', 'Sambar Rice', 'Curd Rice', 'Aloo 65', 'Pickle', 'Gulam Jamun'],
    },
    'Sunday': {
      'Breakfast': ['Rava Dosa, Semiya Upma', 'Sambar, Coconut Chutney', 'BBL Sprouts', 'Seasonal Cut Fruits', 'Tea/Coffee/Milk'],
      'Lunch': ['Pulkha', 'Dal Makhani', 'Kaju Curry', 'Veg Biryani', 'Raitha', 'Tawa Chapathi', 'Badusha', 'Ice Cream', 'Salad'],
      'Snacks': ['Pani Puri', 'Green Chutney', 'Tea/Coffee/Milk'],
      'Dinner': ['Chapatti', 'Veg Curry', 'Tamarind Rice', 'Buttermilk', 'Fryums', 'Lime Pickle', 'Ghee', 'Seasonal Fruits'],
    },
  };

  static const _imgUrls = {
    'Breakfast': 'assets/mess/breakfast.png',
    'Lunch': 'assets/mess/lunch.png',
    'Snacks': 'assets/mess/snacks.png',
    'Dinner': 'assets/mess/dinner.png',
  };

  /// Converts template data for a given week parity into a list of [MessMenu]s.
  static List<MessMenu> buildMenus(bool isEvenWeek) {
    final weekData = isEvenWeek ? evenWeek : oddWeek;
    return weekData.entries.map((dayEntry) {
      final meals = dayEntry.value.entries.map((mealEntry) {
        return MessMeal(
          name: mealEntry.key,
          items: mealEntry.value,
          imageUrl: _imgUrls[mealEntry.key] ?? '',
        );
      }).toList();
      return MessMenu(day: dayEntry.key, meals: meals);
    }).toList();
  }
}

// ─── Notifier ────────────────────────────────────────────────────────────────

class MessNotifier extends StreamNotifier<MessState> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  late bool _isEvenWeek;

  MessNotifier() {
    _isEvenWeek = getCalculatedParity();
  }

  static bool getCalculatedParity() {
    final now = DateTime.now();
    int dayOfYear = int.parse(now.difference(DateTime(now.year, 1, 1)).inDays.toString());
    int weekNum = ((dayOfYear - now.weekday + 10) / 7).floor();
    return weekNum % 2 != 0;
  }

  @override
  Stream<MessState> build() {
    final isAdmin = ref.watch(adminProvider).valueOrNull ?? false;
    final institution = ref.watch(institutionProvider).valueOrNull;
    final collegeId = institution?.collegeId ?? 'iiitdm';
    final weekPath = _isEvenWeek ? 'even' : 'odd';
    final cacheKey = '${collegeId}_$weekPath';

    // ── 1. Seed from Hive cache immediately (synchronous) ─────────────────────
    // The StreamNotifier's initial AsyncValue is AsyncLoading until the stream
    // emits. We schedule a microtask to set cached state before Firestore fires.
    Future.microtask(() {
      if (state is AsyncLoading) {
        final cached = LocalCacheService.readMessMenu(cacheKey, isAdmin: isAdmin);
        if (cached != null) {
          state = AsyncData(cached.state);
        }
      }
    });

    // ── 2. Attach Firestore stream scoped by collegeId ────────────────────────
    return _db
        .collection('institutions')
        .doc(collegeId)
        .collection('messMenu')
        .doc(weekPath)
        .collection('days')
        .snapshots()
        .asyncMap((snapshot) async {
      if (snapshot.docs.isEmpty) {
        // Fallback to default template so students always see a full, real menu
        final fallbackList = MessDefaultTemplate.buildMenus(_isEvenWeek);
        final Map<String, MessMenu> fallbackMenu = {for (var m in fallbackList) m.day: m};

        return MessState(
          weeklyMenu: fallbackMenu,
          isAdmin: isAdmin,
          isEvenWeek: _isEvenWeek,
          fromCache: true,
          lastUpdated: DateTime.now(),
        );
      }

      final Map<String, MessMenu> newMenu = {};
      for (var doc in snapshot.docs) {
        newMenu[doc.id] = MessMenu.fromMap(doc.data());
      }
      final freshState = MessState(
        weeklyMenu: newMenu,
        isAdmin: isAdmin,
        isEvenWeek: _isEvenWeek,
        fromCache: false,
        lastUpdated: DateTime.now(),
      );

      // ── 3. Write back to Hive cache (fire-and-forget) ─────────────────────
      LocalCacheService.writeMessMenu(cacheKey, freshState);

      return freshState;
    }).handleError((error, stackTrace) {
      debugPrint('Firestore Mess Stream Error: $error. Returning default fallback menu.');
      final fallbackList = MessDefaultTemplate.buildMenus(_isEvenWeek);
      final Map<String, MessMenu> fallbackMenu = {for (var m in fallbackList) m.day: m};

      return MessState(
        weeklyMenu: fallbackMenu,
        isAdmin: isAdmin,
        isEvenWeek: _isEvenWeek,
        fromCache: true,
        lastUpdated: DateTime.now(),
      );
    });
  }

  void toggleWeek() {
    _isEvenWeek = !_isEvenWeek;
    ref.invalidateSelf();
  }

  /// Explicit admin action: writes the default menu template for both weeks
  /// to Firestore under the current institution's messMenu subcollection.
  /// Only callable when the admin is logged in.
  /// This is the ONLY place where template data is ever written to Firestore.
  Future<void> initializeDefaultMenu() async {
    final currentState = state.valueOrNull;
    if (currentState == null || !currentState.isAdmin) return;

    final institution = ref.read(institutionProvider).valueOrNull;
    final collegeId = institution?.collegeId ?? 'iiitdm';

    for (final parity in ['even', 'odd']) {
      final isEven = parity == 'even';
      final menus = MessDefaultTemplate.buildMenus(isEven);
      for (final menu in menus) {
        await _db
            .collection('institutions')
            .doc(collegeId)
            .collection('messMenu')
            .doc(parity)
            .collection('days')
            .doc(menu.day)
            .set(menu.toMap());
      }
    }
  }

  Future<void> updateMeal(String day, int mealIndex, List<String> newItems) async {
    final currentStateVal = state.valueOrNull;
    if (currentStateVal == null || !currentStateVal.isAdmin) return;

    final menu = currentStateVal.weeklyMenu[day];
    if (menu != null && mealIndex < menu.meals.length) {
      final updatedMeals = List<MessMeal>.from(menu.meals);
      updatedMeals[mealIndex] = MessMeal(
        name: menu.meals[mealIndex].name,
        items: newItems,
        imageUrl: menu.meals[mealIndex].imageUrl,
      );

      final institution = ref.read(institutionProvider).valueOrNull;
      final collegeId = institution?.collegeId ?? 'iiitdm';
      final weekPath = _isEvenWeek ? 'even' : 'odd';
      await _db
          .collection('institutions')
          .doc(collegeId)
          .collection('messMenu')
          .doc(weekPath)
          .collection('days')
          .doc(day)
          .update({
        'meals': updatedMeals.map((m) => m.toMap()).toList(),
      });
    }
  }
}

final messProvider = StreamNotifierProvider<MessNotifier, MessState>(() {
  return MessNotifier();
});
