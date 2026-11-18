import 'package:flutter_test/flutter_test.dart';
import 'package:umkm_copilot/domain/restock_calculator.dart';

void main() {
  const calc = RestockCalculator();

  RestockInput base({
    double stok = 8,
    double jual7 = 14,
    int hariData = 7,
    double kas = 5000000,
  }) =>
      RestockInput(
        stokSekarang: stok,
        totalJual7Hari: jual7,
        hariDataTersedia: hariData,
        penjualanHariIni: 2,
        leadTimeHari: 2,
        hariCadangan: 3,
        hariCakupan: 14,
        kelipatanPesan: 5,
        hargaBeli: 150000,
        kasTersedia: kas,
      );

  test('stok hampir habis -> rekomendasi, dibulatkan ke kelipatan', () {
    final r = calc.hitung(base());
    // rata = 2/hari, sisa = 4 hari <= titik 5
    // mentah = 2*14 - 8 = 20 -> kelipatan 5 -> 20
    expect(r.status, RestockStatus.perluRestock);
    expect(r.jumlahUsulan, 20);
    expect(r.perkiraanBiaya, 3000000);
  });

  test('kas kurang ditandai', () {
    final r = calc.hitung(base(kas: 1200000));
    expect(r.kasKurang, true);
  });

  test('data kurang dari 3 hari', () {
    final r = calc.hitung(base(hariData: 2));
    expect(r.status, RestockStatus.dataBelumCukup);
  });

  test('jarang laku', () {
    final r = calc.hitung(base(jual7: 0));
    expect(r.status, RestockStatus.jarangLaku);
  });

  test('stok masih aman', () {
    final r = calc.hitung(base(stok: 50));
    expect(r.status, RestockStatus.aman);
  });
}