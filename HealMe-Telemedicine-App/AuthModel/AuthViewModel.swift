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
    @Published var isPatientRegistrationComplete: Bool = false
    @Published var patientName: String = "" // Nuevo: Nombre del paciente
    @Published var patientMedicalHistory: [String: Any] = [:] // Nuevo: Historial médico
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
                    self.isPatientRegistrationComplete = true
                } else {
                    self.doctorData = nil
                    self.checkPatientRegistration(userId: user.uid)
                    self.fetchPatientData(userId: user.uid) // Nuevo: Obtener datos del paciente
                }
            } else {
                self.isDoctor = false
                self.doctorData = nil
                self.isPatientRegistrationComplete = false
                self.patientName = ""
                self.patientMedicalHistory = [:]
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

    func signUpPatient(email: String, password: String, name: String, completion: @escaping (Bool) -> Void) {
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
            let patientData: [String: Any] = [
                "email": email,
                "name": name,

                "createdAt": Timestamp()
            ]
            self.db.collection("patients").document(user.uid).setData(patientData) { error in
                if let error = error {
                    self.errorMessage = "Error al guardar datos del paciente: \(error.localizedDescription)"
                    completion(false)
                    return
                }
                self.errorMessage = ""
                self.patientName = name // Actualizar nombre
                self.isPatientRegistrationComplete = false
                completion(true)
            }
        }
    }

    func updateMedicalHistory(userId: String, age: Int, gender: String, weight: Double, height: Double, bloodType: String, diet: String, exercise: String, allergies: String, completion: @escaping (Bool) -> Void) {
        let medicalHistory: [String: Any] = [
            "age": age,
            "gender": gender,
            "weight": weight,
            "height": height,
            "bloodType": bloodType,
            "diet": diet,
            "exercise": exercise,
            "allergies": allergies,
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
            self.patientMedicalHistory = medicalHistory // Actualizar historial
            self.isPatientRegistrationComplete = true
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
                self.isPatientRegistrationComplete = true
            } else {
                self.isPatientRegistrationComplete = false
            }
        }
    }

    private func fetchPatientData(userId: String) {
        db.collection("patients").document(userId).getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            if let error = error {
                print("Error al obtener datos del paciente: \(error.localizedDescription)")
                self.errorMessage = "Error al cargar datos del paciente"
                return
            }
            guard let data = snapshot?.data() else {
                print("No se encontraron datos para el paciente: \(userId)")
                self.errorMessage = "No se encontraron datos del paciente"
                return
            }
            self.patientName = data["name"] as? String ?? ""
            self.patientMedicalHistory = data
            print("Datos del paciente cargados: \(data)")
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
                    self.errorMessage = "Error al buscar datos del médico"
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
