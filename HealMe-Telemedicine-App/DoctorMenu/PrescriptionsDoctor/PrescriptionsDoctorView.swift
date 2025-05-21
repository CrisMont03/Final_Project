//
//  PrescriptionsDoctorView.swift
//  HealMe-Telemedicine-App
//
//  Created by Cristian Montiel García on 19/05/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct PrescriptionsDoctorView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var prescriptions: [Prescription] = []
    @State private var searchText: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String = ""

    private let colors = (
        red: Color(hex: "D40035"),
        green: Color(hex: "28A745"),
        blue: Color(hex: "007AFE"),
        background: Color(hex: "F5F6F9")
    )

    // Computed property to filter prescriptions based on search text
    private var filteredPrescriptions: [Prescription] {
        if searchText.isEmpty {
            return prescriptions
        } else {
            return prescriptions.filter { prescription in
                prescription.patientName.lowercased().contains(searchText.lowercased()) ||
                prescription.diagnosis.lowercased().contains(searchText.lowercased())
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
                            "Buscar por paciente o diagnóstico...",
                            text: $searchText,
                            prompt: Text("Buscar").foregroundColor(.black.opacity(0.5))
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

                        // Title
                        Text("Mis Recetas")
                            .font(.system(size: 28, weight: .semibold, design: .rounded))
                            .foregroundColor(.black)
                            .padding(.top, 8)

                        // Error Message
                        if !errorMessage.isEmpty || !authViewModel.errorMessage.isEmpty {
                            Text(errorMessage.isEmpty ? authViewModel.errorMessage : errorMessage)
                                .font(.system(size: 14, weight: .regular, design: .rounded))
                                .foregroundColor(colors.red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }

                        // Prescriptions List
                        if isLoading {
                            ProgressView("Cargando recetas...")
                                .foregroundColor(.black)
                                .padding()
                        } else if filteredPrescriptions.isEmpty {
                            Text(searchText.isEmpty ? "No hay recetas registradas" : "No se encontraron recetas")
                                .font(.system(size: 16, weight: .light, design: .rounded))
                                .foregroundColor(.black.opacity(0.7))
                                .padding()
                        } else {
                            ScrollView {
                                LazyVStack(spacing: 12) {
                                    ForEach(filteredPrescriptions) { prescription in
                                        PrescriptionRowView(prescription: prescription)
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
                print("PrescriptionsDoctorView appeared")
                print("AuthViewModel state: userIsLoggedIn=\(authViewModel.userIsLoggedIn), isDoctor=\(authViewModel.isDoctor), currentUser=\(Auth.auth().currentUser?.uid ?? "none")")
                errorMessage = ""
                isLoading = false
                fetchPrescriptions()
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

    // Fetch prescriptions from AuthViewModel
    private func fetchPrescriptions() {
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
        authViewModel.fetchDoctorPrescriptions(doctorId: doctorId) { fetchedPrescriptions in
            DispatchQueue.main.async {
                isLoading = false
                if fetchedPrescriptions.isEmpty {
                    errorMessage = "No se encontraron recetas"
                    print("No prescriptions fetched")
                } else {
                    prescriptions = fetchedPrescriptions
                    errorMessage = ""
                    print("Fetched \(fetchedPrescriptions.count) prescriptions")
                }
            }
        }
    }
}

// Row view for each prescription
struct PrescriptionRowView: View {
    let prescription: Prescription
    private let colors = (
        red: Color(hex: "D40035"),
        green: Color(hex: "28A745"),
        blue: Color(hex: "007AFE"),
        background: Color(hex: "F5F6F9")
    )

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(prescription.patientName)
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundColor(.black)
                Text("Diagnóstico: \(prescription.diagnosis)")
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(.black.opacity(0.7))
                Text("Fecha: \(prescription.date)")
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(.black.opacity(0.7))
            }
            Spacer()
            NavigationLink {
                PrescriptionDetailView(prescription: prescription)
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

// Detailed view for each prescription
struct PrescriptionDetailView: View {
    let prescription: Prescription
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
            ScrollView {
                VStack(spacing: 24) {
                    Text("Detalles de la Receta")
                        .font(.system(size: 28, weight: .semibold, design: .rounded))
                        .foregroundColor(.black)
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Paciente: \(prescription.patientName)")
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundColor(.black)
                        Text("ID del Paciente: \(prescription.patientId)")
                            .font(.system(size: 16, weight: .regular, design: .rounded))
                            .foregroundColor(.black)
                        Text("Médico: \(prescription.doctorName)")
                            .font(.system(size: 16, weight: .regular, design: .rounded))
                            .foregroundColor(.black)
                        Text("ID del Médico: \(prescription.doctorId)")
                            .font(.system(size: 16, weight: .regular, design: .rounded))
                            .foregroundColor(.black)
                        Text("Fecha: \(prescription.date)")
                            .font(.system(size: 16, weight: .regular, design: .rounded))
                            .foregroundColor(.black)
                        Text("Hora: \(prescription.hour)")
                            .font(.system(size: 16, weight: .regular, design: .rounded))
                            .foregroundColor(.black)
                        Text("Diagnóstico: \(prescription.diagnosis)")
                            .font(.system(size: 16, weight: .regular, design: .rounded))
                            .foregroundColor(.black)
                        Text("Receta: \(prescription.prescription)")
                            .font(.system(size: 16, weight: .regular, design: .rounded))
                            .foregroundColor(.black)
                        Text("Creado el: \(dateFormatter.string(from: prescription.createdAt.dateValue()))")
                            .font(.system(size: 16, weight: .regular, design: .rounded))
                            .foregroundColor(.black)
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
        }
        .navigationBarTitle("", displayMode: .inline)
        .navigationBarBackButtonHidden(false)
        .onAppear {
            print("PrescriptionDetailView appeared for prescription ID: \(prescription.id)")
        }
    }

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}

struct PrescriptionsDoctorView_Previews: PreviewProvider {
    static var previews: some View {
        PrescriptionsDoctorView()
            .environmentObject(AuthViewModel())
    }
}
