import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/app_store.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/glass.dart';
import '../widgets/state_view.dart';

class RiwayatPage extends StatefulWidget {
  const RiwayatPage({super.key});

  @override
  State<RiwayatPage> createState() => _RiwayatPageState();
}

class _RiwayatPageState extends State<RiwayatPage> {
  int _tab = 0, _filter = 0;
  static const _filters = ['Semua', 'Uang masuk', 'Uang keluar', 'Direncanakan'];

  String _jam(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}.${d.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppStore>();
    final c = context.dg;
    final list = [...s.trx]..sort((a, b) => b.tgl.compareTo(a.tgl));
    final tampil = list.where((t) {
      switch (_filter) {
        case 1:
          return t.masuk;
        case 2:
          return !t.masuk;
        case 3:
          return t.direncanakan;
        default:
          return true;
      }
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat & aktivitas')),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: ChipTabs(
            labels: const ['Transaksi', 'Aktivitas sistem'],
            index: _tab,
            onChanged: (v) => setState(() => _tab = v),
          ),
        ),
        if (_tab == 0)
          SizedBox(
            height: 46,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (var i = 0; i < _filters.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                        label: Text(_filters[i]),
                        selected: _filter == i,
                        onSelected: (_) => setState(() => _filter = i)),
                  ),
              ],
            ),
          ),
        Expanded(
          child: _tab == 0
              ? (tampil.isEmpty
                  ? const StateView(
                      gambar: 'assets/images/not-found.png',
                      judul: 'Belum ada transaksi',
                      pesan: 'Catatan uang masuk dan keluar akan muncul di sini.')
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: tampil.length,
                      itemBuilder: (_, i) {
                        final t = tampil[i];
                        final w = t.masuk ? c.masuk : c.keluar;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: GlassCard(
                            padding: const EdgeInsets.all(12),
                            radius: 18,
                            child: Row(children: [
                              IconTile(
                                  ukuran: 40,
                                  warna: w,
                                  child: Icon(t.masuk ? Icons.south_west : Icons.north_east,
                                      size: 18, color: w)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(t.ket,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                  Text('${t.kategori} • ${tglPendek(t.tgl)}',
                                      style: TextStyle(color: c.textSecondary, fontSize: 11)),
                                  if (t.direncanakan)
                                    Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Pill('Direncanakan', warna: c.warning)),
                                ]),
                              ),
                              Text('${t.masuk ? '+' : '-'} ${rp(t.nominal)}',
                                  style: TextStyle(fontWeight: FontWeight.w800, color: w)),
                            ]),
                          ),
                        );
                      },
                    ))
              : (s.log.isEmpty
                  ? const StateView(
                      gambar: 'assets/images/not-found.png',
                      judul: 'Belum ada aktivitas',
                      pesan: 'Tindakan robot akan tercatat di sini.')
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: s.log.length,
                      itemBuilder: (_, i) {
                        final e = s.log[i];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: GlassCard(
                            padding: const EdgeInsets.all(12),
                            radius: 18,
                            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Icon(Icons.smart_toy_outlined, size: 20, color: c.info),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(e.aksi, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                                  const SizedBox(height: 2),
                                  Text(e.hasil,
                                      style: TextStyle(color: c.textSecondary, fontSize: 12, height: 1.35)),
                                ]),
                              ),
                              const SizedBox(width: 8),
                              Text(_jam(e.tgl), style: TextStyle(color: c.textSecondary, fontSize: 11)),
                            ]),
                          ),
                        );
                      },
                    )),
        ),
      ]),
    );
  }
}