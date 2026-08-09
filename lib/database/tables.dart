abstract class Tables {
  static const String students = 'students';
  static const String ledger = 'ledger';
  static const String settings = 'settings';

  static const String createStudentsTable = '''
    CREATE TABLE IF NOT EXISTS students (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      jdNo TEXT UNIQUE NOT NULL,
      name TEXT NOT NULL,
      fatherName TEXT,
      motherName TEXT,
      photoPath TEXT,
      permVillage TEXT,
      permPO TEXT,
      permDist TEXT,
      permPin TEXT,
      corrSame INTEGER DEFAULT 1,
      corrVillage TEXT,
      corrPO TEXT,
      corrDist TEXT,
      corrPin TEXT,
      aadhar TEXT,
      dob TEXT,
      gender TEXT DEFAULT 'Male',
      category TEXT DEFAULT 'MALE',
      religion TEXT DEFAULT 'Hindu',
      nationality TEXT DEFAULT 'Indian',
      maritalStatus TEXT DEFAULT 'Unmarried',
      hobbiesJSON TEXT,
      servicesJSON TEXT,
      timingId INTEGER,
      mobile TEXT NOT NULL,
      altMobile TEXT,
      admissionDate TEXT NOT NULL,
      plan TEXT DEFAULT 'Monthly',
      admissionFeeEnabled INTEGER DEFAULT 1,
      monthsCovered INTEGER DEFAULT 0,
      cycleBalance REAL DEFAULT 0.0,
      credit REAL DEFAULT 0.0,
      admissionFeePaid INTEGER DEFAULT 0,
      lastVisitDate TEXT,
      isBlocked INTEGER DEFAULT 0,
      ptEnabled INTEGER DEFAULT 0,
      ptSessions INTEGER DEFAULT 0,
      ptSessionsDone INTEGER DEFAULT 0,
      ptSessionPrice REAL DEFAULT 0.0,
      ptPaid REAL DEFAULT 0.0,
      ptTiming TEXT,
      createdAt TEXT NOT NULL,
      updatedAt TEXT NOT NULL
    );
  ''';

  static const String createLedgerTable = '''
    CREATE TABLE IF NOT EXISTS ledger (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      studentId INTEGER NOT NULL,
      date TEXT NOT NULL,
      type TEXT NOT NULL,
      monthLabel TEXT,
      dueAmount REAL DEFAULT 0.0,
      paidAmount REAL DEFAULT 0.0,
      balanceOrCredit REAL DEFAULT 0.0,
      mode TEXT DEFAULT 'Cash',
      note TEXT,
      FOREIGN KEY (studentId) REFERENCES students(id) ON DELETE CASCADE
    );
  ''';

  static const String createSettingsTable = '''
    CREATE TABLE IF NOT EXISTS settings (
      key TEXT PRIMARY KEY,
      value TEXT NOT NULL
    );
  ''';
}
