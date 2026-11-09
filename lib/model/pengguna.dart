class Pengguna {
  final int id;
  final String namaPengguna;
  final String namaLengkap;
  final String peran;
  final bool aktif;

  const Pengguna({
    required this.id,
    required this.namaPengguna,
    required this.namaLengkap,
    required this.peran,
    required this.aktif,
  });

  bool get adalahAdmin => peran == 'admin';

  factory Pengguna.dariPeta(Map<String, Object?> peta) => Pengguna(
        id: peta['id'] as int,
        namaPengguna: peta['nama_pengguna'] as String,
        namaLengkap: peta['nama_lengkap'] as String,
        peran: peta['peran'] as String,
        aktif: (peta['aktif'] as num) == 1,
      );
}
