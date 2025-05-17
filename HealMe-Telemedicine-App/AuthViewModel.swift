//
//  AuthViewModel.swift
//  HealMe-Telemedicine-App
//
//  Created by Cristian Montiel García on 16/05/25.
//

import FirebaseAuth
import FirebaseFirestore
import Foundation

class AuthViewModel: ObservableObject {
    @Published var errorMessage: String = ""
    @Published var userIsLoggedIn: Bool = false
    @Published var isDoctor: Bool = false
    @Published var doctorData: [String: Any]? = nil
    @Published var isPatientRegistrationComplete: Bool = false // Nueva propiedad
    private var authStateHandle: AuthStateDidChangeListenerHandle?
    private let db = Firestore.firestore()

    init() {
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self = self else { return }
            self.userIsLoggedIn = user != nil
            if let user = user {
                let email = user.email ?? ""
                print("Usuario autenticado con correo: \(email)")
                self.isDoctor = email.hasSuffix("@healme.doc.co")
                print("Es médico: \(self.isDoctor)")
                if self.isDoctor {
                    self.fetchDoctorData(email: email)
                    self.isPatientRegistrationComplete = true // Médicos no necesitan registro adicional
                } else {
                    self.doctorData = nil
                    // Verificar si el paciente ha completado el registro
                    self.checkPatientRegistration(userId: user.uid)
                }
            } else {
                self.isDoctor = false
                self.doctorData = nil
                self.isPatientRegistrationComplete = false
            }
        }
    }

    func signIn(email: String, password: String) {
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            if let error = error {
                self?.errorMessage = error.localizedDescription
                return
            }
            self?.errorMessage = ""
        }
    }

    func signUpPatient(email: String, password: String, name: String, idNumber: String, phone: String, completion: @escaping (Bool) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            guard let self = self else { return }
            if let error = error {
                self.errorMessage = error.localizedDescription
                completion(false)
                return
            }
            guard let user = result?.user else {
                self.errorMessage = "Error al obtener el usuario"
                completion(false)
                return
            }
            // Guardar datos del paciente en Firestore
            let patientData: [String: Any] = [
                "email": email,
                "name": name,
                "idNumber": idNumber,
                "phone": phone,
                "createdAt": Timestamp()
            ]
            self.db.collection("patients").document(user.uid).setData(patientData) { error in
                if let error = error {
                    self.errorMessage = "Error al guardar datos del paciente: \(error.localizedDescription)"
                    completion(false)
                    return
                }
                self.errorMessage = ""
                self.isPatientRegistrationComplete = false // Registro inicial, pero falta historial médico
                completion(true)
            }
        }
    }

    func updateMedicalHistory(userId: String, age: Int, gender: String, weight: Double, height: Double, bloodType: String, diet: String, exercise: String, allergies: String, medicalCondition: String, completion: @escaping (Bool) -> Void) {
        let medicalHistory: [String: Any] = [
            "age": age,
            "gender": gender,
            "weight": weight,
            "height": height,
            "bloodType": bloodType,
            "diet": diet,
            "exercise": exercise,
            "allergies": allergies,
            "medicalCondition": medicalCondition,
            "updatedAt": Timestamp()
        ]
        db.collection("patients").document(userId).updateData(medicalHistory) { [weak self] error in
            guard let self = self else { return }
            if let error = error {
                self.errorMessage = "Error al guardar historial médico: \(error.localizedDescription)"
                completion(false)
                return
            }
            self.errorMessage = ""
            self.isPatientRegistrationComplete = true // Registro completo
            completion(true)
        }
    }

    private func checkPatientRegistration(userId: String) {
        db.collection("patients").document(userId).getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            if let error = error {
                print("Error al verificar registro del paciente: \(error.localizedDescription)")
                self.isPatientRegistrationComplete = false
                return
            }
            if let data = snapshot?.data(), data["age"] != nil {
                self.isPatientRegistrationComplete = true // Historial médico presente
            } else {
                self.isPatientRegistrationComplete = false
            }
        }
    }

    private func fetchDoctorData(email: String) {
        print("Buscando datos del médico para el correo: \(email)")
        db.collection("doctors")
            .whereField("email", isEqualTo: email)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                if let error = error {
                    print("Error al buscar datos del médico: \(error.localizedDescription)")
                    self.errorMessage = "Error al buscar datos del médico: \(error.localizedDescription)"
                    self.doctorData = nil
                    return
                }
                guard let documents = snapshot?.documents, !documents.isEmpty else {
                    print("No se encontraron documentos para el correo: \(email)")
                    self.errorMessage = "No se encontró información para este médico"
                    self.doctorData = nil
                    return
                }
                self.doctorData = documents.first?.data()
                print("Datos del médico encontrados: \(String(describing: self.doctorData))")
                self.errorMessage = ""
            }
    }
}
