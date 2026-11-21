import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FoodMenuScreen extends StatefulWidget {
  const FoodMenuScreen({super.key});

  @override
  State<FoodMenuScreen> createState() => _FoodMenuScreenState();
}

class _FoodMenuScreenState extends State<FoodMenuScreen> {
  final supabase = Supabase.instance.client;

  final menuController = TextEditingController();
  final descriptionController = TextEditingController();

  List<Map<String, dynamic>> meals = [];
  Set<int> selectedMealsForMember = {}; // Meal IDs member has opted in for

  String selectedMeal = 'breakfast';
  String selectedDayOfWeek = 'Monday';
  DateTime selectedDate = DateTime.now();

  String userRole = 'member';
  bool isLoading = true;
  bool isSaving = false;
  String selectedFilter = 'All';

  final Color primaryColor = const Color(0xFF176B50);
  final List<String> days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  void initState() {
    super.initState();
    loadMeals();
  }

  @override
  void dispose() {
    menuController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> loadMeals() async {
    try {
      final user = supabase.auth.currentUser;

      String role = 'member';
      if (user != null) {
        final profile = await supabase
            .from('profiles')
            .select('role')
            .eq('id', user.id)
            .maybeSingle();

        role = profile?['role'] ?? user.userMetadata?['role'] ?? 'member';
      }

      final data = await supabase
          .from('meals')
          .select()
          .order('meal_date', ascending: false);

      if (!mounted) return;

      setState(() {
        userRole = role;
        meals = List<Map<String, dynamic>>.from(data);
        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => isLoading = false);
      showMessage('Unable to load food menu: $error');
    }
  }

  void showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  String formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> chooseDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
    );

    if (date != null) {
      setState(() => selectedDate = date);
    }
  }

  Future<void> saveMeal({int? mealId}) async {
    final menu = menuController.text.trim();

    if (menu.isEmpty) {
      showMessage('Please enter food items.', isError: true);
      return;
    }

    setState(() => isSaving = true);

    try {
      final values = {
        'meal_type': selectedMeal,
        'meal_date': '${selectedDate.year}-'
            '${selectedDate.month.toString().padLeft(2, '0')}-'
            '${selectedDate.day.toString().padLeft(2, '0')}',
        'day_of_week': selectedDayOfWeek,
        'menu_items': menu,
        'description': descriptionController.text.trim(),
      };

      if (mealId == null) {
        await supabase.from('meals').insert(values);
        showMessage('Food menu added to schedule.');
      } else {
        await supabase.from('meals').update(values).eq('id', mealId);
        showMessage('Food menu updated.');
      }

      if (!mounted) return;

      Navigator.pop(context);
      clearFields();
      await loadMeals();
    } catch (error) {
      showMessage('Unable to save menu: $error', isError: true);
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  void clearFields() {
    menuController.clear();
    descriptionController.clear();
    selectedMeal = 'breakfast';
    selectedDayOfWeek = 'Monday';
    selectedDate = DateTime.now();
  }

  void toggleMealOptIn(int mealId) {
    setState(() {
      if (selectedMealsForMember.contains(mealId)) {
        selectedMealsForMember.remove(mealId);
        showMessage('Opted out of meal attendance.');
      } else {
        selectedMealsForMember.add(mealId);
        showMessage('Opted in for meal attendance!');
      }
    });
  }

  void openMealForm({Map<String, dynamic>? meal}) {
    final mealId = meal?['id'] as int?;

    menuController.text = meal?['menu_items'] ?? '';
    descriptionController.text = meal?['description'] ?? '';
    selectedMeal = meal?['meal_type'] ?? 'breakfast';
    selectedDayOfWeek = meal?['day_of_week'] ?? 'Monday';
    selectedDate = meal == null
        ? DateTime.now()
        : DateTime.parse(meal['meal_date']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, updateSheet) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                24,
                20,
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          meal == null ? 'Add Food Timetable' : 'Edit Food Timetable',
                          style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    DropdownButtonFormField<String>(
                      initialValue: selectedMeal,
                      decoration: const InputDecoration(
                        labelText: 'Meal Time',
                        prefixIcon: Icon(Icons.access_time),
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'breakfast', child: Text('Breakfast (Morning)')),
                        DropdownMenuItem(value: 'lunch', child: Text('Lunch (Afternoon)')),
                        DropdownMenuItem(value: 'dinner', child: Text('Dinner (Night)')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          updateSheet(() => selectedMeal = value);
                        }
                      },
                    ),

                    const SizedBox(height: 14),

                    DropdownButtonFormField<String>(
                      initialValue: selectedDayOfWeek,
                      decoration: const InputDecoration(
                        labelText: 'Day of Week',
                        prefixIcon: Icon(Icons.calendar_today),
                        border: OutlineInputBorder(),
                      ),
                      items: days.map((day) {
                        return DropdownMenuItem(value: day, child: Text(day));
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          updateSheet(() => selectedDayOfWeek = value);
                        }
                      },
                    ),

                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              await chooseDate();
                              updateSheet(() {});
                            },
                            icon: const Icon(Icons.calendar_month),
                            label: Text('Date: ${formatDate(selectedDate)}'),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    TextField(
                      controller: menuController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Food Items Menu',
                        hintText: 'e.g., Chicken Karahi, Naan, Salad, Cold Drink',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 14),

                    TextField(
                      controller: descriptionController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Special Instructions / Notes',
                        hintText: 'e.g., Served at 8:30 PM',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: primaryColor),
                        onPressed: isSaving ? null : () => saveMeal(mealId: mealId),
                        child: Text(
                          isSaving
                              ? 'Saving...'
                              : (meal == null ? 'Add to Food Schedule' : 'Save Changes'),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> deleteMeal(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Menu Item?'),
        content: const Text('Are you sure you want to remove this meal from the menu?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await supabase.from('meals').delete().eq('id', id);
      showMessage('Menu item removed.');
      await loadMeals();
    } catch (error) {
      showMessage('Unable to delete menu: $error', isError: true);
    }
  }

  Widget mealIcon(String type) {
    switch (type.toLowerCase()) {
      case 'breakfast':
        return const Icon(Icons.free_breakfast, color: Color(0xFF176B50));
      case 'lunch':
        return const Icon(Icons.lunch_dining, color: Color(0xFF176B50));
      default:
        return const Icon(Icons.dinner_dining, color: Color(0xFF176B50));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = userRole == 'admin';

    final filteredMeals = meals.where((meal) {
      if (selectedFilter == 'All') return true;
      return (meal['meal_type'] as String).toLowerCase() == selectedFilter.toLowerCase();
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(isAdmin ? 'Food Timetable & Menu' : 'Daily Mess Menu'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: loadMeals,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),

      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
        onPressed: () {
          clearFields();
          openMealForm();
        },
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Menu'),
      )
          : null,

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // Filter Bar
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ['All', 'Breakfast', 'Lunch', 'Dinner'].map((type) {
                final selected = selectedFilter == type;
                return ChoiceChip(
                  label: Text(type),
                  selected: selected,
                  selectedColor: primaryColor.withValues(alpha: 0.15),
                  labelStyle: TextStyle(
                    color: selected ? primaryColor : Colors.black87,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (_) {
                    setState(() => selectedFilter = type);
                  },
                );
              }).toList(),
            ),
          ),

          Expanded(
            child: filteredMeals.isEmpty
                ? const Center(
              child: Text(
                'No food items added for this filter.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
                : RefreshIndicator(
              onRefresh: loadMeals,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredMeals.length,
                itemBuilder: (context, index) {
                  final meal = filteredMeals[index];
                  final int mealId = meal['id'] ?? index;
                  final isAttending = selectedMealsForMember.contains(mealId);

                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: const Color(0xFFE1F1E9),
                                child: mealIcon(meal['meal_type'] ?? ''),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      (meal['meal_type'] ?? '').toString().toUpperCase(),
                                      style: TextStyle(
                                        color: primaryColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    Text(
                                      meal['day_of_week'] ?? formatDate(DateTime.parse(meal['meal_date'])),
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isAdmin)
                                PopupMenuButton<String>(
                                  onSelected: (value) {
                                    if (value == 'edit') {
                                      openMealForm(meal: meal);
                                    } else if (value == 'delete') {
                                      deleteMeal(meal['id'] as int);
                                    }
                                  },
                                  itemBuilder: (context) => const [
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: Text('Edit Menu'),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Text('Delete Menu', style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                )
                              else
                                FilterChip(
                                  avatar: Icon(
                                    isAttending ? Icons.check_circle : Icons.circle_outlined,
                                    size: 18,
                                    color: isAttending ? Colors.white : primaryColor,
                                  ),
                                  label: Text(
                                    isAttending ? 'Attending' : 'Opt In',
                                    style: TextStyle(
                                      color: isAttending ? Colors.white : primaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  selected: isAttending,
                                  selectedColor: primaryColor,
                                  onSelected: (_) => toggleMealOptIn(mealId),
                                ),
                            ],
                          ),
                          const Divider(height: 20),
                          Text(
                            meal['menu_items'] ?? '',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (meal['description'] != null &&
                              meal['description'].toString().isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              meal['description'],
                              style: const TextStyle(color: Colors.black87),
                            ),
                          ],
                        ],
                      ),
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
}
