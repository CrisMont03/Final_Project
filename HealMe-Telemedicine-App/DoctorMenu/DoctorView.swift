//
//  DoctorView.swift
//  HealMe-Telemedicine-App
//
//  Created by Cristian Montiel García on 17/05/25.
//

import SwiftUI
import FirebaseAuth

struct DoctorView: View {
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        VStack(spacing: 20) {
            Text("Panel del Médico")
                .font(.largeTitle)
                .fontWeight(.bold)

            if authViewModel.doctorData == nil && authViewModel.errorMessage.isEmpty {
                ProgressView("Cargando datos del médico...")
                    .foregroundColor(.gray)
            } else if let doctorData = authViewModel.doctorData,
                      let name = doctorData["name"] as? String,
                      let specialty = doctorData["medicalSpecialty"] as? String {
                Text("Bienvenido, \(name)")
                    .font(.title2)
                Text("Especialidad: \(specialty)")
                    .font(.subheadline)
            } else {
                Text(authViewModel.errorMessage.isEmpty ? "No se encontraron datos del médico" : authViewModel.errorMessage)
                    .foregroundColor(.red)
                    .font(.subheadline)
            }

            Button(action: {
                try? Auth.auth().signOut()
            }) {
                Text("Cerrar Sesión")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding()
    }
}

struct DoctorView_Previews: PreviewProvider {
    static var previews: some View {
        DoctorView()
            .environmentObject(AuthViewModel())
    }
}
