//
//  DiagnosisFormView.swift
//  HealMe-Telemedicine-App
//
//  Created by Cristian Montiel García on 20/05/25.
//

import SwiftUI
import FirebaseFirestore

struct Prescription: Identifiable {
    let id: String
    let patientId: String
    let patientName: String
    let doctorId: String
    let doctorName: String
    let date: String
    let hour: String
    let diagnosis: String
    let prescription: String
    let createdAt: Timestamp
}

struct Notification: Identifiable {
    let id: String
    let patientId: String
    let message: String
    let createdAt: Timestamp
    let read: Bool
}

struct DiagnosisFormView: View {
    let appointment: AppointmentDoctor
    @ObservedObject var authViewModel: AuthViewModel
    let onDismiss: () -> Void
    @State private var diagnosis: String = ""
    @State private var prescription: String = ""
    @State private var errorMessage: String = ""
    @State private var isSubmitting: Bool = false
    @Environment(\.dismiss) var dismiss

    private let colors = (
        red: Color(hex: "D40035"),
        green: Color(hex: "28A745"),
        blue: Color(hex: "007AFE"),
        background: Color(hex: "F5F6F9")
    )

    var body: some View {
        NavigationView {
            ZStack {
                colors.background
                    .ignoresSafeArea()

                VStack(spacing: 16) {
                    Text("Formulario de Diagnóstico")
                        .font(.system(size: 24, weight: .medium, design: .rounded))
                        .foregroundColor(.black)
                        .padding(.top, 16)

                    Text("Paciente: \(appointment.patientName)")
                        .font(.system(size: 18, weight: .regular, design: .rounded))
                        .foregroundColor(.gray)

                    TextEditor(text: $diagnosis)
                        .frame(height: 100)
                        .padding(8)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                        .padding(.horizontal, 16)
                        .overlay(
                            Text("Diagnóstico")
                                .font(.system(size: 14, weight: .regular, design: .rounded))
                                .foregroundColor(.gray)
                                .padding(.leading, 20)
                                .offset(y: -110),
                            alignment: .leading
                        )

                    TextEditor(text: $prescription)
                        .frame(height: 100)
                        .padding(8)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                        .padding(.horizontal, 16)
                        .overlay(
                            Text("Receta")
                                .font(.system(size: 14, weight: .regular, design: .rounded))
                                .foregroundColor(.gray)
                                .padding(.leading, 20)
                                .offset(y: -110),
                            alignment: .leading
                        )

                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(.system(size: 14, weight: .regular, design: .rounded))
                            .foregroundColor(colors.red)
                            .padding(.horizontal, 16)
                    }

                    Button(action: {
                        submitDiagnosis()
                    }) {
                        Text(isSubmitting ? "Enviando..." : "Enviar")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(diagnosis.isEmpty || prescription.isEmpty || isSubmitting ? .gray : colors.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(diagnosis.isEmpty || prescription.isEmpty || isSubmitting)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                        onDismiss()
                    }
                }
            }
        }
    }

    private func submitDiagnosis() {
        guard let doctorId = authViewModel.currentUserId else {
            errorMessage = "No se pudo obtener el ID del médico"
            return
        }

        isSubmitting = true
        errorMessage = ""

        // Buscar el ID del paciente
        let db = Firestore.firestore()
        db.collection("patients")
            .whereField("name", isEqualTo: appointment.patientName)
            .getDocuments { snapshot, error in
                if let error = error {
                    errorMessage = "Error al buscar paciente: \(error.localizedDescription)"
                    isSubmitting = false
                    return
                }

                guard let document = snapshot?.documents.first else {
                    errorMessage = "No se encontró al paciente"
                    isSubmitting = false
                    return
                }

                let patientId = document.documentID
                let prescriptionData: [String: Any] = [
                    "patientId": patientId,
                    "patientName": appointment.patientName,
                    "doctorId": doctorId,
                    "doctorName": authViewModel.doctorData?["name"] as? String ?? "Desconocido",
                    "date": appointment.date,
                    "hour": appointment.hour,
                    "diagnosis": diagnosis,
                    "prescription": prescription,
                    "createdAt": Timestamp()
                ]

                // Guardar la receta
                db.collection("prescriptions").addDocument(data: prescriptionData) { error in
                    if let error = error {
                        errorMessage = "Error al guardar la receta: \(error.localizedDescription)"
                        isSubmitting = false
                        return
                    }

                    // Crear notificación para el paciente
                    let notificationData: [String: Any] = [
                        "patientId": patientId,
                        "message": "El Dr. \(authViewModel.doctorData?["name"] as? String ?? "Desconocido") ha enviado una nueva receta",
                        "createdAt": Timestamp(),
                        "read": false
                    ]
                    db.collection("notifications").addDocument(data: notificationData) { error in
                        if let error = error {
                            print("Error al crear notificación: \(error.localizedDescription)")
                        }

                        isSubmitting = false
                        dismiss()
                        onDismiss()
                    }
                }
            }
    }
}
