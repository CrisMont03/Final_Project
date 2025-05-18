//
//  ContentView.swift
//  HealMe-Telemedicine-App
//
//  Created by Cristian Montiel García on 16/05/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "F5F6F9") // Fondo consistente con LoginView
                    .ignoresSafeArea()
                
                if authViewModel.isCheckingRegistration {
                    ProgressView("Cargando...")
                        .progressViewStyle(.circular)
                        .foregroundColor(.black)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                } else if authViewModel.userIsLoggedIn {
                    if authViewModel.isDoctor {
                        DoctorView()
                            .environmentObject(authViewModel)
                    } else if authViewModel.isPatientRegistrationComplete {
                        PatientMenuView() // Cambiado de InicioView a PatientMenuView
                            .environmentObject(authViewModel)
                    } else {
                        RegisterMedicalHistoryView() // Corregido: Navegar a RegisterMedicalHistoryView
                            .environmentObject(authViewModel)
                    }
                } else {
                    LoginView()
                        .environmentObject(authViewModel)
                }
            }
            .navigationBarHidden(true)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AuthViewModel())
    }
}
