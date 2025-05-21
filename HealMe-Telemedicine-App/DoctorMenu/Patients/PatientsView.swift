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

    // Computed property to filter appointments based on search text
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
                    VStack {
                        Text("Acceso restringido")
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundColor(colors.red)
                        Text("Esta vista es solo para médicos autenticados.")
                            .font(.system(size: 16, weight: .light, design: .rounded))
                            .foregroundColor(.black)
                    }
                } else {
                    VStack(spacing: 16) {
                        // Search Bar
                        TextField(
                            "Buscar paciente...",
                            text: $searchText,
                            prompt: Text("Buscar por nombre").foregroundColor(.black.opacity(0.5))
                        )
                        .foregroundColor(.black)
                        .padding()
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.black.opacity(0.2), lineWidth: 1)
                        )
                        .padding(.horizontal)
                        .autocapitalization(.none)

                        VStack(spacing: 0) {
                            Text("Lista de Pacientes")
                                .font(.system(size: 28, weight: .medium, design: .rounded))
                                .foregroundColor(.black)
                            Text("Busca algún paciente en específico")
                                .font(.system(size: 16, weight: .regular, design: .rounded))
                                .foregroundColor(.gray)
                        }
                        .padding(.top, 10)
                        .padding(.bottom, 12)

                        // Error Message
                        if !errorMessage.isEmpty || !authViewModel.errorMessage.isEmpty {
                            Text(errorMessage.isEmpty ? authViewModel.errorMessage : errorMessage)
                                .font(.system(size: 14, weight: .regular, design: .rounded))
                                .foregroundColor(colors.red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }

                        // Appointments List
                        if isLoading {
                            ProgressView("Cargando pacientes...")
                                .foregroundColor(.black)
                                .padding()
                        } else if filteredAppointments.isEmpty {
                            Text(searchText.isEmpty ? "No hay pacientes registrados" : "No se encontraron pacientes")
                                .font(.system(size: 16, weight: .light, design: .rounded))
                                .foregroundColor(.black.opacity(0.7))
                                .padding()
                        } else {
                            ScrollView {
                                LazyVStack(spacing: 12) {
                                    ForEach(filteredAppointments) { appointment in
                                        PatientRowView(appointment: appointment)
                                            .padding(.horizontal)
                                    }
                                }
                                .padding(.vertical)
                            }
                        }
                    }
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

    // Fetch appointments from AuthViewModel and deduplicate by patientName
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
                    // Deduplicate appointments by patientName, keeping the first occurrence
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

// Row view for each patient
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
            Text(appointment.patientName)
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundColor(.black)
            Spacer()
            NavigationLink {
                PatientDetailView(appointment: appointment)
            } label: {
                Text("Ver más")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(colors.blue)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.black.opacity(0.2), lineWidth: 1)
        )
    }
}

// Placeholder view for patient details
struct PatientDetailView: View {
    let appointment: AppointmentDoctor
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
            VStack(spacing: 24) {
                VStack(spacing: 0) {
                    Text("Detalles del Paciente")
                        .font(.system(size: 28, weight: .medium, design: .rounded))
                        .foregroundColor(.black)
                    Text("Información personal")
                        .font(.system(size: 16, weight: .regular, design: .rounded))
                        .foregroundColor(.gray)
                }
                .padding(.top, 35)
                .padding(.bottom, 12)
                VStack(alignment: .leading, spacing: 12) {
                    Text("Nombre: \(appointment.patientName)")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundColor(.black)
                    Text("Información adicional no disponible")
                        .font(.system(size: 16, weight: .light, design: .rounded))
                        .foregroundColor(.black.opacity(0.7))
                }
                .padding()
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.black.opacity(0.2), lineWidth: 1)
                )
                Spacer()
            }
            .padding(.horizontal)
        }
        .navigationBarTitle("", displayMode: .inline)
        .navigationBarBackButtonHidden(false)
    }
}

struct PatientsView_Previews: PreviewProvider {
    static var previews: some View {
        PatientsView()
            .environmentObject(AuthViewModel())
    }
}
