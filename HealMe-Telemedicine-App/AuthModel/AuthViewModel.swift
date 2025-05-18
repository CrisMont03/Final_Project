//
//  AuthViewModel.swift
//  HealMe-Telemedicine-App
//
//  Created by Cristian Montiel García on 16/05/25.
//

import FirebaseAuth
import FirebaseFirestore
import Foundation
import FirebaseCore

class AuthViewModel: ObservableObject {
    @Published var errorMessage: String = ""
    @Published var userIsLoggedIn: Bool = false
    @Published var isDoctor: Bool = false
    @Published var doctorData: [String: Any]? = nil
    @Published var isPatientRegistrationComplete: Bool = false
    @Published var patientName: String = ""
    @Published var patientMedicalHistory: [String: Any] = [:]
    private var authStateHandle: AuthStateDidChangeListenerHandle?
    private let db = Firestore.firestore()

    init() {
        // Inicializar Firebase explícitamente
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
            print("Firebase initialized in AuthViewModel")
        } else {
            print("Firebase already initialized")
        }

        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self = self else { return }
            print("Auth state changed: user=\(user?.uid ?? "none"), email=\(user?.email ?? "none")")
            self.userIsLoggedIn = user != nil
            if let user = user {
                let email = user.email ?? ""
                self.isDoctor = email.hasSuffix("@healme.doc.co")
                print("User is doctor: \(self.isDoctor)")
                if self.isDoctor {
                    self.fetchDoctorData(email: email)
                    self.isPatientRegistrationComplete = true
                    self.patientName = ""
                    self.patientMedicalHistory = [:]
                } else {
                    self.doctorData = nil
                    self.checkPatientRegistration(userId: user.uid)
                    self.fetchPatientData(userId: user.uid)
                }
            } else {
                print("No user logged in, resetting state")
                self.isDoctor = false
                self.doctorData = nil
                self.isPatientRegistrationComplete = false
                self.patientName = ""
                self.patientMedicalHistory = [:]
                self.errorMessage = ""
            }
        }
    }

    deinit {
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
            print("Auth state listener removed")
        }
    }

    func signIn(email: String, password: String) {
        print("Attempting to sign in with email: \(email)")
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            guard let self = self else { return }
            if let error = error {
                let errorCode = (error as NSError).code
                switch errorCode {
                case AuthErrorCode.wrongPassword.rawValue:
                    self.errorMessage = "Contraseña incorrecta"
                case AuthErrorCode.invalidEmail.rawValue:
                    self.errorMessage = "Correo no válido"
                case AuthErrorCode.userNotFound.rawValue:
                    self.errorMessage = "Usuario no encontrado"
                case AuthErrorCode.networkError.rawValue:
                    self.errorMessage = "Error de red, verifica tu conexión"
                default:
                    self.errorMessage = "Error al iniciar sesión: \(error.localizedDescription)"
                }
                print("Sign-in error: \(self.errorMessage) (code: \(errorCode))")
                return
            }
            print("Sign-in successful for email: \(email)")
            self.errorMessage = ""
        }
    }

    func signUpPatient(email: String, password: String, name: String, completion: @escaping (Bool) -> Void) {
        print("Attempting to sign up patient with email: \(email), name: \(name)")
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            guard let self = self else {
                print("Self is nil in signUpPatient")
                completion(false)
                return
            }
            if let error = error {
                let errorCode = (error as NSError).code
                switch errorCode {
                case AuthErrorCode.emailAlreadyInUse.rawValue:
                    self.errorMessage = "El correo ya está registrado"
                case AuthErrorCode.weakPassword.rawValue:
                    self.errorMessage = "La contraseña debe tener al menos 6 caracteres"
                case AuthErrorCode.invalidEmail.rawValue:
                    self.errorMessage = "El correo no es válido"
                case AuthErrorCode.networkError.rawValue:
                    self.errorMessage = "Error de red, verifica tu conexión"
                default:
                    self.errorMessage = "Error al registrarse: \(error.localizedDescription)"
                }
                print("Sign-up error: \(self.errorMessage) (code: \(errorCode))")
                completion(false)
                return
            }
            guard let user = result?.user else {
                self.errorMessage = "No se pudo obtener el ID del usuario"
                print("Sign-up error: No user ID")
                completion(false)
                return
            }
            let patientData: [String: Any] = [
                "email": email,
                "name": name,
                "createdAt": Timestamp(),
                "isDoctor": false
            ]
            print("Saving patient data to Firestore: \(patientData)")
            self.db.collection("patients").document(user.uid).setData(patientData) { error in
                if let error = error {
                    self.errorMessage = "Error al guardar datos del paciente: \(error.localizedDescription)"
                    print("Firestore error: \(error.localizedDescription)")
                    completion(false)
                    return
                }
                print("Patient data saved successfully for user: \(user.uid)")
                self.patientName = name
                self.isPatientRegistrationComplete = false
                self.errorMessage = ""
                completion(true)
            }
        }
    }

    func updateMedicalHistory(userId: String, age: Int, gender: String, weight: Double, height: Double, bloodType: String, diet: String, exercise: String, allergies: String, completion: @escaping (Bool) -> Void) {
        print("Updating medical history for userId: \(userId)")
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
        self.db.collection("patients").document(userId).updateData(medicalHistory) { [weak self] error in
            guard let self = self else {
                print("Self is nil in updateMedicalHistory")
                completion(false)
                return
            }
            if let error = error {
                self.errorMessage = "Error al guardar historial médico: \(error.localizedDescription)"
                print("Firestore error: \(error.localizedDescription)")
                completion(false)
                return
            }
            print("Medical history updated: \(medicalHistory)")
            self.patientMedicalHistory = medicalHistory
            self.isPatientRegistrationComplete = true
            self.errorMessage = ""
            completion(true)
        }
    }

    private func checkPatientRegistration(userId: String) {
        print("Checking patient registration for userId: \(userId)")
        db.collection("patients").document(userId).getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            if let error = error {
                print("Error checking patient registration: \(error.localizedDescription)")
                self.isPatientRegistrationComplete = false
                self.errorMessage = "Error al verificar registro del paciente"
                return
            }
            if let data = snapshot?.data(), data["age"] != nil {
                print("Patient registration complete: \(data)")
                self.isPatientRegistrationComplete = true
            } else {
                print("Patient registration incomplete")
                self.isPatientRegistrationComplete = false
            }
        }
    }

    private func fetchPatientData(userId: String) {
        print("Fetching patient data for userId: \(userId)")
        db.collection("patients").document(userId).getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            if let error = error {
                print("Error fetching patient data: \(error.localizedDescription)")
                self.errorMessage = "Error al cargar datos del paciente"
                return
            }
            guard let data = snapshot?.data() else {
                print("No patient data found for userId: \(userId)")
                self.errorMessage = "No se encontraron datos del paciente"
                return
            }
            print("Patient data fetched: \(data)")
            self.patientName = data["name"] as? String ?? ""
            self.patientMedicalHistory = data
        }
    }

    private func fetchDoctorData(email: String) {
        print("Fetching doctor data for email: \(email)")
        db.collection("doctors")
            .whereField("email", isEqualTo: email)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                if let error = error {
                    print("Error fetching doctor data: \(error.localizedDescription)")
                    self.errorMessage = "Error al buscar datos del médico"
                    self.doctorData = nil
                    return
                }
                guard let documents = snapshot?.documents, !documents.isEmpty else {
                    print("No doctor data found for email: \(email)")
                    self.errorMessage = "No se encontró información para este médico"
                    self.doctorData = nil
                    return
                }
                self.doctorData = documents.first?.data()
                print("Doctor data fetched: \(String(describing: self.doctorData))")
                self.errorMessage = ""
            }
    }
}
