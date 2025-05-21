//
//  PatientsView.swift
//  HealMe-Telemedicine-App
//
//  Created by Cristian Montiel García on 19/05/25.
//

import SwiftUI
import FirebaseAuth

struct PatientsView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var appointments: [AppointmentDoctor] = []
    @State private var searchText: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String = ""

    private let colors = (
        red: Color(hex: "D40035"),
        green: Color(hex: "28A745"),
        blue: Color(hex: "007AFE"),
        background: Color(hex: "F5F6F9")
    )

    private var filteredAppointments: [AppointmentDoctor] {
        if searchText.isEmpty {
            return appointments
        } else {
            return appointments.filter { appointment in
                appointment.patientName.lowercased().contains(searchText.lowercased())
            }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                colors.background
                    .ignoresSafeArea()

                if !authViewModel.userIsLoggedIn || !authViewModel.isDoctor {
                    VStack(spacing: 12) {
                        Image(systemName: "lock.fill")
                            .foregroundColor(colors.red)
                            .font(.system(size: 24))
                        Text("Acceso restringido")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(colors.red)
                        Text("Esta vista es solo para médicos autenticados")
                            .font(.system(size: 16, weight: .regular, design: .rounded))
                            .foregroundColor(.black.opacity(0.7))
                    }
                } else {
                    VStack(spacing: 16) {
                        // Header
                        VStack(spacing: 0) {
                            Text("Pacientes")
                                .font(.system(size: 28, weight: .medium, design: .rounded))
                                .foregroundColor(.black)
                            Text("Revisa el historial de cada paciente")
                                .font(.system(size: 16, weight: .regular, design: .rounded))
                                .foregroundColor(.gray)
                        }
                        .padding(.top, 35)
                        .padding(.bottom, 16)

                        // Search Bar
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(colors.blue)
                                .font(.system(size: 16))
                            TextField(
                                "",
                                text: $searchText,
                                prompt: Text("Buscar por nombre").foregroundColor(.black.opacity(0.5))
                            )
                            .foregroundColor(.black)
                            .font(.system(size: 16, weight: .regular, design: .rounded))
                        }
                        .padding(12)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(colors.blue.opacity(0.3), lineWidth: 1)
                        )
                        .shadow(color: .gray.opacity(0.1), radius: 4, x: 0, y: 2)
                        .padding(.horizontal, 16)

                        // Error Message
                        if !errorMessage.isEmpty || !authViewModel.errorMessage.isEmpty {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(colors.red)
                                    .font(.system(size: 16))
                                Text(errorMessage.isEmpty ? authViewModel.errorMessage : errorMessage)
                                    .font(.system(size: 14, weight: .regular, design: .rounded))
                                    .foregroundColor(colors.red)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                        }

                        // Appointments List
                        if isLoading {
                            ProgressView()
                                .tint(colors.blue)
                                .padding()
                        } else if filteredAppointments.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "person.crop.circle.fill")
                                    .foregroundColor(.black.opacity(0.5))
                                    .font(.system(size: 24))
                                Text(searchText.isEmpty ? "No hay pacientes registrados" : "No se encontraron pacientes")
                                    .font(.system(size: 16, weight: .regular, design: .rounded))
                                    .foregroundColor(.black.opacity(0.7))
                            }
                            .padding(.top, 20)
                        } else {
                            ScrollView {
                                LazyVStack(spacing: 12) {
                                    ForEach(filteredAppointments) { appointment in
                                        PatientRowView(appointment: appointment)
                                            .padding(.horizontal, 16)
                                    }
                                }
                                .padding(.vertical, 8)
                            }
                        }

                        Spacer()
                    }
                    .padding(.top, 1)
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                print("PatientsView appeared")
                print("AuthViewModel state: userIsLoggedIn=\(authViewModel.userIsLoggedIn), isDoctor=\(authViewModel.isDoctor), currentUser=\(Auth.auth().currentUser?.uid ?? "none")")
                errorMessage = ""
                isLoading = false
                fetchAppointments()
            }
            .navigationDestination(isPresented: Binding(
                get: { !authViewModel.userIsLoggedIn || !authViewModel.isDoctor },
                set: { _ in }
            )) {
                LoginView()
                    .environmentObject(authViewModel)
            }
        }
    }

    private func fetchAppointments() {
        guard let doctorId = authViewModel.currentUserId else {
            errorMessage = "No se pudo obtener el ID del médico"
            print("No doctor ID available")
            return
        }
        guard authViewModel.isDoctor else {
            errorMessage = "Esta vista es solo para médicos"
            print("User is not a doctor")
            return
        }

        isLoading = true
        authViewModel.fetchDoctorAppointments(doctorId: doctorId) { fetchedAppointments in
            DispatchQueue.main.async {
                isLoading = false
                if fetchedAppointments.isEmpty {
                    errorMessage = "No se encontraron pacientes"
                    print("No appointments fetched")
                } else {
                    var seenNames = Set<String>()
                    let uniqueAppointments = fetchedAppointments.filter { appointment in
                        let isUnique = !seenNames.contains(appointment.patientName)
                        if isUnique {
                            seenNames.insert(appointment.patientName)
                        }
                        return isUnique
                    }
                    appointments = uniqueAppointments
                    errorMessage = ""
                    print("Fetched \(fetchedAppointments.count) appointments, deduplicated to \(uniqueAppointments.count) patients")
                }
            }
        }
    }
}

struct PatientRowView: View {
    let appointment: AppointmentDoctor
    private let colors = (
        red: Color(hex: "D40035"),
        green: Color(hex: "28A745"),
        blue: Color(hex: "007AFE"),
        background: Color(hex: "F5F6F9")
    )

    var body: some View {
        HStack {
            Image(systemName: "person.fill")
                .foregroundColor(colors.blue)
                .font(.system(size: 16))
            Text(appointment.patientName)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.black)
            Spacer()
            NavigationLink {
                PatientDetailView(appointment: appointment)
            } label: {
                HStack {
                    Text("Ver más")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(colors.blue)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(12)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(colors.blue.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: .gray.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

struct PatientDetailView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    let appointment: AppointmentDoctor
    @State private var medicalHistory: [String: Any]? = nil
    @State private var isLoading: Bool = false
    @State private var errorMessage: String = ""
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
            VStack(spacing: 16) {
                // Header
                VStack(spacing: 0) {
                    Image(systemName: "person.crop.circle.fill")
                        .foregroundColor(colors.blue)
                        .font(.system(size: 24))
                    Text("Historial Médico")
                        .font(.system(size: 28, weight: .medium, design: .rounded))
                        .foregroundColor(.black)
                    Text("Revisa los detalles de cada paciente")
                        .font(.system(size: 16, weight: .regular, design: .rounded))
                        .foregroundColor(.gray)
                }
                .padding(.top, 35)
                .padding(.bottom, 16)

                if isLoading {
                    ProgressView()
                        .tint(colors.blue)
                        .padding()
                } else if let history = medicalHistory {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "person.fill")
                                    .foregroundColor(colors.blue)
                                    .font(.system(size: 16))
                                Text("Nombre: \(appointment.patientName)")
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                    .foregroundColor(.black)
                            }
                            HStack {
                                Image(systemName: "calendar")
                                    .foregroundColor(colors.blue)
                                    .font(.system(size: 16))
                                Text("Edad: \(history["age"] as? Int ?? 0) años")
                                    .font(.system(size: 16, weight: .regular, design: .rounded))
                                    .foregroundColor(.black)
                            }
                            HStack {
                                Image(systemName: "person")
                                    .foregroundColor(colors.blue)
                                    .font(.system(size: 16))
                                Text("Género: \(history["gender"] as? String ?? "No especificado")")
                                    .font(.system(size: 16, weight: .regular, design: .rounded))
                                    .foregroundColor(.black)
                            }
                            HStack {
                                Image(systemName: "scalemass")
                                    .foregroundColor(colors.blue)
                                    .font(.system(size: 16))
                                Text("Peso: \(String(format: "%.1f", history["weight"] as? Double ?? 0.0)) kg")
                                    .font(.system(size: 16, weight: .regular, design: .rounded))
                                    .foregroundColor(.black)
                            }
                            HStack {
                                Image(systemName: "ruler")
                                    .foregroundColor(colors.blue)
                                    .font(.system(size: 16))
                                Text("Altura: \(String(format: "%.1f", history["height"] as? Double ?? 0.0)) cm")
                                    .font(.system(size: 16, weight: .regular, design: .rounded))
                                    .foregroundColor(.black)
                            }
                            HStack {
                                Image(systemName: "drop.fill")
                                    .foregroundColor(colors.blue)
                                    .font(.system(size: 16))
                                Text("Tipo de sangre: \(history["bloodType"] as? String ?? "No especificado")")
                                    .font(.system(size: 16, weight: .regular, design: .rounded))
                                    .foregroundColor(.black)
                            }
                            HStack {
                                Image(systemName: "fork.knife")
                                    .foregroundColor(colors.blue)
                                    .font(.system(size: 16))
                                Text("Dieta: \(history["diet"] as? String ?? "No especificada")")
                                    .font(.system(size: 16, weight: .regular, design: .rounded))
                                    .foregroundColor(.black)
                            }
                            HStack {
                                Image(systemName: "figure.walk")
                                    .foregroundColor(colors.blue)
                                    .font(.system(size: 16))
                                Text("Ejercicio: \(history["exercise"] as? String ?? "No especificado")")
                                    .font(.system(size: 16, weight: .regular, design: .rounded))
                                    .foregroundColor(.black)
                            }
                            HStack {
                                Image(systemName: "allergens")
                                    .foregroundColor(colors.blue)
                                    .font(.system(size: 16))
                                Text("Alergias: \(history["allergies"] as? String ?? "Ninguna")")
                                    .font(.system(size: 16, weight: .regular, design: .rounded))
                                    .foregroundColor(.black)
                            }
                        }
                        .padding(12)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(colors.blue.opacity(0.3), lineWidth: 1)
                        )
                        .shadow(color: .gray.opacity(0.1), radius: 4, x: 0, y: 2)
                        .padding(.horizontal, 16)
                    }
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(colors.red)
                            .font(.system(size: 24))
                        Text(errorMessage.isEmpty ? "No se encontraron datos médicos" : errorMessage)
                            .font(.system(size: 16, weight: .regular, design: .rounded))
                            .foregroundColor(errorMessage.isEmpty ? .black.opacity(0.7) : colors.red)
                    }
                    .padding(.top, 20)
                }
                Spacer()
            }
            .padding(.top, 1)
            .navigationBarTitle("", displayMode: .inline)
            .navigationBarBackButtonHidden(false)
            .onAppear {
                print("PatientDetailView appeared for patient: \(appointment.patientName)")
                fetchMedicalHistory()
            }
        }
    }

    private func fetchMedicalHistory() {
        isLoading = true
        errorMessage = ""
        authViewModel.fetchPatientMedicalHistory(patientName: appointment.patientName) { history in
            DispatchQueue.main.async {
                isLoading = false
                if let history = history {
                    medicalHistory = history
                    print("Medical history fetched: \(history)")
                } else {
                    errorMessage = "Error al cargar el historial médico"
                    print("No medical history found for patient: \(appointment.patientName)")
                }
            }
        }
    }
}

struct PatientsView_Previews: PreviewProvider {
    static var previews: some View {
        PatientsView()
            .environmentObject(AuthViewModel())
    }
}
