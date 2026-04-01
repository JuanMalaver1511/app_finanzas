import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/transaction_model.dart';
import '../../widgets/dashboard/add_transaction_dialog.dart';

// ─── COLORES (mismos que el dashboard) ───────────────────────────────────────
const kAmber = Color(0xFFFFBB4E);
const kBg = Color(0xFFF0F2F5);
const kCard = Colors.white;
const kDark = Color(0xFF1A1A2E);
const kGrey = Color(0xFF8A8A9A);
const kGreen = Color(0xFF1D7E45);
const kGreenBtn = Color(0xFF27AE60);
const kRed = Color(0xFFE74C3C);
const kAmberLight = Color(0xFFFFF3DC);

// ─────────────────────────────────────────────────────────────────────────────
//  MOVEMENTS SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  Widget _buildDesktopHeader() {
    return Container(
      color: kBg,
      padding: const EdgeInsets.fromLTRB(32, 16, 32, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, '/');
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: kCard,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: kDark.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: kDark,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 7,
            height: 22,
            decoration: BoxDecoration(
              color: kAmber,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'Mis Metas',
            style: TextStyle(
              color: kDark,
              fontWeight: FontWeight.w800,
              fontSize: 22,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildDesktopHeader(),
        ],
      ),
    );
  }
}
