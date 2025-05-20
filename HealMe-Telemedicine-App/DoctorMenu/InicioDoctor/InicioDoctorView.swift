//
//  InicioDoctorView.swift
//  HealMe-Telemedicine-App
//
//  Created by Cristian Montiel García on 19/05/25.
//

import SwiftUI
import FirebaseFirestore

struct InicioDoctorView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var doctorData: DoctorData = DoctorData()
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    private let db = Firestore.firestore()
    private let colors = (
        red: Color(hex: "D40035"),
        green: Color(hex: "28A745"),
        blue: Color(hex: "007AFE"),
        background: Color(hex: "F5F6F9"),
        gray: Color(hex: "808080")
    )
    
    var body: some View {
        ZStack {
            colors.background
                .ignoresSafeArea()
            
            if isLoading {
                LoadingView(colors: colors)
            } else if let errorMessage = errorMessage {
                ErrorView(errorMessage: errorMessage, colors: colors, retryAction: fetchDoctorData)
            } else {
                ContentView(doctorData: doctorData, colors: colors)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            fetchDoctorData()
        }
    }
    
    // MARK: - Subviews
    
    private struct LoadingView: View {
        let colors: (red: Color, green: Color, blue: Color, background: Color, gray: Color)
        
        var body: some View {
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: colors.blue))
                    .scaleEffect(1.5)
                Text("Cargando datos del doctor...")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundColor(.black)
            }
        }
    }
    
    private struct ErrorView: View {
        let errorMessage: String
        let colors: (red: Color, green: Color, blue: Color, background: Color, gray: Color)
        let retryAction: () -> Void
        
        var body: some View {
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(colors.red)
                    .font(.system(size: 40))
                Text(errorMessage)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                Button(action: retryAction) {
                    Text("Reintentar")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .padding()
                        .background(colors.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding()
        }
    }
    
    private struct ContentView: View {
        let doctorData: DoctorData
        let colors: (red: Color, green: Color, blue: Color, background: Color, gray: Color)
        
        var body: some View {
            VStack(spacing: 16) {
                Text("Buenos días, Dr. \(doctorData.name.isEmpty ? "Doctor" : doctorData.name)")
                    .font(.system(size: 28, weight: .medium, design: .rounded))
                    .foregroundColor(.black)
                    .padding(.top, 35)
                
                Text("Perfil profesional")
                    .font(.system(size: 16, weight: .regular, design: .rounded))
                    .foregroundColor(.gray)
                    .padding(.bottom, 25)
                
                // White container for doctor fields
                VStack(spacing: 0) {
                    HStack {
                        Text("Campo")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(colors.blue)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("Valor")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.vertical, 14)
                    .padding(.horizontal, 16)
                    .background(Color.white)
                    
                    Divider()
                        .background(colors.gray.opacity(0.3))
                    
                    DoctorField(label: "Nombre", value: doctorData.name)
                    Divider().background(colors.gray.opacity(0.3))
                    DoctorField(label: "Correo", value: doctorData.email)
                    Divider().background(colors.gray.opacity(0.3))
                    DoctorField(label: "Certificado Médico", value: doctorData.medicalCertificate)
                    Divider().background(colors.gray.opacity(0.3))
                    DoctorField(label: "Teléfono", value: doctorData.phone)
                    Divider().background(colors.gray.opacity(0.3))
                    DoctorField(label: "Especialidad", value: doctorData.specialty)
                }
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(colors.gray.opacity(0.3), lineWidth: 1)
                )
                .padding(.horizontal, 16)
                .padding(.bottom, 17)
                
                Spacer()
            }
        }
    }
    
    // MARK: - Doctor Field View
    
    private struct DoctorField: View {
        let label: String
        let value: String
        
        var body: some View {
            HStack {
                Text(label)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text(value.isEmpty ? "No registrado" : value)
                    .font(.system(size: 16, design: .rounded))
                    .foregroundColor(value.isEmpty ? .gray : .black)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
        }
    }
    
    // MARK: - Methods
    
    private func fetchDoctorData() {
        guard let userId = authViewModel.currentUserId else {
            errorMessage = "No se encontró el usuario autenticado."
            isLoading = false
            print("Error: No userId found in AuthViewModel")
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        db.collection("doctors").document(userId).getDocument { (document, error) in
            DispatchQueue.main.async {
                isLoading = false
                if let error = error {
                    errorMessage = "Error al cargar los datos: \(error.localizedDescription)"
                    print("Firestore error: \(error)")
                    return
                }
                
                guard let document = document, document.exists, let data = document.data() else {
                    errorMessage = "No se encontraron datos del doctor."
                    print("No doctor data found for userId: \(userId)")
                    return
                }
                
                doctorData = DoctorData(
                    email: data["email"] as? String ?? "",
                    medicalCertificate: data["medicalCertificate"] as? String ?? "",
                    name: data["name"] as? String ?? "",
                    phone: data["phone"] as? String ?? "",
                    specialty: data["specialty"] as? String ?? ""
                )
                print("Doctor data loaded: \(doctorData)")
            }
        }
    }
}

// MARK: - Data Model

struct DoctorData {
    var email: String
    var medicalCertificate: String
    var name: String
    var phone: String
    var specialty: String
    
    init(
        email: String = "",
        medicalCertificate: String = "",
        name: String = "",
        phone: String = "",
        specialty: String = ""
    ) {
        self.email = email
        self.medicalCertificate = medicalCertificate
        self.name = name
        self.phone = phone
        self.specialty = specialty
    }
}

// MARK: - Preview

struct InicioDoctorView_Previews: PreviewProvider {
    static var previews: some View {
        InicioDoctorView()
            .environmentObject(AuthViewModel())
    }
}
