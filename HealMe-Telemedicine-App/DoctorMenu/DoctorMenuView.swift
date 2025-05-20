//
//  DoctorMenuView.swift
//  HealMe-Telemedicine-App
//
//  Created by Cristian Montiel García on 19/05/25.
//

import SwiftUI

struct DoctorMenuView: View {
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
                InicioDoctorView()
                    .tabItem {
                        Label("Inicio", systemImage: "house")
                    }
                    .environmentObject(authViewModel)
                
                AppointmentsDoctorView()
                    .tabItem {
                        Label("Citas", systemImage: "calendar")
                    }
                    .environmentObject(authViewModel)
                
                PatientsView()
                    .tabItem {
                        Label("Pacientes", systemImage: "person.2.fill")
                    }
                    .environmentObject(authViewModel)
                
                PrescriptionsDoctorView()
                    .tabItem {
                        Label("Diagnósticos", systemImage: "doc.text.magnifyingglass")
                    }
                    .environmentObject(authViewModel)
                
                SettingsDoctorView()
                    .tabItem {
                        Label("Ajustes", systemImage: "gear")
                    }
                    .environmentObject(authViewModel)
            }
            .accentColor(colors.blue) // Color de los íconos seleccionados
        }
    }
}

struct DcotorMenuView_Previews: PreviewProvider {
    static var previews: some View {
        DoctorMenuView()
            .environmentObject(AuthViewModel())
    }
}

