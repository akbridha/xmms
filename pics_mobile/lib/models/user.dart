class User {
  final String nrp;
  final String? foto;
  final String? telegramId;
  final String? nama;
  final String? jabatan;
  final String? jobGroup;
  final String? jobRank;
  final String? section;
  final String? departement;
  final String? perusahaan;
  final String? subSection;
  final String? custodianLeader;
  final String? superior;
  final String? statusAktifKaryawan;
  final String? tanggalBergabung;
  final String? tanggalExpMinepermit;
  final String? noHp;
  final String? email;
  final String? statusApprovalUser;
  final String? statusKaryawan;
  final String? verificationCode;
  final String? emailVerifiedAt;
  final String? referensi;
  final String? role;
  final String? typeUser;
  final String? jobSite;
  final String? unicode;
  final String? tanggalDibuat;
  final String? tanggalDiubah;
  final String? dbs;

  const User({
    required this.nrp,
    this.foto,
    this.telegramId,
    this.nama,
    this.jabatan,
    this.jobGroup,
    this.jobRank,
    this.section,
    this.departement,
    this.perusahaan,
    this.subSection,
    this.custodianLeader,
    this.superior,
    this.statusAktifKaryawan,
    this.tanggalBergabung,
    this.tanggalExpMinepermit,
    this.noHp,
    this.email,
    this.statusApprovalUser,
    this.statusKaryawan,
    this.verificationCode,
    this.emailVerifiedAt,
    this.referensi,
    this.role,
    this.typeUser,
    this.jobSite,
    this.unicode,
    this.tanggalDibuat,
    this.tanggalDiubah,
    this.dbs,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // Helper to handle null and "NULL" string
    String? parseNullableString(dynamic value) {
      if (value == null) return null;
      if (value is String && (value.isEmpty || value.toUpperCase() == 'NULL')) {
        return null;
      }
      return value.toString();
    }

    return User(
      nrp: json['nrp'] as String,
      foto: parseNullableString(json['foto']),
      telegramId: parseNullableString(json['telegram_id']),
      nama: parseNullableString(json['nama']),
      jabatan: parseNullableString(json['jabatan']),
      jobGroup: parseNullableString(json['job_group']),
      jobRank: parseNullableString(json['job_rank']),
      section: parseNullableString(json['section']),
      departement: parseNullableString(json['departement']),
      perusahaan: parseNullableString(json['perusahaan']),
      subSection: parseNullableString(json['sub_section']),
      custodianLeader: parseNullableString(json['custodian_leader']),
      superior: parseNullableString(json['superior']),
      statusAktifKaryawan: parseNullableString(json['status_aktif_karyawan']),
      tanggalBergabung: parseNullableString(json['tanggal_bergabung']),
      tanggalExpMinepermit: parseNullableString(json['tanggal_exp_minepermit']),
      noHp: parseNullableString(json['no_hp']),
      email: parseNullableString(json['email']),
      statusApprovalUser: parseNullableString(json['status_approval_user']),
      statusKaryawan: parseNullableString(json['status_karyawan']),
      verificationCode: parseNullableString(json['verification_code']),
      emailVerifiedAt: parseNullableString(json['email_verified_at']),
      referensi: parseNullableString(json['referensi']),
      role: parseNullableString(json['role']),
      typeUser: parseNullableString(json['type_user']),
      jobSite: parseNullableString(json['job_site']),
      unicode: parseNullableString(json['unicode']),
      tanggalDibuat: parseNullableString(json['tanggal_dibuat']),
      tanggalDiubah: parseNullableString(json['tanggal_diubah']),
      dbs: parseNullableString(json['dbs']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nrp': nrp,
      'foto': foto,
      'telegram_id': telegramId,
      'nama': nama,
      'jabatan': jabatan,
      'job_group': jobGroup,
      'job_rank': jobRank,
      'section': section,
      'departement': departement,
      'perusahaan': perusahaan,
      'sub_section': subSection,
      'custodian_leader': custodianLeader,
      'superior': superior,
      'status_aktif_karyawan': statusAktifKaryawan,
      'tanggal_bergabung': tanggalBergabung,
      'tanggal_exp_minepermit': tanggalExpMinepermit,
      'no_hp': noHp,
      'email': email,
      'status_approval_user': statusApprovalUser,
      'status_karyawan': statusKaryawan,
      'verification_code': verificationCode,
      'email_verified_at': emailVerifiedAt,
      'referensi': referensi,
      'role': role,
      'type_user': typeUser,
      'job_site': jobSite,
      'unicode': unicode,
      'tanggal_dibuat': tanggalDibuat,
      'tanggal_diubah': tanggalDiubah,
      'dbs': dbs,
    };
  }

  @override
  String toString() => '${nama ?? 'Unknown'} ($nrp) - ${jabatan ?? 'N/A'}';
}
