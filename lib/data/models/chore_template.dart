// lib/data/models/chore_template.dart
import 'package:flutter/material.dart';

class ChoreTemplate {
  final String name;
  final String description;
  final String choreType;
  final String defaultFrequency; // 'once', 'Daily', 'Weekly', 'Monthly'
  final IconData icon;

  const ChoreTemplate({
    required this.name,
    required this.description,
    required this.choreType,
    required this.defaultFrequency,
    required this.icon,
  });

  static const List<ChoreTemplate> templates = [
    ChoreTemplate(
      name: 'Kitchen Cleaning',
      description: 'Clean counters, stove, sink and kitchen surfaces',
      choreType: 'kitchen_cleaning',
      defaultFrequency: 'Daily',
      icon: Icons.countertops_rounded,
    ),
    ChoreTemplate(
      name: 'Bathroom Cleaning',
      description: 'Clean toilet, shower, sink, and mirror',
      choreType: 'bathroom_cleaning',
      defaultFrequency: 'Weekly',
      icon: Icons.bathtub_rounded,
    ),
    ChoreTemplate(
      name: 'Take Out Trash',
      description: 'Empty all bins and take to collection point',
      choreType: 'taking_out_trash',
      defaultFrequency: 'Daily',
      icon: Icons.delete_outline_rounded,
    ),
    ChoreTemplate(
      name: 'Vacuum Living Areas',
      description: 'Vacuum carpets, rugs, and floors in living areas',
      choreType: 'vacuuming',
      defaultFrequency: 'Weekly',
      icon: Icons.cleaning_services_rounded,
    ),
    ChoreTemplate(
      name: 'Mop Floors',
      description: 'Mop kitchen and bathroom floors',
      choreType: 'mopping',
      defaultFrequency: 'Weekly',
      icon: Icons.water_drop_rounded,
    ),
    ChoreTemplate(
      name: 'Do Dishes',
      description: 'Wash or load dishes, clean and dry the sink',
      choreType: 'dishwashing',
      defaultFrequency: 'Daily',
      icon: Icons.soup_kitchen_rounded,
    ),
    ChoreTemplate(
      name: 'Laundry',
      description: 'Wash, dry, and fold clothes',
      choreType: 'other',
      defaultFrequency: 'Weekly',
      icon: Icons.local_laundry_service_rounded,
    ),
    ChoreTemplate(
      name: 'Grocery Shopping',
      description: 'Buy household essentials and groceries',
      choreType: 'grocery_shopping',
      defaultFrequency: 'Weekly',
      icon: Icons.shopping_cart_rounded,
    ),
    ChoreTemplate(
      name: 'Clean Fridge',
      description: 'Remove expired items and wipe down shelves',
      choreType: 'kitchen_cleaning',
      defaultFrequency: 'Monthly',
      icon: Icons.kitchen_rounded,
    ),
    ChoreTemplate(
      name: 'Dust & Wipe Surfaces',
      description: 'Dust furniture, shelves, and wipe down surfaces',
      choreType: 'other',
      defaultFrequency: 'Weekly',
      icon: Icons.air_rounded,
    ),
  ];
}
