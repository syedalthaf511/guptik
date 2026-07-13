class AppConfig {
  // Supabase Configuration
  static const String supabaseUrl = 'https://aqmcriergkczfkkdgkzc.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFxbWNyaWVyZ2tjemZra2Rna3pjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODI1MzU1NTUsImV4cCI6MjA5ODExMTU1NX0.GTFeWOWlfPBpQabdhwNhR0TGFg3oLzf4AOGkBbs2lP0';
  


  // WhatsApp Business API - PASTE YOUR KEYS HERE
  static const String whatsappAccessToken = 'TEST_ACCESS_TOKEN_123';
  static const String whatsappPhoneNumberId = 'TEST_MODE_12345';
  static const String whatsappBusinessAccountId = 'TEST_BUSINESS_ID_123';
  
  // App Secret for webhook signature verification (found in App Dashboard > App Settings > Basic)
  static const String whatsappAppSecret = 'TEST_APP_SECRET_123';
  
  // Webhook Configuration
  static const String webhookCallbackUrl = 'https://app.metafly.com/webhooks';
  static const String webhookVerifyToken = 'meta-fly';
  
  // MetaFly API Configuration
  static const String metaflyApiBaseUrl = 'https://app.metafly.com/api';
  
  // Google OAuth
  static const String googleClientId = 'YOUR_GOOGLE_CLIENT_ID_HERE';
  static const String googleClientSecret = 'YOUR_GOOGLE_CLIENT_SECRET_HERE';
  
  // Apple OAuth
  static const String appleClientId = 'YOUR_APPLE_CLIENT_ID_HERE';
  static const String appleTeamId = 'YOUR_APPLE_TEAM_ID_HERE';
  
  // API Base URLs
  static const String whatsappApiBaseUrl = 'https://graph.facebook.com/v17.0';
  static const String googleApiBaseUrl = 'https://www.googleapis.com';
}