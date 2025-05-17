//
//  ContentView.swift
//  HealMe-Telemedicine-App
//
//  Created by Cristian Montiel García on 16/05/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var authViewModel = AuthViewModel()

    var body: some View {
        if authViewModel.userIsLoggedIn {
            if authViewModel.isDoctor {
                DoctorView()
                    .environmentObject(authViewModel)
            } else if authViewModel.isPatientRegistrationComplete {
                
                PatientMenuView() // Cambiado de PatientView a PatientMenuView
                    .environmentObject(authViewModel)
            } else {
                LoginView()
                    .environmentObject(authViewModel)
            }
        } else {
            LoginView()
                .environmentObject(authViewModel)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AuthViewModel())
    }
}
