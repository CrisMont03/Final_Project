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
                    VStack(spacing: 12) {
                        Image(systemName: "lock.fill")
                            .foregroundColor(colors.red)
                            .font(.system(size: 24))
                        Text("Acceso restringido")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(colors.red)
                        Text("Solo para médicos autenticados")
                            .font(.system(size: 16, weight: .regular, design: .rounded))
                            .foregroundColor(.black.opacity(0.7))
                    }
                } else {
                    VStack(spacing: 16) {
                        // Header
                        VStack(spacing: 0) {
                            Text("Diagnósticos")
                                .font(.system(size: 28, weight: .medium, design: .rounded))
                                .foregroundColor(.black)
                            Text("Recetas médicas de los pacientes")
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
                                prompt: Text("Paciente o diagnóstico").foregroundColor(.black.opacity(0.5))
                            )
                            .foregroundColor(.black)
                            .font(.system(size: 16, weight: .regular, design: .rounded))
                        }
                        .padding(12)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(colors.blue.opacity(0.3), lineWidth: 1)
                        )
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

                        // Prescriptions List
                        if isLoading {
                            ProgressView()
                                .tint(colors.blue)
                                .padding()
                        } else if filteredPrescriptions.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "doc.text.fill")
                                    .foregroundColor(.black.opacity(0.5))
                                    .font(.system(size: 24))
                                Text(searchText.isEmpty ? "No hay recetas" : "No se encontraron recetas")
                                    .font(.system(size: 16, weight: .regular, design: .rounded))
                                    .foregroundColor(.black.opacity(0.7))
                            }
                            .padding(.top, 20)
                        } else {
                            ScrollView {
                                VStack(spacing: 12) {
                                    ForEach(filteredPrescriptions) { prescription in
                                        PrescriptionRowView(prescription: prescription)
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
            Image(systemName: "doc.text.fill")
                .foregroundColor(colors.green)
                .font(.system(size: 16))
            VStack(alignment: .leading, spacing: 4) {
                Text(prescription.patientName)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.black)
                Text("Diagnóstico: \(prescription.diagnosis)")
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(.black.opacity(0.7))
            }
            Spacer()
            NavigationLink {
                PrescriptionDetailView(prescription: prescription)
            } label: {
                HStack {
                    Text("Ver más")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(colors.green)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(12)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(colors.blue.opacity(0.3), lineWidth: 1)
        )
    }
}

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
            VStack(spacing: 16) {
                // Header
                Image(systemName: "doc.text.fill")
                    .foregroundColor(colors.blue)
                    .font(.system(size: 20))
                    .padding(.top, 35)
                VStack(spacing: 0) {
                    Text("Detalles")
                        .font(.system(size: 28, weight: .medium, design: .rounded))
                        .foregroundColor(.black)
                    Text("Observa los detalles específicos de la receta")
                        .font(.system(size: 16, weight: .regular, design: .rounded))
                        .foregroundColor(.gray)
                }
                .padding(.bottom, 16)

                ScrollView {
                    VStack(spacing: 12) {
                        // Paciente
                        HStack {
                            Image(systemName: "person.fill")
                                .foregroundColor(colors.blue)
                                .font(.system(size: 16))
                            Text("Paciente: \(prescription.patientName)")
                                .font(.system(size: 16, weight: .regular, design: .rounded))
                                .foregroundColor(.black)
                            Spacer()
                        }
                        .padding(12)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(colors.blue.opacity(0.3), lineWidth: 1)
                        )


                        // Médico
                        HStack {
                            Image(systemName: "stethoscope")
                                .foregroundColor(colors.blue)
                                .font(.system(size: 16))
                            Text("Médico: \(prescription.doctorName)")
                                .font(.system(size: 16, weight: .regular, design: .rounded))
                                .foregroundColor(.black)
                            Spacer()
                        }
                        .padding(12)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(colors.blue.opacity(0.3), lineWidth: 1)
                        )


                        // Fecha
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(colors.blue)
                                .font(.system(size: 16))
                            Text("Fecha: \(prescription.date)")
                                .font(.system(size: 16, weight: .regular, design: .rounded))
                                .foregroundColor(.black)
                            Spacer()
                        }
                        .padding(12)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(colors.blue.opacity(0.3), lineWidth: 1)
                        )

                        // Hora
                        HStack {
                            Image(systemName: "clock")
                                .foregroundColor(colors.blue)
                                .font(.system(size: 16))
                            Text("Hora: \(prescription.hour)")
                                .font(.system(size: 16, weight: .regular, design: .rounded))
                                .foregroundColor(.black)
                            Spacer()
                        }
                        .padding(12)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(colors.blue.opacity(0.3), lineWidth: 1)
                        )

                        // Diagnóstico
                        HStack {
                            Image(systemName: "cross.case.fill")
                                .foregroundColor(colors.blue)
                                .font(.system(size: 16))
                            Text("Diagnóstico: \(prescription.diagnosis)")
                                .font(.system(size: 16, weight: .regular, design: .rounded))
                                .foregroundColor(.black)
                            Spacer()
                        }
                        .padding(12)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(colors.blue.opacity(0.3), lineWidth: 1)
                        )

                        // Receta
                        HStack {
                            Image(systemName: "pills.fill")
                                .foregroundColor(colors.blue)
                                .font(.system(size: 16))
                            Text("Receta: \(prescription.prescription)")
                                .font(.system(size: 16, weight: .regular, design: .rounded))
                                .foregroundColor(.black)
                            Spacer()
                        }
                        .padding(12)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(colors.blue.opacity(0.3), lineWidth: 1)
                        )

                        // Creado el
                        HStack {
                            Image(systemName: "clock.fill")
                                .foregroundColor(colors.blue)
                                .font(.system(size: 16))
                            Text("Creado el: \(dateFormatter.string(from: prescription.createdAt.dateValue()))")
                                .font(.system(size: 16, weight: .regular, design: .rounded))
                                .foregroundColor(.black)
                            Spacer()
                        }
                        .padding(12)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(colors.blue.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
                Spacer()
            }
            .padding(.top, 1)
            .navigationBarTitle("", displayMode: .inline)
            .navigationBarBackButtonHidden(false)
            .onAppear {
                print("PrescriptionDetailView appeared for prescription ID: \(prescription.id)")
            }
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
