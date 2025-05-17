//
//  PatientMenuView.swift
//  HealMe-Telemedicine-App
//
//  Created by Cristian Montiel García on 17/05/25.
//

import SwiftUI

struct PatientMenuView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    private let colors = (
        red: Color(hex: "D40035"),
        green: Color(hex: "28A745"),
        blue: Color(hex: "007AFE"),
        background: Color(hex: "F5F6F9")
    )
    
    var body: some View {
        ZStack {
            colors.background
                .ignoresSafeArea()
            
            TabView {
                InicioView()
                    .tabItem {
                        Label("Inicio", systemImage: "house")
                    }
                    .environmentObject(authViewModel)
                
                AppointmentsView()
                    .tabItem {
                        Label("Citas", systemImage: "calendar")
                    }
                    .environmentObject(authViewModel)
                
                InfoView()
                    .tabItem {
                        Label("Información", systemImage: "info.circle")
                    }
                    .environmentObject(authViewModel)
                
                ChatView()
                    .tabItem {
                        Label("Chat", systemImage: "message")
                    }
                    .environmentObject(authViewModel)
                
                PrescriptionsView()
                    .tabItem {
                        Label("Recetas", systemImage: "pills")
                    }
                    .environmentObject(authViewModel)
                
                SettingsView()
                    .tabItem {
                        Label("Ajustes", systemImage: "gear")
                    }
                    .environmentObject(authViewModel)
            }
            .accentColor(colors.blue) // Color de los íconos seleccionados
        }
    }
}

struct PatientMenuView_Previews: PreviewProvider {
    static var previews: some View {
        PatientMenuView()
            .environmentObject(AuthViewModel())
    }
}
