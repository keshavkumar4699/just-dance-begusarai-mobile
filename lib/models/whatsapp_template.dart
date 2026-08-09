class WhatsAppTemplate {
  final String key;
  final String title;
  final String templateText;

  const WhatsAppTemplate({
    required this.key,
    required this.title,
    required this.templateText,
  });

  Map<String, dynamic> toMap() {
    return {
      'key': key,
      'title': title,
      'templateText': templateText,
    };
  }

  factory WhatsAppTemplate.fromMap(Map<String, dynamic> map) {
    return WhatsAppTemplate(
      key: map['key'] as String,
      title: map['title'] as String,
      templateText: map['templateText'] as String,
    );
  }

  static List<WhatsAppTemplate> get defaultTemplates => const [
        WhatsAppTemplate(
          key: 'WELCOME',
          title: 'Welcome Message',
          templateText:
              '🎉 Welcome {name} ji! {studio} family me swagat hai. ID No: {id}. Plan: {plan}. Valid till: {validTill}. – {studio}',
        ),
        WhatsAppTemplate(
          key: 'FEE_COLLECTED',
          title: 'Fee Collected',
          templateText:
              '✅ {name} ji, fees ₹{amount} mil gayi. Ab valid till: {validTill}. Dhanyavad! – {studio}',
        ),
        WhatsAppTemplate(
          key: 'FEES_DUE',
          title: 'Fees Due Reminder',
          templateText:
              '🙏 Namaste {name} ji! {studio} se reminder: {month} ki fees ₹{due} baki hai. Jaldi jama karein. Dhanyavad! 🕺 – {studio} 📍 {address}',
        ),
        WhatsAppTemplate(
          key: 'SEND_ID_CARD',
          title: 'Send ID Card',
          templateText:
              '🪪 {name} ji, aapki {studio} ID card attached hai. – {studio}',
        ),
      ];
}
