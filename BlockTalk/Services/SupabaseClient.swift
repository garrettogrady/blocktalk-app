import Foundation
import Supabase

enum SupabaseConfig {
    static let projectURL = URL(string: "https://sxwhldbjizzeesexsurh.supabase.co")!
    static let anonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InN4d2hsZGJqaXp6ZWVzZXhzdXJoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODE2NTQzOTEsImV4cCI6MjA5NzIzMDM5MX0.gNrKElxIqDFQGE1_NIH2YJb5xtZaPebDJHXFoCk-jt4" 
}

let supabase = SupabaseClient(
    supabaseURL: SupabaseConfig.projectURL,
    supabaseKey: SupabaseConfig.anonKey
)
