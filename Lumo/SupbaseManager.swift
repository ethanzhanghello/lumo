//
//  SupbaseManager.swift
//  FireBase
//
//  Created by Tony on 7/11/25.
//

import Foundation
import Supabase

class SupabaseManager {
    static let shared = SupabaseManager()

    let client: SupabaseClient

    private init() {
        client = SupabaseClient(
            supabaseURL: URL(string: "https://jjasxjcmbpijozdypirj.supabase.co")!,
            supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpqYXN4amNtYnBpam96ZHlwaXJqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTIyMTU2ODUsImV4cCI6MjA2Nzc5MTY4NX0.zlUpoj47040asd6dkEBGJA7vSAgaq1DtCcENNbZhhJ0"
        )
    }
}
