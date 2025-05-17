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
                } else {
                    self.doctorData = nil
                }
            } else {
                self.isDoctor = false
                self.doctorData = nil
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

    func signUp(email: String, password: String) {
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            if let error = error {
                self?.errorMessage = error.localizedDescription
                return
            }
            self?.errorMessage = ""
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
                // Tomamos el primer documento encontrado
                self.doctorData = documents.first?.data()
                print("Datos del médico encontrados: \(String(describing: self.doctorData))")
                self.errorMessage = ""
            }
    }
}
