import 'package:flutter/material.dart';

/// Central color definitions used across the app UI (not templates).
/// Templates define their own colors internally.
class AppColors {
  AppColors._();

  // ── Base ──────────────────────────────────────────────────────
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);
  static const Color transparent = Colors.transparent;

  // ── Launcher background shades ────────────────────────────────
  static const Color darkBg = Color(0xFF0A0A0A);
  static const Color darkSurface = Color(0xFF1A1A1A);
  static const Color darkCard = Color(0xFF242424);

  // ── Accent ────────────────────────────────────────────────────
  static const Color accent = Color(0xFF6C63FF);
  static const Color accentLight = Color(0xFF9D97FF);

  // ── Text ──────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0B0);
  static const Color textHint = Color(0xFF606060);

  // ── Glass / overlay ───────────────────────────────────────────
  static const Color glassWhite = Color(0x1AFFFFFF);
  static const Color glassBorder = Color(0x33FFFFFF);
  static const Color overlayDark = Color(0x80000000);
  static const Color overlayLight = Color(0x33FFFFFF);

  // ── Dock ──────────────────────────────────────────────────────
  static const Color dockBg = Color(0x99000000);
  static const Color dockBorder = Color(0x33FFFFFF);

  // ── Drawer ────────────────────────────────────────────────────
  static const Color drawerBg = Color(0xE6000000);
  static const Color searchBarBg = Color(0xFF1E1E1E);
  static const Color searchBarBorder = Color(0xFF333333);
}