import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../features/loans/screens/loans_list_screen.dart';
import '../features/bills/screens/bills_history_screen.dart';
import '../features/clients/screens/clients_list_screen.dart';
import '../features/bills/screens/manage_jewelry_types_screen.dart';
import '../features/reports/screens/reports_tab.dart';
import '../features/auth/auth_provider.dart';
import '../core/theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'widgets/gold_price_banner.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    ReportsTab(),
    LoansListScreen(),
    BillsHistoryScreen(),
    ClientsListScreen(),
    ManageJewelryTypesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 800;
    return isWide ? _buildWideLayout() : _buildNarrowLayout();
  }

  Widget _buildNarrowLayout() {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const GoldPriceBanner(),
            Expanded(child: IndexedStack(index: _selectedIndex, children: _pages)),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildWideLayout() {
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            _buildSideNav(),
            const VerticalDivider(width: 1),
            Expanded(
              child: Column(
                children: [
                  const GoldPriceBanner(),
                  Expanded(child: IndexedStack(index: _selectedIndex, children: _pages)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex > 4 ? 4 : _selectedIndex,
      onTap: (i) => setState(() => _selectedIndex = i),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_outlined),
          activeIcon: Icon(Icons.dashboard),
          label: 'Accueil',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.credit_card_outlined),
          activeIcon: Icon(Icons.credit_card),
          label: 'Dettes',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.receipt_long_outlined),
          activeIcon: Icon(Icons.receipt_long),
          label: 'Factures',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people_outline),
          activeIcon: Icon(Icons.people),
          label: 'Clients',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.inventory_2_outlined),
          activeIcon: Icon(Icons.inventory_2),
          label: 'Stock',
        ),
      ],
      type: BottomNavigationBarType.fixed,
    );
  }

  Widget _buildSideNav() {
    return Container(
      width: 220,
      decoration: AppTheme.greenGradientDecoration,
      child: Column(
        children: [
          const SizedBox(height: 40),
          // Logo
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/logo.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Bijouterie\nEl-Hajjam',
            textAlign: TextAlign.center,
            style: GoogleFonts.playfairDisplay(
              color: AppTheme.gold,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 32),
          _sideNavItem(0, Icons.dashboard, 'Accueil / Rapports', 'الرئيسية'),
          _sideNavItem(1, Icons.credit_card, 'Gestion des Dettes', 'إدارة الديون'),
          _sideNavItem(2, Icons.receipt_long, 'Factures', 'الفواتير'),
          _sideNavItem(3, Icons.people, 'Clients', 'الزبائن'),
          _sideNavItem(4, Icons.inventory_2, 'Stock / Articles', 'السلع'),
          const Spacer(),
          _sideNavLogout(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _sideNavItem(int index, IconData icon, String label, String arLabel) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.gold.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: isSelected
              ? Border.all(color: AppTheme.gold.withOpacity(0.3))
              : null,
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppTheme.gold : Colors.white60, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? AppTheme.gold : Colors.white70,
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                    ),
                  ),
                  Text(
                    arLabel,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      color: isSelected ? AppTheme.goldLight : Colors.white38,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sideNavLogout() {
    return GestureDetector(
      onTap: () => context.read<AuthProvider>().signOut(),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white24),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(Icons.logout, color: Colors.white54, size: 18),
            const SizedBox(width: 10),
            Text(
              'Déconnexion',
              style: GoogleFonts.lato(color: Colors.white54, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
