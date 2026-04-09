class User {
  final String nrp;
  final String? foto;
  final String? telegramId;
  final String nama;
  final String jabatan;
  final String jobGroup;
  final String jobRank;
  final String section;
  final String departement;
  final String perusahaan;
  final String subSection;
  final String custodianLeader;
  final String superior;
  final String? statusAktifKaryawan;
  final String? tanggalBergabung;
  final String? tanggalExpMinepermit;
  final String? noHp;
  final String? email;
  final String statusApprovalUser;
  final String? statusKaryawan;
  final String? verificationCode;
  final String? emailVerifiedAt;
  final String? referensi;
  final String role;
  final String typeUser;
  final String jobSite;
  final String? unicode;
  final String tanggalDibuat;
  final String tanggalDiubah;
  final String? dbs;

  const User({
    required this.nrp,
    this.foto,
    this.telegramId,
    required this.nama,
    required this.jabatan,
    required this.jobGroup,
    required this.jobRank,
    required this.section,
    required this.departement,
    required this.perusahaan,
    required this.subSection,
    required this.custodianLeader,
    required this.superior,
    this.statusAktifKaryawan,
    this.tanggalBergabung,
    this.tanggalExpMinepermit,
    this.noHp,
    this.email,
    required this.statusApprovalUser,
    this.statusKaryawan,
    this.verificationCode,
    this.emailVerifiedAt,
    this.referensi,
    required this.role,
    required this.typeUser,
    required this.jobSite,
    this.unicode,
    required this.tanggalDibuat,
    required this.tanggalDiubah,
    this.dbs,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      nrp: json['nrp'] as String,
      foto: json['foto'] as String?,
      telegramId: json['telegram_id'] as String?,
      nama: json['nama'] as String,
      jabatan: json['jabatan'] as String,
      jobGroup: json['job_group'] as String,
      jobRank: json['job_rank'] as String,
      section: json['section'] as String,
      departement: json['departement'] as String,
      perusahaan: json['perusahaan'] as String,
      subSection: json['sub_section'] as String,
      custodianLeader: json['custodian_leader'] as String,
      superior: json['superior'] as String,
      statusAktifKaryawan: json['status_aktif_karyawan'] as String?,
      tanggalBergabung: json['tanggal_bergabung'] as String?,
      tanggalExpMinepermit: json['tanggal_exp_minepermit'] as String?,
      noHp: json['no_hp'] as String?,
      email: json['email'] as String?,
      statusApprovalUser: json['status_approval_user'] as String,
      statusKaryawan: json['status_karyawan'] as String?,
      verificationCode: json['verification_code'] as String?,
      emailVerifiedAt: json['email_verified_at'] as String?,
      referensi: json['referensi'] as String?,
      role: json['role'] as String,
      typeUser: json['type_user'] as String,
      jobSite: json['job_site'] as String,
      unicode: json['unicode'] as String?,
      tanggalDibuat: json['tanggal_dibuat'] as String,
      tanggalDiubah: json['tanggal_diubah'] as String,
      dbs: json['dbs'] as String?,
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
  String toString() => '$nama ($nrp) - $jabatan';
}
