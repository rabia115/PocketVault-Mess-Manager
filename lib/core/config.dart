
class AppConfig {
  static const String supabaseUrl = 'https://buqqvudrvheitdhlkrmj.supabase.co';

  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJ1cXF2dWRydmhlaXRkaGxrcm1qIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODc3NDA2OTIsImV4cCI6MjEwMzMxNjY5Mn0.5FRqj-I81jw_D_udQhX9-vCumOSM_S7dA6KH-O6EPF8';

  static bool get isConfigured {
    return supabaseUrl.isNotEmpty &&
        supabaseAnonKey.isNotEmpty;
  }
}
