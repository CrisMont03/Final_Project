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
    @State private var isEditing = false
    
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
                ContentView(doctorData: doctorData, isEditing: $isEditing, colors: colors)
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
        @Binding var isEditing: Bool
        let colors: (red: Color, green: Color, blue: Color, background: Color, gray: Color)
        
        var body: some View {
            VStack(spacing: 16) {
                // Welcome header with icon and date
                VStack(spacing: 8) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(colors.blue)
                    HStack(spacing: 8) {
                        Text("¡\(greeting())!")
                            .font(.system(size: 28, weight: .medium, design: .rounded))
                            .foregroundColor(.black)
                    }
                    Text("21 de mayo de 2025")
                        .font(.system(size: 16, weight: .regular, design: .rounded))
                        .foregroundColor(colors.gray)
                }
                .padding(.top, 35)
                .padding(.bottom, 10)
                
                // White container for doctor profile
                VStack(spacing: 0) {
                    // Profile card header
                    VStack(spacing: 8) {
                        Text("Dr. " + (doctorData.name.isEmpty ? "Perfil del Doctor" : doctorData.name))
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundColor(.black)
                        if !doctorData.specialty.isEmpty {
                            Text(doctorData.specialty)
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(.white)
                                .padding(.vertical, 4)
                                .padding(.horizontal, 12)
                                .background(colors.blue)
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.vertical, 16)
                    .padding(.horizontal, 16)
                    .background(Color.white)
                    
                    Divider()
                        .background(colors.gray.opacity(0.3))
                    
                    // Doctor fields
                    DoctorField(label: "Nombre", value: doctorData.name, icon: "person.fill", colors: colors)
                    Divider().background(colors.gray.opacity(0.3))
                    DoctorField(label: "Correo", value: doctorData.email, icon: "envelope.fill", colors: colors)
                    Divider().background(colors.gray.opacity(0.3))
                    DoctorField(label: "Certificado Médico", value: doctorData.medicalCertificate, icon: "doc.text.fill", colors: colors)
                    Divider().background(colors.gray.opacity(0.3))
                    DoctorField(label: "Teléfono", value: doctorData.phone, icon: "phone.fill", colors: colors)
                    Divider().background(colors.gray.opacity(0.3))
                    DoctorField(label: "Especialidad", value: doctorData.specialty, icon: "stethoscope", colors: colors)
                }
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(colors.gray.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: colors.gray.opacity(0.2), radius: 4, x: 0, y: 2)
                .padding(.horizontal, 16)
                
                // Edit button
                Button(action: { isEditing = true }) {
                    HStack(spacing: 8) {
                        Image(systemName: "pencil")
                            .font(.system(size: 16, weight: .medium))
                        Text("Editar perfil")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(colors.red)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 16)
                
            }
        }
        
        private func greeting() -> String {
            let hour = Calendar.current.component(.hour, from: Date())
            switch hour {
            case 0..<12:
                return "Buenos días"
            case 12..<18:
                return "Buenas tardes"
            default:
                return "Buenas noches" // Current time (10:22 PM) will use this
            }
        }
    }
    
    // MARK: - Doctor Field View
    
    private struct DoctorField: View {
        let label: String
        let value: String
        let icon: String
        let colors: (red: Color, green: Color, blue: Color, background: Color, gray: Color)
        
        var body: some View {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(colors.blue)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(label)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(colors.blue)
                    Text(value.isEmpty ? "No registrado" : value)
                        .font(.system(size: 16, design: .rounded))
                        .foregroundColor(value.isEmpty ? colors.gray : .black)
                        .lineLimit(2)
                }
                
                Spacer()
            }
            .padding(.vertical, 12)
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
